// Organic, landscape and volumetric designs. Original PulseCanvas procedural code.
// Every effect receives Ctx from NativeCommon.metal; audio terms are zero at zero Chaos.

float3 natureNormal(float d0, float dx, float dy, float dz) { return normalize(float3(dx - d0, dy - d0, dz - d0) + 1e-6); }

// Folding fractal tree in local coordinates; returns distance to the nearest branch and
// the depth of that branch.


// ------------------------------------------------------------------ 34 Electric Orchard
// Rows of luminous fractal trees recede across a dark orchard. Current climbs every tree
// in pulses; each tree pulses on its band and attacks flash the whole canopy.


// ------------------------------------------------------------------ 36 Graviton Petals
// A flight through a weightless garden of huge flowers that open and close. Each bloom
// opens on its band; attacks shiver the petals.


// ------------------------------------------------------------------ 42 Sonic Topography
// A living contour map seen from above. Glowing isolines wrap hills that rise and fall;
// each region's hills lift with their band, attacks ripple through the contours, and the
// map glides and slowly turns with Zoom speed.
float topographyHeight(float2 p, Ctx c) {
    float h = fbm2(p * .35, 5) * 2.2;
    float2 cell = floor(p * .25);
    float band = c.b[int(hash21(cell) * 3.99)];
    h += band * .6 * smoothstep(.2f, 1.f, fbm2(p * .5 + 3, 2));
    h += c.hit * .08 * sin(length(p - float2(sin(c.m) * 3, c.travel * 1.5)) * 3 - c.m * 6);
    return h + .15 * sin(p.x * .4 + c.t * .1) * sin(p.y * .3 - c.t * .08);
}
float3 sonicTopography(Ctx c, constant NativeFrame &f) {
    float2 xz = rot(c.uv, c.t * .01) * 3.2 / c.size + float2(sin(c.t * .05) * 2, c.travel * 1.5);
    float e = .02, h = topographyHeight(xz, c);
    float2 slope = float2(topographyHeight(xz + float2(e, 0), c) - h, topographyHeight(xz + float2(0, e), c) - h) / e;
    float3 n = normalize(float3(-slope, 1.2));
    float shade = .2 + .8 * max(dot(n, normalize(float3(-.5, .5, .7))), 0.f);
    float levels = h * 10;
    float w = fwidth(levels);
    float toLevel = .5 - abs(fract(levels) - .5);
    float contour = 1 - smoothstep(.015f, .015f + max(w * 1.5, .02f), toLevel);
    float toMajor = .5 - abs(fract(h * 2) - .5);
    float major = 1 - smoothstep(.01f, .01f + max(fwidth(h * 2) * 1.5, .015f), toMajor);
    float2 gridLines = abs(fract(xz * .5) - .5);
    float grid = (1 - smoothstep(.0f, .015f, min(gridLines.x, gridLines.y))) * .12;
    float water = smoothstep(.75f, .7f, h);
    float3 land = deep(.25 + h * .1, f) * .1 * shade + paint(.15 + h * .3, f) * .08 * shade;
    float3 sea = deep(.6, f) * .08 + paint(.5, f) * .05 * (1 + sin(h * 40 - c.t));
    float3 color = mix(land, sea, water * .8);
    color += paint(.25 + h * .25, f) * contour * .8 * (.5 + shade) + paint(.9, f) * major * 1.1 + paint(.6, f) * grid;
    return color;
}

// ------------------------------------------------------------------ 43 Prismatic Dunes
// A low flight over wind-rippled dunes at golden hour. Ridges split the light into
// prismatic sheen; bass lifts dune crests as gusts pass and highs blow sand off them.
float duneHeight(float2 p, Ctx c) {
    float ridges = 0;
    float2 q = p * .25;
    ridges += (1 - abs(sin(q.x * 1.3 + sin(q.y * .7) * 1.5 + q.y * .3))) * 1.2;
    ridges += (1 - abs(sin(q.x * 2.7 - q.y * .9 + 2))) * .4;
    ridges += fbm2(q * 1.5, 3) * .5;
    float gust = (c.b.x * 1.1 + c.hit * .8) * pow(.5 + .5 * sin(q.y * 1.4 - c.m * 2), 3.f);
    float ripples = sin(p.x * 2.2 + p.y * .6 + fbm2(p * .4, 2) * 3) * .03;
    return ridges * (1 + gust) + ripples;
}
float3 prismaticDunes(Ctx c, constant NativeFrame &f) {
    c.travel += c.m * f.camera.w * .7;
    float3 ro = float3(c.t * .2, 4.0, c.travel * 2.2);
    float3 rd = cameraRay(c.uv, float3(.2, -.18, 1), float3(0, 1, 0), 1.5);
    float3 sun = normalize(float3(-.6, .22, 1));
    float3 sky = mix(paint(.65, f) * 1.1, deep(.3, f) * .25, smoothstep(-.05f, .55f, rd.y));
    sky += paint(.82, f) * pow(max(dot(rd, sun), 0.f), 200.f) * 3 + paint(.85, f) * pow(max(dot(rd, sun), 0.f), 6.f) * .4;
    float travel = 0;
    bool hit = false;
    for (int i = 0; i < 90; ++i) {
        float3 p = ro + rd * travel;
        float gap = p.y - duneHeight(p.xz / c.size, c);
        if (gap < .006) { hit = true; break; }
        travel += max(gap * .45, .015f);
        if (travel > 60) break;
    }
    if (!hit) return sky;
    float3 p = ro + rd * travel;
    float2 xz = p.xz / c.size;
    float e = .015, h = duneHeight(xz, c);
    float3 n = normalize(float3(h - duneHeight(xz + float2(e, 0), c), e, h - duneHeight(xz + float2(0, e), c)));
    float diffuse = max(dot(n, sun), 0.f);
    float shadowSide = smoothstep(.0f, .25f, diffuse);
    float prism = pow(1 - abs(dot(n, normalize(rd + sun))), 6.f);
    float3 sand = mix(deep(.35, f) * .2, paint(.55 + h * .1, f), shadowSide) * (.25 + diffuse * .9);
    sand += paint(.55 + .12 * sin(dot(n.xz, float2(1, .5)) * 2 + h), f) * prism * .45;
    float drift = pow(fbm2(xz * 3 + float2(c.t * .8, 0), 3), 4.f) * smoothstep(.8f, 1.4f, h) * (.3 + c.b.w * 2 + c.hit * 3);
    sand += paint(.95, f) * drift;
    float ripples = .5 + .5 * sin(xz.x * 2.5 + xz.y * 1.5 - c.t - c.m * 3);
    sand += paint(.48 + n.x * .16, f) * ripples * (c.b.y * .65 + c.hit * .7);
    return mix(sky, sand, exp(-travel * (.012 + c.fog * .03)));
}

// ------------------------------------------------------------------ 44 Honeycomb Tide
// A flight low over golden comb. Honey in every cell rises and falls like a tide; cells
// fill on their own band and attacks make the honey surfaces shimmer.


// ------------------------------------------------------------------ 45 Nebula Nursery
// A slow flight into an emission nebula where new stars ignite. Bands light their own
// layers of gas; attacks flare the young stars' diffraction spikes.


// ------------------------------------------------------------------ 46 Crystal Orchard
// A glide across a plain of quartz clusters. Hexagonal crystals catch the light and glow
// from within; each cluster grows on its band and attacks spark across the facets.
float crystalField(float3 p, Ctx c, thread float &glowOut) {
    // Only the two nearest cells on each axis can hold the closest crystal.
    float spacing = 2.4;
    float2 cellPosition = p.xz / spacing;
    float2 base = floor(cellPosition - .5);
    float d = p.y;
    glowOut = 0;
    for (int y = 0; y <= 1; ++y) for (int x = 0; x <= 1; ++x) {
        float2 g = base + float2(x, y);
        float3 seed = hash33(float3(g, 3));
        float band = c.b[int(seed.x * 3.99)];
        for (int k = 0; k < 2; ++k) {
            float3 s2 = hash33(float3(g, float(k) + 7));
            float2 center = float2((g.x + .5 + (s2.x - .5) * .5) * spacing, (g.y + .5 + (s2.y - .5) * .5) * spacing);
            // A crystal (radius ≤ .32, ≤ 3.3 tall, leaning ≤ .35 rad) lies within 1.5 of its base axis,
            // so one farther away than the current nearest cannot be the nearest surface.
            if (length(p.xz - center) - 1.5 > d) continue;
            float3 q = p - float3(center.x, 0, center.y);
            q.xy = rot(q.xy, (s2.z - .5) * .7);
            float height = min((.6 + s2.z * 1.1) * (1 + band * .45) * (.85 + .15 * sin(c.t * .3 + seed.y * 9)), 2.6f);
            float radius = .2 + s2.y * .12;
            float prism = max(sdHex(q.xz, radius), max(-q.y, q.y - height - radius * 1.8 + length(q.xz) * 1.8));
            if (prism < d) { d = prism; glowOut = seed.z; }
        }
    }
    return d;
}
float3 crystalOrchard(Ctx c, constant NativeFrame &f) {
    // The glide over the orchard speeds up with the music clock.
    float3 ro = float3(sin(c.t * .06) * 1.5, 3.4, c.travel * 1.6 + c.m * .5);
    float3 rd = cameraRay(c.uv, float3(0, -.45, 1), float3(0, 1, 0), 1.35);
    float travel = 0, glow = 0;
    bool hit = false;
    for (int i = 0; i < 64; ++i) {
        float3 p = ro + rd * travel;
        float d = crystalField(p, c, glow);
        if (d < .002 * (1 + travel * .3)) { hit = true; break; }
        // Above the tallest crystal the field is exact, so take long steps.
        travel += min(d * .75, p.y > 3.1 ? 1.5f : .6f);
        if (travel > 35) break;
    }
    float3 sky = mix(paint(.75, f) * .3, deep(.4, f) * .08, smoothstep(-.1f, .5f, rd.y));
    if (!hit) return sky;
    float3 p = ro + rd * travel;
    float e = .002, g2;
    float d0 = crystalField(p, c, g2);
    float3 n = natureNormal(d0, crystalField(p + float3(e, 0, 0), c, g2), crystalField(p + float3(0, e, 0), c, g2), crystalField(p + float3(0, 0, e), c, g2));
    float3 light = normalize(float3(.4, .7, -.3));
    float diffuse = max(dot(n, light), 0.f);
    float fresnel = pow(1 - max(dot(-rd, n), 0.f), 3.f);
    float3 color;
    if (p.y < .01) {
        float3 reflected = mix(paint(.75, f) * .3, deep(.4, f) * .08, smoothstep(-.1f, .5f, reflect(rd, n).y));
        // The floor catches the light of nearby crystals as they glow on their bands.
        float floorBand = c.b[int(hash21(floor(p.xz * .5)) * 3.99)];
        color = deep(.3, f) * .08 * (.6 + .4 * fbm2(p.xz * 3, 3)) + reflected * .3 + paint(.6, f) * floorBand * .12;
    } else {
        // Each crystal cluster glows from within on its own band.
        float crystalBand = c.b[int(hash21(floor(p.xz * .5)) * 3.99)];
        float inner = (.5 + .5 * sin(p.y * 6 - c.t - c.m * 2 + glow * 20)) * (1 + c.hit * 1.4 * step(.4, glow)) * (1 + crystalBand * 2.2);
        color = paint(.3 + glow * .5, f) * (.12 + diffuse * .4 + inner * .45) + paint(.95, f) * (fresnel * .8 + pow(max(dot(reflect(rd, n), light), 0.f), 40.f) * (1 + c.hit * 2));
    }
    return mix(sky, color, exp(-travel * (.035 + c.fog * .05)));
}

// ------------------------------------------------------------------ 48 Velvet Nebula
// Towering dust pillars stand against a glowing nebula, their rims lit from behind.
// Layers drift past; bands brighten the emission behind each pillar and attacks light
// the tips where stars are being born.
float3 velvetNebula(Ctx c, constant NativeFrame &f) {
    float3 color = 0.f;
    float2 glowCenter = float2(c.extent.x * .4, c.extent.y * .6);
    float2 flow = float2(fbm2(c.uv * .8 + c.t * .03, 3), fbm2(c.uv * .8 - c.t * .025 + 4, 3)) - .5;
    float3 emission = mix(paint(.3, f), paint(.85, f), exp(-length(c.uv - glowCenter) * .9)) * (.4 + .6 * fbm2(c.uv * 1.5 + flow * 1.2 + c.t * .04, 5));
    emission *= 1 + c.b.y * .8;
    color = emission;
    color += paint(.95, f) * pow(hash21(floor(c.uv * 120)), 60.f);
    const int count = 4;
    for (int k = 0; k < count; ++k) {
        float2 slot = layerSlot(k, count, c.travel * 0.06);
        float phase = slot.x, id = slot.y, fade = layerFade(phase);
        float scale = layerScale(phase, 1.6) * .9 / c.size;
        float2 p = c.uv * scale + float2(id * 2.7 + c.t * .03 * (1 + phase), 0);
        float column = floor(p.x / 1.4 + .5);
        float local = p.x - column * 1.4;
        float seed = hash21(float2(column, id));
        float top = -.2 + seed * 1.1 + .15 * sin(c.t * .05 + seed * 9);
        float wobble = fbm2(float2(p.y * 2 - c.t * .05, column * 3 + id), 4) - .5 + .06 * sin(c.t * .3 + column + p.y * 2);
        float width = (.28 + seed * .2) * (1 - smoothstep(top - .6, top + .1, p.y) * .6);
        float pillar = abs(local + wobble * .35) - width;
        pillar = max(pillar, p.y - top - fbm2(float2(local * 4, id), 3) * .3);
        float edge = c.px * scale * 2;
        float body = (1 - smoothstep(-edge, edge, pillar)) * fade;
        float rim = exp(-abs(pillar) * 25) * smoothstep(.1f, -.3f, p.y - top) * 0 + exp(-abs(pillar) * 30);
        float band = c.b[int(seed * 3.99)];
        float tip = exp(-length(float2(local, p.y - top)) * 6) * (.4 + c.hit * 2 + band);
        float3 dust = deep(.15 + seed * .1, f) * .05 * (.6 + fbm2(p * 6, 4));
        color = mix(color, dust, body * mix(.7, 1., phase));
        color += paint(.8, f) * rim * .5 * fade + paint(.95, f) * tip * .4 * fade;
    }
    return color;
}

// ------------------------------------------------------------------ 49 Arc Foundry
// A dark steel foundry floor lit by welding arcs. Showers of sparks fly, fall and bounce;
// each arc flickers on its band and attacks throw bigger showers.


// ------------------------------------------------------------------ 51 Paper Cascades
// Layered paper-cut hills drift toward the viewer, each casting a soft shadow on the
// one behind. Ridges carry tiny cut-out trees; bands lift their own hills and attacks
// flutter the paper edges.


// ------------------------------------------------------------------ 53 Fractal Canopy
// Looking up through a forest canopy: fractal branches against a bright sky, clusters of
// leaves and sun rays through the gaps. Bass sends gusts through the branches; bands
// rustle their own trees and attacks flash the sun through the leaves.


// ------------------------------------------------------------------ 58 Kelp Cathedral
// A kelp forest: tall swaying stalks carrying long rippled blades in deep layers, god
// rays from the surface and drifting marine snow. Bands sway their own stalks; attacks
// shimmer the light shafts.


// ------------------------------------------------------------------ 59 Solar Filigree
// The curved limb of a star fills the lower canvas: boiling granulation, a glowing
// chromosphere and loops of plasma arching into black space, threaded with flowing
// filaments. Each loop brightens on its band, attacks flare them higher, and Zoom speed
// turns the star beneath the viewer.


// ------------------------------------------------------------------ 77 Zen Rake
// A raked gravel garden seen from above. Grooves flow around moss-ringed stones; the
// rake slowly redraws them. Bass sends ripples outward from each stone; highs glint on
// the gravel.


// ------------------------------------------------------------------ 93 Mitosis Garden
// A living culture under phase-contrast light: membranes, nuclei and organelles drift
// in two focal planes, and cells pinch apart as they divide. Each cell swells on its
// band; attacks quicken the cytoplasm.


// ------------------------------------------------------------------ 94 Neural Bloom
// Large neurons glow in shallow focus: bright somas with nuclei, tapering dendrites and
// a few long axons. Action potentials race along the axons; each neuron fires at a rate
// set by its band and attacks trigger cascades. The far layer is soft, like microscopy.


// ------------------------------------------------------------------ 95 Jellyfish Abyss
// Bioluminescent jellyfish drift through the deep in layers. Bells contract and trail
// rippling tentacles; each jelly pulses on its band and attacks make them contract.


// ------------------------------------------------------------------ 96 Glacier Rift
// A flight down a crevasse of translucent glacier ice: banded walls, glowing fractures
// and blowing snow. Bands light their own fracture families; attacks shimmer the ice.


// ------------------------------------------------------------------ 97 Firefly Meadow
// A moonlit meadow. Layers of tall grass sway toward the viewer while fireflies blink
// and drift; each firefly blinks on its band and attacks send a wave of light through
// the swarm.


#define NATURE_EFFECTS(X)   X(sonicTopography) X(prismaticDunes)   X(crystalOrchard) X(velvetNebula)           
NATURE_EFFECTS(NATIVE_EFFECT)
