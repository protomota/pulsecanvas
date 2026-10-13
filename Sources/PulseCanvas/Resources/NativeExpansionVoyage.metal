// Original PulseCanvas forward-motion scenes, authored from geometry and surface math.

float3 fuchsiaFlyway(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size; float h=.35, d=max(h-p.y,.035f), z=2/d+c.travel*2.4;
    float x=p.x/d-.6*sin(z*.13+c.t*.2);
    float road=exp(-pow(x*.3,4.f)), rails=glow(abs(x)-3.2,.11);
    float cable=glow(abs(x)-3.7-(.6+.5*cos(z*.7)),.08);
    float posts=line(sin(z*1.4),.08,c.px/d)*smoothstep(2.8f,3.2f,abs(x));
    float3 ground=paint(.15+z*.023,f)*(.17*road+rails*1.8+cable+posts*.5);
    ground+=paint(.85,f)*road*pow(.5+.5*cos(z*3+x*.7+c.b.x*sin(x)*2),6.f)*.3;
    float sky=.5+.5*sin(p.x*2+sin(p.y*3+c.t*.3));
    return mix(paint(.6+sky*.15,f)*(.15+sky*.3),ground,smoothstep(-.03f,.04f,h-p.y));
}
NATIVE_EFFECT(fuchsiaFlyway)

float3 amberAqueduct(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size; float r=max(length(p*float2(1,.6)),.06f), z=2.4/r+c.travel*1.8;
    float a=atan2(p.y*.6,p.x), wave=sin(z*1.7+a*5+c.t*.6);
    float channel=pow(.5+.5*cos(a*2),4.f), bricks=line(sin(z*3+cos(a*6)),.13,c.px/r);
    float water=.5+.5*sin(z*.8+sin(a*4+z*.2)*2+c.b.x*sin(a*9));
    float3 col=paint((.5+.3*sin(a))+z*.012,f)*(.25+channel*.45+bricks*.8);
    col+=paint(.8+water*.1,f)*pow(max(0.f,wave),12.f)*(1+c.b.w)*.8;
    return col*smoothstep(.025f,.18f,r)+deep(.5,f)*.08;
}
NATIVE_EFFECT(amberAqueduct)

float3 photonOverpass(Ctx c, constant NativeFrame &f) {

    float3 col=deep(.4,f)*.1;
    for(int k=0;k<5;++k){float2 s=layerSlot(k,5,c.travel*.15); float sc=layerScale(s.x,3)/c.size;
      float2 p=rot(c.uv*sc,.5*sin(c.t*.2)+s.y*.38); float arc=p.y-.4*sin(p.x*1.3+s.y);
      float ribbon=glow(arc,.22), curb=glow(abs(arc)-.3,.025);
      float dash=pow(.5+.5*cos(p.x*5+s.y+c.t*.7),5.f);
      col+=paint(s.y*.18+p.x*.025,f)*(ribbon*(.35+dash*.55)+curb*1.7)*(1+c.b[int(s.y-4*floor(s.y/4))]*.5)*layerFade(s.x);
    }return col;
}
NATIVE_EFFECT(photonOverpass)

float3 indigoEscalator(Ctx c, constant NativeFrame &f) {

    float2 p=rot(c.uv/c.size,.12*sin(c.t*.2)); float d=max(.4-p.y,.035f), z=2.3/d+c.travel*2;
    float x=p.x/d, step=fract(z*.8), edge=line(sin(z*.8*PI),.06,c.px/(d*d));
    float groove=line(sin(x*4),.035,c.px/d), rail=glow(abs(x)-4,.15);
    float3 floor=paint(z*.04+x*.035,f)*(.22+step*.4+edge*.8+groove*.3+rail*1.6);
    floor+=paint(.75,f)*pow(max(0.f,cos(x*2+z*3+c.b.y*sin(x))),12.f)*.45;
    return mix(paint(.7+sin(p.x+c.t*.2)*.1,f)*.2,floor,smoothstep(-.03f,.04f,.4-p.y));
}
NATIVE_EFFECT(indigoEscalator)

float3 solarSlalom(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size; float d=max(.3-p.y,.04f), z=2/d+c.travel*2.3;
    float lane=p.x/d-1.5*sin(z*.3+c.t*.3), rip=.5+.5*sin(z*2.4+lane*1.4+c.b.x*sin(lane)*2);
    float stripe=glow(abs(lane)-2,.18), gates=line(sin(z*2),.08,c.px/d)*glow(abs(lane)-2.6,.35);
    float chevron=line(sin(z*4-abs(lane)*1.6),.09+c.b.w*.1,c.px/d);
    float3 floor=paint(lane*.045+z*.019,f)*(.18+rip*.5+stripe+gates+chevron*.5);
    float3 sky=paint(.7+p.y*.05,f)*(.2+.15*sin(p.x*3+p.y*2+c.t*.2));
    return mix(sky,floor,smoothstep(-.03f,.03f,.3-p.y));
}
NATIVE_EFFECT(solarSlalom)

float3 glacialSprint(Ctx c, constant NativeFrame &f) {

    float2 p=rot(c.uv/c.size,c.t*.08); float r=max(max(abs(p.x),abs(p.y)),.05f), z=2/r+c.travel*1.7;
    float wall=(abs(p.x)>abs(p.y)?p.y:p.x)/r; float crevice=abs(sin(wall*6+sin(z*.7)*1.6+c.b.y*sin(wall*9)));
    float crystal=pow(.5+.5*cos(z*3.5+wall*4),3.f);
    float joint=line(sin(z*2+floor(wall*3)),.1,c.px/r);
    float3 col=paint(.55+wall*.12+z*.016,f)*(.25+crystal*.65+joint*.6);
    col+=paint(.85,f)*glow(crevice,.045)*1.6;
    return col*smoothstep(.03f,.15f,r)+deep(.6,f)*.08;
}
NATIVE_EFFECT(glacialSprint)

float3 velvetVoyage(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size; float r=max(length(p),.05f), a=atan2(p.y,p.x), z=2/r+c.travel*2;
    float fabric=sin(a*4+z*.65+c.t*.3)+.35*sin(a*11-z*.4+c.b.y*sin(z)*2);
    float folds=.5+.5*sin(fabric*4+z*.2), fringe=line(sin(a*12+z*.5),.06,c.px/r);
    float sheen=pow(max(0.f,cos(fabric*4+z*.2)),8.f);
    float3 col=paint(fabric*.11+z*.012,f)*(.15+folds*.65+fringe*.3);
    col+=paint(.9,f)*sheen*(.6+c.b.w*.5);
    return col*smoothstep(.02f,.13f,r)+deep(.4,f)*.1;
}
NATIVE_EFFECT(velvetVoyage)

float3 plasmaRally(Ctx c, constant NativeFrame &f) {

    float2 p=rot(c.uv/c.size,c.t*.09); float r=max(length(p),.05f), a=atan2(p.y,p.x), z=2.1/r+c.travel*2;
    float2 tile=float2(a*6/PI+z*.08,z*.7); float4 cell=hexCell(tile);
    float rim=line(sdHex(cell.xy,.48),.05+c.b.w*.035,c.px/r*1.2);
    float panel=exp(-dot(cell.xy,cell.xy)*5)*(.5+.5*sin(cell.z*.8+cell.w*.6+c.t));
    float ion=glow(sin(a*3+z*.45),.11);
    float3 col=paint(.3*sin(cell.z*TAU/12)+cell.w*.08,f)*(.14+rim+panel*.6+ion*.7);
    return col*smoothstep(.03f,.16f,r)+paint(.6,f)*.08;
}
NATIVE_EFFECT(plasmaRally)

float3 crystalCauseway(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size; float d=max(.45-p.y,.05f), z=1.8/d+c.travel*1.7;
    float2 q=float2(p.x/d,z); q.x+=sin(q.y*.2+c.t*.3)*.6;
    float2 cell=floor(q), l=fract(q); float diagonal=abs(l.x+l.y-1);
    float facet=l.x+l.y<1 ? l.x : 1-l.y; float linework=line(diagonal,.035,c.px/d);
    float seams=line(min(min(l.x,1-l.x),min(l.y,1-l.y)),.025,c.px/d);
    float3 floor=paint(cell.x*.09+cell.y*.05,f)*(.2+facet*.7+linework*.6+seams*.5);
    floor+=paint(.9,f)*pow(.5+.5*sin(cell.x*1.3+cell.y+c.t*.6),8.f)*c.b.x*.8;
    return mix(paint(.7+sin(p.x+c.t*.1)*.15,f)*.23,floor,smoothstep(-.03f,.05f,.45-p.y));
}
NATIVE_EFFECT(crystalCauseway)

float3 luminousLift(Ctx c, constant NativeFrame &f) {

    float2 p=rot(c.uv/c.size,.18*sin(c.t*.2)); float d=max(abs(p.x),.045f), z=2/d+c.travel*1.8;
    float vertical=p.y/d, q=z*.6+vertical*.25; float pane=line(sin(q*PI),.07,c.px/d);
    float beam=glow(sin(vertical*2-c.t*.4),.12), step=.5+.5*cos(q*TAU+sin(vertical*3)*c.b.y);
    float3 col=paint(z*.025+vertical*.05,f)*(.22+step*.25+pane*.95+beam*.7);
    float central=exp(-abs(p.x)*5);
    return col*(1-central*.7)+paint(.8,f)*central*.18;
}
NATIVE_EFFECT(luminousLift)

float3 arcJetstream(Ctx c, constant NativeFrame &f) {

    float3 col=paint(.4,f)*.12;
    for(int k=0;k<7;++k){float2 s=layerSlot(k,7,c.travel*.13); float scale=layerScale(s.x,2.8)/c.size;
      float2 p=rot(c.uv*scale,.18*sin(s.y*.7+c.t*.3));
      float wave=p.y-.45*sin(s.y*.83)-.35*sin(p.x*.9+c.t*.8+s.y);
      float trail=glow(wave,.045+.07*c.b[int(s.y-4*floor(s.y/4))]), broad=glow(wave,.25)*.2;
      float streak=.3+.7*pow(.5+.5*cos(p.x*3+s.y*1.8),4.f);
      col+=paint(s.y*.16+p.x*.025,f)*(trail*streak*2+broad)*layerFade(s.x);
    }return col;
}
NATIVE_EFFECT(arcJetstream)

float3 rubyRollway(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size; float d=max(.5-p.y,.04f), z=2/d+c.travel*2;
    float x=p.x/d+.6*sin(z*.18), row=z*.9; float roller=cos(row*TAU), seam=line(sin(row*PI),.045,c.px/d);
    float teeth=pow(.5+.5*cos(x*6+c.t*.6),5.f), band=glow(abs(x)-3.5,.13);
    float3 floor=paint(z*.025+x*.05,f)*(.18+.6*max(0.f,roller)+teeth*.25+band*1.4);
    floor+=paint(.85,f)*(seam+.3*pow(max(0.f,roller),12.f))*(1+c.b.x*.6);
    return mix(paint(.7,f)*(.22+.1*sin(p.x*3+c.t*.3)),floor,smoothstep(-.04f,.04f,.5-p.y));
}
NATIVE_EFFECT(rubyRollway)

float3 neonRegatta(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size; float d=max(.15-p.y,.045f), z=1.6/d+c.travel*2;
    float x=p.x/d; float wake=sin(z*2-abs(x)*2.6+c.b.x*sin(x)*2), wave=sin(x*1.5+z*.9+c.t*.5);
    float foam=pow(max(0.f,wake),10.f), spec=pow(max(0.f,cos(wave*3)),12.f);
    float buoys=glow(abs(x)-3,.17)*pow(.5+.5*cos(z*3),7.f);
    float3 water=paint(z*.016+x*.03,f)*(.2+(.5+.5*wave)*.35+foam*.8+spec*.5+buoys);
    float3 sky=paint(.65+p.x*.02,f)*(.16+.2*pow(.5+.5*sin(p.x+p.y*3+c.t*.1),3.f));
    return mix(sky,water,smoothstep(-.03f,.05f,.15-p.y));
}
NATIVE_EFFECT(neonRegatta)

float3 radiantRunway(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size; float d=max(.2-p.y,.04f), z=2/d+c.travel*3;
    float x=p.x/d, linework=glow(x,.035)*pow(.5+.5*cos(z*4),6.f);
    float lamps=glow(abs(x)-3,.13)*pow(.5+.5*cos(z*2.5),12.f);
    float tarmac=exp(-pow(x*.24,4.f));
    float3 floor=paint(z*.013,f)*(.2*tarmac+linework*2+lamps*2.5);
    floor+=paint(.85,f)*tarmac*pow(.5+.5*sin(z*1.1+x*3+c.b.y),8.f)*.35;
    float cloud=.5+.5*sin(p.x*2+sin(p.y*3+c.t*.3));
    return mix(paint(.65+cloud*.2,f)*(.15+cloud*.3),floor,smoothstep(-.03f,.05f,.2-p.y));
}
NATIVE_EFFECT(radiantRunway)

float3 electricViaduct(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size; float r=max(length(p*float2(.8,1)),.05f), z=2.3/r+c.travel*2.3;
    float a=atan2(p.y,p.x*.8), ribs=line(sin(z*1.8+.8*cos(a*2)),.085,c.px/r);
    float span=glow(sin(a*4+z*.16+c.t*.2),.075+c.b.w*.04);
    float window=pow(.5+.5*cos(a*8),5.f)*pow(.5+.5*cos(z*3.6),4.f);
    float3 col=paint((.5+.3*sin(a))+z*.02,f)*(.22+ribs+span*.8+window*.6);
    return col*smoothstep(.025f,.15f,r)+deep(.7,f)*.08;
}
NATIVE_EFFECT(electricViaduct)

float3 orbitExpress(Ctx c, constant NativeFrame &f) {

    float3 col=deep(.5,f)*.18;
    for(int k=0;k<8;++k){float2 s=layerSlot(k,8,c.travel*.15); float sc=layerScale(s.x,3.2)/c.size;
      float2 p=rot(c.uv*sc-float2(sin(s.y*.3),cos(s.y*.5))*.25,s.y*.4+c.t*.15);
      float orbit=length(p/float2(1.4,.8))-(1.3+.12*c.b[int(s.y-4*floor(s.y/4))]*sin(atan2(p.y,p.x)*5));
      float rim=glow(orbit,.06), studs=pow(.5+.5*cos(atan2(p.y,p.x)*16+s.y+c.t*.4),8.f);
      col+=paint(s.y*.13,f)*(rim*(.8+studs*1.2)+glow(orbit,.25)*.18)*layerFade(s.x);
    }return col;
}
NATIVE_EFFECT(orbitExpress)

float3 moltenHighway(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size; float d=max(.35-p.y,.04f), z=1.9/d+c.travel*2;
    float2 q=float2(p.x/d,z); float lava=sin(q.x*2+sin(q.y*.9)*2)+cos(q.y*2+sin(q.x));
    lava+=c.b.x*sin(q.x*4+q.y)*.65; float crust=smoothstep(.15f,.7f,lava);
    float crack=glow(lava-.2,.13), heat=pow(.5+.5*sin(q.x*3-q.y*.7+c.t*.4),5.f);
    float3 floor=paint(.1+q.y*.012,f)*(crack*1.8+(1-crust)*(.4+heat*.4))+deep(.5,f)*crust*.22;
    float embers=pow(.5+.5*sin(p.x*8+p.y*11+c.t*.8),16.f)*.3;
    return mix(paint(.65,f)*(.2+embers),floor,smoothstep(-.03f,.05f,.35-p.y));
}
NATIVE_EFFECT(moltenHighway)

float3 violetFlight(Ctx c, constant NativeFrame &f) {

    float3 col=paint(.3,f)*.14;
    for(int k=0;k<7;++k){float2 s=layerSlot(k,7,c.travel*.14); float sc=layerScale(s.x,3)/c.size;
      float2 p=rot(c.uv*sc,c.t*.15+s.y*.37); p.y-=.3*sin(s.y*.5+c.t*.4);
      float delta=abs(p.x)*.7+p.y, wing=glow(delta-.8,.06+.06*c.b[int(s.y-4*floor(s.y/4))]);
      float wingfill=exp(-abs(delta-.8)*4)*exp(-abs(p.x)*.3);
      float braces=line(sin(p.x*5+s.y),.06,c.px*sc)*wingfill;
      col+=paint(s.y*.13+p.x*.04,f)*(wing*1.8+wingfill*.5+braces*.4)*layerFade(s.x);
    }return col;
}
NATIVE_EFFECT(violetFlight)

float3 emeraldLaunch(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size; float r=max(length(p),.05f), a=atan2(p.y,p.x), z=2.2/r+c.travel*2.5;
    float petal=.5+.5*cos(a*7+z*.22+c.t*.15), cut=sin(z*2.4+petal*3);
    float ribs=line(cut,.08+c.b.z*.04,c.px/r), veins=line(sin(a*28-z*.8),.045,c.px/r);
    float tissue=petal*(.5+.5*sin(z*1.2+sin(a*7)));
    float3 col=paint((.5+.3*sin(a))+z*.011,f)*(.16+tissue*.6+ribs*1.3+veins*.35);
    return col*smoothstep(.03f,.16f,r)+deep(.4,f)*.12;
}
NATIVE_EFFECT(emeraldLaunch)

float3 coralDriftway(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size; float r=max(length(p),.06f), a=atan2(p.y,p.x), z=1.6/r+c.travel*1.5;
    float branch=sin(a*6+z*.18+c.t*.1)+.35*sin(a*17-z*.5);
    float coral=glow(branch,.16+c.b.y*.08), bubbles=pow(.5+.5*cos(z*4+sin(a*12)),10.f);
    float water=.5+.5*sin(a*3-z*.7+sin(z*.3));
    float3 col=paint(.45+water*.15,f)*(.2+water*.3);
    col+=paint((.5+.3*sin(a))+z*.02,f)*(coral*(.8+bubbles*.9)+bubbles*.2);
    return col*smoothstep(.03f,.15f,r)+paint(.65,f)*.1;
}
NATIVE_EFFECT(coralDriftway)

float3 azureAscent(Ctx c, constant NativeFrame &f) {

    float2 p=rot(c.uv/c.size,-.3); float d=max(.6-p.y,.04f), z=2/d+c.travel*2;
    float x=p.x/d; float zig=abs(fract(z*.7+x*.15)-.5), stair=line(zig-.4,.06,c.px/d);
    float tread=.5+.5*cos(z*4.4+x*.9), rail=glow(abs(x)-3,.13);
    float3 floor=paint(x*.07+z*.018,f)*(.2+tread*.4+stair+rail);
    floor+=paint(.85,f)*pow(.5+.5*cos(x*3-z+c.b.z*sin(x)),12.f)*.5;
    return mix(paint(.7,f)*(.2+.12*sin(p.x*2+c.t*.2)),floor,smoothstep(-.02f,.05f,.6-p.y));
}
NATIVE_EFFECT(azureAscent)

float3 festivalCruise(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size; float r=max(length(p),.055f), a=atan2(p.y,p.x), z=2.5/r+c.travel*2;
    float2 q=float2(a*7/PI+.1*sin(z*.4),z*.8), id=floor(q), l=fract(q)-.5;
    l.x+=sin(id.y+c.t*.7)*.07; float lantern=length(l/float2(.3,.4));
    float light=fill(lantern-.85,c.px/r), cage=line(sin(l.x*23),.08,c.px/r)*light;
    float cord=glow(l.x,.025), glowlight=glow(lantern,.45);
    float3 col=paint(.3*sin(id.x*TAU/14)+id.y*.09,f)*(.12+light*(.8-cage*.4)*(1+c.b[int(id.y-4*floor(id.y/4))]*.7)+glowlight*.2);
    col+=paint(.65,f)*cord*.25;
    return col*smoothstep(.03f,.15f,r)+deep(.3,f)*.1;
}
NATIVE_EFFECT(festivalCruise)

float3 quantumSled(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size; float r=max(length(p*float2(1,.7)),.055f), a=atan2(p.y*.7,p.x), z=2/r+c.travel*2.1;
    float braid=sin(a*3+z*.55+c.t*.2), companion=sin(a*3-z*.55-c.t*.2);
    float rails=glow(braid,.09)+glow(companion,.09), ties=line(sin(z*3),.07,c.px/r);
    float ice=.5+.5*cos(a*6+z*.4+c.b.x*sin(a*11));
    float3 col=paint((.5+.3*sin(a))+z*.017,f)*(.15+ice*.35+rails+ties*.3);
    return col*smoothstep(.03f,.17f,r)+paint(.8,f)*.08;
}
NATIVE_EFFECT(quantumSled)

float3 citrusSurge(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size; float r=max(length(p),.055f), a=atan2(p.y,p.x), z=2.6/r+c.travel*2;
    float juice=sin(a*4+sin(z*.8+a*2)*2+c.t*.3)+cos(z*1.1-a*3);
    juice+=c.b.y*sin(a*13+z)*.7; float flesh=.5+.5*sin(juice*3);
    float peel=line(sin(z*2.6+.6*cos(a*8)),.07,c.px/r), gleam=pow(max(0.f,cos(juice*3)),14.f);
    float3 col=paint(juice*.07+z*.013,f)*(.2+flesh*.6+peel*.7);
    col+=paint(.85,f)*gleam*(.9+c.b.w*.5);
    return col*smoothstep(.025f,.14f,r)+deep(.6,f)*.1;
}
NATIVE_EFFECT(citrusSurge)

float3 starlightPursuit(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size; float r=max(length(p),.04f), a=atan2(p.y,p.x), z=2.8/r+c.travel*3;
    float drift=a+z*.12+c.t*.1; float lane=pow(.5+.5*cos(drift*15),8.f);
    float star=pow(.5+.5*sin(z*4+floor(drift*8)*1.7),14.f)*lane;
    float streak=lane*pow(.5+.5*cos(z*.9),4.f), canyon=.5+.5*sin(a*4+z*.4);
    float3 col=paint((.5+.3*sin(drift))+z*.013,f)*(.15+canyon*.25+streak*.65+star*(1.5+c.b.w));
    return col*smoothstep(.02f,.12f,r)+paint(.8,f)*.1;
}
NATIVE_EFFECT(starlightPursuit)
