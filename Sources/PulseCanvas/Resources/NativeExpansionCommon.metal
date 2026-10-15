#include <metal_stdlib>
using namespace metal;

// PulseCanvas native effect prelude. Original procedural code: no external images,
// preset equations or third-party shader sources. Classic mathematical forms are
// implemented from their definitions. This file is prepended to every Native*.metal
// effect file when the renderer compiles the native library.
//
// Layout matches NativeUniforms in VisualizerRenderer.swift. The first fields match
// SpatialFrame so every native pass shares one uniform block.
struct NativeFrame {
    float2 resolution; float time; int scene;
    float4 rhythm;   // attack, drive, attack swell, raw treble (Chaos-scaled)
    float4 style;    // brightness, size, fog, camera zoom
    float4 camera;   // rotation, Chaos, detail, zoom speed
    float4 colors[5];
    float4 bands;    // smoothed low, low-mid, high-mid, high (Chaos-scaled)
    float4 motion;   // zoom travel, music clock, procedural time, smoothed energy
};

// Everything an effect needs, already normalized. Every audio term is zero at zero Chaos.
struct Ctx {
    float2 uv;      // centred, y up; the shorter canvas edge spans [-1, 1]
    float2 screen;  // 0...1 across the canvas
    float2 extent;  // half-size of the canvas in uv units (>= 1 on each axis)
    float px;       // one pixel in uv units
    float t;        // procedural time plus integrated percussion motion (Chaos-scaled)
    float m;        // music clock: advances faster in energetic passages
    float e;        // smoothed musical energy, 0...~1
    float hit;      // short attack envelope
    float4 b;       // smoothed bands: low, low-mid, high-mid, high
    float travel;   // integrated forward zoom distance
    float size;     // size control, 1 at default
    float fog;      // depth control, 0...1
    float detail;   // detail control, 0...1
};

constant float PI = 3.14159265;
constant float TAU = 6.2831853;

// ---------------------------------------------------------------- hashing / noise
// Deterministic integer seeds authored for this catalog. Floating coordinates are
// treated as IEEE-754 bits; +/- zero share one identity. The three independently
// mixed coordinate words supply decorrelated channels without floating hash recipes.
uint canvasSeed(uint word) {
    word ^= word >> 13;
    word *= 0xA3B19535u;
    word ^= word >> 17;
    word *= 0xD74F739Du;
    word ^= word >> 11;
    return word;
}
uint canvasWord(float coordinate) { return coordinate == 0 ? 0u : as_type<uint>(coordinate); }
float canvasUnit(uint word) { return float(canvasSeed(word) >> 8) * (1.f / 16777216.f); }
uint canvasPair(float2 p) { return canvasSeed(canvasWord(p.x) ^ 0x13A17C9Bu) ^ canvasWord(p.y); }
uint canvasTriple(float3 p) { return canvasSeed(canvasPair(p.xy) ^ 0x7259B43Fu) ^ canvasWord(p.z); }
float hash11(float p) { return canvasUnit(canvasWord(p) ^ 0x4B7CA815u); }
float hash21(float2 p) { return canvasUnit(canvasPair(p)); }
float2 hash22(float2 p) { uint seed = canvasPair(p); return float2(canvasUnit(seed), canvasUnit(seed ^ 0xF195ED47u)); }
float3 hash33(float3 p) { uint seed = canvasTriple(p); return float3(canvasUnit(seed), canvasUnit(seed ^ 0xF195ED47u), canvasUnit(seed ^ 0x2DB67189u)); }
float hash31(float3 p) { return canvasUnit(canvasTriple(p)); }

float noise2(float2 p) {
    float2 i = floor(p), f = fract(p), u = f * f * (3 - 2 * f);
    return mix(mix(hash21(i), hash21(i + float2(1, 0)), u.x), mix(hash21(i + float2(0, 1)), hash21(i + 1), u.x), u.y);
}
float noise3(float3 p) {
    float3 i = floor(p), f = fract(p), u = f * f * (3 - 2 * f);
    float a = hash31(i), b = hash31(i + float3(1, 0, 0)), c = hash31(i + float3(0, 1, 0)), d = hash31(i + float3(1, 1, 0));
    float e = hash31(i + float3(0, 0, 1)), g = hash31(i + float3(1, 0, 1)), h = hash31(i + float3(0, 1, 1)), k = hash31(i + 1);
    return mix(mix(mix(a, b, u.x), mix(c, d, u.x), u.y), mix(mix(e, g, u.x), mix(h, k, u.x), u.y), u.z);
}
float fbm2(float2 p, int octaves) {
    float sum = 0, amplitude = .5;
    for (int i = 0; i < octaves; ++i) { sum += amplitude * noise2(p); p = float2(p.x * 1.6 - p.y * 1.2, p.x * 1.2 + p.y * 1.6) + 3.1; amplitude *= .5; }
    return sum;
}
float fbm3(float3 p, int octaves) {
    float sum = 0, amplitude = .5;
    for (int i = 0; i < octaves; ++i) { sum += amplitude * noise3(p); p = p * 2.03 + float3(1.7, -3.1, 2.3); amplitude *= .5; }
    return sum;
}
// Smooth divergence-free-looking flow from a noise potential.
float2 curl2(float2 p) {
    const float e = .05;
    float a = noise2(p + float2(0, e)), b = noise2(p - float2(0, e));
    float c = noise2(p + float2(e, 0)), d = noise2(p - float2(e, 0));
    return float2(a - b, d - c) / (2 * e);
}
// Voronoi: x = nearest distance, y = second distance, zw = nearest cell id.
float4 voronoi(float2 p, float jitter, float phase) {
    float2 cell = floor(p), f = fract(p);
    float first = 8, second = 8; float2 winner = 0;
    for (int y = -1; y <= 1; ++y) for (int x = -1; x <= 1; ++x) {
        float2 g = float2(x, y), seed = hash22(cell + g);
        float2 site = g + .5 + jitter * .5 * sin(phase + seed * TAU);
        float d = length(site - f);
        if (d < first) { second = first; first = d; winner = cell + g; } else second = min(second, d);
    }
    return float4(first, second, winner);
}

// ---------------------------------------------------------------- geometry
float2 rot(float2 p, float a) { float c = cos(a), s = sin(a); return float2(c * p.x - s * p.y, s * p.x + c * p.y); }
float smin(float a, float b, float k) { float h = clamp(.5 + .5 * (b - a) / k, 0.f, 1.f); return mix(b, a, h) - k * h * (1 - h); }
float smax(float a, float b, float k) { return -smin(-a, -b, k); }
float sdBox(float3 p, float3 b) { float3 q = abs(p) - b; return length(max(q, 0.f)) + min(max(q.x, max(q.y, q.z)), 0.f); }
float sdBox2(float2 p, float2 b) { float2 q = abs(p) - b; return length(max(q, 0.f)) + min(max(q.x, q.y), 0.f); }
float sdTorus(float3 p, float2 t) { return length(float2(length(p.xz) - t.x, p.y)) - t.y; }
float sdCapsule(float3 p, float3 a, float3 b, float r) { float3 pa = p - a, ba = b - a; float h = clamp(dot(pa, ba) / dot(ba, ba), 0.f, 1.f); return length(pa - ba * h) - r; }
float sdSegment(float2 p, float2 a, float2 b) { float2 pa = p - a, ba = b - a; float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6f), 0.f, 1.f); return length(pa - ba * h); }
float sdHex(float2 p, float r) { const float3 k = float3(-.8660254, .5, .57735); p = abs(p); p -= 2 * min(dot(k.xy, p), 0.f) * k.xy; p -= float2(clamp(p.x, -k.z * r, k.z * r), r); return length(p) * sign(p.y); }
// Hexagonal tiling: xy = local offset, zw = cell id.
float4 hexCell(float2 p) {
    const float2 s = float2(1, 1.7320508);
    float2 a = p - s * floor(p / s + .5), b = p - s * (floor((p - s * .5) / s + .5) + .5);
    return dot(a, a) < dot(b, b) ? float4(a, round(p / s)) : float4(b, round((p - s * .5) / s) + .5);
}
// Repeat with a stable cell index.
float repeatId(float x, float period) { return floor(x / period + .5); }

// ---------------------------------------------------------------- shading
float3 paint(float phase, constant NativeFrame &f) {
    float cycle = phase - floor(phase * .5) * 2;
    float x = (cycle < 1 ? cycle : 2 - cycle) * 4;
    int i = min(3, int(x));
    return mix(f.colors[i].rgb, f.colors[i + 1].rgb, x - float(i));
}
float3 deep(float phase, constant NativeFrame &f) { return paint(phase, f) * paint(phase + .5, f); }
float glow(float d, float width) { return width * width / (width * width + d * d); }
float line(float d, float width, float px) { return 1 - smoothstep(width - px, width + px, abs(d)); }
float fill(float d, float px) { return 1 - smoothstep(-px, px, d); }
float3 hsvTint(float3 color, float amount) { float l = dot(color, float3(.299, .587, .114)); return mix(float3(l), color, amount); }
// Thin-film interference tint, used for soap, oil and opal colors; blended with the palette.
float3 filmColor(float thickness, constant NativeFrame &f) {
    float3 rainbow = .5 + .5 * cos(TAU * (thickness + float3(0, .33, .67)));
    return mix(paint(thickness, f), rainbow * paint(thickness * .5 + .2, f) * 2, .45);
}

// ---------------------------------------------------------------- raymarch helpers
float3 cameraRay(float2 uv, float3 forward, float3 up, float lens) {
    float3 w = normalize(forward), u = normalize(cross(up, w)), v = cross(w, u);
    return normalize(uv.x * u + uv.y * v + lens * w);
}
// Slot k (back to front) of a forward-moving stack of n layers. x = phase (0 far, 1 at
// the viewer), y = a stable layer id that survives the wrap, so layers never pop.
float2 layerSlot(int k, int n, float travel) {
    float shift = travel * float(n);
    return float2((float(k) + fract(shift)) / float(n), float(k) - floor(shift));
}
float layerFade(float phase) { return smoothstep(0.f, .22f, phase) * (1 - smoothstep(.8f, 1.f, phase)); }
// Magnification for a layer: far layers are small and dense, near layers large.
float layerScale(float phase, float range) { return exp2((1 - phase) * range); }
// Seamless scale-space zoom for self-similar patterns: two octaves crossfade at weight 0.
float2 octaveZoom(float travel, int octave) {
    float z = fract(travel);
    float weight = octave == 0 ? 1 - smoothstep(0.f, 1.f, z) : smoothstep(0.f, 1.f, z);
    return float2(exp2(float(octave) - z), weight);
}
// Oblique camera over a ground plane; the horizon sits above the canvas so the plane
// fills every aspect ratio. Returns ground x, forward distance and view distance.
float3 groundView(float2 uv, float2 extent, float height, float margin) {
    float horizon = extent.y + margin;
    float depth = height / max(horizon - uv.y, 1e-3f);
    return float3(uv.x * depth, depth, depth * length(float2(1, uv.x)));
}

// ---------------------------------------------------------------- context / output
Ctx makeContext(float2 position, constant NativeFrame &f) {
    Ctx c;
    float2 res = max(f.resolution, float2(1));
    float shortSide = min(res.x, res.y);
    c.screen = position / res;
    c.extent = res / shortSide;
    float2 uv = (position - res * .5) / (shortSide * .5);
    uv.y = -uv.y;
    float zoom = clamp(f.style.w, .3f, 2.f);
    c.uv = rot(uv, f.camera.x) / zoom;
    c.extent /= zoom;
    c.px = 2 / (shortSide * zoom);
    c.travel = f.motion.x;
    c.m = f.motion.y;
    // Integrate measured percussion energy; never multiply absolute time by a
    // changing amplitude, which would jump or reverse the animation on each beat.
    c.t = f.motion.z + c.m * 3;
    c.e = clamp(f.motion.w, 0.f, 1.5f);
    c.hit = clamp(f.rhythm.x, 0.f, 1.f);
    c.b = clamp(f.bands, 0.f, 1.f);
    c.size = sqrt(clamp(f.style.y, .3f, 6.f));
    c.fog = clamp(f.style.z, 0.f, 1.f);
    c.detail = clamp(f.camera.z, 0.f, 1.f);
    return c;
}

// Music moves each design's elements, never the picture as a whole. Every design gets one of
// three motion styles for its family, so neighbouring designs move differently:
//   tunnels  0 wobble (the tube flexes in lobes that roll around it)
//            1 twist  (rings at different depths turn, so lines wind into spirals; all of 310–319)
//            2 ripple (rings wave in and out as waves run down the bore)
//   flights  0 slither (lanes bend sideways in an S that runs toward the viewer)
//            1 swell   (the ground rolls in waves across the lanes)
//            2 churn   (turbulent ground)
//   fields   0 eddies, 1 rolling waves, 2 liquid flow
// The attack swell keeps each beat moving for about a quarter second and the music's momentum
// keeps everything moving between beats. All of it is zero at zero Chaos or in silence; higher
// Chaos also raises the gain, so the slider reads as "more chaotic", not just "louder".
// Second versions (370–390) move exactly like the designs they come from.
constant short secondVersionSources[20] = {336, 337, 339, 340, 341, 342, 343, 345, 346, 347, 348, 349, 351, 352, 353, 354, 355, 357, 358, 359};
Ctx rhythmicSurface(Ctx c, constant NativeFrame &f) {
    int scene = f.scene >= 370 && f.scene <= 389 ? int(secondVersionSources[f.scene - 370]) : f.scene;
    float variant = float((scene - 100) % 7);
    // Material-lined tunnels (310–319) twist: their fine weaves and scales read best turning,
    // and the encoder keeps their detail; everything else spreads across the three styles.
    int style = scene >= 310 && scene <= 319 ? 1 : scene % 3;
    float2 p = c.uv;
    float chaos = clamp(f.camera.y, 0.f, 1.f);
    float gain = .55 + chaos;
    float beat = min(1.f, c.hit * .7 + clamp(f.rhythm.z, 0.f, 1.f) * .6);
    float energy = c.e;
    float bass = c.b.x, body = c.b.y, fine = .5 * (c.b.z + c.b.w);
    // Slow turbulence shared by every style; its strength follows the music's energy.
    float2 drift = curl2(p * 1.4 + float2(c.t * .05, -c.t * .04) + variant) * .3;
    bool tunnel = (scene >= 245 && scene <= 279) || (scene >= 300 && scene <= 319) || (scene >= 360 && scene <= 369);
    bool drive = (scene >= 200 && scene <= 209) || (scene >= 220 && scene <= 244) || (scene >= 330 && scene <= 339);
    if (tunnel) {
        float r = length(p), a = atan2(p.y, p.x);
        float depth = log(max(r, 1e-3f));
        float reach = smoothstep(.04f, .35f, r);
        float2 radial = p / max(r, 1e-5f);
        float push = 0, turn = 0;
        if (style == 0) {
            push = (beat * .5 + bass * .16 + energy * .1) * sin(a * (3 + variant) + depth * 2 - c.t * .45);
        } else if (style == 1) {
            turn = (beat * 1.1 + bass * .32 + energy * .25) * sin(depth * (3.5 + variant * .4) + beat * 6 - c.t * .4);
        } else {
            push = (beat * .32 + bass * .14 + energy * .08) * sin(depth * 6 - c.t * 1.6 + variant);
            turn = body * .2 * sin(a * 3 - depth * 4 + c.t * .5);
        }
        turn += (body * .16 + fine * .1) * sin(a * 4 - depth * 6 + c.t * .6);
        float2 q = rot(p, turn * gain * reach);
        q += radial * push * gain * r / (1 + r);
        c.uv = q + drift * energy * gain * .35 * reach;
    } else if (drive) {
        float lane = p.x * (2.4 + variant * .2);
        if (style == 0) {
            c.uv.x += (beat * .24 + bass * .1 + energy * .06) * gain * sin(p.y * 4 + beat * 6 + c.t * .5 + variant);
        } else if (style == 1) {
            c.uv.y += (beat * .2 + bass * .1 + energy * .05) * gain * sin(lane + p.y * 3 - c.t * .5);
        } else {
            c.uv += drift * (beat * .35 + bass * .12 + energy * .1) * gain;
        }
        c.uv.x += (body * .1 + fine * .1) * gain * sin(p.y * 5 + lane * .5 + c.t * .4);
        c.uv += drift * energy * gain * .25;
    } else {
        if (style == 0) {
            float2 q = p * (1.2 + variant * .1) + float2(c.t * .06, -c.t * .045);
            c.uv += curl2(q) * .45 * (beat * .55 + bass * .18 + body * .12 + energy * .1) * gain;
        } else if (style == 1) {
            float2 wave = float2(sin(p.y * (3.2 + variant * .2) + p.x * 1.7 + c.t * .6),
                                 cos(p.x * (3.8 + variant * .2) - p.y * 2.1 - c.t * .5));
            c.uv += wave * float2(beat * .3 + bass * .12 + energy * .05, beat * .22 + body * .16 + energy * .05) * gain;
        } else {
            float2 flow = float2(fbm2(p * 1.3 + c.t * .08, 3), fbm2(p * 1.3 + 5.2 - c.t * .07, 3)) - .5;
            c.uv += flow * (beat * .5 + bass * .2 + body * .14 + energy * .15) * gain;
        }
        c.uv += fine * .055 * gain * float2(sin(p.y * 13 - c.t), cos(p.x * 11 + c.t));
        c.uv += drift * energy * gain * .3;
    }
    return c;
}
float4 finish(float3 color, float2 position, constant NativeFrame &f) {
    color = max(color, float3(0)) * max(0.f, f.style.x);
    color = 1 - exp(-color * 1.55);
    // Static ordered dither keeps smooth gradients from banding in 8-bit video.
    float dither = (hash21(floor(position)) - .5) / 255;
    return float4(saturate(color + dither), 1);
}

// Each effect is `float3 name(Ctx c, constant NativeFrame &f)`; this emits its fragment.
#define NATIVE_EFFECT(name) \
fragment float4 name##Fragment(float4 position [[position]], constant NativeFrame &f [[buffer(0)]]) { \
    Ctx c = rhythmicSurface(makeContext(position.xy, f), f); \
    return finish(name(c, f), position.xy, f); \
}

vertex float4 nativeVertex(uint id [[vertex_id]]) {
    const float2 p[3] = {float2(-1, -1), float2(3, -1), float2(-1, 3)};
    return float4(p[id], 0, 1);
}
