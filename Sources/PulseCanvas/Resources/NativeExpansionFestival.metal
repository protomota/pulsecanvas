// Original PulseCanvas dancing surfaces, ribbons, assemblies and liquid forms.

float3 radiantRondo(Ctx c, constant NativeFrame &f) {

    float2 q=c.uv*2.2/c.size, id=floor(q),p=fract(q)-.5;float phase=id.x*.9+id.y*1.3;
    float a=atan2(p.y,p.x)+c.t*.4,r=length(p), band=c.b[int(abs(id.x+id.y))%4];
    float radius=.28+.045*sin(c.t*1.3+phase)+band*.08*sin(a*5+phase);
    float rim=glow(r-radius,.025), hoops=glow(r-radius*.65,.018), spokes=line(sin(a*8),.06,c.px)*exp(-r*5);
    return paint(phase*.1+a*.025,f)*(.14+rim+hoops*.7+spokes*.4)+deep(.5,f)*.1;
}
NATIVE_EFFECT(radiantRondo)

float3 fuchsiaFandango(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size;float3 col=deep(.5,f)*.2;
    for(int k=0;k<6;++k){float y=float(k-3)*.55;float phase=c.t*.9+float(k)*1.2;
      float bend=sin(p.x*2.4+phase)*(.16+c.b[k%4]*.22)+.08*sin(p.x*6-phase);
      float d=p.y-y-bend;float ribbon=glow(d,.1), satin=pow(max(0.f,cos(d*15)),10.f)*exp(-abs(d)*8);
      col+=paint(float(k)*.15+p.x*.03,f)*(ribbon*.7+satin*.7);
    }return col;
}
NATIVE_EFFECT(fuchsiaFandango)

float3 satinShuffle(Ctx c, constant NativeFrame &f) {

    float2 p=rot(c.uv/c.size,.22*sin(c.t*.3));float3 col=deep(.5,f)*.15;
    for(int k=0;k<5;++k){float a=float(k)*PI/5, phase=c.t*.5+float(k)*.8;
      float2 q=rot(p,a);float d=sin(q.x*3+phase)+q.y*.6+c.b[k%4]*sin(q.x*7-phase)*.3;
      float weave=glow(d,.09), stitch=line(sin(q.y*13+phase),.055,c.px)*weave;
      col+=paint(float(k)*.19+q.x*.025,f)*(weave*.85+stitch*.35);
    }return col;
}
NATIVE_EFFECT(satinShuffle)

float3 chromaticCharleston(Ctx c, constant NativeFrame &f) {

    float2 q=c.uv*3/c.size;float2 id=floor(q),p=fract(q)-.5;float phase=id.x*1.2+id.y*.8;
    p=rot(p,.5*sin(c.t+phase));float band=c.b[int(abs(id.x*2+id.y))%4];
    float2 radii=float2(.13+.03*sin(c.t*1.8+phase),.29+band*.12);
    float d=length(p/radii), body=fill(d-1,c.px*4), halo=glow(d-1,.12);
    float seams=line(sin(p.y*30+c.t),.09,c.px*3)*body;
    return paint(phase*.12,f)*(.14+body*(.65+band*.5)+halo*.5+seams*.3);
}
NATIVE_EFFECT(chromaticCharleston)

float3 prismaticPolka(Ctx c, constant NativeFrame &f) {

    float2 q=c.uv*2.4/c.size,id=floor(q),p=fract(q)-.5;float phase=id.x*.8+id.y*1.5;
    p.y-=.1*sin(c.t*1.5+phase);p=rot(p,c.t*.3+.25*sin(phase));
    float a=atan2(p.y,p.x),band=c.b[int(abs(id.x+id.y*2))%4];
    float d=length(p)*cos(fmod(a+TAU,TAU/3)-PI/3)-(.2+band*.04);
    float body=fill(d,c.px*3),facet=.5+.5*cos(a*3),rim=glow(d,.025);
    return paint(phase*.1+a*.04,f)*(.13+body*(.3+facet*.65)+rim*.6);
}
NATIVE_EFFECT(prismaticPolka)

float3 neonBolero(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size;float3 col=deep(.4,f)*.18;
    for(int k=0;k<5;++k){float2 q=rot(p,c.t*.13+float(k)*.37);q+=float2(sin(c.t*.4+float(k)),cos(c.t*.3+float(k)))*.2;
      float2 tile=fract(q*(1.3+float(k)*.25))-.5;float d=sdBox2(tile,float2(.32,.22)+c.b[k%4]*.025);
      float rim=glow(d,.016), cross=line(tile.x+tile.y,.02,c.px)*fill(d,c.px);
      col+=paint(float(k)*.19+q.x*.02,f)*(rim*.6+cross*.18);
    }return col;
}
NATIVE_EFFECT(neonBolero)

float3 pearlescentSwing(Ctx c, constant NativeFrame &f) {

    float2 q=c.uv*2.1/c.size,id=floor(q);float3 col=paint(.6,f)*.12;
    for(int y=-1;y<=1;++y)for(int x=-1;x<=1;++x){float2 cell=id+float2(x,y);float ph=cell.x*1.1+cell.y*.7;
      float2 orbit=float2(cos(c.t*.8+ph),sin(c.t*.8+ph))*float2(.28,.16);float2 p=q-cell-.5-orbit;
      float band=c.b[int(abs(cell.x+cell.y))%4],r=.22+band*.08;
      float sphere=fill(length(p)-r,c.px*2),normal=sqrt(max(0.f,1-dot(p,p)/(r*r)));
      float spec=pow(max(0.f,normal*.85-p.x*.5+p.y*.3),18.f);
      col+=paint(ph*.15,f)*sphere*(.3+normal*.5)+paint(.9,f)*spec*sphere*.7;
    }return col;
}
NATIVE_EFFECT(pearlescentSwing)

float3 solarSway(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size;float sun=sin(p.x*3+sin(p.y*2+c.t*.6)*1.6);
    sun+=.7*cos(p.y*4-sin(p.x*2-c.t*.4))+c.b.x*sin(p.x*7+p.y*5)*.8;
    float waves=.5+.5*sin(sun*3), veins=line(sin(sun*6+p.x*2),.09,c.px*6);
    float gleam=pow(max(0.f,cos(sun*3)),14.f);
    return paint(sun*.12+p.x*.025,f)*(.2+waves*.6+veins*.4)+paint(.85,f)*gleam*.85;
}
NATIVE_EFFECT(solarSway)

float3 liquidLimbo(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv*2/c.size;float wave=sin(p.y*1.7+c.t*.7)*(.35+c.b.x*.4);
    p.x+=wave; p.y+=sin(p.x*1.9-c.t*.5)*(.2+c.b.y*.3);
    float tile=sin(p.x*PI)*sin(p.y*PI),facet=.5+.5*tanh(tile*4);
    float seam=glow(tile,.065),glass=pow(.5+.5*cos(p.x*2.5+p.y*1.8),10.f);
    return paint(facet*.5+p.y*.025,f)*(.2+facet*.55+seam*.7)+paint(.9,f)*glass*.65;
}
NATIVE_EFFECT(liquidLimbo)

float3 violetVogue(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size;float3 col=deep(.6,f)*.18;
    for(int k=0;k<8;++k){float phase=float(k)*.85+c.t*.6;float center=sin(p.y*1.4+phase)*.5+float(k-4)*.35;
      center+=c.b[k%4]*sin(p.y*4-phase)*.17;float d=p.x-center;
      float silk=glow(d,.08),pleat=.5+.5*sin(d*18+p.y*3+phase);
      float stitch=line(sin(p.y*16+phase),.07,c.px)*silk;
      col+=paint(float(k)*.13+p.y*.03,f)*(silk*(.35+pleat*.5)+stitch*.2);
    }return col;
}
NATIVE_EFFECT(violetVogue)

float3 discoRipple(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size;float3 col=deep(.5,f)*.15;
    for(int k=0;k<5;++k){float phase=float(k)*TAU/5;float2 origin=float2(cos(phase+c.t*.2),sin(phase-c.t*.15))*.8;
      float r=length(p-origin);float wave=sin(r*(7+float(k))-c.t*(1.2+float(k)*.2));
      wave+=c.b[k%4]*sin(r*18+phase)*.6;float rim=glow(wave,.07), ripple=.5+.5*wave;
      col+=paint(float(k)*.17+r*.02,f)*(rim*.55+ripple*.12)*exp(-r*.35);
    }return col;
}
NATIVE_EFFECT(discoRipple)

float3 gildedGroove(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size;float3 col=deep(.5,f)*.2;
    for(int k=0;k<6;++k){float phase=float(k)*PI/3;float center=sin(p.x*2+c.t*.7+phase)*.45+cos(p.x*.9-c.t*.4+phase)*.3;
      float d=p.y-float(k-3)*.28-center-c.b[k%4]*sin(p.x*5+phase)*.16;
      float gold=glow(d,.045),filament=glow(d-.09,.012),shadow=glow(d+.06,.1)*.2;
      col+=paint(float(k)*.15+p.x*.02,f)*(gold*.9+filament*.65+shadow);
    }return col;
}
NATIVE_EFFECT(gildedGroove)

float3 auroraWaltz(Ctx c, constant NativeFrame &f) {

    float2 q=c.uv*2.4/c.size;float4 h=hexCell(q);float2 p=rot(h.xy,c.t*.2+h.z*.8);
    float a=atan2(p.y,p.x),r=length(p), band=c.b[int(abs(h.z+h.w))%4];
    float flower=r-(.28+.055*cos(a*3+c.t*.7)+band*.06*sin(a*6));
    float petal=fill(flower,c.px*2),vein=line(sin(a*3),.06,c.px*2)*petal;
    float highlight=pow(max(0.f,1-r*2),6.f);
    return paint(h.z*.12+h.w*.09+a*.035,f)*(.13+petal*.55+vein*.35)+paint(.85,f)*highlight*.6;
}
NATIVE_EFFECT(auroraWaltz)

float3 elasticAnthem(Ctx c, constant NativeFrame &f) {

    float2 q=c.uv*2.3/c.size;float4 v=voronoi(q,.85,c.t*.8);
    float band=c.b[int(abs(v.z*2+v.w))%4],membrane=glow(v.y-v.x,.055+band*.05);
    float bubble=exp(-v.x*v.x*(5+band*3)),rim=glow(v.x-.25-band*.05,.04);
    float flow=.5+.5*sin(q.x*3+q.y*2+c.t*.4);
    return paint(v.z*.16+v.w*.09,f)*(.14+membrane*.9+bubble*.45+rim*.4)+paint(.85,f)*bubble*flow*.2;
}
NATIVE_EFFECT(elasticAnthem)

float3 crimsonCadence(Ctx c, constant NativeFrame &f) {

    float2 q=c.uv*1.8/c.size,id=floor(q),p=fract(q)-.5;float phase=id.x*.7+id.y*1.4;
    float a=atan2(p.y,p.x)+c.t*.4+.15*sin(phase),r=length(p),band=c.b[int(abs(id.x+id.y))%4];
    float fan=pow(.5+.5*cos(a*9+r*5),3.f);float disc=fill(r-.43,c.px*2);
    float ribs=line(sin(a*18+r*3+band*sin(a*9)),.075,c.px*3)*disc;
    return paint(phase*.12+a*.03,f)*(.13+fan*disc*.65+ribs*.5)+paint(.85,f)*glow(r-.43,.025)*.6;
}
NATIVE_EFFECT(crimsonCadence)

float3 sapphireStomp(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv*2/c.size;float row=floor(p.y),y=fract(p.y)-.5;
    float phase=c.t*.8+row*1.4,band=c.b[int(abs(row))%4];
    float zig=abs(fract(p.x*.8+phase*.15)-.5)*2-.5;
    float wave=y-zig*(.4+band*.35)-.1*sin(p.x*5-phase);
    float ridge=glow(wave,.07),face=exp(-abs(wave+.15)*4), seam=line(sin(p.x*PI*1.6+phase*.3),.07,c.px)*face;
    return paint(row*.16+p.x*.035,f)*(.14+ridge+face*.45+seam*.35);
}
NATIVE_EFFECT(sapphireStomp)

float3 coralCrescendo(Ctx c, constant NativeFrame &f) {

    float2 q=c.uv*1.7/c.size;float4 h=hexCell(q);float3 col=paint(h.z*.12+h.w*.08,f)*.15;
    for(int k=0;k<6;++k){float a=float(k)*PI/3+c.t*.35+h.z*.4,band=c.b[k%4];
      float orbit=.29+.025*sin(c.t+h.w)+band*.04;float2 center=float2(cos(a),sin(a))*orbit;
      float r=.115+band*.035,d=length(h.xy-center)-r;
      float sphere=fill(d,c.px*2),normal=sqrt(max(0.f,1-pow(length(h.xy-center)/r,2.f)));
      col+=paint(float(k)*.16+h.z*.1,f)*sphere*(.3+normal*.6)+paint(.85,f)*glow(d,.015)*.3;
    }return col;
}
NATIVE_EFFECT(coralCrescendo)

float3 electricEncore(Ctx c, constant NativeFrame &f) {

    float2 q=c.uv*2.6/c.size;
    q+=float2(sin(q.y*1.4+c.t*.6),cos(q.x*1.6-c.t*.5))*(.18+c.b.y*.35);
    float2 id=floor(q),p=fract(q)-.5;float phase=id.x*.7+id.y*1.1;
    float wires=line(min(abs(p.x),abs(p.y)),.025,c.px*3),diagonal=line(p.x+p.y,.02,c.px*3);
    float node=glow(length(p),.1+c.b[int(abs(id.x+id.y))%4]*.04);
    float charge=.4+.6*pow(.5+.5*sin(phase+c.t*1.1),4.f);
    return paint(phase*.12,f)*(.14+wires*.6+diagonal*.25+node*charge);
}
NATIVE_EFFECT(electricEncore)

float3 luminousLockstep(Ctx c, constant NativeFrame &f) {

    float2 q=rot(c.uv*2/c.size,.12*sin(c.t*.3)),id=floor(q),p=fract(q)-.5;
    float phase=id.x*.8+id.y*1.2,band=c.b[int(abs(id.x*2+id.y))%4];
    p=rot(p,.3*sin(c.t*.8+phase));float kite=abs(p.x)*1.3+abs(p.y)-(.42+band*.055);
    float body=fill(kite,c.px*3),crease=line(p.x,.02,c.px*3)*body;
    float facet=.3+.6*saturate(.5+p.x*1.7-p.y*.5),rim=glow(kite,.02);
    return paint(phase*.14+p.x*.08,f)*(.14+body*facet+crease*.4+rim*.55);
}
NATIVE_EFFECT(luminousLockstep)

float3 festivalFinale(Ctx c, constant NativeFrame &f) {

    float2 p=c.uv/c.size;float3 col=deep(.5,f)*.16;
    for(int k=0;k<4;++k){float phase=float(k)*PI*.5;float2 q=rot(p,phase+c.t*.1);
      float wave=sin(q.x*2.5+sin(q.y*1.7+c.t*.5+phase)*1.3)+cos(q.y*3-c.t*.7+phase);
      wave+=c.b[k]*sin(q.x*7-q.y*4)*.65;float ribbon=glow(wave,.12),core=pow(max(0.f,cos(wave*4)),12.f);
      col+=paint(float(k)*.23+wave*.05,f)*(ribbon*.65+core*.25);
    }return col;
}
NATIVE_EFFECT(festivalFinale)
