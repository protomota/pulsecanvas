#include <metal_stdlib>
using namespace metal;
struct SpatialFrame {
    float2 resolution; float time; int scene;
    float4 rhythm; // pulse, beat drive, bass, treble
    float4 style; // brightness, size, fog, zoom
    float4 camera; // rotation, chaos, liquid detail / halo count, zoom speed
    float4 colors[5];
};
struct SpatialPixel { float4 position [[position]]; float2 uv; };
vertex SpatialPixel spatialVertex(uint id [[vertex_id]]) {
    float2 p = float2((id << 1) & 2, id & 2);
    return {float4(p * 2 - 1, 0, 1), p};
}
float2 spin(float2 p, float a) { float c = cos(a), s = sin(a); return float2(c*p.x-s*p.y,s*p.x+c*p.y); }
float3 tint(float phase, constant SpatialFrame &f) {
    float cycle = phase - floor(phase / 2) * 2;
    float t = (cycle < 1 ? cycle : 2-cycle) * 4;
    int i = min(3, int(t)); return mix(f.colors[i].rgb, f.colors[i+1].rgb, t-i);
}
float cellHash(float3 p) { return fract(sin(dot(p,float3(127.1,311.7,74.7))) * 43758.5453); }
float2 inkBend(float z) { return float2(sin(z*.11)*2,cos(z*.09)*1.8); }
float mist(float3 p) {
    return sin(p.x+sin(p.z*.7))*sin(p.y+cos(p.x*.8))*sin(p.z+cos(p.y*.6));
}
// Source attacks launch local waves; high Chaos gives a stronger liquid response.
float organicStrength(constant SpatialFrame &f) {
    return f.rhythm.x*(.2+.55*f.camera.y)+f.rhythm.y*.08+f.rhythm.z*.12;
}
float field(float3 p, constant SpatialFrame &f) {
    float t=f.time, strength=organicStrength(f), size=clamp(f.style.y, .3f, 3.f);
    float beat=f.rhythm.x*(.55+.45*sin(dot(p,float3(.61,.83,.47))-t*1.6));
    float3 world=p;
    if(f.scene!=23 && f.scene!=12 && f.scene!=26) p+=sin(p.zxy*.9+float3(-t*.9,t*.7,t*.8))*strength*.20;
    if (f.scene == 12) {
        // Spheres can cross their cell edges while bouncing. Evaluate all adjacent
        // centers instead of cutting the field at the nearest-cell boundary.
        float2 base=floor(p.xz/2.8);
        float distance=100;
        for(int z=0;z<2;z++) for(int x=0;x<2;x++) {
            float2 cell=base+float2(x,z), q=p.xz-cell*2.8;
            float bounce=f.rhythm.z*(.9+.9*sin(cell.x*1.37+cell.y*.91+t*2.3))+f.rhythm.w*.45*sin(cell.x*2.1-cell.y*1.7+t*3.1);
            // Keep both rows clear of the camera without clipping their bounce.
            float h=2.3*tanh((sin(cell.x*.53+t*.5)*.8+cos(cell.y*.42-t*.36)*.9+bounce)/2.3);
            float y=min(abs(p.y-h),abs(p.y-(9-h)));
            float localAttack=f.rhythm.x*(.55+.45*sin(cell.x*.61+cell.y*.47-t*1.6));
            float radius=.95+size*.10+localAttack*.18+f.rhythm.w*.14*cellHash(float3(cell,1));
            distance=min(distance,length(float3(q.x,y,q.y))-radius);
        }
        return distance;
    }
    if (f.scene == 23) {
        float detail=clamp(f.camera.z,0.f,1.f), frequency=.9+detail*.9;
        // Keep the camera in an open cavity while the surrounding surface flows.
        p=(p-float3(.9817477))*frequency+float3(.7853982);
        float flow=smoothstep(0.f,.55f,length(p-float3(.7853982)));
        p+=sin(p.zxy*1.4+float3(t*.6,-t*.47,t*.52))*(.15+detail*.08)*flow;
        // Ripple different folds in different directions, keeping the camera cavity open.
        p+=sin(p.yzx*2.3+float3(-t*1.3,t*1.1,t*.9))*strength*.38*flow;
        p+=sin(p.zxy*5.1+float3(t*.8,-t*.7,t))*strength*.10*flow;
        p+=sin(p.yzx*(4+detail*7)+float3(-t,t*.8,t*.7))*(.035+detail*.20)*flow;
        float g=dot(sin(p),cos(p.yzx));
        g+=flow*.22*dot(sin(p*2+t*.18),cos(p.zxy*2-t*.14));
        g+=flow*detail*.22*dot(sin(p*7-t*.45),cos(p.yzx*7+t*.41));
        float localSwelling=strength*.09*(.5+.5*sin(dot(p,float3(1.7,2.1,1.3))-t*1.4));
        return (abs(g)-(.16+size*.03+localSwelling))*(.10/frequency);
    }
    if (f.scene == 24) {
        p+=sin(p.zxy*1.1+t*.8)*(.25+beat*.25);
        float3 q=p-floor(p/4+0.5)*4;
        return min(length(q.xy),min(length(q.yz),length(q.xz)))-(.035+size*.035);
    }
    if (f.scene == 27) {
        // Mirrored skyline: seeded towers rise from the floor and ceiling.
        float2 cell=floor(p.xz/3.2+0.5), q=p.xz-cell*3.2;
        float seed=cellHash(float3(cell.x,0,cell.y));
        float height=1.2+seed*1.3+(.5+.5*sin(t*.8+seed*6.283))*(.5+beat*.6)+f.rhythm.z*.7*(.5+.5*sin(seed*17+t*2.4));
        float y=min(abs(p.y-(height-3.8)),abs(p.y-(9.8-height)));
        float3 d=abs(float3(q.x,y,q.y))-float3(.72+size*.12,height,.85+size*.08);
        return length(max(d,0.f))+min(max(d.x,max(d.y,d.z)),0.f)-.08;
    }
    if (f.scene == 28) {
        // Rings surround the flight path in staggered, independently tumbling groups.
        float count=clamp(round(f.camera.z),1.f,12.f), period=7.2;
        float3 group=floor(p/period+.5), local=p-group*period;
        float row=group.z;
        float2 orbitPoint=spin(local.xy,t*.18+row*.53);
        float sector=6.2831853/count;
        float nearest=floor(atan2(orbitPoint.y,orbitPoint.x)/sector+.5);
        float distance=100;
        // Only neighbouring angular sectors can contribute; cost stays bounded at twelve rings.
        for(int neighbour=-1;neighbour<=1;neighbour++) {
            float index=nearest+neighbour;
            float identity=index-floor(index/count)*count;
            float seed=cellHash(float3(identity+group.x*13,group.y*29,row));
            float angle=index*sector;
            float orbit=1.85+sin(t*.32+seed*6.283)*(.15+beat*.12);
            float3 q=float3(orbitPoint-float2(cos(angle),sin(angle))*orbit,local.z);
            q.xy=spin(q.xy,seed*6.283+t*(.18+seed*.24));
            q.yz=spin(q.yz,seed*4+sin(t*.33+seed*6)*.85);
            float radius=.7+seed*.28+beat*.15;
            float thickness=.085+clamp(size,.3f,6.f)*.04;
            distance=min(distance,length(float2(length(q.xy)-radius,q.z))-thickness);
        }
        return distance;
    }
    if (f.scene == 29) {
        // A camera inside continuous wave walls; the positive field is the open waterway.
        // Low levels heave the waves; highs add a fast chop along the walls.
        float surge=.45+beat*.25+f.rhythm.z*.55;
        float chop=f.rhythm.w*.22*sin(p.z*3.1+p.x*1.7-t*2.4);
        float ceiling=2.3+sin(p.x*.8+p.z*.55+t*.7)*surge+sin(p.z*1.5-t*.4)*.18+chop;
        float wall=3.4+sin(p.y*.9-p.z*.42+t*.55)*(.6+beat*.25+f.rhythm.z*.45)+chop;
        return min(ceiling-abs(p.y),wall-abs(p.x))*.45;
    }
    // Prisms overlap cell boundaries when rotated: use the neighboring-object union.
    float3 base=floor(p/3.8);
    float distance=100;
    for(int z=0;z<2;z++) for(int y=0;y<2;y++) for(int x=0;x<2;x++) {
        float3 cell=base+float3(x,y,z), q=p-cell*3.8;
        float seed=cellHash(cell);
        q-=(float3(seed,cellHash(cell+5.7),cellHash(cell+9.2))-.5)*1.2;
        q.xy=spin(q.xy,t*(.18+seed*.3)+seed*6.283);
        q.yz=spin(q.yz,t*.24+seed*4);
        float pump=f.rhythm.z*(.2+.25*sin(seed*23+t*2.2));
        float localAttack=f.rhythm.x*(.55+.45*sin(seed*19-t*1.6));
        float prism=(dot(abs(q),float3(1))-(1.1+size*.16+localAttack*.23+pump))*.57735-.07;
        distance=min(distance,prism);
    }
    float3 lane=world-float3(1.5,1.8,0);
    float3 laneDirection=normalize(float3(0,-2,1.9));
    float corridor=1.25-length(lane-laneDirection*dot(lane,laneDirection));
    return max(distance,corridor);
}
// Exact ray intersections for the joined cell objects. This avoids raymarch
// iteration limits on flat prism faces and preserves silhouettes at export resolution.
float pearlRay(float3 ro, float3 rd, float3 center, float radius) {
    float3 delta=ro-center;
    float b=dot(delta,rd), discriminant=b*b-dot(delta,delta)+radius*radius;
    if(discriminant<0) return 1e4;
    float root=sqrt(discriminant), near=-b-root;
    return near>=0 ? near : (-b+root>=0 ? -b+root : 1e4);
}
float prismRay(float3 ro, float3 rd, float radius, float corridorExit) {
    float near=max(0.f,corridorExit), far=32;
    for(int z=0;z<2;z++) for(int y=0;y<2;y++) for(int x=0;x<2;x++) {
        float3 face=float3(x?1:-1,y?1:-1,z?1:-1);
        float denominator=dot(face,rd), numerator=radius-dot(face,ro);
        if(abs(denominator)<1e-6) {if(numerator<0)return 1e4;}
        else if(denominator>0) far=min(far,numerator/denominator);
        else near=max(near,numerator/denominator);
    }
    return near<=far ? near : 1e4;
}
float joinedCellRay(float3 ro,float3 rd,constant SpatialFrame &f) {
    bool pearls=f.scene==12;
    float spacing=pearls ? 2.8 : 3.8;
    float3 cell=floor(ro/spacing);
    float3 safeDirection=select(-max(abs(rd),float3(1e-6)),max(abs(rd),float3(1e-6)),rd>=0);
    float3 direction=select(float3(-1),float3(1),rd>=0);
    float3 boundary=(cell+select(float3(0),float3(1),rd>=0))*spacing;
    float3 next=(boundary-ro)/safeDirection, interval=spacing/abs(safeDirection);
    float corridorExit=0;
    if(pearls){cell.y=0;next.y=1e5;interval.y=1e5;}
    else {
        float3 axis=normalize(float3(0,-2,1.9)), delta=ro-float3(1.5,1.8,0);
        float3 origin=delta-axis*dot(delta,axis), ray=rd-axis*dot(rd,axis);
        float a=dot(ray,ray), b=dot(origin,ray), c=dot(origin,origin)-1.25*1.25;
        if(a<1e-8)return -1;
        corridorExit=max(0.f,(-b+sqrt(max(0.f,b*b-a*c)))/a);
    }
    float closest=1e4, size=clamp(f.style.y,.3f,3.f), entry=0;
    for(int step=0;step<32;step++) {
        if(entry>min(32.f,closest))break;
        for(int z=0;z<2;z++) for(int y=0;y<(pearls?1:2);y++) for(int x=0;x<2;x++) {
            float3 centerCell=cell+float3(x,y,z);
            if(pearls) {
                float2 id=centerCell.xz;
                float bounce=f.rhythm.z*(.9+.9*sin(id.x*1.37+id.y*.91+f.time*2.3))+f.rhythm.w*.45*sin(id.x*2.1-id.y*1.7+f.time*3.1);
                float height=2.3*tanh((sin(id.x*.53+f.time*.5)*.8+cos(id.y*.42-f.time*.36)*.9+bounce)/2.3);
                float attack=f.rhythm.x*(.55+.45*sin(id.x*.61+id.y*.47-f.time*1.6));
                float radius=.95+size*.10+attack*.18+f.rhythm.w*.14*cellHash(float3(id,1));
                float3 center=float3(id.x*spacing,height,id.y*spacing);
                closest=min(closest,pearlRay(ro,rd,center,radius)); center.y=9-height;
                closest=min(closest,pearlRay(ro,rd,center,radius));
            } else {
                float seed=cellHash(centerCell);
                float3 offset=(float3(seed,cellHash(centerCell+5.7),cellHash(centerCell+9.2))-.5)*1.2;
                float3 origin=ro-centerCell*spacing-offset, ray=rd;
                origin.xy=spin(origin.xy,f.time*(.18+seed*.3)+seed*6.283);ray.xy=spin(ray.xy,f.time*(.18+seed*.3)+seed*6.283);
                origin.yz=spin(origin.yz,f.time*.24+seed*4);ray.yz=spin(ray.yz,f.time*.24+seed*4);
                float pump=f.rhythm.z*(.2+.25*sin(seed*23+f.time*2.2));
                float attack=f.rhythm.x*(.55+.45*sin(seed*19-f.time*1.6));
                float radius=1.1+size*.16+attack*.23+pump+.07/.57735;
                closest=min(closest,prismRay(origin,ray,radius,corridorExit));
            }
        }
        entry=min(next.x,min(next.y,next.z));
        float3 crossed=float3(next.x<=entry+1e-5?1:0,next.y<=entry+1e-5?1:0,next.z<=entry+1e-5?1:0);
        cell+=direction*crossed; next+=interval*crossed;
    }
    return closest<=32 ? closest : -1;
}
float3 volume(float3 ro, float3 rd, constant SpatialFrame &f) {
    float3 result=0; float transmission=1;
    for (int i=0;i<36;i++) {
        float distance=.5+i*.55;
        float3 p=ro+rd*distance;
        float strength=organicStrength(f);
        p+=sin(p.yzx*.8+float3(f.time*.9,-f.time*.7,f.time*.6))*strength*.25;
        float density, phase;
        if (f.scene==10) {
            float bend=sin(p.z*.34+f.time*.3)*2.1+sin(p.y*.24+f.time*.4);
            float sheet=sin((p.x+bend)*1.4);
            float ribbons=exp(-abs(sheet)*(9.f/clamp(f.style.y,.5f,3.f)));
            float folds=.55+.45*sin(p.y*.7+p.z*.3+f.time*.55);
            density=ribbons*folds*(.15+f.rhythm.x*.13);
            phase=p.y*.06+p.z*.025+f.time*.012;
        } else {
            // Fly inside a curved world-space ink tunnel: nearby walls expand past the camera.
            float2 wall=spin(p.xy-inkBend(p.z),p.z*.18);
            float angle=atan2(wall.y,wall.x), radius=length(wall);
            float3 flow=float3(wall,p.z*.42);
            float cloud=mist(flow*1.1+f.time*.07)+.4*mist(flow*2.3-f.time*.11);
            float tunnelRadius=2.35+sin(p.z*.57+angle*3)*.26+cloud*.32
                +strength*.34*sin(angle*4+p.z*.8-f.time*1.2);
            float sheet=exp(-pow((radius-tunnelRadius)/(.48+clamp(f.style.y,.3f,3.f)*.12),2.f)*2);
            float spiral=.5+.5*sin(angle*5+p.z*1.3+cloud*1.4-f.time*.12);
            float ribbons=.20+.80*pow(spiral,3.f);
            density=sheet*ribbons*(.55+f.rhythm.x*.40)*(.55+.45*smoothstep(-.8f,.8f,cloud));
            phase=p.z*.045+sin(angle)*.16+cloud*.19+f.time*.014;
        }
        density*=exp(-distance*clamp(f.style.z,0.f,1.f)*.025);
        float3 color=tint(phase,f);
        result+=transmission*density*color*(1.3+f.rhythm.x*.5);
        transmission*=1-density*.65;
    }
    return result;
}
// One continuous coordinate field keeps neighbouring cell edges joined as the funnel bends.
float3 meshVortex(float2 uv, constant SpatialFrame &f) {
    float t=f.time, beat=f.rhythm.x, strength=organicStrength(f);
    float2 center=float2(sin(t*.17)*.38,cos(t*.13)*.28);
    // Smooth camera drift avoids lateral jumps on individual attacks.
    float2 p=uv/clamp(f.style.w,.3f,2.f)-center;
    float radius=length(p), angle=atan2(p.y,p.x);
    float depth=-log(max(radius*.45,.018f))*7;
    float twist=angle+depth*.13+t*.19+sin(depth*.23-t*.4)*.12;
    // 24 cells around the circumference; an even repeat keeps the angular seam connected.
    float2 lattice=float2(twist*(48/6.2831853),depth*1.2+t*clamp(f.camera.w,0.f,3.f)*3.4);
    lattice.y+=sin(angle*3+t*.32)*.35;
    // Warp one shared coordinate field, so neighbouring cells keep joined edges.
    // Integer angular harmonics preserve the seam around the tunnel circumference.
    float2 wave=float2(sin(angle*5+depth*.85-t*1.4),sin(angle*3-depth*.67+t*1.1));
    float2 fine=float2(sin(angle*7-depth*1.2+t*.8),cos(angle*4+depth*.93-t*1.3));
    lattice+=strength*(wave*.68+fine*.20);
    // A staggered lattice tiles exclusively with six-sided honeycomb cells.
    const float2 spacing=float2(2,3.46410162);
    float2 a=lattice-spacing*round(lattice/spacing);
    float2 shifted=lattice-spacing*.5;
    float2 b=shifted-spacing*round(shifted/spacing);
    float2 cell=abs(dot(a,a)<dot(b,b) ? a : b);
    float distance=abs(1-max(cell.x,dot(cell,float2(.5,.8660254))));
    float2 dx=dfdx(lattice), dy=dfdy(lattice);
    // Unwrap the circumference before measuring pixel width at the atan2 seam.
    dx.x-=round(dx.x/48)*48; dy.x-=round(dy.x/48)*48;
    float2 footprint=abs(dx)+abs(dy);
    float width=max(.0001f,min(.32f,length(footprint)*(.55+clamp(f.style.y,.3f,6.f)*.22)));
    float core=exp(-pow(distance/width,2.f)*2.5);
    float glow=exp(-distance/(width*2.8))*.28;
    float depthFade=exp(-max(0.f,depth-6)*clamp(f.style.z,0.f,1.f)*.025);
    float centerFade=smoothstep(.025f,.10f,radius);
    float phase=.48+uv.y*.23+sin(angle+t*.14)*.065+t*.018;
    float localLight=beat*(.5+.5*sin(angle*5+depth*.6-t));
    float3 color=tint(phase,f)*(core*(2.0+localLight*.35)+glow)*depthFade*centerFade;
    color+=tint(.65+t*.018,f)*exp(-radius*35)*.35;
    color*=max(0.f,f.style.x);
    return 1-exp(-color*1.45);
}
fragment float4 spatialFragment(SpatialPixel input [[stage_in]], constant SpatialFrame &f [[buffer(0)]]) {
    float2 uv=(input.position.xy/f.resolution-.5)*float2(2*f.resolution.x/f.resolution.y,-2);
    uv=spin(uv,f.camera.x);
    float t=f.time, beat=f.rhythm.x;
    if(f.scene==22) return float4(meshVortex(uv,f),1);
    float zoomSpeed=clamp(f.camera.w,0.f,3.f);
    float3 ro=float3(sin(t*.23)*.3,cos(t*.19)*.3,t*1.9*zoomSpeed);
    float3 rd=normalize(float3(uv,1.45*clamp(f.style.w,.5f,2.5f)));
    if (f.scene==12) { ro.y=4.2; rd.y-=.24+sin(t*.14)*.12; rd=normalize(rd); }
    if (f.scene==23) { ro=float3(.9817477); rd=normalize(float3(uv*1.8,1.05*clamp(f.style.w,.5f,2.5f))); rd.xy=spin(rd.xy,t*.13); rd.yz=spin(rd.yz,sin(t*.17)*.45); }
    if (f.scene==24) { ro.xy+=float2(1.6,1.7); }
    if (f.scene==25) { ro.z=t*3.2*zoomSpeed; ro.xy=inkBend(ro.z); }
    if (f.scene==26) { ro.y=-t*2.0*zoomSpeed+1.8; ro.x+=1.5; }
    if (f.scene==27) { ro=float3(1.6,3,t*3.2*zoomSpeed); rd.y-=.12+sin(t*.2)*.12; }
    if (f.scene==28) { ro.xy=float2(sin(t*.17)*.15,cos(t*.13)*.15); rd.xy=spin(rd.xy,sin(t*.19)*.25); }
    if (f.scene==29) { ro=float3(sin(t*.23)*.7,cos(t*.29)*.4,t*2.6*zoomSpeed); rd.xy=spin(rd.xy,sin(t*.24)*.3); }
    if(f.scene==12 || f.scene==26 || f.scene==27) rd.xz=spin(rd.xz,sin(t*.09)*.22+sin(t*.037)*.12);
    rd=normalize(rd);
    float3 atmospheric=tint(.15+uv.y*.09+t*.01,f)*(.045+.02*(.5+.5*sin(uv.x*2+uv.y*3+t*.3)));
    if(f.scene==23 || f.scene==25) atmospheric*=.16;
    float3 color=atmospheric;
    if (f.scene==10 || f.scene==25) {
        color+=volume(ro,rd,f);
    } else {
        float travel=0, glow=0; bool hit=false;
        bool joinedCells=f.scene==12 || f.scene==26;
        int steps=(f.scene==23 || joinedCells) ? 160 : (f.scene>=27 ? 128 : 64);
        float previousTravel=0;
        if(joinedCells){travel=joinedCellRay(ro,rd,f);hit=travel>=0;}
        for(int i=0;i<steps && !joinedCells;i++) {
            float d=field(ro+rd*travel,f);
            if(f.scene==24) glow+=exp(-abs(d)*16)*.025;
            if(joinedCells && d<0) {
                float low=previousTravel, high=travel;
                for(int refine=0;refine<7;refine++) {
                    float middle=(low+high)*.5;
                    if(field(ro+rd*middle,f)>0) low=middle; else high=middle;
                }
                travel=(low+high)*.5; hit=true; break;
            }
            if(abs(d)<(joinedCells ? .004 : (f.scene==23 ? .003 : .012))) {hit=true;break;}
            float advance=abs(d)*.75;
            // Repeated cells have discontinuous nearest-cell choices: cross them in bounded steps.
            if(joinedCells) advance=min(advance,.35f);
            if(f.scene==27 || f.scene==28) advance=min(advance,.4f);
            previousTravel=travel;
            travel+=max(joinedCells ? .002 : (f.scene==23 ? .003 : .015),advance);
            if(travel>32) break;
        }
        if(hit) {
            float3 p=ro+rd*travel;
            float e=joinedCells ? .018 : (f.scene==23 ? .006 : .018);
            float3 n=normalize(float3(field(p+float3(e,0,0),f)-field(p-float3(e,0,0),f),field(p+float3(0,e,0),f)-field(p-float3(0,e,0),f),field(p+float3(0,0,e),f)-field(p-float3(0,0,e),f))+float3(.00001));
            float3 light=normalize(float3(-.4,.7,-.6));
            float diffuse=abs(dot(n,light));
            float fresnel=pow(1-abs(dot(n,-rd)),3.f);
            float spec=pow(max(0.f,dot(reflect(rd,n),light)),24.f);
            float phase=dot(p,float3(.05,.04,.035))+t*.018+f.rhythm.z*.1;
            float shade=.24+diffuse*.65+spec*.7+fresnel*.34;
            if(f.scene==23) {
                float detail=clamp(f.camera.z,0.f,1.f);
                float ripple=.5+.5*sin(dot(p,float3(5,4,6))+sin(p.y*9+t)*detail-t*.7);
                phase=.15+(n.y*.5+.5)*.55+ripple*.2;
                float reflection=pow(max(0.f,dot(reflect(rd,n),light)),12.f);
                shade=.035+pow(diffuse,2.f)*.7+reflection*1.8+fresnel*1.2;
                shade*=.65+ripple*(.35+detail*.4);
            }
            if(f.scene==24) shade=1.5+beat;
            if(f.scene==28) { phase=dot(p,float3(.08,.06,.09))+t*.02; shade=.3+diffuse*.65+spec*1.3+fresnel*.7; }
            if(f.scene==29) {
                float ripple=.5+.5*sin(p.z*2.7+p.x*1.3+sin(p.y*3)-t*.6);
                phase=.2+ripple*.45+n.y*.12+f.rhythm.z*.15;
                // Crests catch light on the highs: bright bands travel along the walls.
                float crest=pow(.5+.5*sin(p.z*1.9-p.y*1.2-t*2.2),6.f)*f.rhythm.w;
                shade=.3+diffuse*.5+spec*1.6+fresnel*.7+ripple*.16+crest*1.4;
            }
            if(f.scene==26 || f.scene==27) {
                float3 cell=f.scene==27 ? float3(floor(p.xz/3.2+0.5),0).xzy : floor(p/(f.scene==4 ? 3.2 : 3.8)+0.5);
                float lit=.5+.5*sin(cellHash(cell)*19+t*2.3);
                phase+=f.rhythm.w*.2*lit;
                shade+=(f.rhythm.z*.55+f.rhythm.w*.4)*lit*lit;
            }
            if(f.scene==12) {
                float2 cell=floor(p.xz/2.8+0.5);
                float lit=.5+.5*sin(cell.x*1.37+cell.y*.91+t*2.3);
                phase+=f.rhythm.w*.25*lit;
                shade+=(f.rhythm.z*.7+f.rhythm.w*.5)*lit*lit;
            }
            float fog=exp(-travel*(.015+clamp(f.style.z,0.f,1.f)*.032));
            color=mix(atmospheric,tint(phase,f)*shade,fog);
        }
        color+=tint(.35+t*.025,f)*glow*(1+beat);
    }
    color*=max(0.f,f.style.x);
    // Tone-map each palette channel without introducing unrelated rainbow hues.
    color=1-exp(-color*1.45);
    return float4(color,1);
}
