// Particle, orbital and constellation designs. Original PulseCanvas procedural code.
// Every effect receives Ctx from NativeCommon.metal; audio terms are zero at zero Chaos.

// ------------------------------------------------------------------ 41 Photon Rapids
// Light rushes past from an off-centre vanishing point that drifts and curves, so the
// streaks swirl like rapids. The music clock speeds the current, bands light their own
// streak families and attacks stretch every streak.


// ------------------------------------------------------------------ 50 Magnetic Ballet
// Field lines of four magnetic poles waltzing across the canvas, drawn as glowing lines
// over an iron-filing texture. Each pole's strength follows a band, so the lines bend and
// gather with the music; attacks brighten the filings.
float3 magneticBallet(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float stream = 0, potential = 0;
    float2 field = 0.f;
    for (int i = 0; i < 5; ++i) {
        float fi = float(i);
        float2 pole = float2(sin(c.t * (.13 + fi * .03) + fi * 2.4 + c.m * .1) * c.extent.x * .85, cos(c.t * (.11 + fi * .025) + fi * 1.7) * c.extent.y * .8);
        // Whole-number charges keep every field line continuous; bands move the poles.
        float charge = fmod(fi, 2.f) < 1 ? 1. : -1.;
        pole += float2(sin(c.m * .7 + fi * 2), cos(c.m * .6 + fi)) * c.b[i % 4] * .25;
        float2 d = p - pole;
        float r2 = dot(d, d) + .002;
        stream += charge * atan2(d.y, d.x);
        potential += charge * .5 * log(r2);
        field += charge * d / r2;
    }
    float lines = stream * 3 / PI + c.travel * .2;
    float strength = length(field);
    // |grad stream| = |field|; using it avoids derivative spikes at the atan2 branch cuts.
    float w = 3 / PI * strength * c.px / c.size;
    float fieldLine = 1 - smoothstep(.0f, max(w * 1.5, .06f), abs(fract(lines) - .5) - .02);
    float equipotential = 1 - smoothstep(.0f, max(2 * strength * c.px * 1.5, .04f), abs(fract(potential * 2) - .5) - .45);
    float2 direction = field / max(strength, 1e-4f);
    // Iron filings: short dashes aligned with the local field.
    float2 grid = p * 60;
    float2 cell = floor(grid), local = fract(grid) - .5;
    float2 jitter = hash22(cell) - .5;
    float2 q = local - jitter * .3;
    float along = dot(q, direction), across = dot(q, float2(-direction.y, direction.x));
    float filing = (1 - smoothstep(.05f, .09f, abs(across))) * (1 - smoothstep(.28f, .36f, abs(along))) * step(.25, hash21(cell + 3));
    float3 color = deep(.4, f) * .06;
    color += paint(.2 + potential * .05, f) * filing * clamp(strength * .15, 0.f, 1.f) * (.5 + c.hit * 1.5);
    color += paint(.55 + stream * .02, f) * fieldLine * clamp(strength * .2, .25f, 1.f) * 1.1;
    color += paint(.85, f) * equipotential * .12;
    color += paint(.95, f) * exp(-1 / max(strength * .02, 1e-3f)) * .4;
    return color;
}

// ------------------------------------------------------------------ 52 Diamond Undertow
// Schools of faceted diamond shards ride a curling undertow in several depth layers.
// Each shard aligns with the current; bands tumble their own shards and attacks make
// the facets flash.


// ------------------------------------------------------------------ 54 Gyroscopic Garden
// A low glide over a garden of brass gyroscopes on pedestals. Each has three nested
// gimbals spinning on different axes; bands spin their own gyroscopes faster and attacks
// glint across the rings.


// ------------------------------------------------------------------ 55 Bubble Choir
// Clouds of soap bubbles float toward the viewer in layers. Thin-film colors swirl over
// every skin; each bubble swells with its own band and attacks make the skins wobble.


// ------------------------------------------------------------------ 57 Echo Lanterns
// Hundreds of paper sky lanterns rise over a still lake; the water mirrors them. Each
// flame flickers with its own band, attacks flare nearby lanterns, and Zoom speed lifts
// the camera through the swarm.


// ------------------------------------------------------------------ 86 Plexus Constellations
// Stars drifting in deep layers join into constellations whenever they come close. Loud
// passages raise the joining distance so the web grows; stars twinkle on their bands.
float2 plexusPoint(float2 cell, float layer, Ctx c) {
    float2 seed = hash22(cell + layer * 17);
    return cell + .5 + .4 * float2(sin(c.t * (.2 + seed.x * .3) + seed.y * 9), cos(c.t * (.17 + seed.y * .3) + seed.x * 9));
}
float3 plexusConstellations(Ctx c, constant NativeFrame &f) {
    float3 color = deep(.45 + c.uv.y * .1, f) * .06 + paint(.4, f) * .04 * fbm2(c.uv * 1.2 + c.t * .01, 4);
    const int count = 3;
    for (int k = 0; k < count; ++k) {
        float2 slot = layerSlot(k, count, c.travel * 0.1);
        float phase = slot.x, id = slot.y, fade = layerFade(phase);
        float scale = layerScale(phase, 1.8) * 3.2 / c.size;
        float2 p = c.uv * scale + id * 9.1;
        float2 base = floor(p);
        float2 points[9];
        int n = 0;
        for (int y = -1; y <= 1; ++y) for (int x = -1; x <= 1; ++x) points[n++] = plexusPoint(base + float2(x, y), id, c);
        float reach = 1.05 + c.e * .35 + c.b.x * .2;
        float lines = 0, stars = 0;
        for (int i = 0; i < 9; ++i) {
            float2 a = points[i];
            float band = c.b[int(hash21(floor(a) + id) * 3.99)];
            stars += exp(-length(p - a) / (.035 * (1 + band * .8 + c.hit * .7))) * (.6 + band + c.hit * 1.2);
            for (int j = i + 1; j < 9; ++j) {
                float2 b = points[j];
                float span = length(a - b);
                if (span > reach) continue;
                float strength = pow(1 - span / reach, 1.2f);
                float d = sdSegment(p, a, b);
                lines += (exp(-d / (.01 + c.px * scale)) + exp(-d / .06) * .15) * strength;
            }
        }
        float tone = mix(.25, 1., phase) * fade;
        color += paint(.35 + id * .07, f) * lines * 1.1 * tone + paint(.9, f) * stars * 1.3 * tone;
    }
    return color;
}

// ------------------------------------------------------------------ 87 Murmuration
// A starling murmuration rolls across a dusk sky: thousands of birds forming one folding
// cloud. Bass thickens the flock, attacks snap it into a turn, highs scatter the edges.


// ------------------------------------------------------------------ 88 Ring Shepherds
// Skimming a planetary ring at a grazing angle. Thousands of ringlets, gaps and spiral
// density waves sweep past, with the planet's limb filling the sky. Ringlets brighten on
// their bands; attacks launch wakes from the shepherd moons.
float3 ringShepherds(Ctx c, constant NativeFrame &f) {
    float2 planetCenter = float2(-c.extent.x * .35, c.extent.y * .25 + 2.75);
    float planetRadius = 2.2;
    float3 color = deep(.4, f) * .03 + paint(.9, f) * pow(hash21(floor(c.uv * 140)), 70.f);
    float planetDistance = length(c.uv - planetCenter);
    if (planetDistance < planetRadius) {
        float2 n2 = (c.uv - planetCenter) / planetRadius;
        float3 n = float3(n2, sqrt(max(0.f, 1 - dot(n2, n2))));
        float light = max(dot(n, normalize(float3(.6, -.3, .7))), 0.f);
        float bands = fbm2(float2(n.y * 6, c.t * .02), 4);
        color = paint(.3 + bands * .5, f) * (.04 + light * .9) + paint(.7, f) * pow(1 - n.z, 4.f) * .3;
    }
    if (c.uv.y < .25 * c.extent.y) {
        float3 g = groundView(c.uv, c.extent, 1., -.75 * c.extent.y);
        // The camera orbits the planet, so ring structure streams past along the azimuth.
        float2 fromPlanet = rot(float2(g.x * 4 + 60, g.y * 4 - 120), c.travel * .03 + c.t * .006);
        float radius = length(fromPlanet) - 85;
        float azimuth = atan2(fromPlanet.y, fromPlanet.x) * 60;
        float ringlets = fbm2(float2(radius * 1.3, 0), 5);
        ringlets = mix(ringlets, .5 + .5 * sin(radius * 9), .25);
        float gap = 1 - smoothstep(.01f, .035f, abs(fract(radius * .07) - .5));
        float band = c.b[int(fract(radius * .11) * 3.99)];
        float wake = 0;
        for (int i = 0; i < 2; ++i) {
            float moonRadius = 46 + float(i) * 9;
            float moonAzimuth = c.t * (.01 + float(i) * .004) + float(i) * 3;
            float dr = radius - moonRadius;
            float phase = dr * 6 - (azimuth - moonAzimuth) * 60 * sign(dr);
            wake += sin(phase - c.m * 3) * exp(-abs(dr) * .35) * (.4 + c.hit * 1.2);
        }
        float density = clamp(ringlets * (1 - gap) + wake * .15, 0.f, 1.f);
        float grain = .75 + .25 * noise2(float2(radius * 6, azimuth * 3));
        float clumps = .7 + .3 * smoothstep(.3f, .8f, noise2(float2(radius * .8, azimuth * .6)));
        float spokes = 1 - .35 * smoothstep(.55f, .8f, noise2(float2(azimuth * .9, radius * .05)));
        grain *= clumps * spokes;
        float3 ring = paint(.2 + ringlets * .6, f) * density * grain * (.6 + band * 1.4);
        ring += paint(.95, f) * pow(density, 6.f) * .3;
        float coverage = smoothstep(.25f * c.extent.y, .15f * c.extent.y, c.uv.y);
        float fade = exp(-g.z * .03) * smoothstep(0.f, .2f, .25f * c.extent.y - c.uv.y);
        color = mix(color, ring * fade + color * (1 - density) * .4, coverage);
    }
    return color;
}

// ------------------------------------------------------------------ 89 Pendulum Wave
// Rows of pendulums with slowly increasing periods swing in and out of phase, forming
// snakes, standing waves and chaos. Bass widens the swings, each row's bobs glow on
// their band and the music clock advances the pattern.


// ------------------------------------------------------------------ 90 Firework Garden
// Fireworks bloom over a dark garden and mirror in a pond. Shells launch on a steady
// schedule; louder music launches more and larger shells, bands color their bursts and
// attacks crackle the sparks.


// ------------------------------------------------------------------ 91 Event Horizon
// A black hole bends a starfield and its own accretion disk into the classic lensed
// halo. The disk spins faster inside; bands heat their own radii, attacks launch flares
// that orbit, and Zoom speed slowly circles the camera.
float3 eventHorizon(Ctx c, constant NativeFrame &f) {
    float orbit = c.travel * .12 + c.t * .015;
    float3 ro = float3(sin(orbit) * 9, 1.1 + sin(c.t * .03) * .4, -cos(orbit) * 9);
    float3 target = float3(1.6, 0, 0);
    target.xz = rot(target.xz, -orbit);
    float3 rd = cameraRay(c.uv / c.size, target - ro, float3(0, 1, 0), 1.4);
    float3 p = ro, v = rd;
    float3 color = 0.f;
    float transmission = 1;
    float h2 = dot(cross(p, v), cross(p, v));
    for (int i = 0; i < 90; ++i) {
        float r = length(p);
        if (r < 1) { transmission = 0; break; }
        float stepSize = .06 * r;
        float3 previous = p;
        float3 acceleration = -1.5 * h2 * p / pow(r, 5.f);
        v += acceleration * stepSize;
        p += v * stepSize;
        if (previous.y * p.y < 0) {
            float3 crossing = mix(previous, p, previous.y / (previous.y - p.y));
            float radius = length(crossing.xz);
            if (radius > 2.4 && radius < 9) {
                float angle = atan2(crossing.z, crossing.x);
                float spin = c.t * 2.2 / pow(radius, 1.5f) * 3 + c.m * .8 / radius;
                float swirl = fbm2(float2(angle * 3 + spin * 3 + log(radius) * 4, radius * 1.5), 4);
                float band = c.b[int(clamp((9 - radius) / 6.6 * 3.99, 0.f, 3.99f))];
                float heat = pow(2.4 / radius, 1.6f);
                float flare = c.hit * exp(-pow(fract((angle - spin * 4) / TAU) - .5, 2.f) * 80) * step(3.f, radius) * step(radius, 5.f);
                float density = smoothstep(2.4f, 3.f, radius) * smoothstep(9.f, 6.f, radius) * (.35 + .9 * swirl) * (1 + band * 1.3);
                float doppler = 1 + .5 * sin(angle - orbit);
                float3 emission = mix(paint(.4, f), paint(.95, f), heat) * (heat * 2.5 + .3) * doppler + paint(.98, f) * flare * 3;
                color += emission * density * transmission;
                transmission *= 1 - clamp(density * .85, 0.f, .95f);
            }
        }
        if (r > 30) break;
    }
    float3 direction = normalize(v);
    float2 sky = float2(atan2(direction.z, direction.x), asin(clamp(direction.y, -1.f, 1.f)));
    float stars = pow(hash21(floor(sky * 180)), 60.f) * 2 + pow(hash21(floor(sky * 90 + 3)), 40.f);
    float3 background = paint(.9, f) * stars + deep(.4, f) * .05 * fbm2(sky * 3, 4);
    color += background * transmission;
    return color;
}

// ------------------------------------------------------------------ 99 Neon Calligraphy
// Neon tubes write sweeping calligraphic strokes across the canvas, layered at different
// depths over a wet floor that reflects them. Each tube draws on, lingers and fades;
// bands brighten their tubes and attacks make them buzz.


#define PARTICLE_EFFECTS(X)  X(magneticBallet)     X(plexusConstellations)  X(ringShepherds)   X(eventHorizon)
PARTICLE_EFFECTS(NATIVE_EFFECT)
