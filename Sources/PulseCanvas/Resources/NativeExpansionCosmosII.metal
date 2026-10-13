// Second versions of designs whose original and final review clips were both red-tagged.
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
// Level of band i (0...3) for a data-dependent index, without dynamic vector indexing.
float cosmBand(float4 bands, float i) {
    return dot(bands, saturate(1 - abs(float4(0, 1, 2, 3) - i)));
}
// Raised cosine in [0, 1], clamped so pow() never sees a rounding-negative base.
float cosmWave(float x) { return saturate(.5f + .5f * cos(x)); }
// A fixed oblique rotation, so value-noise lattice planes never line up with polar axes.
float3 cosmTilt(float3 p) {
    return float3(.80f * p.x + .36f * p.y + .48f * p.z, -.48f * p.x + .80f * p.y + .36f * p.z, -.36f * p.x - .48f * p.y + .80f * p.z);
}
// Sharp crest of a ridge value (1 on the crest), widened where it would fall below a pixel.
float cosmCrest(float ridge, float sharpness) {
    float k = min(sharpness, .8f / max(fwidth(ridge), 1e-4f));
    return exp(-k * (1 - ridge)) * sqrt(k / sharpness);
}
// Lay a two-body composition along the canvas's long axis.
float2 cosmLongAxis(float2 p, float2 extent) {
    return extent.y > extent.x ? float2(p.y, -p.x) : p;
}


// ---------------------------------------------------------------- 351 Twin Suns
// A glowing star: saturated limb-darkened body with a soft edge, a neon rim, corona and rays.
float4 cosmSun(float2 d, float radius, float spin, float hue, float corona, constant NativeFrame &f) {
    float r = length(d) / radius;
    float mu = sqrt(max(0.f, 1 - r * r));
    float2 sp = rot(d / radius, spin);
    float cells = noise2(sp * 5 + 3.3) * .6 + noise2(sp * 11 + 8.1) * .4;
    float3 surface = paint(hue + .22 * mu + .1 * cells, f) * (.3 + .55 * mu * (.6 + .6 * cells))
                   + paint(.92, f) * pow(mu, 8.f) * .45;
    float disc = 1 - smoothstep(.9f, 1.02f, r);
    float a = atan2(d.y, d.x) + spin * .3;
    float outer = max(r - 1, 0.f);
    float rays = pow(cosmWave(a * 14 + 2 * sin(a * 5 + spin * 2)), 8.f) * exp(-outer * (3.2 - corona * 1.6));
    float halo = glow(outer, .2 + corona * .35) * (.22 + corona * .8);
    float rim = glow(r - .98, .035) * .9 + glow(r - .98, .012);
    float3 col = surface * disc + paint(hue + .3, f) * rim * (.5 + .8 * corona)
               + paint(hue + .1, f) * (halo + rays * (.2 + corona * 1.2)) * (1 - disc);
    return float4(col, disc);
}

float3 twinSunsII(Ctx c, constant NativeFrame &f) {
    float2 p = cosmLongAxis(c.uv / c.size, c.extent);
    float phase = c.t * .3;
    // The heavy primary rides close to the canvas centre while the companion swings wide along
    // the long axis, so the forward-zoom echo of the primary reads as its own corona.
    float span = clamp(max(c.extent.x, c.extent.y) / c.size, 1.f, 1.8f);
    float2 orbit = float2(cos(phase) * (.62 + .35 * span), sin(phase) * .55);
    float2 s1 = -orbit * .2, s2 = orbit * .8;
    const float r1 = .2, r2 = .075;

    // Circumbinary outflow: trailing arms of fine glowing threads that turn with the orbit.
    float rho = length(p), th = atan2(p.y, p.x);
    float spiral = 2 * (th - phase) + log(rho + .08) * 3.4;
    float arms = pow(cosmWave(spiral), 3.f);
    float tex = fbm2(p * 2.1 + float2(c.t * .02, -c.t * .013), 4);
    float threads = pow(cosmWave(spiral * 5 + tex * 5), 14.f);
    float reachArms = exp(-rho * .45);
    float3 col = deep(.2 + .25 * tex, f) * (.025 + .09 * tex * tex);
    col += paint(.12 + .3 * tex, f) * pow(cosmWave(spiral), 1.5f) * reachArms * (.05 + .16 * tex) * (.6 + 1.2 * c.b.y);
    col += paint(.35 + .4 * arms, f) * threads * arms * reachArms * (.3 + 1.6 * c.b.y);

    // Tidal streams pulled from the companion onto the primary, one strand per band.
    float2 dv = s1 - s2; float len = length(dv);
    float2 ax = dv / len, nv = float2(-ax.y, ax.x), rel = p - s2;
    float u = dot(rel, ax) / len, v = dot(rel, nv), uc = clamp(u, 0.f, 1.f);
    float ends = smoothstep(-.05f, .12f, u) * smoothstep(1.02f, .85f, u);
    for (int k = 0; k < 4; ++k) {
        float fk = float(k), level = c.b[k];
        float bend = ((.1 + .07 * fk) * len + .05 * sin(TAU * uc * 1.5 + c.t * .8 + fk * 1.7)) * sin(PI * uc) * (k % 2 == 0 ? 1.f : -.7f);
        float dist = abs(v - bend);
        float flow = pow(cosmWave(u * 18 - c.t * 2.4 + fk * 1.9 - PI * .5), 4.f);
        float strand = glow(dist, .006 + .008 * level) * (.3 + .7 * flow) + glow(dist, .035) * .12;
        col += paint(.25 + .17 * fk + .12 * flow, f) * strand * ends * (.3 + 1.9 * level);
    }

    // Attacks erupt a flare loop and an ejected blob from each star.
    float burst = c.hit * (.6 + .4 * c.hit) * 1.8;
    float3 flares = 0;
    for (int k = 0; k < 2; ++k) {
        float2 s = k == 0 ? s1 : s2; float radius = k == 0 ? r1 : r2;
        float fa = phase * (k == 0 ? 1.7 : -1.3) + float(k) * 2.4 + .8;
        float2 dir = float2(cos(fa), sin(fa));
        float2 site = s + dir * radius;
        float loopArc = abs(length(p - site) - radius * (.3 + 1.4 * c.hit));
        float outside = smoothstep(radius, radius * 1.05, length(p - s));
        float blob = glow(length(p - s - dir * radius * (1.15 + 3 * (1 - c.hit))), .04 + .06 * (1 - c.hit));
        flares += paint(.7, f) * (glow(loopArc, .008) * outside * 1.5 + blob) * burst;
    }

    // Stars, drawn back to front; they swap only at full separation, never while overlapping.
    float4 a = cosmSun(p - s1, r1, c.t * .2, .3, c.b.x, f);
    float4 b = cosmSun(p - s2, r2, -c.t * .3, .62, .35 + c.b.z, f);
    bool firstFront = sin(phase) > 0;
    float4 back = firstFront ? b : a, front = firstFront ? a : b;
    col = col * (1 - back.w) + back.rgb;
    col += flares;
    col = col * (1 - front.w) + front.rgb;
    col += paint(.8, f) * cosmStars(p * 9, .25, c.t) * .5;
    return col;
}
NATIVE_EFFECT(twinSunsII)

// ---------------------------------------------------------------- 352 Supernova Shell
float3 supernovaShellII(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float r = length(p);
    float2 dirv = p / max(r, 1e-4f);
    const float R = .64;
    float wob = noise2(dirv * 2.2 + 11.3) - .5;
    float Ro = R * (1 + .14 * wob), Ri = Ro * .78;
    float shell = (sqrt(max(Ro * Ro - r * r, 0.f)) - sqrt(max(Ri * Ri - r * r, 0.f))) / sqrt(Ro * Ro - Ri * Ri);

    // Rayleigh-Taylor fingers: ridges of a noise field stretched along the radius. They drift
    // outward in log radius, so the forward-zoom echo lines up with the fingers themselves.
    // The music clock drives the expansion, so energetic passages push the fingers out faster.
    float lr = log(max(r, .03f));
    float3 fq = float3(dirv * 6.5, lr * 1.25 - c.t * .05 - c.m * .45);
    float ridgeA = 1 - abs(2 * noise3(cosmTilt(fq)) - 1);
    float ridgeB = 1 - abs(2 * noise3(cosmTilt(fq * float3(1.8, 1.8, 1.5) + 7.3).zxy) - 1);
    float fingerA = cosmCrest(ridgeA, 16), fingerB = cosmCrest(ridgeB, 22);
    float bead = smoothstep(.62f, .9f, noise3(cosmTilt(fq * float3(1, 1, 5) + 2.1).yzx));
    float band = smoothstep(Ri * .35f, Ri, r) * smoothstep(Ro * 1.06f, Ro * .97f, r);
    float tip = smoothstep(Ri * .8f, Ro, r);

    // Hit: a fresh shock ring races out and lights the fingers it crosses.
    float Rh = R * (.08 + 1.35 * (1 - c.hit)) * (1 + .1 * wob);
    float shockBoost = 1 + 2.5 * c.hit * exp(-(r - Rh) * (r - Rh) / .008);
    float newRing = (glow(r - Rh, .012) * 2.2 + glow(r - Rh, .06) * .4) * c.hit;

    float inner = smoothstep(Ri, Ri * .25f, r);
    float wisp = fbm2(p * 3 + float2(c.t * .02, 1.3), 3);
    float Rs = R * (1.15 + .1 * (noise2(dirv * 3.1 + 2.2) - .5));
    float forward = glow(r - Rs, .006) * .9 + glow(r - Rs, .045) * .2;
    float outside = smoothstep(Rs * .98f, Rs * 1.1f, r);

    float haze = fbm2(p * .9 + float2(4.1, c.t * .01), 3);
    float3 col = deep(.9 + haze * .2, f) * (.05 + .12 * haze * haze);
    col += paint(.95 + .1 * haze, f) * smoothstep(.5f, .85f, haze) * .06 * outside;
    col += paint(.92, f) * shell * shell * .1;
    col += paint(mix(.8f, .6f, tip), f) * band * fingerA * (.38 + 2 * c.b.x) * shockBoost;
    col += paint(.06 + .12 * tip, f) * band * fingerB * (.24 + 2 * c.b.y) * shockBoost;
    col += paint(.5, f) * band * fingerA * bead * (.3 + 3 * c.b.w) * shockBoost;
    col += paint(1 - .1 * wisp, f) * inner * pow(wisp, 3.f) * (.4 + 1.8 * c.b.z);
    col += paint(.02, f) * forward;
    col += paint(.65, f) * newRing + paint(.5, f) * (glow(r, .02) * 1.4 + glow(r, .07) * .25);
    col += paint(.6, f) * cosmStars(p * 11, .2, c.t) * .4 * outside;
    return col;
}
NATIVE_EFFECT(supernovaShellII)

// ---------------------------------------------------------------- 353 Galaxy Collision
// Two-armed log spiral in its own (de-projected) plane: x = arm A, y = arm B (broad),
// z = arm A spine, w = arm B spine (thin glowing cores). Radius returned separately.
float4 cosmSpiral(float2 q, float spin, float wind, thread float &r) {
    r = max(length(q), 1e-3f);
    float c1 = cos(atan2(q.y, q.x) - wind * log(r) - spin);
    float a = max(c1, 0.f), b = max(-c1, 0.f);
    return float4(pow(a, 6.f), pow(b, 6.f), pow(a, 110.f), pow(b, 110.f));
}

float3 galaxyCollisionII(Ctx c, constant NativeFrame &f) {
    float2 p = cosmLongAxis(c.uv / c.size, c.extent);
    float orbit = c.t * .035;
    // A close pair near the centre: the forward-zoom echo lands on their own discs and tails.
    float2 c1 = rot(float2(-.36, .1), orbit), c2 = rot(float2(.4, -.1), orbit);
    float2 q1 = rot(p - c1, .5 + orbit); q1.y /= .6;
    float2 q2 = rot(p - c2, -.9 + orbit); q2.y /= .5;
    float r1, r2;
    float4 g1 = cosmSpiral(q1 * .8, c.t * .16, 2.3, r1), g2 = cosmSpiral(q2 * .9, -c.t * .13, -2.1, r2);
    float clumps = .45 + .55 * noise2(p * 9 + float2(c.t * .05, 0));

    float disc1 = exp(-r1 * 2.6), disc2 = exp(-r2 * 3);
    // Tidal tails: the outer arms keep going on the side facing away from the partner.
    float2 away1 = normalize(c1 - c2);
    float tailMask1 = smoothstep(-.2f, .5f, dot(normalize(p - c1 + 1e-4), away1)) * smoothstep(.25f, .6f, r1);
    float tailMask2 = smoothstep(-.2f, .5f, dot(normalize(p - c2 + 1e-4), -away1)) * smoothstep(.25f, .6f, r2);
    float tail1 = (g1.x * .6 + g1.z) * exp(-r1 * .75) * tailMask1;
    float tail2 = (g2.y * .6 + g2.w) * exp(-r2 * .8) * tailMask2;

    // A bridge of stars stretched between the pair.
    float2 dv = c2 - c1; float len = length(dv);
    float2 ax = dv / len, rel = p - c1;
    float u = dot(rel, ax) / len, v = dot(rel, float2(-ax.y, ax.x));
    float bridgeDist = abs(v - .16 * len * sin(PI * clamp(u, 0.f, 1.f)));
    float bridge = (glow(bridgeDist, .025) + glow(bridgeDist, .005)) * smoothstep(-.05f, .2f, u) * smoothstep(1.05f, .8f, u);

    float armA = (g1.x * .35 + g1.z * 2.1) * disc1, armB = (g1.y * .35 + g1.w * 2.1) * disc1;
    float armC = ((g2.x + g2.y) * .35 + (g2.z + g2.w) * 2.1) * disc2;
    float tails = tail1 + tail2 + bridge * .5;

    // Starburst knots sit on the arms; attacks blossom them with an expanding ring.
    float2 kq = p * 7, kid = floor(kq), kl = (fract(kq) - .5 - (hash22(kid + 2.7) - .5) * .6) / 7;
    float kd = length(kl);
    float knotOn = step(.6, hash21(kid + 6.1));
    float host = min(1.f, (armA + armB + armC) * 2 + tails * 2);
    float knot = knotOn * host * (glow(kd, .006 + .014 * c.hit) * (.6 + 5 * c.hit)
                                + glow(kd - (.02 + .08 * (1 - c.hit)), .005) * c.hit * 3 * smoothstep(.5f, .9f, host));

    float3 col = paint(0, f) * .05 + paint(.2, f) * exp(-min(length(p - c1), length(p - c2)) * 1.3) * .08;
    col += paint(.75, f) * armA * clumps * (.5 + 2.4 * c.b.x);
    col += paint(.55, f) * armB * clumps * (.5 + 2.4 * c.b.y);
    col += paint(.3, f) * armC * clumps * (.55 + 2.4 * c.b.z);
    col += paint(.45 + .25 * clumps, f) * tails * clumps * (.45 + 2.2 * c.b.w);
    col += paint(.3, f) * (disc1 + disc2) * .1;
    col += paint(.8, f) * (exp(-r1 * r1 * 90) * 1.8 + exp(-r2 * r2 * 110) * 1.6);
    col += paint(.78, f) * knot;
    col += paint(.7, f) * cosmStars(p * 10, .25, c.t) * .5;
    return col;
}
NATIVE_EFFECT(galaxyCollisionII)

// ---------------------------------------------------------------- 354 Solar Prominence
float3 solarProminenceII(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    const float Rs = 2.2;
    // The limb crosses just below the canvas centre, so the forward-zoom echo of the limb
    // stays on the limb instead of drawing a second horizon.
    float2 C = float2(0, -.1 - Rs);
    float2 d = p - C; float rr = length(d);
    float h = rr - Rs;                         // height above the limb
    float s = atan2(d.x, d.y) * Rs;            // arc length along the limb
    float above = smoothstep(-.004f, .02f, h);

    // Granulated surface, foreshortened toward the limb.
    float mu = sqrt(max(0.f, 1 - (rr / Rs) * (rr / Rs)));
    float2 gq = float2(s, acos(clamp(rr / Rs, 0.f, 1.f)) * Rs) * 9;
    float4 cell = voronoi(gq + float2(c.t * .05, 0), .9, c.t * .6);
    float granule = exp(-cell.x * cell.x * 4.5) * smoothstep(0.f, .14f, cell.y - cell.x);
    float gran = mix(.55f, granule, smoothstep(0.f, .3f, mu));
    float plage = smoothstep(.55f, .8f, noise2(gq * .09 + 3.3)) * c.b.x;
    float sink = .3 + .7 * exp(max(-h, 0.f) * -2.2);          // the deep disc settles darker than the limb
    // Glowing granules in hot orange over crimson lanes: saturated at every brightness.
    float3 surface = (mix(paint(.04, f) * .3, paint(.2 + .32 * gran, f) * (.55 + .5 * mu), gran)
                   + paint(.75, f) * plage * gran * 1.1) * sink;
    float disc = 1 - above;

    float hp = max(h, 0.f);
    float streamer = pow(noise2(float2(s * 1.4, hp * .3 - c.t * .04)), 2.f);
    float corona = exp(-hp * 2.2) * (.3 + .9 * streamer) + exp(-hp * .45) * streamer * .3;
    float spicule = pow(noise2(float2(s * 45, c.t * .7)), 4.f) * 5 * exp(-hp / (.03 + .06 * c.b.w)) * above;
    float limb = glow(h, .012);
    float tall = 1 + .45 * max(c.extent.y - c.extent.x, 0.f);   // taller loops on portrait canvases
    // A faint arcade of nested field arches high in the corona.
    float sa = (floor(s / 1.1) + .5) * 1.1;
    float2 ea = float2((s - sa) / .55, hp / ((.8 + .2 * sin(sa * 3.1 + c.t * .1)) * tall));
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
        float H = (.26 + .3 * hash11(fk + 8.7)) * (.6 + 1.2 * level) * (1 + .08 * sin(c.t * .3 + fk)) * tall;
        float tilt = .5 * (hash11(fk + 1.9) - .5);
        float2 e = float2((s - sk - h * tilt) / w, h / H);
        float el = length(e), along = atan2(e.y, e.x), scale = min(w, H);
        float rope = 0;
        for (int j = 0; j < 3; ++j) {
            float off = .09 * sin(along * 5 + c.t * 1.1 + float(j) * 2.09 + fk);
            rope += glow((el - 1 - off) * scale, .005 + .003 * level);
        }
        float flow = pow(cosmWave(along * 7 - c.t * 2.2 + fk * 2 - PI * .5), 4.f);
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
    col += paint(.88, f) * cme * c.hit * (.5 + .5 * c.hit) * 2 * above;
    return col * .85;
}
NATIVE_EFFECT(solarProminenceII)

// ---------------------------------------------------------------- 355 Quasar Jet
float3 quasarJetII(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float ang = atan2(c.extent.y, c.extent.x) * .85 + .17 * sin(c.t * .09);
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
        float ph = fract(c.t * .075 + float(k) * .25 + (side > 0 ? 0.f : .125f));
        knots += glow(length(float2(ax - ph * L, q.y * 1.4)), .018 + .02 * ax) * sin(PI * ph);
    }
    float lx = .06 + (1 - c.hit) * L * .85;
    float launch = (glow(length(float2(ax - lx, q.y * 1.3)), .03 + .035 * lx) * 3 + glow(length(float2(ax - lx, q.y)), .15) * .4)
                 * c.hit * reach;

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
    float haze = fbm2(p * 1.1 + float2(c.t * .05, 3), 4);

    float3 col = paint(.02 + haze * .2, f) * (.05 + .14 * haze * haze);
    col += paint(.3 + .5 * strands, f) * lobe * (.3 + 1.6 * c.b.x) + paint(.85, f) * (lobeRim * .3 + hotspot) * (.5 + 1.2 * c.b.x);
    col += paint(.45, f) * cocoon;
    col += paint(.6, f) * jet * .8 + paint(.95, f) * spine * 1.2;
    col += paint(.8, f) * helix;
    col += paint(.95, f) * (knots * 1.2 + launch);
    col += paint(.5, f) * hostGlow * .22 + paint(.98, f) * (glow(rp, .022) * 3 + glow(rp, .1) * .25);
    col += paint(.9, f) * cosmStars(p * 10, .22, c.t) * .5;
    return col * .85;
}
NATIVE_EFFECT(quasarJetII)


// ---------------------------------------------------------------- 357 Magnetosphere
float3 magnetosphereII(Ctx c, constant NativeFrame &f) {
    float2 p = cosmLongAxis(c.uv / c.size, c.extent);
    // The planet sits at the canvas centre, where the forward-zoom echo of the dipole field
    // lands on the field itself.
    float2 q = rot(p, .25 * sin(c.t * .14));
    const float Rp = .12;
    // Dayside compressed by the wind (harder on attacks), nightside stretched into a tail.
    float press = 1.45 + .15 * sin(c.t * .3) + .4 * c.hit;
    float xd = q.x * mix(press, 1 / (1 + 1.25 * max(q.x, 0.f)), smoothstep(-.1f, .1f, q.x));
    float flap = .2 * sin(q.x * 2.2 - c.t * .8) * smoothstep(0.f, 1.5f, q.x);   // the tail flaps in the wind
    float rd = length(float2(xd, q.y + flap));
    float shellL = rd * rd * rd / max(xd * xd, 1e-6f);
    float lv = log2(shellL) * 2.4 - c.t * .22;            // field shells drift steadily outward
    float id = floor(lv + .5);
    float level = cosmBand(c.b, id - 4 * floor(id / 4));
    float lat = atan2(q.y, abs(xd));
    float bounce = .55 + .45 * pow(cosmWave(lat * 8 - c.t * 3 + id * 1.7 - PI * .5), 3.f);
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
    float dash = pow(cosmWave(q.x * 12 - c.t * 4 + hash11(floor(wv + .5)) * TAU - PI * .5), 6.f);
    float wind = (glow(windD, .003) * (.25 + dash * (.5 + 2.2 * c.b.w))) * outside * smoothstep(.45f, .15f, fwidth(wv));
    float sheathMask = (1 - outside) * (1 - inside) * smoothstep(Rp, Rp * 1.3, length(q));
    float sheath = fbm2(q * 4 + float2(-c.t * .3, 0), 3) * sheathMask;
    float bowD = abs(q.x - xb0 - y2 / 2.6) / sqrt(1 + (2 * q.y / 2.6) * (2 * q.y / 2.6));
    float mpD = abs(q.x - xm) / sqrt(1 + (1.4 * q.y) * (1.4 * q.y));

    // Attacks fire an interplanetary shock front across the scene.
    float xf = -2.8 + (1 - c.hit) * 5.4;
    float shockD = q.x - xf - .25 * y2;
    float shock = (glow(shockD, .02) * 2 + glow(shockD, .12) * .35 * step(shockD, 0.f)) * c.hit;

    float2 pole = float2(0, Rp * .9);
    float aurora = glow(abs(length((q - pole) * float2(1, 3.2)) - .045), .006) + glow(abs(length((q + pole) * float2(1, 3.2)) - .045), .006);

    float pr = length(q) / Rp;
    float disc = fill(pr - 1, c.px / Rp);
    float2 nrm = q / Rp;
    float day = clamp(-nrm.x * .9 + .25, 0.f, 1.f) * sqrt(max(0.f, 1 - pr * pr));

    float haze = fbm2(p * 1.4 + float2(-c.t * .12, 0), 3);
    float3 col = paint(.02 + haze * .2, f) * (.05 + .12 * haze * haze);
    col += paint(.35, f) * sheath * .55;
    col += paint(.25 + .1 * id, f) * field * .9 + paint(.15, f) * wind;
    col += paint(.8, f) * (glow(bowD, .006) * .9 + glow(bowD, .05) * .2) + paint(.6, f) * glow(mpD, .005) * inside * .4;
    col += paint(.92, f) * shock + paint(.95, f) * aurora * (.3 + 2 * c.b.z);
    float dayRim = glow((pr - 1) * Rp, .005) * clamp(.45 - nrm.x * .7, 0.f, 1.f);
    col = mix(col, deep(.1 + .2 * day, f) * .25 + paint(.4 + .3 * day, f) * day * .75, disc);
    col += paint(.75, f) * dayRim * 1.3 + paint(.5, f) * glow(max(pr - 1, 0.f) * Rp, .02) * .35;
    col += paint(.9, f) * cosmStars(p * 9, .2, c.t) * .4;
    return col;
}
NATIVE_EFFECT(magnetosphereII)

// ---------------------------------------------------------------- 358 Nebular Filaments
struct CosmCells { float d1; float d3; float edge; float2 a; float2 b; };
CosmCells cosmCells(float2 p, float phase) {
    float2 cell = floor(p), fp = fract(p);
    float d1 = 64, d2 = 64, d3 = 64; float2 a = 0, b = 0, sa = 0, sb = 0;
    float cosine, sine = sincos(phase, cosine);       // every site circles its cell at one rate
    for (int y = -1; y <= 1; ++y) for (int x = -1; x <= 1; ++x) {
        float2 g = float2(x, y), id = cell + g;
        uint seed = canvasSeed(canvasPair(id));        // one mix, split into two channels
        float2 o = float2(float(seed & 0xFFFFu), float(seed >> 16)) * (.6f / 65536.f) - .3f;
        float2 site = g + .5 + float2(o.x * cosine - o.y * sine, o.x * sine + o.y * cosine);
        float2 delta = site - fp;
        float d = dot(delta, delta);
        bool first = d < d1, second = d < d2;          // branch-free insertion keeps SIMD lanes together
        d3 = second ? d2 : min(d3, d);
        d2 = first ? d1 : (second ? d : d2);
        b = first ? a : (second ? id : b);
        sb = first ? sa : (second ? site : sb);
        d1 = first ? d : d1; a = first ? id : a; sa = first ? site : sa;
    }
    CosmCells k;
    k.d1 = sqrt(d1); k.d3 = sqrt(d3); k.a = a; k.b = b;
    k.edge = abs(dot(fp - .5 * (sa + sb), normalize(sb - sa + 1e-5)));
    return k;
}

float3 cosmicWebII(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float r = length(p);
    // A supercluster sits ahead: the web crowds toward it, brightens and feeds it great filaments.
    float well = exp(-r * 1.5), pull = 1 + 1.3 * exp(-r * 1.3);
    float haze = fbm2(c.uv * .8 + float2(c.t * .01, 0), 2);
    float3 col = paint(.02 + haze * .2, f) * (.03 + .1 * haze * haze) + paint(.45, f) * well * .08;
    float bend = atan2(p.y, p.x) + .35 * sin(r * 2.2 - c.t * .12);
    float spoke = glow(r * abs(sin(3 * bend)) / 3, .004 + .012 * r) * smoothstep(.05f, .25f, r) * exp(-r * .45);
    for (int k = 0; k < 4; ++k) {
        float2 s = layerSlot(k, 4, c.travel * .07);
        float sc = layerScale(s.x, 2) * pull;
        float2 q = rot(p * sc, s.y * 1.1) + hash22(float2(s.y, 7.3)) * 40;
        q += .32 * sin(q.yx * float2(.9, 1.1) + float2(s.y, s.y * 1.7 + 2));      // bend the filaments
        CosmCells v = cosmCells(q, c.t * .25 + s.y);
        float edge = v.edge / sc, node = (v.d3 - v.d1) / sc;
        float pair = hash21(v.a + v.b);
        float band = floor(pair * 3.999);
        float level = cosmBand(c.b, band);
        float strength = fract(pair * 7.3);                 // some filaments thick and bright, some faint
        float fade = layerFade(s.x) * (.3 + .7 * s.x) * (1 - c.fog * .5 * (1 - s.x)) * (.42 + .5 * well);
        float beads = .55 + .45 * sin(q.x * 6.3 + s.y) * sin(q.y * 5.7 - s.y);
        float pulseAlong = .6 + .4 * sin(v.d1 * 9 - c.t * 2 + hash21(v.a) * TAU);
        float wide = (.0015 + .004 * s.x) * (.6 + strength) * (1 + 1.5 * exp(-node * sc * 4));   // thicker near clusters
        float fil = (glow(edge, wide * (1 + 1.2 * level)) * (.4 + 2.2 * level) * beads * pulseAlong
                   + glow(edge, .03 * (.4 + s.x)) * .08) * (.3 + 1.1 * strength);
        float lightUp = step(.45, hash21(v.a + 3.3));
        float flare = 1 + 3.5 * c.hit * lightUp;
        float hub = glow(node, .009 + .018 * s.x) * flare + glow(node, .07 * (.4 + s.x)) * .28 * flare;
        col += (paint(.25 + s.y * .11 + band * .1, f) * fil + paint(.75, f) * hub) * fade;
    }
    col += paint(.6, f) * spoke * (.4 + 1.2 * c.b.x);
    col += paint(.78, f) * (glow(r, .03) * 1.2 + glow(r, .15) * .15) * (1 + 1.5 * c.hit);
    return col * .8;
}
NATIVE_EFFECT(cosmicWebII)

// ---------------------------------------------------------------- 359 Einstein Ring
float3 cosmGalaxySource(float2 d, float spin, float hue, constant NativeFrame &f) {
    float r = length(d);
    float phi = atan2(d.y, d.x) - 2.6 * log(r + .02);
    float arms = pow(cosmWave(2 * phi - spin), 5.f);
    float body = exp(-r * 6) * (.15 + .85 * arms) * 1.4 + exp(-r * r * 300) * 1.8;
    return paint(hue + .3 * exp(-r * 6), f) * body;
}

float3 einsteinRingII(Ctx c, constant NativeFrame &f) {
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
    float3 col = deep(.9 + bg * .2, f) * (.04 + .1 * bg * bg) * centre;
    col += paint(.1 + bg * .8, f) * pow(smoothstep(.45f, .9f, bg), 2.f) * .12 * centre;
    // A field of faint background galaxies, sheared into tangential arclets around the lens.
    float2 gq = beta * 3.2 + float2(7.1, 2.3);
    float2 gid = floor(gq);
    float3 gh = hash33(float3(gid, 4.7));
    float2 home = (gid + .5 - float2(7.1, 2.3)) / 3.2;          // each galaxy lies along its circle
    float2 go = rot(fract(gq) - .5 - (gh.xy - .5) * .45, -atan2(home.y, home.x) + (gh.z - .5) * .5) * float2(2.4, 1);
    float arclet = exp(-dot(go, go) * 55) * step(.3f, gh.x) * smoothstep(thetaE * .75f, thetaE * 1.05f, r);
    col += paint(gh.z > .5 ? .02 + .2 * gh.y : .74 + .22 * gh.y, f) * arclet * (.35 + 1.2 * c.b.w) * centre;
    // A compact source almost exactly behind the lens: its image is a crisp near-complete ring
    // on the Einstein radius, which swells and contracts with the lens mass.
    float2 b0 = .05 * float2(cos(c.t * .11), sin(c.t * .13));
    float d0 = length(beta - b0);
    col += paint(.02 + 2 * d0, f) * (exp(-d0 * d0 * 1400) * 2.2 + exp(-d0 * 12) * .35) * (.5 + 1.4 * c.b.x) * centre;
    for (int j = 0; j < 5; ++j) {
        float fj = float(j);
        float2 home = float2(cos(fj * 2.4 + 1), sin(fj * 2.4 + 1)) * (.1 + .36 * fract(fj * .618 + .2));
        float2 sp = rot(home, c.t * (.04 + .015 * fj) * (j % 2 == 0 ? 1 : -1));
        float2 d = rot(beta - sp, fj * 1.3 + c.t * .1);
        d.y /= .6;
        float level = c.b[j % 4];
        float hue = j % 2 == 0 ? .02 + fj * .04 : .72 + fj * .05;      // cool and hot sources alternate
        col += cosmGalaxySource(d * (1.5 + fj * .15), c.t * .3 + fj, hue, f) * (.6 + 2.8 * level) * centre;
    }
    // Attacks slide a bright new source behind the lens: a ring forms, then breaks into arcs.
    float2 sh2 = rot(float2(-.08 + (1 - c.hit) * .9, .04), c.t * .07);
    float flash = length(beta - sh2);
    col += paint(.75, f) * (glow(flash, .035) * 3 + glow(flash, .12) * .6) * c.hit * centre;
    col += paint(.6, f) * cosmStars(beta * 9, .25, c.t) * .5 * centre;
    col += paint(.9, f) * glow(r, .05) * .3;
    return col;
}
NATIVE_EFFECT(einsteinRingII)
