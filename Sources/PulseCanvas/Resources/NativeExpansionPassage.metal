// Original PulseCanvas tunnel surfaces and independently choreographed depth stacks.
// Periodic cell sites keep the cylinder seam continuous, including cell colors.
float4 passageCells(float2 p,float width,float jitter,float phase){
 float2 cell=floor(p),f=fract(p);float first=8,second=8;float2 winner=0;
 for(int y=-1;y<=1;++y)for(int x=-1;x<=1;++x){
   float2 g=float2(x,y),id=cell+g;id.x-=width*floor(id.x/width);
   float2 seed=hash22(id),site=g+.5+jitter*.5*sin(phase+seed*TAU);
   float d=length(site-f);
   if(d<first){second=first;first=d;winner=id;}else second=min(second,d);
 }return float4(first,second,winner);
}

struct Passage { float a; float z; float r; float aa; };
Passage passage(Ctx c,float pitch,float sway) {
    float2 p=c.uv/c.size+float2(sin(c.t*.19),cos(c.t*.17))*sway;
    Passage w;w.r=max(length(p),.04f);w.z=pitch/w.r+c.travel*2;
    w.a=atan2(p.y,p.x)+c.t*.08;
    w.aa=min(.35f,c.px*(1+pitch/(w.r*w.r)));
    return w;
}
float3 passageFinish(float3 color,Passage w,constant NativeFrame &f){
    return color*smoothstep(.03f,.17f,w.r)+deep(.6,f)*.1;
}

float3 saffronSpindle(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.4,.12); float tooth=cos(w.a*18+w.z*.35+c.t*.25);
    float spoke=glow(sin(w.a*9+w.z*.15),.055), rib=line(sin(w.z*3+tooth*.3),.08,w.aa);
    float lathe=.5+.5*cos(w.z*1.7+tooth*(1+c.b.y));
    return passageFinish(paint((.5+.3*sin(w.a))+w.z*.015,f)*(.22+lathe*.45+rib*.9+spoke*.8),w,f);
}
NATIVE_EFFECT(saffronSpindle)

float3 opalineIris(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,1.8,.08); float sector=w.a*7+w.z*.28+c.t*.18;
    float leaf=.5+.5*cos(sector), shutter=sin(w.z*2.7+leaf*3+c.b.x*sin(sector*2));
    float vein=line(sin(sector*5-w.z),.06,w.aa), lip=glow(shutter,.095);
    float3 col=paint(leaf*.3+w.z*.022,f)*(.2+leaf*.55+vein*.25+lip);
    col+=paint(.85,f)*pow(max(0.f,cos(w.z*2.7+leaf*3)),14.f)*.6;
    return passageFinish(col,w,f);
}
NATIVE_EFFECT(opalineIris)

float3 electricHelicoid(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.8,.1); float helical=w.a*2+w.z*.65+c.t*.2;
    float sail=pow(.5+.5*cos(helical+c.b.y*sin(w.z)*.8),4.f);
    float seam=line(sin(w.z*5+helical*2),.08,w.aa)*sail;
    float counter=glow(sin(w.a*5-w.z*.45),.065);
    return passageFinish(paint((.5+.3*sin(helical))+w.z*.008,f)*(.16+sail*.95+seam*.6)+paint(.75,f)*counter*.9,w,f);
}
NATIVE_EFFECT(electricHelicoid)

float3 ultramarineArcade(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.2,.07); float2 q=float2(w.a*5/PI,w.z*.7), l=fract(q)-.5;
    float arch=length(float2(l.x,l.y*.7+max(0.f,l.y)*.6))-.38;
    float arcade=line(arch,.055,w.aa), pillar=glow(abs(l.x)-.42,.045);
    float window=fill(arch-.06,w.aa)*(.3+.3*cos(q.y+c.t*.4+c.b.x));
    return passageFinish(paint(q.y*.04+.3*sin(floor(q.x)*TAU/10),f)*(.2+arcade+pillar*.4+window),w,f);
}
NATIVE_EFFECT(ultramarineArcade)

float3 fuchsiaFurnace(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.5,.15); float ring=sin(w.z*2+sin(w.a*12)*.6);
    float tooth=pow(.5+.5*cos(w.a*24+c.t*.4+w.z*.18),5.f);
    float rim=line(ring,.1+c.b.z*.05,w.aa), sparks=pow(.5+.5*sin(w.z*5-w.a*11),12.f);
    return passageFinish(paint((.5+.3*sin(w.a))+w.z*.015,f)*(.17+tooth*.55+rim*1.25+sparks*.4),w,f);
}
NATIVE_EFFECT(fuchsiaFurnace)

float3 amberAperture(Ctx c, constant NativeFrame &f) {

    float3 col=deep(.5,f)*.16;
    for(int k=0;k<8;++k){float2 s=layerSlot(k,8,c.travel*.14);float sc=layerScale(s.x,3.4)/c.size;
      float2 p=rot(c.uv*sc,c.t*.12+s.y*.21);float corner=.22+.05*sin(s.y+c.t*.4);
      float d=sdBox2(p,float2(1.1, .85))-corner;float rim=glow(d,.055+c.b[int(s.y-4*floor(s.y/4))]*.06);
      float bevel=glow(d-.14,.04), wall=exp(-abs(d)*5)*.35;
      col+=paint(s.y*.12,f)*(rim+bevel*.6+wall)*layerFade(s.x);
    }return col;
}
NATIVE_EFFECT(amberAperture)

float3 auroraCorkscrew(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.1,.14);float liquid=w.a*3+w.z*.85+sin(w.a*5-w.z*.3)*1.4;
    liquid+=c.b.y*sin(w.a*13+w.z)*.7;float fold=.5+.5*sin(liquid);
    float crest=pow(max(0.f,cos(liquid)),12.f), ripple=line(sin(liquid*5+w.z),.055,w.aa);
    return passageFinish(paint(liquid*.05+w.z*.012,f)*(.18+fold*.6+ripple*.35)+paint(.85,f)*crest*.9,w,f);
}
NATIVE_EFFECT(auroraCorkscrew)

float3 prismPortals(Ctx c, constant NativeFrame &f) {

    float3 col=paint(.5,f)*.12;
    for(int k=0;k<9;++k){float2 s=layerSlot(k,9,c.travel*.15);float sc=layerScale(s.x,3.2)/c.size;
      float2 p=rot(c.uv*sc-float2(sin(s.y*.7),cos(s.y*.4))*.2,s.y*.31+c.t*.14);
      float a=atan2(p.y,p.x), polygon=length(p)*cos(fmod(a+TAU,TAU/3)-PI/3)-.78;
      float edge=glow(polygon,.045+.03*c.b[int(s.y-4*floor(s.y/4))]), facet=glow(polygon-.15,.08)*.3;
      col+=paint(s.y*.17+sin(a)*.2,f)*(edge*1.3+facet)*layerFade(s.x);
    }return col;
}
NATIVE_EFFECT(prismPortals)

float3 magentaConduit(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.3,.07);float2 q=float2(w.a*10/PI,w.z*1.1),l=fract(q)-.5,id=floor(q);
    float direction=fmod(abs(id.x+id.y),2.f), trace=min(abs(l.x),abs(l.y-(direction-.5)*.45));
    float wire=line(trace,.055,w.aa), node=glow(length(l-float2(0,(direction-.5)*.45)),.14);
    float charge=.45+.55*pow(.5+.5*sin(q.y*2-id.x+c.t*.6),4.f);
    return passageFinish(paint(id.y*.04+.3*sin(id.x*TAU/20),f)*(.16+wire*charge+node*(.5+c.b.w)),w,f);
}
NATIVE_EFFECT(magentaConduit)

float3 verdantSpiral(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.6,.11);float spine=sin(w.a*5+w.z*.65), frond=sin(w.a*20+w.z*1.8);
    float stalk=glow(spine,.06), leaf=pow(.5+.5*cos(frond+spine*3+c.b.y*sin(w.z)),4.f)*exp(-abs(spine)*1.5);
    float veins=line(sin(w.z*7+w.a*30),.06,w.aa)*leaf;
    return passageFinish(paint((.5+.3*sin(w.a))+w.z*.014,f)*(.15+leaf*.8+veins*.35)+paint(.7,f)*stalk*.9,w,f);
}
NATIVE_EFFECT(verdantSpiral)

float3 sapphireCascade(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.8,.07);float falls=sin(w.a*18+sin(w.z*.4)*.7+c.t*.2);
    float water=.5+.5*sin(w.z*3+falls*2+c.b.x*sin(w.a*9));
    float film=pow(max(0.f,cos(w.z*3+falls*2)),10.f), droplets=pow(.5+.5*cos(w.a*36-w.z*5),12.f);
    return passageFinish(paint(.55+falls*.08+w.z*.015,f)*(.2+water*.6+droplets*.4)+paint(.9,f)*film*.9,w,f);
}
NATIVE_EFFECT(sapphireCascade)

float3 garnetGallery(Ctx c, constant NativeFrame &f) {

    float3 col=deep(.6,f)*.16;
    for(int k=0;k<8;++k){float2 s=layerSlot(k,8,c.travel*.12);float sc=layerScale(s.x,3.3)/c.size;
      float2 p=rot(c.uv*sc,s.y*.3+c.t*.13);float diamond=abs(p.x)+abs(p.y)-(1.3+c.b[int(s.y-4*floor(s.y/4))]*.12);
      float face=exp(-abs(diamond)*5), edge=glow(diamond,.05), corners=glow(min(abs(p.x),abs(p.y)),.1)*face;
      col+=paint(s.y*.13+p.x*.03,f)*(face*.4+edge+corners*.5)*layerFade(s.x);
    }return col;
}
NATIVE_EFFECT(garnetGallery)

float3 luminousNautilus(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.1,.06);float spiral=w.a*3+w.z*.55+c.t*.13;
    float chamber=sin(spiral)+.4*sin(w.z*3.8+cos(spiral)*2);
    float ribs=line(chamber,.08+c.b.z*.05,w.aa), pearl=pow(.5+.5*cos(spiral),4.f);
    float3 col=paint(sin(spiral)*.24+w.z*.02,f)*(.18+pearl*.6+ribs*.8);
    col+=paint(.85,f)*pow(max(0.f,cos(chamber*4)),14.f)*.5;
    return passageFinish(col,w,f);
}
NATIVE_EFFECT(luminousNautilus)

float3 indigoInfinity(Ctx c, constant NativeFrame &f) {

    float3 col=paint(.5,f)*.12;
    for(int k=0;k<7;++k){float2 s=layerSlot(k,7,c.travel*.13);float sc=layerScale(s.x,3)/c.size;
      float2 p=rot(c.uv*sc,s.y*.27+c.t*.12);float r2=dot(p,p);
      float curve=abs(r2*r2-2*(p.x*p.x-p.y*p.y))- (.14+.07*c.b[int(s.y-4*floor(s.y/4))]);
      float hoop=glow(curve/max(.3f,r2),.055), mist=glow(curve/max(.3f,r2),.3)*.18;
      col+=paint(s.y*.16+p.x*.04,f)*(hoop+mist)*layerFade(s.x);
    }return col;
}
NATIVE_EFFECT(indigoInfinity)

float3 goldenGyre(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.7,.1);float fan=w.a*11+w.z*.45;
    float shade=.5+.5*cos(fan+sin(w.z)*c.b.y), slat=line(sin(fan),.065,w.aa);
    float arc=line(sin(w.z*3+sin(fan)*.5),.07,w.aa), sun=pow(.5+.5*cos(fan-w.z*.8),8.f);
    return passageFinish(paint((.5+.3*sin(w.a))+w.z*.01,f)*(.2+shade*.45+slat*.6+arc*.7+sun*.5),w,f);
}
NATIVE_EFFECT(goldenGyre)

float3 liquidLabyrinth(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.1,.05);float2 q=float2(w.a*5/PI,w.z*.9);
    q+=float2(sin(q.y*.8+c.t*.4),cos(w.a*3+c.t*.3))*(.3+c.b.x*.35);
    float4 v=passageCells(q,10,.6,c.t*.7);float seam=glow(v.y-v.x,.065), pool=exp(-v.x*v.x*4);
    float chrome=pow(max(0.f,1-v.x*1.5),12.f);
    return passageFinish(paint(v.z*.13+v.w*.11,f)*(.18+pool*.45+seam*.8)+paint(.85,f)*chrome*.5,w,f);
}
NATIVE_EFFECT(liquidLabyrinth)

float3 photonPetals(Ctx c, constant NativeFrame &f) {

    float3 col=paint(.4,f)*.12;
    for(int k=0;k<8;++k){float2 s=layerSlot(k,8,c.travel*.14);float sc=layerScale(s.x,3)/c.size;
      float2 p=rot(c.uv*sc,s.y*.34+c.t*.14);float a=atan2(p.y,p.x),r=length(p);
      float edge=r-(1.2+.25*cos(a*6)+.1*c.b[int(s.y-4*floor(s.y/4))]*sin(a*12));
      float lip=glow(edge,.05), petal=glow(edge-.18,.13)*(.5+.5*cos(a*6));
      col+=paint(s.y*.15+(.5+.3*sin(a)),f)*(lip*1.2+petal*.5)*layerFade(s.x);
    }return col;
}
NATIVE_EFFECT(photonPetals)


float3 celestialCoil(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.3,.09);float spring=w.z*4+w.a*2+c.t*.17;
    float wire=glow(sin(spring),.075), rail=glow(sin(w.a*5+w.z*.08),.05);
    float bead=pow(.5+.5*cos(w.a*20-w.z),8.f)*wire;
    float sheen=.5+.5*cos(spring+c.b.y*sin(w.a*9)*.8);
    return passageFinish(paint(w.z*.016+(.5+.3*sin(w.a)),f)*(.18+sheen*.35+wire*.8+rail*.6+bead*.8),w,f);
}
NATIVE_EFFECT(celestialCoil)

float3 chromeComet(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.4,.08);float metal=sin(w.a*4+w.z*.6)+.45*sin(w.a*9-w.z*.35);
    metal+=c.b.x*sin(w.a*16+w.z)*.5;float crease=.5+.5*sin(metal*4+w.z*.4);
    float spec=pow(max(0.f,cos(metal*4+w.z*.4)),16.f), tails=line(sin(w.a*24+w.z*.2),.07,w.aa);
    return passageFinish(paint(metal*.08+w.z*.01,f)*(.16+crease*.6+tails*.25)+paint(.9,f)*spec*1.2,w,f);
}
NATIVE_EFFECT(chromeComet)

float3 candyCathedral(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.2,.1);float arch=sin(w.z*2.1+cos(w.a*3)*1.4);
    float rose=pow(.5+.5*cos(w.a*12+w.z*.1),4.f), mullion=line(sin(w.a*24),.07,w.aa);
    float ribs=line(arch,.09+c.b.z*.06,w.aa), glass=.5+.5*sin(w.z*3.7+w.a*7);
    return passageFinish(paint((.5+.3*sin(w.a))+w.z*.025,f)*(.16+glass*rose*.65+mullion*.35+ribs),w,f);
}
NATIVE_EFFECT(candyCathedral)

float3 scarletSiphon(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.6,.14);float stream=w.z*.8+w.a*4+sin(w.z*.5-w.a*2)*1.5;
    float tear=pow(.5+.5*cos(stream+c.b.y*sin(w.z)*.9),3.f), small=line(sin(stream*7+w.a*5),.07,w.aa);
    float shine=pow(max(0.f,sin(stream)),12.f);
    return passageFinish(paint(sin(stream)*.24+w.z*.01,f)*(.18+tear*.65+small*.25)+paint(.85,f)*shine*.8,w,f);
}
NATIVE_EFFECT(scarletSiphon)

float3 emeraldEcho(Ctx c, constant NativeFrame &f) {

    float3 col=paint(.5,f)*.12;
    for(int k=0;k<9;++k){float2 s=layerSlot(k,9,c.travel*.15);float sc=layerScale(s.x,3.5)/c.size;
      float2 p=rot(c.uv*sc,s.y*.2+c.t*.14);float a=atan2(p.y,p.x);
      float d=length(p)*cos(fmod(a+TAU,TAU/8)-PI/8)-1.1;
      float rim=glow(d,.045+.03*c.b[int(s.y-4*floor(s.y/4))]), brace=glow(d-.18,.035)*(.5+.5*cos(a*16));
      col+=paint(s.y*.14+sin(a)*.2,f)*(rim*1.3+brace*.6)*layerFade(s.x);
    }return col;
}
NATIVE_EFFECT(emeraldEcho)

float3 arcticRaceway(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.8,.09);float2 q=float2(w.a*7/PI,w.z*.85),l=fract(q)-.5;
    float shard=abs(l.x)+abs(l.y)*1.3-.5, cuts=min(abs(l.x-l.y),abs(l.x+l.y));
    float ridge=line(shard,.06,w.aa), glint=glow(cuts,.04)*fill(shard,w.aa);
    float shade=.5+.5*cos(q.y*2+floor(q.x)+c.b.x*sin(q.x));
    return passageFinish(paint(.3*sin(floor(q.x)*TAU/14)+floor(q.y)*.06,f)*(.18+shade*.4+ridge*.8+glint*.7),w,f);
}
NATIVE_EFFECT(arcticRaceway)

float3 plasmaPassage(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.4,.12);float plasma=sin(w.a*5+w.z*.8+sin(w.a*3-w.z*.4)*1.2);
    plasma+=.6*cos(w.a*11-w.z*1.6+c.t*.4+c.b.y*sin(w.z));
    float skin=glow(plasma,.1), body=.5+.5*sin(plasma*3), hot=pow(max(0.f,cos(plasma*3)),12.f);
    return passageFinish(paint(plasma*.12+w.z*.017,f)*(.2+body*.5+skin*.7)+paint(.85,f)*hot*.65,w,f);
}
NATIVE_EFFECT(plasmaPassage)

float3 violetVelocity(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,3.3,.07);float a=w.a+w.z*.05;
    float slats=pow(.5+.5*cos(a*22),7.f), streak=.5+.5*sin(w.z*1.2+floor(a*12)*1.3);
    float lips=line(sin(w.z*3.6+a*2),.07+c.b.w*.05,w.aa);
    float cross=pow(.5+.5*cos(a*5-w.z*.6+c.t*.2),4.f);
    return passageFinish(paint((.5+.3*sin(a))+w.z*.011,f)*(.18+slats*(.5+streak*.7)+lips*.9+cross*.3),w,f);
}
NATIVE_EFFECT(violetVelocity)

float3 tangerineTurbine(Ctx c, constant NativeFrame &f) {

    float3 col=deep(.6,f)*.18;
    for(int k=0;k<7;++k){float2 s=layerSlot(k,7,c.travel*.13);float sc=layerScale(s.x,3.1)/c.size;
      float2 p=c.uv*sc;float a=atan2(p.y,p.x)+s.y*.45+c.t*.3,r=length(p);
      float blade=pow(.5+.5*cos(a*8+r*.7+sin(a*8)*c.b[int(s.y-4*floor(s.y/4))]*.5),5.f);
      float rim=glow(r-1.4,.055), fan=blade*exp(-abs(r-1.3)*2.5);
      col+=paint(s.y*.15+(.5+.3*sin(a)),f)*(fan*.85+rim*.7)*layerFade(s.x);
    }return col;
}
NATIVE_EFFECT(tangerineTurbine)

float3 ceruleanShell(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.4,.08);float scallop=cos(w.a*10+w.z*.18);
    float shell=sin(w.z*2.7+scallop*.7+c.b.x*sin(w.a*20)*.35), growth=line(shell,.08,w.aa);
    float pearl=pow(.5+.5*cos(w.z*2.7+scallop*.7),5.f), hair=line(sin(w.a*40+w.z*.15),.05,w.aa);
    return passageFinish(paint((.5+.3*sin(w.a))+w.z*.014,f)*(.22+pearl*.5+growth*.8+hair*.2),w,f);
}
NATIVE_EFFECT(ceruleanShell)

float3 discoHelix(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.6,.11);float2 q=float2(w.a*8/PI+w.z*.16,w.z*.85);
    float4 cell=hexCell(q);float r=length(cell.xy), rim=line(sdHex(cell.xy,.47),.045,w.aa);
    float local=.5+.5*sin(sin(cell.z*TAU/16)*2+cell.w*1.7+c.t*.8), band=c.b[int(cell.z+cell.w-4*floor((cell.z+cell.w)/4))];
    float jewel=pow(max(0.f,1-r*1.6),2.f), facets=.5+.5*cos(atan2(cell.y,cell.x)*6);
    return passageFinish(paint(.3*sin(cell.z*TAU/16)+cell.w*.07,f)*(.14+rim*.8+jewel*(.5+facets*.4+band*.5)*local),w,f);
}
NATIVE_EFFECT(discoHelix)

float3 iridescentDescent(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.9,.1);float terrace=w.z*2+sin(w.a*4)*.8;
    float rounded=floor(terrace)+smoothstep(.35f,.65f,fract(terrace)), contour=line(sin(terrace*PI),.06,w.aa);
    float gleam=pow(.5+.5*cos(w.a*7+rounded+c.b.y*sin(w.a*13)),8.f);
    return passageFinish(paint(rounded*.065+(.5+.3*sin(w.a)),f)*(.2+.25*fract(terrace)+contour*.85+gleam*.6),w,f);
}
NATIVE_EFFECT(iridescentDescent)

float3 solarSerpent(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.3,.1);float3 col=deep(.5,f)*.18;
    for(int k=0;k<4;++k){float phase=w.a+float(k)*PI*.5+w.z*.4+c.t*.16;
      float center=sin(phase)+.25*sin(w.z*1.2+float(k)+c.b[k]*sin(w.a*5));
      float ribbon=glow(center,.17), scales=line(sin(w.z*7+phase*6),.07,w.aa);
      col+=paint(float(k)*.22+w.z*.014,f)*ribbon*(.6+scales*.6);
    }return passageFinish(col,w,f);
}
NATIVE_EFFECT(solarSerpent)

float3 rainbowReactor(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.7,.08);float2 q=float2(w.a*7/PI,w.z*.8);float4 cell=hexCell(q);
    float edge=line(sdHex(cell.xy,.43),.06,w.aa), core=glow(length(cell.xy),.2+c.b.x*.08);
    float bolt=line(sin(w.a*21+w.z*.7),.05,w.aa), energy=.4+.6*pow(.5+.5*cos(w.z*3+c.t*.4),4.f);
    return passageFinish(paint(.3*sin(cell.z*TAU/14)+cell.w*.08,f)*(.16+edge*.6+core*energy+bolt*.35),w,f);
}
NATIVE_EFFECT(rainbowReactor)


float3 crystalCarousel(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.5,.1);float2 q=float2(w.a*8/PI+w.z*.1,w.z*.8),l=fract(q)-.5;
    float square=max(abs(l.x),abs(l.y)), diamond=abs(l.x)+abs(l.y);
    float edges=line(square-.42,.05,w.aa)+line(diamond-.45,.035,w.aa);
    float bevel=pow(min(abs(l.x),abs(l.y))/max(.03f,square),6.f)*fill(square-.4,w.aa);
    float pulse=.4+.6*pow(.5+.5*cos(floor(q.x)+floor(q.y)*.7+c.t*.5),3.f);
    return passageFinish(paint(.3*sin(floor(q.x)*TAU/16)+floor(q.y)*.06,f)*(.2+edges*.65+bevel*(.6+c.b.z)*pulse),w,f);
}
NATIVE_EFFECT(crystalCarousel)

float3 neonMaelstrom(Ctx c, constant NativeFrame &f) {

    Passage w=passage(c,2.8,.16);float twist=w.a*6+w.z*.85+c.t*.2;
    float eddy=sin(twist)+.45*sin(twist*2-w.z*.6+c.b.y*sin(w.a*11));
    float flow=.5+.5*cos(eddy*4+w.z*.7), curl=line(sin(twist*4+w.z*2),.065,w.aa);
    float foam=pow(max(0.f,sin(eddy*4+w.z*.7)),14.f);
    return passageFinish(paint(sin(twist)*.24+w.z*.011,f)*(.16+flow*.6+curl*.4)+paint(.9,f)*foam*.85,w,f);
}
NATIVE_EFFECT(neonMaelstrom)
