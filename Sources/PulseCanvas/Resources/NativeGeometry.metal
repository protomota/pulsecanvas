// Fractal, tessellation, kaleidoscope and optical designs. Original PulseCanvas code;
// classic forms (Mandelbulb power formula, Menger sponge, sphere inversion, Poincare disk)
// are implemented from their mathematical definitions. Audio terms are zero at zero Chaos.

float3 geometryNormal(float d0, float dx, float dy, float dz) { return normalize(float3(dx - d0, dy - d0, dz - d0) + 1e-6); }

// ------------------------------------------------------------------ 35 Glass Mosaic
// Three stained-glass screens at different depths drift toward the viewer, a moving light
// behind them. Light passes through every screen, so overlapping panes mix colors. Each
// pane brightens with its band; attacks flare the light.


// ------------------------------------------------------------------ 47 Opal Tessera
// An endless zoom into a triangular opal mosaic: each tile subdivides into four as the
// view deepens. Tiles tilt to catch the light, flashing play-of-color; bands tilt their
// own tiles further and attacks flash the facets.
float3 triangleTile(float2 p, thread float2 &id, thread float &edge) {
    float2 s = float2(p.x - p.y * .57735, p.y * 1.1547);
    float2 cell = floor(s), local = fract(s);
    float upper = step(1.f, local.x + local.y);
    id = cell * 2 + upper;
    float a = local.x, b = local.y, cc = 1 - a - b;
    edge = min(min(abs(a), abs(b)), abs(cc));
    edge = upper > .5 ? min(min(1 - a, 1 - b), abs(a + b - 1)) : edge;
    return float3(local, upper);
}
float3 opalLevel(float2 p, float level, Ctx c, constant NativeFrame &f, thread float &edgeOut) {
    float2 id; float edge;
    triangleTile(p, id, edge);
    edgeOut = edge;
    float seed = hash21(id + level * 31);
    float band = c.b[int(seed * 3.99)];
    float tilt = sin(c.t * (.3 + seed * .5) + seed * 20 + c.m * .8) * .6 + band * .8;
    float play = fbm2(p * 3 + id * .37 + tilt, 3);
    float3 film = filmColor(play * 1.5 + tilt * .4 + seed, f);
    float flash = pow(max(0.f, sin(play * 12 + tilt * 3)), 12.f) * (.5 + c.hit * 1.5);
    float milk = .35 + .65 * smoothstep(.0f, .15f, edge);
    return film * (.35 + .5 * smoothstep(-.4f, .8f, tilt)) * milk + paint(.95, f) * flash * .6;
}
float3 opalTessera(Ctx c, constant NativeFrame &f) {
    float3 color = 0.f;
    float edges = 0;
    for (int octave = 0; octave < 2; ++octave) {
        float2 z = octaveZoom(c.travel * .1, octave);
        float level = floor(c.travel * .1) + float(octave);
        float edge;
        float3 layer = opalLevel(c.uv * z.x * 1.8 / c.size, level, c, f, edge);
        color += layer * z.y;
        edges += (1 - smoothstep(.0f, .03f, edge)) * z.y;
    }
    return color * (1 - edges * .85) + paint(.7, f) * edges * .05;
}

// ------------------------------------------------------------------ 56 Laser Origami
// A Miura-folded paper landscape recedes to the horizon while palette lasers sweep across
// it; every beam bends over the folds. Bass deepens the folds, the music clock sweeps the
// lasers and attacks flash them.


// ------------------------------------------------------------------ 60 Mandel Bloom
// A Mandelbulb unfurls and folds through a continuously bending liquid domain. Bass
// twists its cross-sections, mids push waves through its lobes and attacks ripple veins.
// Continuous domain bending changes the actual folds, rather than only orbiting them.
// Integer power preserves the azimuth seam; rotating the domain preserves the poles.
float mandelField(float3 p, Ctx c, thread float4 &trap) {
    float phase = c.t * .72 + c.m * .60;
    float2 twist = rot(p.xz, sin(p.y * 1.5 + phase * .45) * (.16 + c.b.x * .28));
    float3 q = float3(twist.x, p.y, twist.y);
    float3 wave = sin(q.yzx * 1.9 + float3(phase, -phase * .83, phase * .71));
    float3 fine = sin(q.zxy * 3.6 + float3(-phase * 1.2, phase * .92, -phase * .76));
    float strength = .10 + c.b.y * .14 + c.hit * .09;
    q += wave * strength + fine * (.025 + c.b.z * .045);
    q /= float3(1 + .09 * sin(phase * .63), 1 + .11 * cos(phase * .51), 1 + .08 * sin(phase * .57 + 2));
    float3 z = q;
    float dr = 1, r = 0;
    const float power = 8;
    trap = float4(1e3);
    int iterations = 6 + int(c.detail * 3);
    for (int i = 0; i < iterations; ++i) {
        r = max(length(z), 1e-6f);
        if (r > 2) break;
        float theta = acos(clamp(z.z / r, -1.f, 1.f)) * power;
        float phi = atan2(z.y, z.x) * power;
        dr = pow(r, power - 1) * power * dr + 1;
        float zr = pow(r, power);
        z = zr * float3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta)) + q;
        trap = min(trap, float4(abs(z), dot(z, z)));
    }
    // Domain warping stretches distances; conservative steps keep thin folds intact.
    return .5 * log(r) * r / max(dr, 1e-6f) / 2.1;
}
float3 mandelBloom(Ctx c, constant NativeFrame &f) {
    float orbit = c.t * .04 + c.travel * .06;
    // The bulb stays inside radius ~1.3 for these powers; the camera orbits outside it.
    float distance = 1.75 + .2 * (.5 + .5 * sin(c.travel * .05 + c.t * .02));
    // Normalized, so the orbit keeps its full distance at every phase.
    float3 direction = normalize(float3(sin(orbit) * cos(orbit * .7), sin(orbit * .5) * .5, cos(orbit) * cos(orbit * .7)) + float3(0, 0, 1e-3));
    float3 ro = direction * distance;
    // Aim at a point on the far flank, so the surface fills most of the frame off-centre.
    float3 side = normalize(cross(direction, float3(0, 1, 0)) + float3(1e-3, 0, 0));
    float3 target = side * (.55 + .1 * sin(c.t * .05)) + float3(0, .25 * cos(c.t * .04), 0);
    float3 rd = cameraRay(c.uv / c.size, target - ro, float3(0, 1, 0), 1.7);
    float travel = 0;
    float4 trap;
    bool hit = false;
    int steps = 0;
    for (int i = 0; i < 180; ++i) {
        float d = mandelField(ro + rd * travel, c, trap);
        if (d < max(.0002f, .00045 * travel)) { hit = true; break; }
        travel += max(d * .75, .0001f);
        steps = i;
        if (travel > 6) break;
    }
    float3 background = deep(.4 + c.uv.y * .1, f) * .1 + paint(.6 + c.uv.x * .1, f) * .13 * smoothstep(.3f, .8f, fbm2(c.uv * 1.4 + float2(c.t * .02, 0), 4));
    if (!hit) return background + paint(.8, f) * pow(float(steps) / 180, 1.5f) * .6;
    float3 p = ro + rd * travel;
    float e = .0006 * travel + .0002;
    float4 t2;
    float d0 = mandelField(p, c, t2);
    float3 n = geometryNormal(d0, mandelField(p + float3(e, 0, 0), c, t2), mandelField(p + float3(0, e, 0), c, t2), mandelField(p + float3(0, 0, e), c, t2));
    mandelField(p, c, trap);
    float occlusion = 1 - float(steps) / 180;
    float3 light = normalize(float3(.6, .7, -.4));
    float diffuse = max(dot(n, light), 0.f);
    float rim = pow(1 - max(dot(-rd, n), 0.f), 2.f);
    float flow = .5 + .5 * sin(dot(p, float3(3.1, 2.4, 2.8)) - c.t * 1.1 - c.m * 2.0);
    float veins = (exp(-trap.x * 6) + exp(-trap.y * 6) * .6) * (.35 + flow * .45);
    float band = c.b[int(clamp(trap.w * 1.4, 0.f, 3.99f))];
    float3 albedo = paint(.15 + trap.w * .5 + trap.z * .3, f);
    float3 color = albedo * (.05 + diffuse * .8) * occlusion + paint(.9, f) * veins * (.4 + band * 1.7 + c.hit * flow) + paint(.6, f) * rim * .35;
    return mix(background, color, exp(-travel * c.fog * .2));
}

// ------------------------------------------------------------------ 61 Menger Nave
// A flight through an endless Menger sponge cathedral. Each level of holes breathes with
// its own band, so the architecture opens and closes at different scales with the music.
float mengerField(float3 p, Ctx c) {
    // Infinite sponge in units where each solid cube spans 2; the camera rides an open axis.
    float unit = 1.5;
    float3 q = p / unit;
    float d = -1;
    float s = 1;
    for (int i = 0; i < 4; ++i) {
        float band = c.b[min(i, 3)];
        float3 a = fmod(q * s + 1000, 2.f) - 1;
        s *= 3;
        float3 r = abs(1 - 3 * abs(a));
        float da = max(r.x, r.y), db = max(r.y, r.z), dc = max(r.z, r.x);
        float cross = (min(da, min(db, dc)) - 1 + band * .25) / s;
        d = max(d, cross);
    }
    return d * unit;
}
float3 mengerNave(Ctx c, constant NativeFrame &f) {
    float3 ro = float3(sin(c.t * .05) * .12, cos(c.t * .04) * .12, c.travel * 1.6 + 3);
    float3 rd = cameraRay(c.uv, float3(sin(c.t * .09) * .25, sin(c.t * .07) * .2, 1), float3(sin(c.t * .05) * .2, 1, 0), 1.3 * c.size);
    float travel = 0;
    bool hit = false;
    int steps = 0;
    for (int i = 0; i < 110; ++i) {
        float d = mengerField(ro + rd * travel, c);
        if (d < .0008 * (1 + travel)) { hit = true; break; }
        travel += d;
        steps = i;
        if (travel > 30) break;
    }
    float3 fogColor = paint(.75, f) * .2;
    if (!hit) return fogColor;
    float3 p = ro + rd * travel;
    float e = .001, d0 = mengerField(p, c);
    float3 n = geometryNormal(d0, mengerField(p + float3(e, 0, 0), c), mengerField(p + float3(0, e, 0), c), mengerField(p + float3(0, 0, e), c));
    float occlusion = pow(1 - float(steps) / 110, 2.f);
    float3 light = normalize(float3(.3, .8, .5));
    float diffuse = max(dot(n, light), 0.f);
    float pulse = pow(.5 + .5 * sin(p.z * .8 - c.t * 1.5 - c.m * 3), 12.f) * (.3 + c.hit * 1.5);
    float3 albedo = paint(.25 + dot(abs(n), float3(.1, .2, .3)) + p.z * .01, f);
    float3 color = albedo * (.1 + diffuse * .9) * occlusion + paint(.9, f) * pulse * occlusion;
    return mix(fogColor, color, exp(-travel * (.06 + c.fog * .08)));
}

// ------------------------------------------------------------------ 62 Apollonian Foam
// A flight through an Apollonian sphere-inversion foam. Bubble walls glow by their orbit
// depth; each depth listens to its own band, and attacks shimmer across the foam.


// ------------------------------------------------------------------ 63 Hyperbolic Rosette
// An {8,3} tiling of the Poincare disk, scaled so the disk overfills the canvas. A
// continuous hyperbolic translation carries the viewer through the tiling forever. Tile
// walls glow; bands light the tiles in their screen sector and attacks pulse the walls.


// ------------------------------------------------------------------ 64 Quasicrystal Bloom
// Seven plane waves at equal angles interfere into a quasicrystal that never repeats. As
// the phases advance the pattern seems to bloom outward forever. Each wave's strength
// follows a band and attacks kick its phase.
float3 quasicrystalBloom(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv * 9 / c.size;
    float sum = 0, gradientX = 0, gradientY = 0;
    const int waves = 7;
    for (int i = 0; i < waves; ++i) {
        float angle = PI * float(i) / float(waves);
        float2 d = float2(cos(angle), sin(angle));
        float band = c.b[i % 4];
        float phase = c.travel * .9 + c.t * .25 + c.m * (.3 + .1 * float(i));
        float amplitude = 1 + band * .8 + c.hit * .5 * float(i % 2);
        float w = dot(p, d) + phase;
        sum += cos(w) * amplitude;
        gradientX -= sin(w) * amplitude * d.x;
        gradientY -= sin(w) * amplitude * d.y;
    }
    sum /= float(waves);
    float contour = fract(sum * 3 + c.t * .05);
    float lines = exp(-abs(contour - .5) * 18);
    float3 n = normalize(float3(-gradientX * .08, -gradientY * .08, 1));
    float light = max(dot(n, normalize(float3(-.4, .6, .7))), 0.f);
    float3 color = paint(.5 + sum * .9, f) * (.12 + .5 * light) * smoothstep(-.4f, .8f, sum + .3);
    color += paint(.9 + sum * .2, f) * lines * .6 + paint(.95, f) * pow(max(sum, 0.f), 4.f) * 1.4;
    return color;
}

// ------------------------------------------------------------------ 65 Tesseract Garden
// Layers of rotating tesseracts drift toward the viewer, each turning through four
// dimensions so its cubes fold through one another. Bands spin individual tesseracts
// faster; attacks flare their edges.


// ------------------------------------------------------------------ 66 Harmonograph
// Three decaying pendulum traces sweep across the canvas like ink from a harmonograph.
// The visible window of each trace rolls continuously inward; bands tug individual
// pendulum phases, so the loops shear and re-form with the music.


// ------------------------------------------------------------------ 67 Moire Engine
// Three fine gratings (rings, rays and lines) overlap; their interference throws huge
// moving fringes across the canvas. Zoom speed scales one grating against the others;
// bands swing the gratings and attacks shift their frequency.


// ------------------------------------------------------------------ 68 Riley Undulation
// Op-art stripes whose widths and phases swell into an illusion of a rolling surface.
// Bass sends a travelling bulge through the stripes; highs add a fine shimmer.


// ------------------------------------------------------------------ 69 Kaleido Chamber
// A three-mirror kaleidoscope: a chamber of tumbling glass shards reflected across an
// endless triangular lattice. The music clock tumbles the shards, bands brighten their
// colors and attacks rotate the chamber.


// ------------------------------------------------------------------ 70 Girih Lattice
// An eight-fold star-and-cross pattern of interlaced gilded straps, mapped through a
// log-polar Droste projection centred off-canvas, so zoom flows endlessly. Star tiles
// light with their bands; attacks run light along the straps.


#define GEOMETRY_EFFECTS(X)  X(opalTessera)  X(mandelBloom) X(mengerNave)   X(quasicrystalBloom)
GEOMETRY_EFFECTS(NATIVE_EFFECT)
