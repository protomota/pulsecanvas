
// Independently travelling reflections on existing scene surfaces. Their four
// spatial phases follow different frequency bands; attacks launch narrow wavefronts.
// Only material samples change: the camera and horizon remain in place.

// PulseCanvas native designs: driving scenes. Original procedural code; see NativeCommon.metal.
// Roads are pseudo-3D. A camera at eye height looks along a bending road: ground pixels get a
// depth from their distance below the horizon, vertical planes (rails, facades, cable planes)
// are solved per pixel, and roadside objects are projected from world-space instances whose
// ids stay stable as the travel distance grows, so nothing pops when a period wraps.

// ---------------------------------------------------------------- shared helpers
// Lateral offset of a road centre along world distance s, its slope and its curvature.


// Road centre at depth z, seen from a camera at s0 that looks along the road's tangent.

// The same with the camera's own bend and slope computed once per pixel.
struct DrvRoad { float4 k; float s0; float base; float slope; };


// Depth at which the ray through screen x meets the vertical plane at road-relative lateral x.
// Damped fixed-point iteration; returns -1 where it does not settle (far, near the vanishing
// point), so callers simply skip the plane there.

// Anti-aliased stripe of half width w around d = 0, given the pixel footprint aa.
float drvStripe(float d, float w, float aa) {
    aa = max(aa, 1e-5f);
    return (1 - smoothstep(w - aa, w + aa, abs(d))) * min(1.f, w / aa);
}
// Anti-aliased dashes centred on multiples of period; fades to the duty cycle when tiny.


// The band an element listens to, chosen by its integer id.

// Point stars: one candidate per cell, a soft dot about a pixel wide.

// Rear view of a car in metres, origin at the rear centre on the road.
// x = body coverage, y = tail lamps, z = rear glass.

// Skyline of towers along a horizon: x = silhouette coverage, y = lit window amount.


// ---------------------------------------------------------------- 134 Night Highway
// A divided highway at night: median lamp masts throw sodium pools, tail lights pull away
// and oncoming headlights rush past on the far carriageway, the skyline glows ahead.


// ---------------------------------------------------------------- 135 Neon Boulevard
// Neon facade at (along, height) on one side of the street. blur widens the tubes for
// reflections in the wet asphalt.


// ---------------------------------------------------------------- 136 Desert Interstate


// ---------------------------------------------------------------- 137 Mountain Switchbacks
// Serpentine road: straight rows across the slope joined by hairpins. Returns distance to
// the centreline, arc length along the road and a signed offset (positive = outer/downhill).


// Pine crown height above p on a jittered grid (2x2 neighbours, tallest wins).

// A chase view from above over hairpin bends cut into a forested slope at dusk. The camera
// swings with the car through each hairpin; mist pools in the valley below. Bass runs the
// rail reflectors in sequence, attacks flash the reflectors next to the car.


// ---------------------------------------------------------------- 138 Sodium Tunnel
// First depth where a camera ray (lateral/vertical slope per metre) leaves a tube whose
// centre follows the road bend: geometric march, then bisection.


// ---------------------------------------------------------------- 139 Coastal Cruise


// ---------------------------------------------------------------- 140 Long Exposure
// A hillside view of an S-shaped freeway at night as a long exposure: every lane is a
// continuous ribbon, warm one way and cool the other, with brighter car heads riding the
// front of each streak over the speckled city grid. Bass thickens the ribbons, highs add
// sparkles, attacks send a bright pulse down the fast lanes.


// ---------------------------------------------------------------- 141 Light Cycles
constant uint drvCyclePatterns[8] = {0x0Fu, 0x33u, 0x55u, 0x3Cu, 0x5Au, 0x66u, 0x69u, 0x96u};
// Lateral lane (in steps) of a bike at the start of cycle n: balanced 8-step blocks of
// right-angle jogs, so every position has a closed form.
float drvCycleX(float n, float seed) {
    float block = floor(n / 8);
    uint i = uint(n - block * 8);
    uint mask = drvCyclePatterns[uint(hash11(block * 7.3 + seed) * 7.99)];
    if (hash11(block * 3.7 + seed * 1.3) > .5) mask ^= 0xFFu;
    uint ones = popcount(mask & ((1u << i) - 1u));
    return float(2 * int(ones) - int(i));
}
float3 neonTrails(Ctx c, constant NativeFrame &f) {
    const float Lf = 9, M = 3.2, Lc = Lf + M, wallH = 1.1, lens = 1.5;
    float progress = c.travel * 9 + c.t * 3 + c.m * 8;
    float pl = progress - 7;
    float nl = floor(pl / Lc);
    float camX = M * mix(drvCycleX(nl, 0), drvCycleX(nl + 1, 0), smoothstep(.2f, 1.f, (pl - nl * Lc) / Lc));
    float3 ro = float3(camX, 5.4, progress * Lf / Lc - 12);
    float3 forward = normalize(float3(0, -.42, 1));
    float3 rd = cameraRay(c.uv, forward, float3(0, 1, 0), lens);
    float3 camU = normalize(cross(float3(0, 1, 0), forward)), camV = cross(forward, camU);
    float tFloor = rd.y < 0 ? ro.y / -rd.y : 1e5;
    float tTop = rd.y < 0 ? (ro.y - wallH) / -rd.y : 1e5;
    float3 G = ro + rd * tFloor;
    float3 T = ro + rd * tTop;
    float tBest = tFloor;
    float3 hitColor = 0;
    float3 floorGlow = 0, halo = 0;
    float width = .14 * c.size;
    // Ground footprint of the part of this ray that can see a wall, its glow or its halo.
    float tHalo = rd.y < 0 ? max(ro.y - wallH - 2.5, 0.f) / -rd.y : 0;
    float2 traceLo = min((ro + rd * tHalo).xz, G.xz) - 5, traceHi = max((ro + rd * tHalo).xz, G.xz) + 5;
    for (int b = 0; b < 5; ++b) {
        float fb = float(b);
        float home = (b == 0 ? 0 : (b % 2 == 1 ? -1 : 1) * (floor((fb + 1) * .5) * 3)) * M;
        float pb = progress * (1 + (b == 0 ? 0 : .03 * (fb - 2.5))) + (b == 0 ? 0 : fb * 7 - 4);
        float nb = floor(pb / Lc);
        float rb = pb - nb * Lc;
        float seed = fb * 13.1;
        float3 tone = paint(fb * .25, f);
        float boost = 1 + c.b[b % 4] * 1.6;
        for (int k = 0; k < 6 && rd.y < 0; ++k) {
            float n = nb - float(k);
            float xn = home + M * drvCycleX(n, seed), xn1 = home + M * drvCycleX(n + 1, seed);
            float z0 = n * Lf;
            float progStart = n * Lc;
            if (max(xn, xn1) < traceLo.x || min(xn, xn1) > traceHi.x || z0 + Lf < traceLo.y || z0 > traceHi.y) continue;
            for (int part = 0; part < 2; ++part) {
                float2 a, bb;
                float len;
                if (part == 0) {
                    float reach = k == 0 ? min(rb, Lf) : Lf;
                    a = float2(xn, z0); bb = float2(xn, z0 + reach); len = reach;
                } else {
                    if (k == 0 && rb < Lf) continue;
                    float reach = k == 0 ? (rb - Lf) / M : 1;
                    a = float2(xn, z0 + Lf); bb = float2(mix(xn, xn1, reach), z0 + Lf); len = M * reach;
                }
                float startProg = progStart + (part == 0 ? 0 : Lf);
                // Floor glow from this wall.
                float2 ba = bb - a;
                float hG = clamp(dot(G.xz - a, ba) / max(dot(ba, ba), 1e-4f), 0.f, 1.f);
                float age = pb - (startProg + hG * len);
                float bright = exp(-max(age, 0.f) / 36) * (1 - smoothstep(3.6 * Lc, 5 * Lc, age)) * boost;
                float dG = length(G.xz - a - ba * hG);
                floorGlow += tone * bright * exp(-dG * 1.4) * .5;
                // Top face.
                float hT = clamp(dot(T.xz - a, ba) / max(dot(ba, ba), 1e-4f), 0.f, 1.f);
                float dT = length(T.xz - a - ba * hT);
                float ageT = pb - (startProg + hT * len);
                float brightT = exp(-max(ageT, 0.f) / 36) * (1 - smoothstep(3.6 * Lc, 5 * Lc, ageT)) * boost;
                if (dT < width && tTop < tBest) { tBest = tTop; hitColor = tone * brightT * 2.2 + paint(.95, f) * brightT * .6; }
                // Side face (vertical plane).
                float denom = part == 0 ? rd.x : rd.z;
                float tPlane = abs(denom) > 1e-5 ? (part == 0 ? (a.x - ro.x) / denom : (a.y - ro.z) / denom) : -1.f;
                if (tPlane > 0) {
                    float3 P = ro + rd * tPlane;
                    float along = part == 0 ? P.z : P.x;
                    float lo = part == 0 ? min(a.y, bb.y) : min(a.x, bb.x), hi = part == 0 ? max(a.y, bb.y) : max(a.x, bb.x);
                    float h = P.y / wallH;
                    float ageP = pb - (startProg + (part == 0 ? P.z - a.y : abs(P.x - a.x)));
                    float brightP = exp(-max(ageP, 0.f) / 36) * (1 - smoothstep(3.6 * Lc, 5 * Lc, ageP)) * boost;
                    if (along > lo && along < hi && h > 0 && h < 1 && tPlane < tBest) {
                        tBest = tPlane;
                        hitColor = tone * brightP * (.35 + 1.3 * pow(h, 3.f)) + paint(.95, f) * brightP * smoothstep(.9f, 1.f, h) * .8;
                    }
                    float out = length(float2(max(max(lo - along, along - hi), 0.f), max(max(-h, h - 1), 0.f) * wallH));
                    halo += tone * brightP * exp(-out * 2.2) * .12 * step(hi - lo, 1e3);
                }
            }
        }
        // Bike head glow.
        float xh = home + M * mix(drvCycleX(nb, seed), drvCycleX(nb + 1, seed), saturate((rb - Lf) / M));
        float3 headP = float3(xh, .6, nb * Lf + min(rb, Lf));
        float3 v = headP - ro;
        float zc = dot(v, forward);
        if (zc > .5) {
            float2 sp = lens * float2(dot(v, camU), dot(v, camV)) / zc;
            float r = length(c.uv - sp);
            halo += tone * (glow(r, .5 / zc) * 2 + exp(-r * zc * 1.2) * .5) * boost;
            if (b == 0) halo += paint(.95, f) * c.hit * (exp(-abs(length(G.xz - headP.xz) - c.hit * 6) * 2) * .8 + glow(r, 1.5 / zc) * 1.5);
        }
    }
    float3 color;
    if (tBest < tFloor - 1e-3) color = hitColor;
    else if (rd.y < 0) {
        float fp = c.px * tFloor / lens / max(-rd.y, .15f);
        float2 cell = abs(fract(G.xz / 4 + .5) - .5) * 4;
        float grid = max(drvStripe(cell.x, .03, fp), drvStripe(cell.y, .03, fp));
        color = deep(.92, f) * .05 + paint(.05, f) * grid * .22 + floorGlow;
    } else color = 0;
    float fogK = exp(-min(tBest, tFloor) * (.008 + c.fog * .02));
    float3 sky = deep(.95, f) * .12 + paint(.55, f) * .25 * exp(-abs(rd.y) * 14) + paint(.85, f) * .03 * step(.5, fract(rd.y * 60));
    color = mix(sky, color, rd.y < 0 ? fogK : 0) + halo;
    return color;
}

// ---------------------------------------------------------------- 142 Rally Forest
// Chasing a rally car down a forest track: trunks whip past in parallax rows, sun shafts
// fall through the canopy and dust rolls back from the car. Bass kicks up the dust plume,
// highs glitter in the shafts, attacks throw mud from the rear wheels.


// ---------------------------------------------------------------- 143 Bridge Run
// Crossing a long suspension bridge at night: floodlit towers approach and pass, the main
// cables sweep down and up strung with lights, suspenders flick past and the skyline glows
// across the river. Bass runs a wave along the cable lights, highs twinkle the skyline,
// attacks brighten the tower beacons.


// ---------------------------------------------------------------- 144 Coaster Loop
// Track centreline at u from the sines/cosines of its four base phases (u * freq + phase),
// with a vertical loop and a corkscrew in every 330 m of layout. twist is the rails' extra
// roll through the corkscrew; bank is the gentle lean into turns.
constant float4 drvCoasterFreq = float4(.037, .089, .05, .12);
constant float4 drvCoasterPhase = float4(0, 1.3, .4, 2.1);

// The second track weaves around the first's base path, crossing above and below it.


// A projected track sample: screen centre, screen offset to the right rail, depth, position.
struct DrvRail { float2 c; float2 o; float z; float u; };

// One span of twin rails, a quadratic from m0 to m1 bending toward the sample k between them
// (corner cutting keeps the curve smooth), drawn in three pieces with perspective width, a
// glossy top highlight and a glow halo.

// A night ride on a light-show coaster: glossy twin rails outlined in palette light sweep
// far ahead as the track climbs, loops and corkscrews, while a second track weaves around
// it with its own lit train. Slim dark towers and crossties streak past and a park
// glitters far below. The camera banks gently over a level horizon. Bass chases the rail
// lights, highs sparkle them, attacks send surges of light racing along the rails.


// ---------------------------------------------------------------- 145 Hover Lanes


// ---------------------------------------------------------------- 146 Bullet Train
// A golden-hour ride on a high-speed line, seen through the side window: a graded sky with
// a low sun, hills in aerial perspective, saturated field patches, a highway whose car
// lights streak by, lit farm windows and dark hedges and catenary poles whipping past in
// the foreground. Bass shakes the fields' colour bands, highs flash the distant lights,
// attacks sweep a tunnel portal's shadow across the near field.


// ---------------------------------------------------------------- 147 Apex Chase


// ---------------------------------------------------------------- 148 Snow Drive


// ---------------------------------------------------------------- 149 Dashboard Glow
constant int drvDigitMasks[10] = {0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F};

// One round gauge: arcs, ticks, needle. value in 0..1; redline lights the last 15% of the sweep.

// The night road through the windshield, out of focus.

// Car interior at night: two glowing dials with a digital readout, the steering wheel in
// silhouette and the road ahead out of focus. Needles drift on their own and follow the
// bands with Chaos; attacks light the tachometer's rev-limit arc.


// ---------------------------------------------------------------- 150 Midnight Skyline


#define DRIVE_EFFECTS(X)        X(neonTrails)
DRIVE_EFFECTS(NATIVE_EFFECT)
