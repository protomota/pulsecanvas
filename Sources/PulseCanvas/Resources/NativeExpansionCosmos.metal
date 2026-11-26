// Original PulseCanvas designs 350–359. Cosmic phenomena drawn as vivid neon light, not
// photographic space art: beams, shells, streams, loops and lensed arcs built from analytic
// curves and a little noise. Every band drives its own structures; attacks make local events.

// ---------------------------------------------------------------- shared helpers (cosm*)
// Ridged noise: thin bright creases, the raw material of filaments.
float cosmRidge(float2 p, int octaves) {
    float sum = 0, amplitude = .5;
    for (int i = 0; i < octaves; ++i) {
        float n = 1 - abs(2 * noise2(p) - 1);
        sum += amplitude * n * n;
        p = float2(p.x * 1.6 - p.y * 1.2, p.x * 1.2 + p.y * 1.6) + 4.7;
        amplitude *= .5;
    }
    return sum;
}
// Sparse twinkling specks, one jittered candidate per cell, with no seams at cell edges.
float cosmStars(float2 p, float density, float t) {
    float2 id = floor(p), local = fract(p) - .5, h = hash22(id + 31.7);
    float on = step(1 - density, hash21(id + 9.1));
    float2 offset = local - (h - .5) * .6;
    float twinkle = .6 + .4 * sin(t * (1.1 + h.x * 2) + h.y * TAU);
    return on * twinkle * exp(-dot(offset, offset) * 900);
}
// Distance in uv units to the nearest integer contour of a smooth field v.
float cosmContour(float v, float px) {
    return abs(fract(v + .5) - .5) * px / max(fwidth(v), 1e-5f);
}
// Lay a two-body composition along the canvas's long axis.
float2 cosmLongAxis(float2 p, float2 extent) {
    return extent.y > extent.x ? float2(p.y, -p.x) : p;
}

// ---------------------------------------------------------------- 350 Pulsar Beacon
float3 pulsarBeacon(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float spin = c.t * .55;
    // Attacks shear thin horizontal slices sideways: a glitch flare through the beams.
    float slice = floor(p.y * 28);
    float shear = (noise2(float2(slice * 1.37, c.t * 5)) - .5) * c.hit * c.hit * .8;
    float2 g = p + float2(shear, 0);
    float r = length(g), a = atan2(g.y, g.x);
    float lag = (spin - a) - PI * floor((spin - a) / PI);          // time since a beam swept here
    float offset = lag > PI * .5 ? lag - PI : lag;                   // signed angle to nearest beam
    float width = .045 + .05 * c.b.x;
    float cone = exp(-offset * offset / (width * width)) * exp(-r * .25);
    float spine = glow(r * sin(offset), .004 + .005 * c.b.x) * exp(-r * .4);

    // Nebula gas, lit by the sweep and fading behind it.
    float2 drift = float2(c.t * .013, -c.t * .009);
    float gas = fbm2(p * 1.25 + drift, 5);
    float strands = cosmRidge(p * 2.3 + gas * 1.6 - drift * 1.5, 4);
    float cloud = smoothstep(.3f, .78f, gas);
    float after = (1 - exp(-lag * 30)) * exp(-lag * (2.6 - 1.4 * c.b.y));
    float lit = after * (.3 + .7 * cloud) * (.35 + strands * 1.6);
    float glint = pow(strands, 6.f) * cloud * (.2 + 3 * c.b.w);
    float pulse = pow(.5 + .5 * cos(TAU * (r * 1.5 - c.t * .4)), 30.f) * cloud * (.15 + 1.6 * c.b.w);

    // Magnetic loops share the beam axis and spin with it.
    float2 m = rot(p, -spin);
    float rm = max(length(m), 1e-3f);
    float shell = rm * rm * rm / max(m.y * m.y, 1e-6f);
    float lv = log2(shell) * 1.6;
    float loopMask = smoothstep(1.2f, .7f, shell) * smoothstep(.03f, .08f, rm);
    float flowing = .55 + .45 * sin(atan2(m.y, m.x) * 6 - c.t * 3);
    float loops = glow(cosmContour(lv, c.px) / c.size, .005) * loopMask * flowing * (.25 + 1.8 * c.b.z);

    float rp = length(p);
    float star = glow(rp, .02) * 3 + glow(rp, .09) * .5;
    float flare = (glow(p.y, .005 + .006 * c.hit) * exp(-abs(p.x) * (3.4 - 2.4 * c.hit))
                 + glow(p.x, .004) * exp(-abs(p.y) * 6)) * (.25 + 2.4 * c.hit);
    float bars = c.hit * c.hit * smoothstep(.62f, .8f, noise2(float2(slice * 2.1, c.t * 6))) * exp(-r * .9) * .7;

    float3 col = paint(.02 + gas * .2, f) * (.035 + .12 * gas * gas);
    col += paint(.22 + strands * .15, f) * cloud * strands * .16;
    col += paint(.42 + .38 * after, f) * lit * (.75 + .25 * strands);
    col += paint(.75, f) * (glint + pulse * .6);
    col += paint(.72, f) * cone * (.35 + 1.9 * c.b.x) * (.3 + .6 * cloud + strands * .7);
    col += paint(.8, f) * spine * (.8 + 2.5 * c.b.x);
    col += paint(.58, f) * loops * 1.4;
    col += paint(.78, f) * (star + flare) + paint(.25, f) * bars;
    return col;
}
NATIVE_EFFECT(pulsarBeacon)

// ---------------------------------------------------------------- 351 Twin Suns
float4 cosmSun(float2 d, float radius, float spin, float hue, float corona, float px, constant NativeFrame &f) {
    float r = length(d) / radius;
    float mu = sqrt(max(0.f, 1 - r * r));
    float2 sp = rot(d / radius, spin);
    float cells = noise2(sp * 5 + 3.3) * .6 + noise2(sp * 11 + 8.1) * .4;
    float3 surface = paint(hue + .2 * mu + .12 * cells, f) * (.7 + 1.1 * mu) + paint(.95, f) * pow(mu, 3.f) * .5;
    float disc = fill(r - 1, px / radius);
    float a = atan2(d.y, d.x) + spin * .3;
    float rays = pow(.5 + .5 * cos(a * 14 + 2 * sin(a * 5 + spin * 2)), 6.f) * exp(-max(r - 1, 0.f) * (2.6 - corona * 1.2));
    float halo = glow(max(r - 1, 0.f), .25 + corona * .45) * (.3 + corona * 1.4);
    float rim = glow(r - 1, .05);
    float3 col = surface * disc + (paint(hue + .15, f) * (halo + rays * (.25 + corona * 1.5)) + paint(.9, f) * rim * .6) * (1 - disc);
    return float4(col, disc);
}

float3 twinSuns(Ctx c, constant NativeFrame &f) {
    float2 p = cosmLongAxis(c.uv / c.size, c.extent);
    float phase = c.t * .3;
    float2 orbit = float2(cos(phase), sin(phase) * .55);
    float2 s1 = orbit * .42, s2 = -orbit * .74;
    const float r1 = .23, r2 = .135;

    // Circumbinary outflow: two trailing arms of glowing filaments that turn with the orbit.
    float rho = length(p), th = atan2(p.y, p.x);
    float spiral = 2 * (th - phase) + log(rho + .08) * 3.4;
    float arms = pow(.5 + .5 * cos(spiral), 2.f);
    float tex = fbm2(p * 2.1 + float2(c.t * .02, -c.t * .013), 4);
    float threads = pow(.5 + .5 * cos(spiral * 5 + tex * 5), 10.f);
    float gas = arms * exp(-rho * .3);
    float3 col = paint(.02 + tex * .1, f) * (.04 + .1 * tex);
    col += paint(.25 + tex * .35, f) * gas * (.06 + .2 * tex) * (.6 + 1.2 * c.b.y);
    col += paint(.5 + .25 * tex, f) * gas * threads * (.22 + 1.5 * c.b.y);

    // Tidal streams from the larger star to its companion, one strand per band.
    float2 dv = s2 - s1; float len = length(dv);
    float2 ax = dv / len, nv = float2(-ax.y, ax.x), rel = p - s1;
    float u = dot(rel, ax) / len, v = dot(rel, nv), uc = clamp(u, 0.f, 1.f);
    float ends = smoothstep(-.05f, .15f, u) * smoothstep(1.05f, .85f, u);
    for (int k = 0; k < 4; ++k) {
        float fk = float(k), level = c.b[k];
        float bend = ((.12 + .06 * fk) * len + .04 * sin(TAU * uc * 1.5 + c.t * .8 + fk * 1.7)) * sin(PI * uc);
        float dist = abs(v - bend);
        float flow = pow(.5 + .5 * sin(u * 16 - c.t * 2.4 + fk * 1.9), 3.f);
        float strand = glow(dist, .009 + .009 * level) * (.35 + .65 * flow) + glow(dist, .06) * .2;
        col += paint(.55 + .08 * fk + .25 * flow, f) * strand * ends * (.35 + 1.8 * level);
    }

    // Attacks erupt a flare loop and an ejected blob from each star.
    float burst = c.hit * c.hit;
    float3 flares = 0;
    for (int k = 0; k < 2; ++k) {
        float2 s = k == 0 ? s1 : s2; float radius = k == 0 ? r1 : r2;
        float fa = phase * (k == 0 ? 1.7 : -1.3) + float(k) * 2.4 + .8;
        float2 dir = float2(cos(fa), sin(fa));
        float2 site = s + dir * radius;
        float loopArc = abs(length(p - site) - radius * (.2 + .9 * c.hit));
        float outside = smoothstep(radius, radius * 1.05, length(p - s));
        float blob = glow(length(p - s - dir * radius * (1.15 + 2.6 * (1 - c.hit))), .03 + .05 * (1 - c.hit));
        flares += paint(.85, f) * (glow(loopArc, .008) * outside * 1.5 + blob) * burst;
    }

    // Stars, drawn back to front as the orbit turns.
    float4 a = cosmSun(p - s1, r1, c.t * .2, .45, c.b.x, c.px, f);
    float4 b = cosmSun(p - s2, r2, -c.t * .3, .7, c.b.z, c.px, f);
    bool firstFront = sin(phase) < 0;
    float4 back = firstFront ? b : a, front = firstFront ? a : b;
    col = col * (1 - back.w) + back.rgb;
    col += flares;
    col = col * (1 - front.w) + front.rgb;
    col += paint(.9, f) * cosmStars(p * 9, .25, c.t) * .5;
    return col;
}
NATIVE_EFFECT(twinSuns)

// ---------------------------------------------------------------- 352 Supernova Shell
float3 supernovaShell(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float r = length(p);
    float2 dirv = p / max(r, 1e-4f);
    const float R = .64;
    float wob = noise2(dirv * 2.2 + 11.3) - .5;
    float Ro = R * (1 + .14 * wob), Ri = Ro * .84;
    float shell = (sqrt(max(Ro * Ro - r * r, 0.f)) - sqrt(max(Ri * Ri - r * r, 0.f))) / sqrt(Ro * Ro - Ri * Ri);

    // Filaments drift outward through a seamless two-octave zoom.
    float coarse = 0, fine = 0, wisp = 0;
    for (int o = 0; o < 2; ++o) {
        float2 z = octaveZoom(c.t * .03, o);
        float2 q = p * z.x;
        coarse += z.y * cosmRidge(q * 3.1 + 1.7, 3);
        fine += z.y * cosmRidge(q * 7.3 - 4.1, 3);
        wisp += z.y * fbm2(q * 2.4 + 9.5, 2);
    }
    coarse = pow(coarse / .875, 5.f);
    fine = pow(fine / .875, 7.f);

    // Hit: a fresh shock ring races out and lights the filaments it crosses.
    float Rh = R * (.08 + 1.35 * (1 - c.hit)) * (1 + .1 * wob);
    float shockBoost = 1 + 2.5 * c.hit * exp(-(r - Rh) * (r - Rh) / .008);
    float newRing = glow(r - Rh, .012) * c.hit * c.hit * 2;

    float inner = smoothstep(Ri, Ri * .3, r);
    float2 kq = p * 8;
    float2 kid = floor(kq), kl = fract(kq) - .5 - (hash22(kid + 4.4) - .5) * .6;
    float knot = step(.6, hash21(kid + 1.9)) * exp(-dot(kl, kl) * 60) * smoothstep(.3f, .7f, shell);

    float Rs = R * (1.15 + .1 * (noise2(dirv * 3.1 + 2.2) - .5));
    float forward = glow(r - Rs, .006) * .9 + glow(r - Rs, .05) * .18;

    float haze = fbm2(p * .9 + float2(4.1, c.t * .01), 3);
    float3 col = paint(.95 + haze * .1, f) * (.03 + .08 * haze * haze);
    col += paint(.1 + haze * .3, f) * smoothstep(.5f, .85f, haze) * .1;
    col += paint(.8 + .1 * wob, f) * shell * (.07 + coarse * (.7 + 2.4 * c.b.x)) * shockBoost;
    col += paint(.3 + .1 * fine, f) * shell * fine * (.45 + 2.6 * c.b.y) * shockBoost;
    col += paint(.02 + .08 * wisp, f) * inner * pow(wisp, 3.f) * (.4 + 2.4 * c.b.z);
    col += paint(.72, f) * knot * (.4 + 3 * c.b.w) * shockBoost;
    col += paint(.05, f) * forward;
    col += paint(.7, f) * (newRing + glow(r, .025) * 1.2 + glow(r, .08) * .2);
    col += paint(.6, f) * cosmStars(p * 11, .2, c.t) * .4;
    return col;
}
NATIVE_EFFECT(supernovaShell)

// ---------------------------------------------------------------- 353 Galaxy Collision
// Two-armed log spiral seen in its own (de-projected) plane: x = arm A, y = arm B, z = disc.
float3 cosmSpiral(float2 q, float spin, float wind) {
    float r = max(length(q), 1e-3f);
    float phi = atan2(q.y, q.x) - wind * log(r) - spin;
    float c1 = cos(phi);
    return float3(pow(max(c1, 0.f), 6.f), pow(max(-c1, 0.f), 6.f), r);
}

float3 galaxyCollision(Ctx c, constant NativeFrame &f) {
    float2 p = cosmLongAxis(c.uv / c.size, c.extent);
    float orbit = c.t * .035;
    float2 c1 = rot(float2(-.58, .14), orbit), c2 = rot(float2(.62, -.16), orbit);
    float2 q1 = rot(p - c1, .5 + orbit); q1.y /= .6;
    float2 q2 = rot(p - c2, -.9 + orbit); q2.y /= .5;
    float3 g1 = cosmSpiral(q1 * .8, c.t * .16, 2.3), g2 = cosmSpiral(q2 * .9, -c.t * .13, -2.1);
    float clumps = .45 + .55 * noise2(p * 9 + float2(c.t * .05, 0));

    float disc1 = exp(-g1.z * 2.6), disc2 = exp(-g2.z * 3);
    // Tidal tails: the outer arms keep going on the side facing away from the partner.
    float2 away1 = normalize(c1 - c2);
    float tailMask1 = smoothstep(-.2f, .5f, dot(normalize(p - c1 + 1e-4), away1));
    float tailMask2 = smoothstep(-.2f, .5f, dot(normalize(p - c2 + 1e-4), -away1));
    float tail1 = g1.x * exp(-g1.z * .75) * tailMask1 * smoothstep(.25f, .6f, g1.z);
    float tail2 = g2.y * exp(-g2.z * .8) * tailMask2 * smoothstep(.25f, .6f, g2.z);

    // A bridge of stars stretched between the pair.
    float2 dv = c2 - c1; float len = length(dv);
    float2 ax = dv / len, rel = p - c1;
    float u = dot(rel, ax) / len, v = dot(rel, float2(-ax.y, ax.x));
    float bridgeDist = abs(v - .16 * len * sin(PI * clamp(u, 0.f, 1.f)));
    float bridge = glow(bridgeDist, .03) * smoothstep(-.05f, .2f, u) * smoothstep(1.05f, .8f, u);

    float armA = g1.x * disc1, armB = g1.y * disc1, armC = (g2.x + g2.y) * disc2;
    float tails = tail1 + tail2 + bridge * .6;

    // Starburst knots sit on the arms; attacks blossom them with an expanding ring.
    float2 kq = p * 7, kid = floor(kq), kl = (fract(kq) - .5 - (hash22(kid + 2.7) - .5) * .6) / 7;
    float kd = length(kl);
    float knotOn = step(.5, hash21(kid + 6.1));
    float host = min(1.f, (armA + armB + armC) * 2 + tails * 2);
    float knot = knotOn * host * (glow(kd, .006 + .01 * c.hit) * (.6 + 3 * c.hit)
                                + glow(kd - (.015 + .05 * (1 - c.hit)), .004) * c.hit * c.hit * 2);

    float3 col = paint(0, f) * .07 + paint(.2, f) * exp(-min(length(p - c1), length(p - c2)) * 1.1) * .1;
    col += paint(.75, f) * armA * clumps * (.5 + 2.4 * c.b.x);
    col += paint(.52, f) * armB * clumps * (.5 + 2.4 * c.b.y);
    col += paint(.3, f) * armC * clumps * (.55 + 2.4 * c.b.z);
    col += paint(.45 + .25 * clumps, f) * tails * clumps * (.45 + 2.2 * c.b.w);
    col += paint(.3, f) * (disc1 + disc2) * .3;
    col += paint(.8, f) * (exp(-g1.z * g1.z * 90) * 1.8 + exp(-g2.z * g2.z * 110) * 1.6);
    col += paint(.78, f) * knot;
    col += paint(.7, f) * cosmStars(p * 10, .25, c.t) * .5;
    return col;
}
NATIVE_EFFECT(galaxyCollision)

// ---------------------------------------------------------------- 354 Solar Prominence
float3 solarProminence(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    const float Rs = 2.2;
    float2 C = float2(0, -.3 - .3 * max(c.extent.y - c.extent.x, 0.f) - Rs);
    float2 d = p - C; float rr = length(d);
    float h = rr - Rs;                         // height above the limb
    float s = atan2(d.x, d.y) * Rs;            // arc length along the limb
    float above = smoothstep(-.004f, .02f, h);

    // Granulated surface, foreshortened toward the limb.
    float mu = sqrt(max(0.f, 1 - (rr / Rs) * (rr / Rs)));
    float2 gq = float2(s, acos(clamp(rr / Rs, 0.f, 1.f)) * Rs) * 7;
    float4 cell = voronoi(gq + float2(c.t * .05, 0), .9, c.t * .6);
    float gran = mix(.6f, smoothstep(0.f, .45f, cell.y - cell.x), smoothstep(0.f, .3f, mu));
    float plage = smoothstep(.55f, .8f, noise2(gq * .09 + 3.3)) * c.b.x;
    float3 surface = paint(.5 + .25 * gran * mu + .15 * mu, f) * (.5 + 1.1 * mu) * (.7 + .4 * gran)
                   + paint(.9, f) * plage * gran * 1.2;
    float disc = 1 - above;

    float hp = max(h, 0.f);
    float streamer = pow(noise2(float2(s * 1.4, hp * .3 - c.t * .04)), 2.f);
    float corona = exp(-hp * 2.2) * (.3 + .9 * streamer) + exp(-hp * .45) * streamer * .3;
    float spicule = pow(noise2(float2(s * 45, c.t * .7)), 4.f) * 5 * exp(-hp / (.03 + .06 * c.b.w)) * above;
    float limb = glow(h, .012);
    // A faint arcade of nested field arches high in the corona.
    float sa = (floor(s / 1.1) + .5) * 1.1;
    float2 ea = float2((s - sa) / .55, hp / (.8 + .2 * sin(sa * 3.1 + c.t * .1)));
    float ela = length(ea);
    float arcade = glow(cosmContour(ela * 5, c.px) / c.size, .0035) * smoothstep(.98f, .85f, ela) * smoothstep(.2f, .35f, ela);

    float3 col = surface * disc;
    col += (paint(0, f) * (.05 + .07 * streamer) + paint(.25 + .35 * streamer, f) * corona * .6) * above;
    col += paint(.45, f) * arcade * above * (.2 + 1.3 * c.b.y);
    col += paint(.85, f) * limb * .9 + paint(.3, f) * spicule * (.4 + 1.5 * c.b.w);

    // Prominence loops: twisted triple-strand arches, each band lifting its own loops.
    for (int k = 0; k < 6; ++k) {
        float fk = float(k), level = c.b[k % 4];
        float sk = (fk - 2.5) * .95 + .25 * sin(c.t * .05 + fk * 1.3);
        float w = .2 + .16 * hash11(fk + 3.1);
        float H = (.26 + .3 * hash11(fk + 8.7)) * (.6 + 1.2 * level) * (1 + .08 * sin(c.t * .3 + fk));
        float tilt = .5 * (hash11(fk + 1.9) - .5);
        float2 e = float2((s - sk - h * tilt) / w, h / H);
        float el = length(e), along = atan2(e.y, e.x), scale = min(w, H);
        float rope = 0;
        for (int j = 0; j < 3; ++j) {
            float off = .09 * sin(along * 5 + c.t * 1.1 + float(j) * 2.09 + fk);
            rope += glow((el - 1 - off) * scale, .005 + .003 * level);
        }
        float flow = pow(.5 + .5 * sin(along * 7 - c.t * 2.2 + fk * 2), 4.f);
        float halo = glow((el - 1) * scale, .035) * .3;
        col += paint(.55 + .3 * flow + .05 * fk, f) * (rope * (.4 + .6 * flow) + halo) * above * (.3 + 1.5 * level);
    }

    // Attacks launch an ejection: a bright-fronted bubble rising off the limb.
    float site = 1.1 * sin(c.t * .045);
    float lift = 1 - c.hit;
    float2 eb = float2(s - site, h - (.06 + lift * 1.1));
    float rad = .08 + lift * .5;
    float bubble = length(eb * float2(1, 1.15)) - rad;
    float cme = glow(bubble, .02 + .03 * lift) * 1.4 + glow(length(eb + float2(0, rad * .5)), .04 + .06 * lift) * .9;
    col += paint(.88, f) * cme * c.hit * c.hit * above;
    return col;
}
NATIVE_EFFECT(solarProminence)

// ---------------------------------------------------------------- 355 Quasar Jet
float3 quasarJet(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float ang = atan2(c.extent.y, c.extent.x) * .85 + .1 * sin(c.t * .05);
    float2 q = rot(p, -ang);
    float ax = abs(q.x), side = q.x < 0 ? -1.f : 1.f;
    const float L = 1.15;
    float reach = smoothstep(L + .15f, L - .25f, ax);
    float wj = .022 + .06 * ax;
    float flick = noise2(float2(ax * 7 - c.t * 6, side * 3.7));
    float jetLevel = .6 + .4 * flick + c.b.w * 2.6 * flick * flick;
    float jet = exp(-q.y * q.y / (wj * wj)) * reach / (1 + ax * .6) * jetLevel;
    float spine = glow(q.y, .0035 + .002 * ax) * reach / (1 + ax) * jetLevel;

    float helix = 0;
    for (int j = 0; j < 2; ++j) {
        float ph = ax * 13 - c.t * 2.2 + float(j) * PI + side;
        helix += glow(q.y - wj * .85 * sin(ph), .004 + .002 * ax) * (.55 + .45 * cos(ph));
    }
    helix *= reach * (.3 + 1.8 * c.b.z);

    float knots = 0;
    for (int k = 0; k < 4; ++k) {
        float ph = fract(c.t * .05 + float(k) * .25 + (side > 0 ? 0.f : .125f));
        knots += glow(length(float2(ax - ph * L, q.y * 1.4)), .018 + .02 * ax) * sin(PI * ph);
    }
    float lx = .06 + (1 - c.hit) * L * .85;
    float launch = glow(length(float2(ax - lx, q.y * 1.3)), .025 + .03 * lx) * c.hit * c.hit * 2.5;

    // Radio lobes where the jets stall, with hot spots and glowing rims.
    float2 lc = q - float2(side * L, 0);
    float lt = fbm2(q * 2.3 + float2(-side * c.t * .04, c.t * .03), 4);
    float lobeShape = length(lc * float2(.8, 1.2)) - (.34 + .26 * lt);
    float strands = cosmRidge(lc * 3.4 + float2(c.t * .05, side * 2.3) + lt, 3) / .875;
    float lobe = (smoothstep(.1f, -.25f, lobeShape) * .85 + exp(-max(lobeShape, 0.f) * 4) * .15) * (.15 + .85 * pow(strands, 3.f));
    float lobeRim = glow(lobeShape, .012) * (.2 + .8 * lt);
    float hotspot = glow(length(lc + float2(side * .12, 0)), .04);

    float sheathW = .12 + .22 * ax / L;
    float sheath = exp(-q.y * q.y / (sheathW * sheathW)) * reach;
    float backflow = noise2(float2(ax * 4 + c.t * .5, q.y * 9));
    float cocoon = sheath * (.3 + .7 * backflow) * (.2 + 1.3 * c.b.y);

    float rp = length(p);
    float hostGlow = exp(-length(rot(p, .4) * float2(1, 1.6)) * 2.2);
    float haze = fbm2(p * 1.1 + float2(c.t * .01, 3), 4);

    float3 col = paint(.02 + haze * .2, f) * (.05 + .14 * haze * haze);
    col += paint(.3 + .5 * strands, f) * lobe * (.3 + 1.6 * c.b.x) + paint(.85, f) * (lobeRim * .3 + hotspot) * (.5 + 1.2 * c.b.x);
    col += paint(.45, f) * cocoon;
    col += paint(.6, f) * jet * .8 + paint(.95, f) * spine * 1.2;
    col += paint(.8, f) * helix;
    col += paint(.95, f) * (knots * 1.2 + launch);
    col += paint(.5, f) * hostGlow * .22 + paint(.98, f) * (glow(rp, .022) * 3 + glow(rp, .1) * .25);
    col += paint(.9, f) * cosmStars(p * 10, .22, c.t) * .5;
    return col;
}
NATIVE_EFFECT(quasarJet)

// ---------------------------------------------------------------- 356 Ring Plane Run
float3 ringPlaneRun(Ctx c, constant NativeFrame &f) {
    float2 uv = rot(c.uv / c.size, .1 * sin(c.t * .07));
    // Low, gently tilted view across the ring plane; the planet lies far off to the upper left,
    // so the ringlets sweep diagonally as long, nearly parallel arcs.
    float den = max(1.1 - .32 * uv.y, .5f);
    float2 P = uv / den;
    const float2 C = float2(-9, 11);
    const float Rref = 14;
    float2 dp = P - C;
    float sway = .9 * sin(c.t * .045);              // the camera drifts slowly across the ringlets
    float rho = length(dp) + sway, phi = atan2(dp.y, dp.x);
    float flowArc = c.travel * 1.6 + c.t * .06;
    float arc = phi * Rref + flowArc;              // along-ring coordinate, streaming with travel

    // Two shepherd gaps, each with moonlets that scallop the ringlet edges downstream.
    float wake = 0, gapMask = 1, moonCover = 0;
    float3 moonBody = 0, moonHalo = 0;
    for (int g = 0; g < 2; ++g) {
        float rg = g == 0 ? 13.55 : 14.92;
        float drift = c.t * (g == 0 ? .11 : .08);
        float local = arc - drift;
        float idm = floor(local / 5 + .5);
        float ds = local - idm * 5;
        wake += .06 * sin(ds * 3) * exp(-max(ds, 0.f) * .35) * step(0.f, ds) * smoothstep(2.5f, 1.8f, ds)
              * exp(-(rho - rg) * (rho - rg) * 5);
        gapMask *= smoothstep(.05f, .13f, abs(rho - rg));
        float phiM = (idm * 5 + drift - flowArc) / Rref;
        float2 Pm = C + (rg - sway) * float2(cos(phiM), sin(phiM));
        float uyM = 1.1 * Pm.y / (1 + .32 * Pm.y);
        float denM = max(1.1 - .32 * uyM, .5f);
        float radM = .075 * denM;
        float2 nrm = (uv - float2(Pm.x * denM, uyM)) / radM;
        float dm = length(nrm);
        float body = fill(dm - 1, c.px / radM);
        float lit = clamp(.35 - nrm.x * .5 + nrm.y * .6, 0.f, 1.f) * sqrt(max(0.f, 1 - dm * dm));
        moonBody += paint(.55 + .4 * lit, f) * (.12 + 1.4 * lit) * body;
        moonHalo += paint(.9, f) * glow(max(dm - 1, 0.f) * radM, .015) * .6;
        moonCover = max(moonCover, body);
    }
    float rw = rho + wake;

    // Ringlets: faint fills edged by glowing lines; each band lights its own family of lines.
    float rr = rw * 5.5;
    float n = floor(rr), m = floor(rr + .5);
    float dens = hash11(n * 1.37 + 2.1);
    float present = smoothstep(.08f, .2f, dens) * gapMask;
    float lineDens = hash11(m * 2.31 + .7);
    float level = c.b[int(m - 4 * floor(m / 4))];
    float rim = glow(cosmContour(rr, c.px) / c.size, .003 + .003 * level) * smoothstep(.5f, .2f, fwidth(rr));
    float fineLines = glow(cosmContour(rr * 3 + dens, c.px) / c.size, .0016) * smoothstep(.35f, .12f, fwidth(rr * 3));
    float clumps = .3 + .7 * smoothstep(.2f, .8f, noise2(float2(arc * .9, rw * 7)));

    // Attacks drive a spiral density wave outward across the plane.
    float rhoF = 11.5 + (1 - c.hit) * 5.5;
    float packet = exp(-(rho - rhoF) * (rho - rhoF) / .1) * c.hit;
    float ripple = .5 + .5 * sin((rho - rhoF) * 32 - arc * .3);
    float waveBoost = 1 + 2.6 * packet * ripple;

    float2 gq = float2(arc, rw) * 2.5, gid = floor(gq);
    float2 gl = fract(gq) - .5 - (hash22(gid + 1.3) - .5) * .5;
    float grains = step(.55, hash21(gid + 4.2)) * exp(-dot(gl, gl) * 160) * (.5 + .5 * sin(c.t * 3 + hash21(gid) * TAU))
                 * (.3 + 2.4 * c.b.w);
    float body = present * (.06 + .45 * dens * dens) * clumps * waveBoost;

    float3 col = paint(0, f) * .045;
    col += paint(.3 + .4 * dens, f) * body;
    col += paint(.55 + .35 * lineDens, f) * rim * gapMask * (.15 + .85 * lineDens * lineDens) * (.4 + 2 * level) * waveBoost * (.4 + .6 * clumps);
    col += paint(.7, f) * fineLines * present * (.2 + .5 * dens);
    col += paint(.95, f) * (grains * present + packet * ripple * .3);
    col = mix(col, moonBody, moonCover) + moonHalo;

    // Planetshine from the inner rings warms the side nearest the planet.
    col *= .7 + .5 * smoothstep(16.5f, 12.f, rho);
    col = mix(col, paint(.45, f) * .18 + col * .6, smoothstep(.95f, .55f, den) * .6);   // far side recedes into haze
    return col;
}
NATIVE_EFFECT(ringPlaneRun)

// ---------------------------------------------------------------- 357 Magnetosphere
float3 magnetosphere(Ctx c, constant NativeFrame &f) {
    float2 p = cosmLongAxis(c.uv / c.size, c.extent);
    float2 q = rot(p - float2(-.15, 0), .18 * sin(c.t * .08));
    const float Rp = .1;
    // Dayside compressed by the wind (harder on attacks), nightside stretched into a tail.
    float press = 1.45 + .4 * c.hit;
    float xd = q.x * mix(press, 1 / (1 + 1.25 * max(q.x, 0.f)), smoothstep(-.1f, .1f, q.x));
    float rd = length(float2(xd, q.y));
    float shellL = rd * rd * rd / max(xd * xd, 1e-6f);
    float lv = log2(shellL) * 2.4;
    float id = floor(lv + .5);
    float level = c.b[int(id - 4 * floor(id / 4))];
    float lat = atan2(q.y, abs(xd));
    float bounce = .55 + .45 * pow(.5 + .5 * sin(lat * 8 - c.t * 3 + id * 1.7), 3.f);
    float xm = -.62 + .7 * q.y * q.y;                       // magnetopause
    float inside = smoothstep(xm - .02, xm + .03, q.x) * smoothstep(Rp, Rp * 1.3, length(q));
    float fieldD = cosmContour(lv, c.px) / c.size;
    float crowd = smoothstep(.45f, .15f, fwidth(lv));      // fade lines where they bunch at the poles
    float field = (glow(fieldD, .0045 + .003 * level) * bounce * crowd + glow(fieldD, .025) * .15 * crowd + .08 * (1 - crowd))
                * inside * (.3 + 1.7 * level);

    // Solar wind streamlines bending around the bow shock.
    const float xb0 = -.86;
    float body = 2.6 * .08 * log(1 + exp((q.x - xb0) / .08));
    float y2 = q.y * q.y;
    float eta = sign(q.y) * sqrt(max(y2 - body, 0.f));
    float outside = smoothstep(0.f, .02f, y2 - body);
    float wv = eta * 9;
    float windD = cosmContour(wv, c.px) / c.size;
    float dash = pow(.5 + .5 * sin(q.x * 12 - c.t * 4 + hash11(floor(wv + .5)) * TAU), 6.f);
    float wind = (glow(windD, .003) * (.25 + dash * (.5 + 2.2 * c.b.w))) * outside * smoothstep(.45f, .15f, fwidth(wv));
    float sheathMask = (1 - outside) * (1 - inside) * smoothstep(Rp, Rp * 1.3, length(q));
    float sheath = fbm2(q * 4 + float2(-c.t * .3, 0), 3) * sheathMask;
    float bowD = abs(q.x - xb0 - y2 / 2.6) / sqrt(1 + (2 * q.y / 2.6) * (2 * q.y / 2.6));
    float mpD = abs(q.x - xm) / sqrt(1 + (1.4 * q.y) * (1.4 * q.y));

    // Attacks fire an interplanetary shock front across the scene.
    float xf = -2.8 + (1 - c.hit) * 5.4;
    float shock = glow(q.x - xf - .25 * y2, .02) * c.hit * c.hit * 1.8;

    float2 pole = float2(0, Rp * .9);
    float aurora = glow(abs(length((q - pole) * float2(1, 3.2)) - .045), .006) + glow(abs(length((q + pole) * float2(1, 3.2)) - .045), .006);

    float pr = length(q) / Rp;
    float disc = fill(pr - 1, c.px / Rp);
    float2 nrm = q / Rp;
    float day = clamp(-nrm.x * .9 + .25, 0.f, 1.f) * sqrt(max(0.f, 1 - pr * pr));

    float haze = fbm2(p * 1.4 + float2(-c.t * .04, 0), 3);
    float3 col = paint(.02 + haze * .2, f) * (.05 + .12 * haze * haze);
    col += paint(.35, f) * sheath * .55;
    col += paint(.25 + .1 * id, f) * field * .9 + paint(.15, f) * wind;
    col += paint(.8, f) * (glow(bowD, .006) * .9 + glow(bowD, .05) * .2) + paint(.6, f) * glow(mpD, .005) * inside * .4;
    col += paint(.92, f) * shock + paint(.95, f) * aurora * (.3 + 2 * c.b.z);
    col = mix(col, paint(.55 + .3 * day, f) * (.12 + 1.3 * day), disc) + paint(.9, f) * glow(max(pr - 1, 0.f) * Rp, .012) * .7;
    col += paint(.9, f) * cosmStars(p * 9, .2, c.t) * .4;
    return col;
}
NATIVE_EFFECT(magnetosphere)

// ---------------------------------------------------------------- 358 Cosmic Web
struct CosmCells { float d1; float d3; float edge; float2 a; float2 b; };
CosmCells cosmCells(float2 p, float phase) {
    float2 cell = floor(p), fp = fract(p);
    float d1 = 8, d2 = 8, d3 = 8; float2 a = 0, b = 0, sa = 0, sb = 0;
    for (int y = -1; y <= 1; ++y) for (int x = -1; x <= 1; ++x) {
        float2 g = float2(x, y), id = cell + g, h = hash22(id);
        float2 site = g + .5 + .4 * sin(phase * (.4 + .3 * h) + h * TAU);
        float d = length(site - fp);
        if (d < d1) { d3 = d2; d2 = d1; b = a; sb = sa; d1 = d; a = id; sa = site; }
        else if (d < d2) { d3 = d2; d2 = d; b = id; sb = site; }
        else if (d < d3) d3 = d;
    }
    CosmCells k;
    k.d1 = d1; k.d3 = d3; k.a = a; k.b = b;
    k.edge = abs(dot(fp - .5 * (sa + sb), normalize(sb - sa + 1e-5)));
    return k;
}

float3 cosmicWeb(Ctx c, constant NativeFrame &f) {
    float haze = fbm2(c.uv * .8 + float2(c.t * .01, 0), 3);
    float3 col = paint(.02 + haze * .2, f) * (.04 + .12 * haze * haze);
    for (int k = 0; k < 6; ++k) {
        float2 s = layerSlot(k, 6, c.travel * .09);
        float sc = layerScale(s.x, 2.4) / c.size;
        float2 q = rot(c.uv * sc, s.y * 1.1) + hash22(float2(s.y, 7.3)) * 40;
        q += (float2(noise2(q * .5), noise2(q * .5 + 9.1)) - .5) * .7;
        CosmCells v = cosmCells(q, c.t * .25 + s.y);
        float edge = v.edge / sc, node = (v.d3 - v.d1) / sc;
        float pair = hash21(v.a + v.b);
        int band = int(pair * 3.999);
        float level = c.b[band];
        float strength = fract(pair * 7.3);                 // some filaments thick and bright, some faint
        float fade = layerFade(s.x) * (.3 + .7 * s.x) * (1 - c.fog * .5 * (1 - s.x));
        float beads = .5 + .5 * noise2(q * 3.5 + s.y);
        float pulseAlong = .6 + .4 * sin(v.d1 * 9 - c.t * 2 + hash21(v.a) * TAU);
        float wide = (.0015 + .004 * s.x) * (.6 + strength);
        float fil = (glow(edge, wide * (1 + 1.2 * level)) * (.3 + 2 * level) * beads * pulseAlong
                   + glow(edge, .03 * (.4 + s.x)) * .1) * (.3 + .9 * strength);
        float lightUp = step(.45, hash21(v.a + 3.3));
        float flare = 1 + 3.5 * c.hit * lightUp;
        float hub = glow(node, .007 + .014 * s.x) * (.7 * flare) + glow(node, .06 * (.4 + s.x)) * .22 * flare;
        col += (paint(.25 + s.y * .11 + float(band) * .1, f) * fil + paint(.75, f) * hub) * fade;
    }
    return col;
}
NATIVE_EFFECT(cosmicWeb)

// ---------------------------------------------------------------- 359 Einstein Ring
float3 cosmGalaxySource(float2 d, float spin, float hue, constant NativeFrame &f) {
    float r = length(d);
    float phi = atan2(d.y, d.x) - 2.6 * log(r + .02);
    float arms = pow(.5 + .5 * cos(2 * phi - spin), 5.f);
    float body = exp(-r * 6) * (.15 + .85 * arms) * 1.4 + exp(-r * r * 300) * 1.8;
    return paint(hue + .3 * exp(-r * 6), f) * body;
}

float3 einsteinRing(Ctx c, constant NativeFrame &f) {
    float2 th = c.uv / c.size;
    float r = max(length(th), 1e-3f);
    // Point lens plus a slowly turning external shear; mass breathes with the bass.
    float thetaE = .56 * (1 + .3 * c.b.x);
    float2 beta = th - thetaE * thetaE * th / (r * r);
    float sa = c.t * .03;
    float2 sh = float2(cos(2 * sa), sin(2 * sa)) * .1;
    beta -= float2(sh.x * th.x + sh.y * th.y, sh.y * th.x - sh.x * th.y);
    float centre = smoothstep(.06f, .22f, r);

    float bg = fbm2(beta * 1.6 + float2(3, c.t * .01), 4);
    float3 col = paint(1 - bg * .15, f) * (.035 + .05 * bg * bg) * centre;
    col += paint(.1 + bg * .8, f) * pow(smoothstep(.4f, .9f, bg), 2.f) * .25 * centre;
    for (int j = 0; j < 5; ++j) {
        float fj = float(j);
        float2 home = float2(cos(fj * 2.4 + 1), sin(fj * 2.4 + 1)) * (.1 + .36 * fract(fj * .618 + .2));
        float2 sp = rot(home, c.t * (.04 + .015 * fj) * (j % 2 == 0 ? 1 : -1));
        float2 d = rot(beta - sp, fj * 1.3 + c.t * .1);
        d.y /= .6;
        float level = c.b[j % 4];
        col += cosmGalaxySource(d * (1.1 + fj * .12), c.t * .3 + fj, .05 + fj * .22, f) * (.4 + 1.9 * level) * centre;
    }
    // Attacks slide a bright new source behind the lens: a ring forms, then breaks into arcs.
    float2 sh2 = rot(float2(-.08 + (1 - c.hit) * .9, .04), c.t * .07);
    float flash = length(beta - sh2);
    col += paint(.75, f) * (glow(flash, .03) * 2 + glow(flash, .1) * .4) * c.hit * c.hit * centre;
    col += paint(.6, f) * cosmStars(beta * 9, .25, c.t) * .5 * centre;
    col += paint(.9, f) * glow(r, .05) * .3;
    return col;
}
NATIVE_EFFECT(einsteinRing)
