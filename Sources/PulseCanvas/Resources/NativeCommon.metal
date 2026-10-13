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
    float4 rhythm;   // attack swell, drive, low and high levels (Chaos-scaled)
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
    float t;        // procedural time (speed-scaled, never audio-driven)
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
float hash11(float p) { p = fract(p * .1031); p *= p + 33.33; p *= p + p; return fract(p); }
float hash21(float2 p) { float3 q = fract(float3(p.xyx) * .1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float2 hash22(float2 p) { float3 q = fract(float3(p.xyx) * float3(.1031, .1030, .0973)); q += dot(q, q.yzx + 33.33); return fract((q.xx + q.yz) * q.zy); }
float3 hash33(float3 p) { p = fract(p * float3(.1031, .1030, .0973)); p += dot(p, p.yxz + 33.33); return fract((p.xxy + p.yxx) * p.zyx); }
float hash31(float3 p) { p = fract(p * .1031); p += dot(p, p.zyx + 31.32); return fract((p.x + p.y) * p.z); }

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
    c.t = f.motion.z;
    c.e = clamp(f.motion.w, 0.f, 1.5f);
    c.hit = clamp(f.rhythm.x, 0.f, 1.f);
    c.b = clamp(f.bands, 0.f, 1.f);
    c.size = sqrt(clamp(f.style.y, .3f, 6.f));
    c.fog = clamp(f.style.z, 0.f, 1.f);
    c.detail = clamp(f.camera.z, 0.f, 1.f);
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
    Ctx c = makeContext(position.xy, f); \
    return finish(name(c, f), position.xy, f); \
}

vertex float4 nativeVertex(uint id [[vertex_id]]) {
    const float2 p[3] = {float2(-1, -1), float2(3, -1), float2(-1, 3)};
    return float4(p[id], 0, 1);
}
