// Architecture, machinery and lattice designs. Original PulseCanvas procedural code.
// Every effect receives Ctx from NativeCommon.metal; audio terms are zero at zero Chaos.

float3 normalFrom(float3 p, float e, float d0, float dx, float dy, float dz) { return normalize(float3(dx - d0, dy - d0, dz - d0)); }

// ------------------------------------------------------------------ 32 Chrome Reef
// A flight through a labyrinth of chrome coral. A channel stays open around the camera;
// each coral branch swells with its band and attacks send ripples along the surfaces.
float2 reefPath(float z) { return float2(sin(z * .21) * 1.3, cos(z * .17) * .9); }
float reefField(float3 p, Ctx c) {
    float s = 1.6 / c.size;
    float3 q = p * s;
    float band = c.b[int(hash31(floor(q * .5)) * 3.99)];
    q += .25 * sin(q.yzx * .7 + c.t * .2 + c.m * .35);
    float gyroid = dot(sin(q), cos(q.yzx));
    float detail = dot(sin(q * 3.1 + c.t * .1), cos(q.zxy * 3.1)) * .12;
    float shell = abs(gyroid + detail) - (.28 + band * .22 + c.hit * .05 * sin(q.z * 4 - c.m * 6));
    float d = shell / (s * 2.2);
    float2 path = reefPath(p.z);
    return max(d, 1.1 - length(p.xy - path));
}
float3 chromeReef(Ctx c, constant NativeFrame &f) {
    float z = c.travel * 1.4;
    float3 ro = float3(reefPath(z), z);
    float3 ahead = float3(reefPath(z + 1.5), z + 1.5) - ro;
    float3 rd = cameraRay(c.uv, ahead, float3(sin(c.t * .07) * .3, 1, 0), 1.3);
    float travel = 0, steps = 0;
    bool hit = false;
    for (int i = 0; i < 96; ++i) {
        float d = reefField(ro + rd * travel, c);
        if (d < .0015 * (1 + travel)) { hit = true; break; }
        travel += d * .8;
        steps += 1;
        if (travel > 18) break;
    }
    float3 haze = deep(.25 + rd.y * .2, f) * .25 + paint(.6, f) * .05;
    if (!hit) return haze;
    float3 p = ro + rd * travel;
    float e = .003, d0 = reefField(p, c);
    float3 n = normalFrom(p, e, d0, reefField(p + float3(e, 0, 0), c), reefField(p + float3(0, e, 0), c), reefField(p + float3(0, 0, e), c));
    float3 r = reflect(rd, n);
    float occlusion = 1 - steps / 96;
    float3 environment = mix(deep(.15, f) * .3, paint(.35 + r.y * .35, f) * 1.3, smoothstep(-.3f, .5f, r.y));
    environment += paint(.95, f) * pow(max(dot(r, normalize(float3(.3, .8, .4))), 0.f), 18.f) * 2;
    environment += paint(.7, f) * pow(.5 + .5 * sin(r.x * 6 + r.z * 4 + c.t * .2), 12.f) * .5;
    float fresnel = .35 + .65 * pow(1 - max(dot(-rd, n), 0.f), 3.f);
    float polyps = pow(.5 + .5 * sin(p.x * 18) * sin(p.y * 18) * sin(p.z * 18), 10.f) * .25 * (1 + c.b.w);
    float3 color = environment * fresnel * (.35 + .65 * occlusion) + paint(.8, f) * polyps * occlusion;
    return mix(haze, color, exp(-travel * (.05 + c.fog * .12)));
}

// ------------------------------------------------------------------ 37 Ion Cathedral
// A flight down an endless gothic nave: pointed arches, ribbed vaults and columns, lit by
// ionised light that runs along the ribs. The music clock drives the light pulses; bass
// thickens the glow and attacks send a flash down the nave.

// Each bay of the nave listens to its own band.


// ------------------------------------------------------------------ 38 Velvet Circuit
// A low flight over a circuit board. Truchet routing keeps every copper trace connected,
// with 45-degree chamfers, vias and chips. Signal packets race along the traces on the
// music clock; each trace family brightens with its own band.


// ------------------------------------------------------------------ 39 Lunar Loom
// A moonlit jacquard tapestry billows gently. Real over-under threads carry a large
// woven motif of drifting crescents; individual threads shimmer on their bands, bass
// swells the cloth and attacks send a bright shuttle thread racing across.


// ------------------------------------------------------------------ 71 Gear Works
// Layers of meshing brass gear trains drift toward the viewer. Neighbouring gears counter-
// rotate with matched teeth; the music clock drives each train and gears glow with their
// bands. Alternate layers use larger gears for depth.


// ------------------------------------------------------------------ 72 Piston Hall
// Down the length of an engine hall: rows of cylinders whose pistons pump on a shared
// crankshaft. Bass lengthens each row's stroke, attacks fire the combustion glow, and
// the music clock raises engine speed.
float pistonField(float3 p, Ctx c, thread float &fire) {
    float3 q = p;
    float row = repeatId(q.z, 1.6);
    q.z -= row * 1.6;
    float side = sign(q.x);
    q.x = abs(q.x) - 1.5;
    float phase = row * 1.3 + (side > 0 ? PI : 0) + c.t * 2.2 + c.m * 2.5;
    float stroke = .45 + c.b.x * .8 + c.hit * .25;
    float lift = sin(phase) * stroke;
    float cylinder = max(length(q.xz) - .52, abs(q.y - .6) - .7);
    cylinder = max(cylinder, -(length(q.xz) - .44));
    float piston = max(length(q.xz) - .42, abs(q.y - (1.45 + lift)) - .28);
    piston = min(piston, max(length(q.xz) - .3, abs(q.y - (1.78 + lift)) - .05));
    float rod = sdCapsule(q, float3(0, 1.2 + lift, 0), float3(sin(phase) * .25, -.3, 0), .08);
    float block = sdBox(float3(q.x, q.y + 1, q.z), float3(.8, .35, .78));
    float floorPlane = p.y + 1.4;
    fire = (.5 + .5 * cos(phase)) * smoothstep(.35f, .0f, abs(q.y - 1.3)) * smoothstep(.6f, .2f, length(q.xz));
    return min(min(min(cylinder, piston), min(rod, block)), floorPlane);
}
float3 pistonHall(Ctx c, constant NativeFrame &f) {
    c.travel += c.m * f.camera.w * .5;
    float3 ro = float3(sin(c.t * .07) * .4, 3.1 + sin(c.t * .2) * .2, c.travel * 2);
    float3 rd = cameraRay(c.uv, float3(sin(c.t * .11) * .2, -.55, 1), float3(0, 1, 0), 1.3);
    float travel = 0, fire = 0, glow = 0;
    bool hit = false;
    for (int i = 0; i < 90; ++i) {
        float3 p = ro + rd * travel;
        float d = pistonField(p, c, fire);
        glow += fire * .02 * exp(-max(d, 0.f) * 6);
        if (d < .002) { hit = true; break; }
        travel += d * .8;
        if (travel > 35) break;
    }
    float3 color = deep(.3, f) * .08;
    if (hit) {
        float3 p = ro + rd * travel;
        float e = .003, dummy;
        float d0 = pistonField(p, c, fire);
        float3 n = normalFrom(p, e, d0, pistonField(p + float3(e, 0, 0), c, dummy), pistonField(p + float3(0, e, 0), c, dummy), pistonField(p + float3(0, 0, e), c, dummy));
        float3 r = reflect(rd, n);
        float3 light = normalize(float3(.4, .9, -.3));
        float diffuse = max(dot(n, light), 0.f);
        float specular = pow(max(dot(r, light), 0.f), 30.f);
        float stripes = pow(.5 + .5 * sin(atan2(r.x, r.z) * 6), 20.f) * smoothstep(0.f, .4f, r.y);
        float3 metal = paint(.35 + n.y * .2, f) * (.12 + diffuse * .7) + paint(.95, f) * (specular * 1.5 + stripes * .8);
        metal += paint(.7, f) * pow(max(r.y, 0.f), 3.f) * .4;
        metal += paint(.8, f) * fire * 1.5 * (1 + c.hit * 2);
        float wave = .5 + .5 * sin(p.z * 5 - c.t * 3 - c.m * 4);
        metal += paint(.35 + .18 * sin(p.x * 2), f) * (c.b[int(abs(p.z) * 2) % 4] * wave * .85 + c.hit * pow(wave, 5.f));
        color = metal;
    }
    color += paint(.8, f) * glow * (1.5 + c.hit * 1.5 + c.b.x * 1.5);
    return mix(color, deep(.3, f) * .15 + paint(.6, f) * .1, 1 - exp(-travel * (.03 + c.fog * .05)));
}

// ------------------------------------------------------------------ 73 Orrery Engine
// A colossal brass orrery seen from above, its hub off-canvas, so engraved orbits and
// planets sweep across the frame. Orbits repeat in scale for an endless zoom; each planet
// orbits on its own band and attacks light the engraved tracks.


// ------------------------------------------------------------------ 74 Space Frame
// A flight through a colossal octet space-frame of box beams, lit by moving spotlights.
// Nodes flare on their own bands and light pulses run along the beams with the music.
float beam(float2 q, float w) { float2 d = abs(q) - w; return length(max(d, 0.f)) + min(max(d.x, d.y), 0.f); }
float frameField(float3 p, Ctx c, thread float &node) {
    float cell = 3;
    float3 id = floor(p / cell + .5);
    float3 q = p - id * cell;
    float w = .07 * c.size;
    float d = min(min(beam(q.yz, w), beam(q.xz, w)), beam(q.xy, w));
    // Face diagonals in the xz and xy planes.
    float2 diagonal = float2((q.x + q.z) * .7071, (q.x - q.z) * .7071);
    d = min(d, beam(float2(min(abs(diagonal.x), abs(diagonal.y)), q.y), w * .7));
    float2 diagonal2 = float2((q.x + q.y) * .7071, (q.x - q.y) * .7071);
    d = min(d, beam(float2(min(abs(diagonal2.x), abs(diagonal2.y)), q.z), w * .7));
    float band = c.b[int(hash31(id) * 3.99)];
    node = length(q) - (.22 + band * .12) * c.size;
    return min(d, node);
}
float3 spaceFrame(Ctx c, constant NativeFrame &f) {
    float3 ro = float3(1.5 + sin(c.t * .1) * .3, .75 + cos(c.t * .08) * .2, c.travel * 2.4);
    float3 rd = cameraRay(c.uv, float3(sin(c.t * .07) * .3, sin(c.t * .05) * .2, 1), float3(sin(c.t * .04) * .3, 1, 0), 1.2);
    float travel = 0, node = 9, nodeGlow = 0;
    bool hit = false;
    for (int i = 0; i < 100; ++i) {
        float3 p = ro + rd * travel;
        float d = frameField(p, c, node);
        nodeGlow += exp(-max(node, 0.f) * 5) * .015;
        if (d < .002) { hit = true; break; }
        travel += d * .9;
        if (travel > 45) break;
    }
    float3 sky = deep(.3 + rd.y * .2, f) * .12 + paint(.75, f) * pow(max(dot(rd, normalize(float3(.5, .4, 1))), 0.f), 12.f) * .5;
    float3 color = sky;
    if (hit) {
        float3 p = ro + rd * travel;
        float e = .003, dummy, d0 = frameField(p, c, dummy);
        float3 n = normalFrom(p, e, d0, frameField(p + float3(e, 0, 0), c, dummy), frameField(p + float3(0, e, 0), c, dummy), frameField(p + float3(0, 0, e), c, dummy));
        float3 light = normalize(float3(.5, .4, 1));
        float diffuse = max(dot(n, light), 0.f);
        float specular = pow(max(dot(reflect(rd, n), light), 0.f), 24.f);
        float pulse = pow(.5 + .5 * sin(dot(p, float3(.3, .2, 1)) * 1.5 - c.t * 2 - c.m * 3), 10.f);
        color = paint(.3 + dot(p, float3(.01, .02, .015)), f) * (.05 + diffuse * .5) + paint(.95, f) * specular * .8;
        color += paint(.85, f) * pulse * .6 * (.3 + c.b.y * 1.5);
        color = mix(sky, color, exp(-travel * (.035 + c.fog * .05)));
    }
    return color + paint(.9, f) * nodeGlow * (1 + c.hit * 2);
}

// ------------------------------------------------------------------ 75 Brutalist Shift
// An isometric concrete megastructure under hard sunlight. Tower blocks slide up and
// down on slow schedules, each also rising with its own band; attacks pop window lights.


// ------------------------------------------------------------------ 76 Rose Window
// Colored light streams through a vast rose window into a dusty nave. The tracery turns
// slowly; panes brighten with their bands and attacks flare the light shafts.


// ------------------------------------------------------------------ 92 Atom Lattice
// A flight through a ball-and-stick crystal with two kinds of atoms. Each atom vibrates
// on its own band, bonds stretch with them, and attacks send a flash along the bonds.
float3 atomOffset(float3 id, Ctx c) {
    float3 seed = hash33(id);
    float band = c.b[int(seed.x * 3.99)];
    return sin(c.t * (1.3 + seed * 1.7) + c.m * 3 * seed + seed * TAU) * (.03 + band * .14);
}
float atomField(float3 p, Ctx c, thread float &kind, thread float &bond) {
    // Body-centred lattice: test the nearest corner atom, the nearest centre atom and
    // the single bond between them; farther primitives cannot be closer.
    float cell = 2;
    float3 cornerId = floor(p / cell + .5);
    float3 corner = cornerId * cell + atomOffset(cornerId, c);
    float3 centerId = floor(p / cell);
    float3 center = (centerId + .5) * cell + atomOffset(centerId + .5, c);
    float cornerRadius = (.36 + .08 * hash31(cornerId)) * c.size * .8;
    float cornerAtom = length(p - corner) - cornerRadius;
    float centerAtom = length(p - center) - .26 * c.size * .8;
    float3 octant = centerId + step(float3(.5), fract(p / cell));
    float3 bondCorner = octant * cell + atomOffset(octant, c);
    bond = sdCapsule(p, bondCorner, center, .06);
    kind = centerAtom < cornerAtom ? 1. : 0.;
    return min(min(cornerAtom, centerAtom), bond);
}
float3 atomLattice(Ctx c, constant NativeFrame &f) {
    float3 ro = float3(1 + sin(c.t * .11) * .2, cos(c.t * .09) * .2, c.travel * 2.2);
    float3 rd = cameraRay(c.uv, float3(sin(c.t * .06) * .4, cos(c.t * .05) * .3, 1), float3(0, 1, 0), 1.25);
    rd.xy = rot(rd.xy, c.t * .03);
    float travel = 0, kind = 0, bond = 9;
    bool hit = false;
    for (int i = 0; i < 90; ++i) {
        float d = atomField(ro + rd * travel, c, kind, bond);
        if (d < .002) { hit = true; break; }
        travel += d * .9;
        if (travel > 30) break;
    }
    float3 background = deep(.5, f) * .06;
    if (!hit) return background;
    float3 p = ro + rd * travel;
    float e = .003, k2, b2;
    float d0 = atomField(p, c, k2, b2);
    float3 n = normalFrom(p, e, d0, atomField(p + float3(e, 0, 0), c, k2, b2), atomField(p + float3(0, e, 0), c, k2, b2), atomField(p + float3(0, 0, e), c, k2, b2));
    float isBond = bond < .003 ? 1. : 0.;
    float3 light = normalize(float3(-.4, .7, -.5));
    float diffuse = max(dot(n, light), 0.f);
    float specular = pow(max(dot(reflect(rd, n), light), 0.f), 40.f);
    float rim = pow(1 - max(dot(-rd, n), 0.f), 3.f);
    float3 albedo = isBond > .5 ? paint(.5, f) * .5 : paint(kind > .5 ? .85 : .2 + hash31(floor(p / 2)) * .3, f);
    float flash = isBond * c.hit * pow(.5 + .5 * sin(p.z * 2 - c.m * 8), 8.f) * 2;
    float3 color = albedo * (.1 + diffuse * .8) + paint(.95, f) * (specular * .9 + flash) + paint(.7, f) * rim * .5;
    return mix(background, color, exp(-travel * (.04 + c.fog * .07)));
}

// ------------------------------------------------------------------ 98 Synth Horizon
// A neon grid racing toward a striped sun behind wireframe mountains. Bass rolls waves
// through the floor toward the viewer, highs light the sun's bands, attacks flash the grid.
float3 synthHorizon(Ctx c, constant NativeFrame &f) {
    float horizon = .08 * c.extent.y;
    float3 color = 0.f;
    if (c.uv.y > horizon) {
        float h = c.uv.y - horizon;
        color = mix(paint(.75, f) * .55, deep(.2, f) * .15, smoothstep(0.f, 1.2f, h));
        float2 sunCenter = float2(0, horizon + .42);
        float sunDistance = length(c.uv - sunCenter);
        float stripes = step(.5, fract((c.uv.y - sunCenter.y) * 14 - c.t * .3 + c.m * .2)) + step(0.f, c.uv.y - sunCenter.y + .05);
        float sun = (1 - smoothstep(.48f, .5f, sunDistance)) * min(stripes, 1.f);
        color = mix(color, mix(paint(.95, f), paint(.6, f), smoothstep(.4f, -.4f, c.uv.y - sunCenter.y)) * (1.3 + c.b.w * .8), sun);
        color += paint(.85, f) * exp(-sunDistance * 3) * .25;
        // Mountains.
        float ridge = horizon + .18 * fbm2(float2(c.uv.x * 1.6 + c.travel * .02, 1), 4) + .1 * abs(sin(c.uv.x * 2.3));
        float mountain = step(c.uv.y, ridge);
        float wire = exp(-abs(fract(c.uv.x * 12 + fbm2(float2(c.uv.x * 4, c.uv.y * 6), 2)) - .5) * 30) * .4 + exp(-abs(c.uv.y - ridge) * 120);
        color = mix(color, deep(.2, f) * .1 + paint(.8, f) * wire * .6, mountain);
        float stars = pow(hash21(floor(c.uv * 90)), 50.f) * smoothstep(.3f, .8f, h);
        color += paint(.9, f) * stars;
    } else {
        float depth = .5 / max(horizon - c.uv.y, 1e-3f);
        float2 floorUV = float2(c.uv.x * depth, depth + c.travel * 1.6 + c.t * .4);
        float wave = (c.b.x * .5 + c.hit * .3) * sin(floorUV.y * .8 - c.m * 4) * exp(-depth * .08);
        floorUV.x += wave * .4;
        float2 grid = abs(fract(floorUV * float2(1.2, 1) / c.size) - .5);
        float2 width = fwidth(floorUV * float2(1.2, 1) / c.size) * 1.2;
        float lines = max(1 - smoothstep(.0f, 1.f, grid.x / max(width.x, .02f)), 1 - smoothstep(.0f, 1.f, grid.y / max(width.y, .02f)));
        float glow = exp(-min(grid.x, grid.y) * 8) * .3;
        float fade = exp(-depth * .05);
        float ripple = c.hit * exp(-abs(fract(floorUV.y * .08 - c.m * .5) - .5) * 14);
        color = deep(.25, f) * .08 + paint(.65 + wave * .2, f) * (lines * (1.1 + ripple * 1.5) + glow) * fade;
        color += paint(.85, f) * exp(-(horizon - c.uv.y) * 12) * .5;
    }
    return color;
}

#define STRUCTURE_EFFECTS(X) X(chromeReef)     X(pistonHall)  X(spaceFrame)   X(atomLattice) X(synthHorizon)
STRUCTURE_EFFECTS(NATIVE_EFFECT)
