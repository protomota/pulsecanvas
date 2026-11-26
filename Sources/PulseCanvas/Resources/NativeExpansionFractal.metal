// Original PulseCanvas designs 360–364. Escape-time fractals that twist into each other: endless spiral dives,
// braided Julia sets, Newton basins, Phoenix spirals and a Droste recursion. Every form is computed from its
// mathematical definition. Seamless zooms use exact self-similarity (linearisation at a repelling fixed point)
// or crossfaded layers, so float32 precision never runs out and nothing resets.

// ---------------------------------------------------------------- complex helpers
float2 frc_mul(float2 a, float2 b) { return float2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x); }
float2 frc_div(float2 a, float2 b) { return float2(a.x * b.x + a.y * b.y, a.y * b.x - a.x * b.y) / max(dot(b, b), 1e-30f); }
float2 frc_polar(float radius, float angle) { return radius * float2(cos(angle), sin(angle)); }
float frc_band(float4 b, float id) { return b[int(id - 4 * floor(id / 4))]; }

// ---------------------------------------------------------------- 360 Julia Dive
// Zoom into the repelling fixed point of z^2 + k. Near that point the Julia set is exactly self-similar
// under multiplication by its multiplier lambda, so starting the orbit at fixedPoint + w * lambda^-2(n+u)
// and iterating (the Poincare linearisation, done in offset form so float32 keeps every digit) makes
// depth u and u + 1 identical: an endless, exact dive with no crossfade. A multiplier just past -1 gives
// a two-armed spiral that turns as you fall in.
float3 juliaDive(Ctx c, constant NativeFrame &f) {
    float mag = 1.12 + .012 * sin(c.t * .043);
    float arg = 2.953 + .025 * sin(c.t * .029 + 1.3);
    float2 lam = frc_polar(mag, arg);
    float2 fixedPoint = lam * .5;
    float2 k = fixedPoint - frc_mul(fixedPoint, fixedPoint);
    // One octave is two iterations: the zoom factor lambda^2 with a residual twist that winds the arms.
    const int per = 2;
    float logMag = per * log(mag), logArg = per * arg - TAU;
    float u = fract(c.travel * .8);
    const int pre = 15;
    float shrink = -(float(pre) + u);
    float2 zoom = frc_polar(exp(shrink * logMag) * .3 / c.size, shrink * logArg);
    float2 drift = float2(sin(c.t * .07), cos(c.t * .053)) * .14 * (c.extent - .6);
    float2 p = rot(c.uv - drift, c.t * .06);
    float2 d = frc_mul(p, zoom), dd = zoom;
    // Orbit-trap layers: four trap shapes, each summed over its own window of orbit depth.
    float4 trapGlow = float4(0);
    float mu = 0, de = 0; bool escaped = false;
    const int steps = per * pre + 40;
    for (int i = 0; i < steps; ++i) {
        dd = 2 * frc_mul(lam * .5 + d, dd);
        d = frc_mul(d, lam + d);
        float2 z = fixedPoint + d;
        float depth = float(i) - per * (pre + u);
        if (depth > -4 && depth < 17) {
            float4 offset = float4(depth) - float4(1, 4.5, 8, 11.5);
            float4 window = exp(-offset * offset * .18);
            float4 q = float4(length(z), abs(length(z - k) - .3), abs(z.y - z.x * .4), abs(length(z) - .85));
            float4 g = float4(.035, .018, .014, .012) / (float4(.035, .018, .014, .012) + q);
            trapGlow += window * g * g;
        }
        float r2 = dot(z, z);
        if (r2 > 1024) {
            float r = sqrt(r2);
            mu = float(i) + 1 - log2(log(r));
            de = .5 * r * log(r) / max(length(dd), 1e-20f);
            escaped = true;
            break;
        }
    }
    // Orbits still bounded after the fixed budget form the glowing body of the arms. The budget is a
    // fixed escape-time phase, so it does not move when the octave wraps.
    float phase = escaped ? min(mu - per * (pre + u), 38.f) : 38;
    float inner = smoothstep(24.f, 38.f, phase);
    float dist = escaped && phase < 38 ? de : 0;
    float body = exp(-dist * 30) * (1 - inner);
    float core = glow(dist, .003 + .004 * c.b.w) * (1 - inner);
    float hue = phase * .07 + .3 * sin(c.t * .05);
    float band = phase * .25;
    float wave = .5 + .5 * cos(band * TAU);
    float3 col = paint(.02, f) * (.1 + .06 * wave) + paint(.3 + .15 * wave, f) * .05 * wave;
    col += paint(.45, f) * .22 * exp(-dist * 9) * (1 - inner) + paint(.62 + hue * .2, f) * .45 * body;
    col += deep(.55, f) * inner * .26 + paint(.4, f) * inner * .05;
    float contour = line(fract(band + .5) - .5, .035, .05);
    col += paint(.28 + .3 * wave, f) * contour * (.22 + .4 * body);
    col += paint(.9, f) * core * .8;
    float4 lit = float4(.1, .09, .08, .08) + c.b * float4(1.3, 1.2, 1.1, 1.1);
    col += paint(.05 + phase * .01, f) * trapGlow.x * lit.x * 1.4;
    col += paint(.3 + phase * .01, f) * trapGlow.y * lit.y;
    col += paint(.55 + phase * .01, f) * trapGlow.z * lit.z;
    col += paint(.78, f) * trapGlow.w * lit.w;
    col *= .72;
    // Attack: a bright ripple runs inward along the escape-time contours toward the arms.
    float front = 4 + 14 * (1 - c.hit);
    float ripple = glow(phase - front, .9) * (line(fract(band + .5) - .5, .12, .06) + .6 * body) * (1 - inner * .7);
    col += paint(.88, f) * c.hit * 3.2 * ripple;
    return col;
}
NATIVE_EFFECT(juliaDive)

// ---------------------------------------------------------------- 361 Julia Braid
struct FrcOrbit { float pot; float de; float trap; float inside; };
FrcOrbit frc_julia(float2 z, float scale, float2 k, int steps) {
    FrcOrbit o; o.trap = 9; o.inside = 1; o.pot = float(steps); o.de = 0;
    float2 dz = float2(scale, 0);
    for (int i = 0; i < steps; ++i) {
        dz = 2 * frc_mul(z, dz);
        z = frc_mul(z, z) + k;
        o.trap = min(o.trap, abs(length(z) - .6));
        float r2 = dot(z, z);
        if (r2 > 400) {
            float r = sqrt(r2);
            o.pot = float(i) + 1 - log2(log(r));
            o.de = .5 * r * log(r) / max(length(dz), 1e-20f);
            o.inside = 0;
            break;
        }
    }
    return o;
}

float3 juliaBraid(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    // The two sets revolve around each other while counter-rotating, so their filaments keep winding through.
    float orbit = c.travel * .06 + c.t * .02;
    float spin = c.travel * .05 + c.t * .015;
    float2 offset = float2(cos(orbit), sin(orbit)) * .22 * float2(c.extent.x / max(c.extent.y, 1.f), 1);
    float2 kA = float2(-.8, .18) + .02 * float2(cos(c.travel * .021 + c.t * .03), sin(c.travel * .017 + c.t * .023));
    float2 kB = float2(-.55, .62) + .02 * float2(cos(c.travel * .019 - c.t * .027 + 2), sin(c.travel * .023 - c.t * .021 + 1));
    float scaleA = .82, scaleB = .9;
    float2 zA = rot(p - offset, spin) * scaleA;
    float2 zB = rot(p + offset, -spin * 1.3 + 1.2) * scaleB;
    FrcOrbit a = frc_julia(zA, scaleA, kA, 36);
    FrcOrbit b = frc_julia(zB, scaleB, kB, 36);
    float wa = .0035 + .006 * c.b.x, wb = .0035 + .006 * c.b.w;
    float lineA = a.inside > .5 ? 0 : glow(a.de, wa) + .12 * glow(a.de, wa * 4);
    float lineB = b.inside > .5 ? 0 : glow(b.de, wb) + .12 * glow(b.de, wb * 4);
    float3 colA = paint(.05 + a.pot * .008, f) * lineA * (.9 + 1.2 * c.b.y);
    float3 colB = paint(.62 + b.pot * .008, f) * lineB * (.9 + 1.2 * c.b.z);
    colA += a.inside > .5 ? paint(.15, f) * (.05 + .3 * glow(a.trap, .03) * (1 + c.b.y)) : float3(0);
    colB += b.inside > .5 ? paint(.75, f) * (.05 + .3 * glow(b.trap, .03) * (1 + c.b.z)) : float3(0);
    // Over/under weave that slides along the filaments.
    float r = length(p), ang = atan2(p.y, p.x);
    float over = smoothstep(-.35f, .35f, sin(ang * 3 + r * 4.5 - c.t * .35));
    float occA = saturate(lineA), occB = saturate(lineB);
    float3 col = mix(colA * (1 - .8 * occB) + colB, colB * (1 - .8 * occA) + colA, over);
    // Equipotential ripples of both sets wind around each other behind the filaments.
    float ringA = a.inside > .5 ? 0 : pow(.5 + .5 * cos(a.pot * 1.8 - c.t * .5), 8.f);
    float ringB = b.inside > .5 ? 0 : pow(.5 + .5 * cos(b.pot * 1.8 + c.t * .5), 8.f);
    float fadeA = smoothstep(1.5f, 5.f, a.pot) * (1 - occA), fadeB = smoothstep(1.5f, 5.f, b.pot) * (1 - occB);
    col += paint(.97, f) * .06 + paint(.0, f) * .025;
    col += paint(.1, f) * ringA * fadeA * (.16 + .2 * c.b.x) + paint(.72, f) * ringB * fadeB * (.16 + .2 * c.b.w);
    col *= .78;
    // Attack: the crossings of the two sets flare.
    col += paint(.92, f) * c.hit * 4 * occA * occB + paint(.5, f) * c.hit * .6 * glow(a.de, .03) * glow(b.de, .03);
    return col;
}
NATIVE_EFFECT(juliaBraid)

// ---------------------------------------------------------------- 362 Newton Vortex
// Newton's method for a cubic whose roots orbit with their centroid fixed at zero. Near infinity the
// Newton map is z -> 2z/3, so starting the orbit at Z * 1.5^n linearises it exactly: the picture is
// self-similar under Z -> 1.5 Z. A conformal log-spiral map that gains nine octaves per turn then
// winds the basins seamlessly into the centre, and iteration-count stripes swirl around them.
float3 newtonVortex(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float a0 = c.t * .06, a1 = c.t * -.045 + 2.2;
    float2 r0 = frc_polar(1 + .18 * sin(c.t * .11), a0);
    float2 r1 = frc_polar(1 + .2 * sin(c.t * .083 + 1.7), a0 + a1 * .15 + 2.1);
    float2 r2 = -r0 - r1;
    float2 e2 = frc_mul(r0, r1) + frc_mul(r1, r2) + frc_mul(r2, r0);
    float2 e3 = frc_mul(frc_mul(r0, r1), r2);
    const float ln15 = .4054651;
    const float tau = 9 * ln15 / TAU;
    float r = max(length(p), 1e-5f), th = atan2(p.y, p.x), lr = log(r);
    float u = fract(c.travel * .55);
    float logZ = log(2.2f) + u * ln15 - lr + tau * th;
    float argZ = -th - tau * lr + c.t * .11;
    const int pre = 10;
    float2 z = frc_polar(exp(logZ + pre * ln15), argZ);
    int root = 0; float mu = 0; bool done = false;
    const float tol = .002;
    for (int i = 0; i < 40; ++i) {
        float2 z2 = frc_mul(z, z);
        float2 num = frc_mul(z2, z) + frc_mul(e2, z) - e3;
        float2 den = 3 * z2 + e2;
        z -= frc_div(num, den);
        float d0 = length(z - r0), d1 = length(z - r1), d2 = length(z - r2);
        float dm = min(d0, min(d1, d2));
        if (dm < tol) {
            root = d0 == dm ? 0 : (d1 == dm ? 1 : 2);
            mu = float(i) - log2(max(log(max(dm, 1e-30f)) / log(tol), 1.f));
            done = true;
            break;
        }
    }
    if (!done) {
        float s0 = dot(z, r0), s1 = dot(z, r1), s2 = dot(z, r2);
        root = s0 >= max(s1, s2) ? 0 : (s1 >= s2 ? 1 : 2);
        mu = 40;
    }
    float phase = mu - pre - logZ / ln15;
    float edge = smoothstep(2.5f, 6.f, phase);
    float rid = float(root);
    float lit = c.b[root];
    float stripe = pow(.5 + .5 * cos(mu * TAU), 2.f);
    float3 basin = paint(.08 + rid * .22 + stripe * .12, f) * (.07 + .26 * stripe + .3 * lit * stripe) + deep(.3 + rid * .2, f) * .06;
    float3 col = basin;
    col += paint(.55 + rid * .1, f) * smoothstep(1.f, 4.f, phase) * (.2 + .35 * lit);
    col += paint(.9, f) * edge * (.3 + 1.1 * c.b.w);
    col *= .85;
    // Attack: a bright ring runs inward along the basin boundaries as the attack decays.
    float front = 1.7 * c.hit;
    col += paint(.95, f) * c.hit * 3.5 * edge * glow(r - front, .07 + .1 * r);
    col *= smoothstep(.0f, .12f + c.fog * .2f, r) * .85 + .15;
    return col;
}
NATIVE_EFFECT(newtonVortex)

// ---------------------------------------------------------------- 363 Phoenix Spiral
// The Phoenix recurrence z' = z^2 + k + p * z_prev. Four nested layers at octave scales travel toward
// the viewer around a wandering centre, twisting as they grow, so feathers keep unfurling from the depth.
// Only the feather edges and veins emit light, so the layers read as depth instead of a muddy blend.
float3 phoenixSpiral(Ctx c, constant NativeFrame &f) {
    float2 centre = float2(sin(c.t * .043) * .3, cos(c.t * .037) * .22) * (c.extent - .4);
    float2 p = (c.uv - centre) / c.size;
    float rr = length(p);
    float3 col = paint(.08, f) * .2 + paint(.4, f) * .3 * exp(-rr * 2);
    for (int layer = 0; layer < 4; ++layer) {
        float2 s = layerSlot(layer, 4, c.travel * .06);
        float fade = layerFade(s.x);
        float scale = layerScale(s.x, 6.f) * .4;
        float twist = s.x * 2.6 + c.hit * .45 * (s.x - .45) + s.y * 2.39996 + c.t * .03;
        float2 z = rot(p, twist).yx * scale;
        float2 dz = float2(scale, 0), prev = float2(0), dprev = float2(0);
        float2 k = float2(.38 + .012 * sin(s.y * 1.3 + c.t * .05), .01 * cos(s.y * .7));
        float2 pk = float2(-.17 + .03 * cos(s.y * 2.1 + c.t * .03), 0);
        float vein = 9, mu = 24, de = 0; bool escaped = false;
        for (int i = 0; i < 24; ++i) {
            float2 nextDz = 2 * frc_mul(z, dz) + frc_mul(pk, dprev);
            float2 next = frc_mul(z, z) + k + frc_mul(pk, prev);
            dprev = dz; dz = nextDz; prev = z; z = next;
            vein = min(vein, abs(z.x * .8 + z.y * .6));
            float r2 = dot(z, z);
            if (r2 > 256) { float r = sqrt(r2); mu = float(i) + 1 - log2(log(r)); de = .5 * r * log(r) / max(length(dz), 1e-20f); escaped = true; break; }
        }
        float band = frc_band(c.b, s.y);
        float depthLight = fade * (.3 + .7 * s.x);
        // Feather outline, barbs (escape-time bands hugging the edge) and veins inside the wings.
        float edge = escaped ? glow(de, .005 + .005 * band) : 0;
        float barbs = escaped ? pow(.5 + .5 * cos(mu * 2.2), 3.f) * exp(-de * 25) : 0;
        float veins = escaped ? 0 : glow(vein, .015 + .01 * band);
        float3 layerCol = paint(.45 + .45 * s.x, f) * edge * (.8 + 1.4 * band);
        layerCol += paint(.3 + .4 * s.x + mu * .01, f) * barbs * (.35 + .6 * band);
        layerCol += paint(.2 + .4 * s.x, f) * (veins * (.3 + .8 * band) + (escaped ? 0 : .12));
        layerCol += paint(.95, f) * glow(de, .0025) * (escaped ? 1 : 0) * 1.5 * c.hit * smoothstep(.3f, .7f, s.x);
        col += layerCol * depthLight;
    }
    return col;
}
NATIVE_EFFECT(phoenixSpiral)

// ---------------------------------------------------------------- 364 Droste Fractal
// A framed Julia picture that holds a copy of itself inside its inner frame. The complex logarithm of
// the screen, multiplied by (1 - i 2 lnS / 2pi), makes one turn equal two recursion levels, so the frames
// twist into an endless double spiral (Escher's construction); travel slides along the log-scale axis.
float3 drosteFractal(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    const float S = 2.8, lnS = 1.0296194;
    const float k = 2 * lnS / TAU;  // two recursion levels per turn
    float r = max(length(p), 1e-5f), th = atan2(p.y, p.x), lr = log(r);
    float2 w = float2(lr + k * th, th - k * lr);
    float flow = c.travel * .16;
    float level = w.x / lnS - flow;
    float2 z = frc_polar(exp((fract(level) - 1) * lnS), w.y + c.t * .03);
    float m = max(abs(z.x), abs(z.y));
    if (m < 1 / S) { z *= S; m *= S; }
    // One full turn descends two recursion levels, so the seam-free ring coordinate is log_S(r): the
    // recursion rings are concentric on screen and drift outward with travel (stable ids per ring).
    float ring = lr / lnS - flow;
    // Frame seams at |z|inf = 1 and 1/S, measured in outer-level units on both sides.
    float seam = min(1 - m, (m - 1 / S) * S);
    float pxz = c.px * length(z) * sqrt(1 + k * k) / r;
    // The Julia picture between the frames.
    float2 q = rot(z, .6) * 1.25;
    float2 kj = float2(-.122 + .02 * sin(c.t * .05), .745 + .02 * cos(c.t * .04));
    float2 dq = float2(1.25, 0);
    float trap = 9, mu = 28, de = 0; bool escaped = false;
    for (int i = 0; i < 28; ++i) {
        dq = 2 * frc_mul(q, dq);
        q = frc_mul(q, q) + kj;
        trap = min(trap, abs(q.x) + abs(q.y) * .5);
        float r2 = dot(q, q);
        if (r2 > 256) { float rq = sqrt(r2); mu = float(i) + 1 - log2(log(rq)); de = .5 * rq * log(rq) / max(length(dq), 1e-20f); escaped = true; break; }
    }
    // Each band lights every fourth ring; smooth windows keep the ring edges seamless.
    float4 window = pow(.5 + .5 * cos((float4(ring) - float4(0, 1, 2, 3)) * TAU / 4), float4(6));
    float ringLit = .6 + .9 * dot(window, c.b);
    float edge = escaped ? glow(de, max(.008f, pxz * 1.5f)) : .25;
    float ringHue = .1 * sin(ring * 1.5708);
    float stripe = pow(.5 + .5 * cos(mu * 2.2), 3.f) * smoothstep(1.f, 5.f, mu);
    float cycle = .5 + .5 * cos(atan2(q.y, q.x));
    float3 picture = escaped ? paint(.18 + mu * .025 + ringHue, f) * (.14 + .3 * stripe) + paint(.45, f) * .3 * smoothstep(5.f, 16.f, mu)
                             : paint(.22 + .3 * cycle + ringHue, f) * (.08 + .12 * cycle) * (.6 + .4 * cos(log(trap + 1e-4f) * 5))
                               + paint(.6, f) * glow(trap, .04) * .45;
    picture += paint(.7, f) * edge * .9;
    picture *= ringLit;
    float frameMask = smoothstep(.015f, .07f, seam);
    float3 frame = paint(.8, f) * glow(seam, .007 + pxz) * 1.3 + paint(.45, f) * glow(seam, .045) * .45;
    float3 col = picture * frameMask + frame;
    // Attack: one ring of the recursion flashes.
    float ringPos = lr / lnS + 1.2;
    float flash = c.hit * exp(-ringPos * ringPos * 3);
    col += paint(.75, f) * flash * (1.6 * frameMask * edge + 1.2 * glow(seam, .02 + pxz)) + paint(.4, f) * flash * .25;
    col *= smoothstep(.0f, .1f + c.fog * .15f, r) * .9 + .1;
    return col;
}
NATIVE_EFFECT(drosteFractal)
