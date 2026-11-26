#include <metal_stdlib>
using namespace metal;

struct StudyFrame {
    float phase;
    float beat;
    float travel;
    float scale;
    float fog;
};

constant float studyTurn = 6.28318530718f;

constant float flightLength = 16.0f;

static float repeatDepth(float depth, float period) {
    return depth - floor(depth / period) * period;
}

static float lattice(float3 cell) {
    cell = fract(cell * 0.1031f);
    cell += dot(cell, cell.yzx + 33.33f);
    return fract((cell.x + cell.y) * cell.z);
}

static float noise3D(float3 position, float depthCells) {
    float3 cell = floor(position);
    float3 blend = fract(position);
    blend = blend * blend * (3.0f - 2.0f * blend);

    cell.z = repeatDepth(cell.z, depthCells);
    float3 farCell = float3(cell.xy, repeatDepth(cell.z + 1.0f, depthCells));
    float nearLayer = mix(
        mix(lattice(cell), lattice(cell + float3(1, 0, 0)), blend.x),
        mix(lattice(cell + float3(0, 1, 0)), lattice(cell + float3(1, 1, 0)), blend.x),
        blend.y
    );
    float farLayer = mix(
        mix(lattice(farCell), lattice(farCell + float3(1, 0, 0)), blend.x),
        mix(lattice(farCell + float3(0, 1, 0)), lattice(farCell + float3(1, 1, 0)), blend.x),
        blend.y
    );
    return mix(nearLayer, farLayer, blend.z);
}

// Overlapping randomized spheres form round lobes before finer noise erodes
// them. Radii plus center jitter stay below one cell, so eight nodes suffice.
static float billowField(float3 position, float depthCells) {
    float3 cell = floor(position);
    float3 local = fract(position);
    float surface = -0.13f;
    for (uint corner = 0; corner < 8; ++corner) {
        float3 offset = float3(corner & 1, (corner >> 1) & 1, corner >> 2);
        float3 node = cell + offset;
        node.z = repeatDepth(node.z, depthCells);
        float3 random = float3(lattice(node), lattice(node + 13.1f), lattice(node - 17.4f));
        float3 displacement = local - offset - (random - 0.5f) * 0.26f;
        float radius = 0.58f + 0.19f * random.z;
        float lobe = radius * radius - dot(displacement, displacement);
        float join = max(0.09f - abs(lobe - surface), 0.0f);
        float blend = smoothstep(-0.10f, -0.04f, min(lobe, surface));
        surface = max(surface, lobe) + join * join * 2.78f * blend;
    }
    return surface;
}

static float seam(float depth) {
    float turn = depth * (studyTurn / flightLength);
    return 0.24f * sin(turn) + 0.13f * sin(turn * 2.0f - 0.7f);
}

// The camera passes the same world-space filaments as it passes the billows.
static float emberSeam(float3 point, float arcDepth, float phase, float beat) {
    float height = point.y;
    float depth = 0.30f * sin(height * 1.9f);
    float center = seam(point.z) + height * 0.54f - 0.43f
        + (noise3D(float3(height * 4.0f, 2.0f, 1.0f), 16.0f) - 0.5f) * 0.44f
        + (noise3D(float3(height * 13.0f, 7.0f, 4.0f), 16.0f) - 0.5f) * 0.14f;
    float2 offset = float2((point.x - center) * 31.0f, (arcDepth - depth) * 6.0f);
    float mask = smoothstep(-1.65f, -1.18f, height) * (1.0f - smoothstep(0.52f, 1.26f, height));
    float sweep = 0.23f + 0.77f * pow(0.5f + 0.5f * cos(height * 3.8f - phase * 5.0f), 3.0f);
    return exp(-dot(offset, offset)) * mask * sweep * (0.25f + 1.4f * beat);
}

// Each octave spans an integer number of cells along the flight. Sampling
// one flight length later therefore returns the same world-space density.
static float smokeDensity(float3 point, bool fine) {
    float turn = point.z * (studyTurn / flightLength);
    float across = dot(point.xy, float2(0.86f, -0.51f)) - seam(point.z);
    float along = dot(point.xy, float2(0.51f, 0.86f));
    float width = 1.07f + 0.16f * sin(turn * 3.0f + 0.3f);
    float shoulder = length(float2(across, along * 0.46f)) - width;
    float billows = billowField(point * 1.3125f + float3(2.0f, 4.1f, 7.3f), 21.0f);
    float body = noise3D(point * 0.9375f, 15.0f) - 0.48f;
    float volume = clamp(shoulder, -1.8f, 0.75f) * 0.76f
        + billows * 1.42f + body * 0.64f - 0.39f;
    if (volume > -0.30f) {
        float curls = noise3D(point * 4.125f + 2.7f, 66.0f);
        float folds = noise3D(point * 9.1875f - 4.3f, 147.0f);
        volume += (curls - 0.51f) * 0.40f + (folds - 0.53f) * 0.22f;
        if (fine) {
            volume += (noise3D(point * 18.0f + 8.2f, 288.0f) - 0.53f) * 0.12f;
        }
    }
    return smoothstep(-0.06f, 0.29f, volume) * 6.2f;
}

static float4 backlitRiftColor(float2 viewport, uint2 pixel, StudyFrame frame) {
    viewport /= frame.scale;
    float phase = frame.phase;
    float3 eye = float3(0.0f, 0.0f, 1.75f + frame.travel * (flightLength / studyTurn));
    float3 ray = normalize(float3(viewport * 0.46f + float2(0.0f, -0.05f), 1.0f));
    float3 lamp = float3(-0.55f, 0.96f, 7.1f);
    float3 shadow = float3(0.005f, 0.020f, 0.030f);
    float3 mint = float3(0.13f, 0.81f, 0.53f);
    float3 copper = float3(1.0f, 0.54f, 0.15f);
    float transmission = 1.0f;
    float3 color = float3(0.0f);
    const int steps = 144;
    float depthStep = 11.8f / float(steps);
    float jitter = mix(0.14f, 0.86f, lattice(float3(float2(pixel), 21.0f)));
    float distanceStep = depthStep / ray.z;

    for (int step = 0; step < steps && transmission > 0.012f; ++step) {
        float depth = (float(step) + jitter) * depthStep;
        float3 fromEye = ray * (depth / ray.z);
        float3 point = eye + fromEye;
        // Feather a billow as it passes the lens and as it enters visibility far ahead.
        float fade = smoothstep(0.32f, 1.45f, depth) * (1.0f - smoothstep(10.0f, 11.8f, depth));
        float density = smokeDensity(point, true) * fade * (0.65f + 0.70f * frame.fog);
        float3 toLamp = lamp - fromEye;
        float distanceSquared = dot(toLamp, toLamp);

        float channel = point.x - 0.64f * point.y - seam(point.z);
        float haze = exp(-abs(channel) * 1.26f) * exp(-distanceSquared * 0.40f);
        float core = exp(-distanceSquared * 1.25f);
        color += transmission * haze * distanceStep
            * (float3(0.09f, 0.43f, 0.39f) + float3(1.18f, 1.29f, 1.02f) * core);
        float arcDepth = repeatDepth(point.z - 1.5f, flightLength * 0.5f) - flightLength * 0.25f;
        if (abs(arcDepth) < 0.85f && point.y > -1.65f && point.y < 1.26f) {
            float arcFade = smoothstep(1.0f, 2.75f, depth) * fade;
            color += transmission * distanceStep * copper * arcFade * emberSeam(point, arcDepth, phase, frame.beat);
        }

        if (density < 0.008f) {
            continue;
        }
        float3 lightDirection = toLamp * rsqrt(max(distanceSquared, 0.002f));
        float nearDensity = smokeDensity(point + lightDirection * 0.13f, false);
        float middleDensity = smokeDensity(point + lightDirection * 0.39f, false);
        float farDensity = smokeDensity(point + lightDirection * 0.85f, false);
        float opticalDepth = density * 0.09f + nearDensity * 0.18f
            + middleDensity * 0.34f + farDensity * 0.55f;
        float light = exp(-opticalDepth);
        float scatter = 0.28f + 0.72f * exp(-distanceSquared * 0.052f);
        float forward = pow(max(dot(ray, lightDirection), 0.0f), 5.0f);

        float rim = saturate((density - nearDensity) * 0.52f);
        float3 fill = float3(0.015f, 0.14f, 0.17f) * exp(-density * 0.37f);
        float3 radiance = shadow + fill + mint * light * scatter * (0.61f + 0.80f * forward + 1.1f * rim);
        float glint = exp(-distanceSquared * 0.12f) * light * (0.28f + 1.53f * rim);
        float3 beatOffset = -toLamp + float3(0.40f, 0.10f, 1.0f);
        float localBeat = frame.beat * exp(-dot(beatOffset, beatOffset) * 1.5f);
        radiance += copper * glint * (1.24f + 1.0f * localBeat);

        float opacity = 1.0f - exp(-density * distanceStep);
        color += transmission * opacity * radiance;
        transmission *= 1.0f - opacity;
    }

    float2 skyOffset = viewport - float2(-0.07f, 0.26f);
    float sky = exp(-dot(skyOffset, skyOffset) * 2.1f);
    color += transmission * mix(shadow, float3(0.034f, 0.14f, 0.14f), sky);
    color *= mix(1.0f, 0.70f, smoothstep(0.55f, 1.9f, length(viewport)));
    color = 1.0f - exp(-color * 1.66f);
    color = pow(saturate(color), float3(0.73f));
    return float4(color, 1.0f);
}

static float hash3(float3 p) {
    p = fract(p * float3(0.1031f, 0.1030f, 0.0973f));
    p += dot(p, p.yxz + 33.33f);
    return fract((p.x + p.y) * p.z);
}

static float studyNoise3(float3 p, float repeatZ = 0.0f) {
    float3 cell = floor(p);
    float3 f = fract(p);
    f = f * f * (3.0f - 2.0f * f);
    float3 farCell = cell + float3(0, 0, 1);
    if (repeatZ > 0.0f) {
        cell.z -= floor(cell.z / repeatZ) * repeatZ;
        farCell.z -= floor(farCell.z / repeatZ) * repeatZ;
    }
    float a = mix(
        mix(hash3(cell), hash3(cell + float3(1, 0, 0)), f.x),
        mix(hash3(cell + float3(0, 1, 0)), hash3(cell + float3(1, 1, 0)), f.x), f.y
    );
    float b = mix(
        mix(hash3(farCell), hash3(farCell + float3(1, 0, 0)), f.x),
        mix(hash3(farCell + float3(0, 1, 0)), hash3(farCell + float3(1, 1, 0)), f.x), f.y
    );
    return mix(a, b, f.z);
}


static float4 displayColor(float3 color, uint2 pixel) {
    float grain = (hash3(float3(float2(pixel), 19.0f)) - 0.5f) / 255.0f;
    float3 mapped = pow(saturate(1.0f - exp(-max(color, 0.0f))), float3(0.62f));
    return float4(mapped + grain, 1.0f);
}

// Undersurface. A camera below a moving height field sees transmitted light
// within Snell's window, with internal reflection at more grazing angles.
static float waterLevel(float2 p, float t) {
    return 0.13f * sin(dot(p, float2(1.7f, 2.2f)) - t)
        + 0.085f * sin(dot(p, float2(-2.5f, 1.3f)) + t)
        + 0.048f * sin(dot(p, float2(4.9f, -2.8f)) + 2.0f * t)
        + 0.023f * sin(dot(p, float2(8.0f, 5.2f)) - 3.0f * t)
        + 0.009f * sin(dot(p, float2(-13.0f, 8.1f)) + 4.0f * t);
}

static float3 waterNormal(float2 p, float t) {
    const float e = 0.016f;
    float height = waterLevel(p, t);
    float2 slope = float2(waterLevel(p + float2(e, 0), t), waterLevel(p + float2(0, e), t)) - height;
    return normalize(float3(-slope.x, e, -slope.y));
}

static float surfaceDistance(float3 eye, float3 ray, float phase) {
    float lo = 0.0f;
    float hi = min((-eye.y + 0.31f) / max(ray.y, 0.001f), 30.0f);
    if (eye.y + ray.y * hi < -0.30f) {
        return 30.0f;
    }
    // Find the first interface even where a shallow ray crosses several waves.
    const uint steps = 40;
    float stepSize = hi / float(steps);
    for (uint i = 1; i <= steps; ++i) {
        float distance = float(i) * stepSize;
        float3 point = eye + ray * distance;
        if (point.y >= waterLevel(point.xz, phase)) {
            hi = distance;
            for (uint refine = 0; refine < 5; ++refine) {
                float middle = 0.5f * (lo + hi);
                float3 samplePoint = eye + ray * middle;
                if (samplePoint.y > waterLevel(samplePoint.xz, phase)) {
                    hi = middle;
                } else {
                    lo = middle;
                }
            }
            return hi;
        }
        lo = distance;
    }
    return 30.0f;
}

static float underwaterSilt(float3 eye, float3 ray, float distance, float phase) {
    float particles = 0.0f;
    for (int layer = 1; layer <= 11; ++layer) {
        float depth = 0.65f + float(layer) * 0.68f;
        if (depth > distance) {
            break;
        }
        float3 point = eye + depth * ray;
        float2 grid = point.xy * 4.0f + float2(0.22f * sin(phase), -0.21f * cos(phase + float(layer)));
        float2 cell = floor(grid);
        float3 seed = float3(cell, float(layer));
        float2 center = 0.18f + 0.64f * float2(hash3(seed), hash3(seed + 11.3f));
        float2 delta = fract(grid) - center;
        float size = 0.027f + 0.036f * hash3(seed + 17.0f);
        float brightness = pow(hash3(seed + 25.4f), 2.0f);
        particles += exp(-dot(delta, delta) / (size * size)) * exp(-0.16f * depth) * brightness;
    }
    return particles;
}

static float4 undersurfaceColor(float2 uv, uint2 pixel, StudyFrame frame) {
    float phase = frame.phase;
    float3 eye = float3(0.29f * sin(phase), (-1.36f + 0.10f * cos(phase)) * frame.scale, 0.23f * cos(phase));
    float3 ray = normalize(float3(uv.x * 0.68f, 0.72f + uv.y * 0.91f, 1.0f));
    float3 sun = normalize(float3(-0.55f, 0.45f, 0.78f));
    float distance = surfaceDistance(eye, ray, phase);
    float3 color = float3(0.005f, 0.015f, 0.060f) + float3(0.01f, 0.065f, 0.19f) * smoothstep(-0.2f, 0.9f, ray.y);
    if (distance < 29.9f) {
        float3 hit = eye + ray * distance;
        float3 normal = waterNormal(hit.xz, phase);
        float3 airRay = refract(ray, -normal, 1.333f);
        float transmission = smoothstep(0.0f, 0.45f, airRay.y);
        float sunlight = pow(max(dot(airRay, sun), 0.0f), 9.0f);
        float glint = pow(max(dot(airRay, sun), 0.0f), 90.0f);
        float3 waterTint = exp(-distance * float3(0.39f, 0.23f, 0.12f));
        float3 sky = float3(0.055f, 0.18f, 0.43f) + float3(3.3f, 2.4f, 1.30f) * sunlight
            + float3(4.6f, 3.9f, 2.7f) * glint;
        float2 bent = hit.xz * float2(3.3f, 4.2f) + normal.xz * 5.5f;
        float laceA = abs(sin(bent.x + 1.1f * sin(bent.y + phase)));
        float laceB = abs(sin(bent.y + 1.4f * sin(bent.x - phase)));
        float shimmer = exp(-min(laceA, laceB) * 7.0f) * exp(-distance * 0.47f);
        float2 pool = hit.xz - float2(-0.57f, 1.18f);
        float poolLight = exp(-dot(pool, pool) * 0.88f);
        float reflectedSun = pow(max(dot(reflect(ray, -normal), float3(-0.55f, -0.42f, 0.72f)), 0.0f), 28.0f);
        float3 reflection = float3(0.014f, 0.075f, 0.25f) + reflectedSun * float3(0.32f, 0.42f, 0.63f);
        color += waterTint * mix(reflection, sky, transmission)
            + shimmer * float3(0.61f, 0.78f, 1.12f) * (0.055f + 0.75f * poolLight);
    }
    float fan = 0.0f;
    float reach = min(distance, 8.0f);
    for (uint step = 0; step < 18; ++step) {
        float3 point = eye + ray * (float(step) + 0.5f) * (reach / 18.0f);
        float2 cast = point.xz - sun.xz * (point.y / sun.y);
        float angle = 5.3f * cast.x + 1.4f * cast.y + 2.1f * sin(cast.y * 1.6f + phase);
        float light = pow(0.5f + 0.5f * cos(angle), 7.0f + 3.0f * frame.beat);
        float2 pool = cast - float2(-0.57f, 1.18f);
        float spread = exp(-dot(pool, pool) * 0.26f);
        fan += light * spread * exp(point.y * 0.44f);
    }
    color += fan * (reach / 18.0f) * float3(0.10f, 0.17f, 0.28f) * (0.65f + 0.70f * frame.fog);
    color += underwaterSilt(eye, ray, distance, phase) * float3(0.038f, 0.081f, 0.13f);
    return displayColor(color, pixel);
}

// Mercury Fold. A narrow twisted band collects into larger bulbs, with
// separate beads shaped by the same lighting as the main mass.
static float softUnion(float a, float b, float width) {
    float h = max(width - abs(a - b), 0.0f) / width;
    return min(a, b) - h * h * width * 0.25f;
}

static float mercuryShape(float3 p, float phase) {
    float y = clamp(p.y, -1.0f, 1.0f);
    float center = 0.37f * sin(y * 2.25f - 0.4f)
        + 0.12f * sin(phase + y * 3.1f);
    float depth = 0.22f * sin(y * 3.0f + phase);
    float2 q = float2(p.x - center, p.z - depth);
    float angle = 1.52f * y + 0.44f * sin(phase - y);
    float2 band = float2(dot(q, float2(cos(angle), sin(angle))), dot(q, float2(-sin(angle), cos(angle))));
    float width = 0.35f + 0.16f * cos(3.5f * y - phase);
    width *= 1.0f - 0.53f * pow(abs(y), 4.0f);
    float2 edge = abs(band) - float2(width, 0.039f + 0.024f * cos(4.0f * y + phase));
    float ribbon = length(max(edge, 0.0f)) + min(max(edge.x, edge.y), 0.0f) - 0.084f;
    float2 ends = float2(ribbon + 0.055f, abs(p.y) - 0.95f);
    ribbon = length(max(ends, 0.0f)) + min(max(ends.x, ends.y), 0.0f) - 0.055f;
    float3 bulb = float3(0.27f + 0.15f * cos(phase), 0.34f + 0.16f * sin(phase), 0.13f);
    float shape = softUnion(ribbon, length((p - bulb) * float3(0.90f, 1.2f, 1.0f)) - 0.29f, 0.26f);
    float3 lower = float3(-0.37f, -0.72f, -0.13f + 0.14f * sin(phase));
    shape = softUnion(shape, length(p - lower) - 0.21f, 0.19f);
    for (uint i = 0; i < 6; ++i) {
        float turn = phase + 1.83f * float(i);
        float side = i % 2 == 0 ? -1.0f : 1.0f;
        float3 drop = float3(side * (0.67f + float(i) * 0.061f) + 0.08f * cos(turn),
                             -0.82f + float(i) * 0.31f + 0.11f * sin(turn),
                             0.27f * cos(turn));
        shape = min(shape, length(p - drop) - (0.045f + 0.027f * (0.5f + 0.5f * sin(turn))));
    }
    float ripples = sin(p.y * 23.0f - phase * 2.0f + 3.6f * p.x) * sin(p.x * 13.0f + p.z * 8.0f);
    return shape + ripples * 0.012f;
}

static float3 studioReflection(float3 ray) {
    float whiteStrip = exp(-pow((ray.x + 0.53f) * 7.5f, 2.0f)) * smoothstep(-0.55f, 0.22f, ray.y);
    float softBox = pow(max(dot(ray, normalize(float3(0.29f, 0.85f, -0.43f))), 0.0f), 13.0f);
    float amber = exp(-pow((ray.y + 0.38f + 0.18f * ray.x) * 7.5f, 2.0f)) * smoothstep(-0.2f, 0.77f, ray.x);
    float blue = pow(max(dot(ray, normalize(float3(0.84f, 0.25f, 0.23f))), 0.0f), 14.0f);
    return float3(0.008f, 0.012f, 0.025f) + whiteStrip * float3(1.6f, 1.85f, 2.0f)
        + softBox * float3(1.35f, 1.2f, 1.04f) + amber * float3(2.25f, 0.76f, 0.25f)
        + blue * float3(0.12f, 0.23f, 0.46f);
}

static float4 mercuryFoldColor(float2 uv, uint2 pixel, StudyFrame frame) {
    float phase = frame.phase;
    float azimuth = 0.21f * sin(phase);
    float3 eye = float3(3.6f * sin(azimuth), 0.15f + 0.19f * cos(phase), -3.6f * cos(azimuth));
    float3 forward = normalize(-eye);
    float3 right = normalize(cross(float3(0, 1, 0), forward));
    float3 up = cross(forward, right);
    float3 ray = normalize(forward + (0.34f / frame.scale) * (right * (uv.x + 0.13f) + up * uv.y));
    float tilt = -0.32f;
    float2 axisX = float2(cos(tilt), sin(tilt));
    float2 axisY = float2(-sin(tilt), cos(tilt));
    float3 eyeLocal = float3(dot(eye.xy, axisX), dot(eye.xy, axisY), eye.z);
    float3 rayLocal = float3(dot(ray.xy, axisX), dot(ray.xy, axisY), ray.z);
    float at = 2.05f;
    float3 point;
    float distance = 2.0f;
    for (uint step = 0; step < 100 && at < 5.7f; ++step) {
        point = eyeLocal + rayLocal * at;
        distance = mercuryShape(point, phase);
        if (distance < 0.0018f) {
            break;
        }
        at += max(distance * 0.46f, 0.003f);
    }
    float halo = exp(-dot(uv * float2(0.8f, 1.2f), uv * float2(0.8f, 1.2f)) * 1.5f);
    float3 color = float3(0.003f, 0.003f, 0.007f) + halo * float3(0.019f, 0.012f, 0.011f);
    if (distance < 0.0018f) {
        const float e = 0.003f;
        float3 normal = normalize(float3(
            mercuryShape(point + float3(e, 0, 0), phase) - mercuryShape(point - float3(e, 0, 0), phase),
            mercuryShape(point + float3(0, e, 0), phase) - mercuryShape(point - float3(0, e, 0), phase),
            mercuryShape(point + float3(0, 0, e), phase) - mercuryShape(point - float3(0, 0, e), phase)
        ));
        float3 reflected = reflect(rayLocal, normal);
        float rim = pow(1.0f - saturate(dot(-rayLocal, normal)), 3.0f);
        float sheen = 0.72f + 0.24f * sin(point.y * 5.4f - phase + normal.x * 2.6f);
        color = studioReflection(reflected) * sheen + float3(0.20f, 0.08f, 0.035f) * rim
            * (0.54f + 0.24f * frame.beat);
    }
    return displayColor(color, pixel);
}

// Ember Front. Particles live on periodic depth layers. The camera advances
// through the layers and the nearest grains stretch with their screen velocity.
static float4 emberFrontColor(float2 uv, uint2 pixel, StudyFrame frame) {
    float phase = frame.phase;
    float travel = 24.0f * frame.travel / studyTurn;
    float3 ray = normalize(float3(uv * 0.57f, 1.0f));
    float ridge = 0.40f + uv.y * 0.29f + 0.11f * sin(uv.y * 3.1f + phase);
    float cloud = exp(-abs(uv.x - ridge) * 2.1f);
    float smoke = studyNoise3(float3(uv * 1.75f + float2(cos(phase), sin(phase)) * 0.46f, 7.6f));
    float3 color = float3(0.006f, 0.004f, 0.009f) +
        cloud * (0.26f + 0.74f * smoke) * float3(0.15f, 0.031f, 0.012f);
    const float layerSpacing = 0.67f;

    for (int i = 0; i < 28; ++i) {
        float layer = floor(travel) + float(i);
        float z = (layer - travel) * layerSpacing;
        if (z < 0.45f) {
            continue;
        }
        float seed = layer - floor(layer / 24.0f) * 24.0f;
        float2 position = ray.xy * (z / ray.z);
        float curl = sin(seed * (studyTurn / 24.0f) + position.y * 0.66f);
        float shift = 1.07f * curl + 0.25f * sin(2.0f * phase + position.y * 1.1f);
        float2 currentPoint = float2(position.x - shift - 0.30f * position.y, position.y);
        // Rotate each layer's lattice in its own plane so rows of particles in
        // different depth layers cannot line up into horizontal seams.
        float rotation = studyTurn * hash3(float3(seed, 14.9f, 8.7f));
        float2 axisX = float2(cos(rotation), sin(rotation));
        float2 axisY = float2(-axisX.y, axisX.x);
        float2 grid = float2(dot(currentPoint, axisX), dot(currentPoint, axisY)) * 4.8f;
        float2 base = floor(grid);
        float3 sampleSeed = float3(base, seed);
        float2 center = 0.29f + 0.42f * float2(hash3(sampleSeed), hash3(sampleSeed + 19.27f));
        float2 delta = fract(grid) - center;
        float random = hash3(sampleSeed + 7.36f);
        float2 cellPoint = (axisX * (base.x + center.x) + axisY * (base.y + center.y)) / 4.8f;
        float front = 0.26f + 0.42f * sin(seed * (studyTurn / 12.0f));
        float current = cellPoint.x - front;
        float veil = smoothstep(-0.60f, 0.63f, current) * (1.0f - 0.55f * smoothstep(1.5f, 3.5f, current));
        float pockets = studyNoise3(float3(cellPoint, seed * 0.25f), 6.0f);
        float occupancy = 0.032f + 0.64f * veil * smoothstep(0.20f, 0.75f, pockets);
        if (random > occupancy) {
            continue;
        }
        float brightness = hash3(sampleSeed + 37.0f);
        float2 radial = position + float2(0.002f, -0.002f);
        float2 outward = normalize(float2(dot(radial, axisX), dot(radial, axisY)));
        float2 stroke = float2(dot(delta, outward), dot(delta, float2(-outward.y, outward.x)));
        float width = frame.scale * (0.028f + 0.044f * brightness) * (1.0f + 0.020f * z);
        float length = width * (1.0f + 1.82f * saturate(3.5f / z));
        float footprint = dot(stroke / float2(length, width), stroke / float2(length, width));
        float blast = smoothstep(0.5f, 1.55f, z) * (1.0f - smoothstep(9.0f, 17.5f, z));
        float core = exp(-footprint * 1.25f);
        float glow = exp(-footprint * 0.25f) * 0.21f;
        float3 copper = mix(float3(0.72f, 0.11f, 0.04f), float3(2.4f, 0.86f, 0.19f), brightness * brightness);
        float3 grain = mix(copper, float3(0.18f, 0.27f, 0.63f), smoothstep(0.72f, 0.92f, hash3(sampleSeed + 43.9f)));
        float pulse = 1.0f + 0.6f * frame.beat * smoothstep(0.6f, 1.0f, brightness);
        float falloff = 1.0f - smoothstep(0.17f, 0.29f, max(abs(delta.x), abs(delta.y)));
        color += grain * (core + glow) * blast * pulse * falloff * (0.11f + 0.74f * brightness);
    }
    return displayColor(color, pixel);
}

// Anvil Flyover. A repeating terrain-like cloud deck, seen from above.
// Sampling X in the periodic dimension makes a continuous lateral flight.
static float anvilDensity(float3 p, bool detail) {
    float3 q = p.zyx;
    float large = studyNoise3(q * 0.25f + float3(21.0f, 4.0f, 1.0f), 4.0f);
    float banks = studyNoise3(q * 0.625f + float3(0.0f, 3.0f, 11.1f), 10.0f);
    float tower = smoothstep(0.51f, 0.82f, large);
    float crowns = studyNoise3(q * 0.875f + float3(3.4f, 9.3f, 5.2f), 14.0f);
    float ceiling = -0.48f + banks * 1.33f + tower * (1.69f + 1.30f * crowns);
    const float base = -2.0f;
    float volume = min(ceiling - p.y, p.y - base);
    if (volume > -0.85f && detail) {
        float fleece = studyNoise3(q * 1.5f + 6.0f, 24.0f);
        float grain = studyNoise3(q * 3.75f - 4.4f, 60.0f);
        float billows = studyNoise3(q * 8.0f + 11.3f, 128.0f);
        volume += (fleece - 0.50f) * 1.40f + (grain - 0.53f) * 0.47f + (billows - 0.52f) * 0.19f;
    }
    return smoothstep(-0.23f, 0.28f, volume) * 2.55f;
}

static float4 anvilFlyoverColor(float2 uv, uint2 pixel, StudyFrame frame) {
    float phase = frame.phase;
    float3 eye = float3(2.9f + 16.0f * (frame.travel / studyTurn), 2.62f + 0.31f * sin(phase) + (frame.scale - 1.0f) * 0.58f, 1.8f);
    float3 ray = normalize(float3(0.43f * uv.x + 0.11f, 0.46f * uv.y - 0.21f, 1.0f));
    float3 sun = normalize(float3(0.56f, 0.28f, 0.91f));
    float towardSun = max(dot(ray, sun), 0.0f);
    float horizon = exp(-abs(ray.y + 0.055f) * 5.5f);
    float3 sky = mix(float3(0.041f, 0.039f, 0.15f), float3(0.45f, 0.22f, 0.31f), horizon);
    sky += float3(0.50f, 0.27f, 0.31f) * pow(towardSun, 26.0f);
    sky += float3(0.76f, 0.49f, 0.33f) * pow(towardSun, 260.0f);
    float3 color = float3(0.0f);
    float transmittance = 1.0f;
    const uint steps = 116;
    const float stride = 0.19f;
    float offset = mix(0.12f, 0.88f, hash3(float3(float2(pixel), 3.1f)));
    for (uint step = 0; step < steps && transmittance > 0.015f; ++step) {
        float distance = 0.43f + (float(step) + offset) * stride;
        float3 point = eye + ray * distance;
        if (point.y < -2.45f) {
            break;
        }
        float visibility = smoothstep(0.43f, 1.85f, distance) * (1.0f - smoothstep(17.0f, 22.0f, distance));
        float density = anvilDensity(point, true) * visibility * (0.65f + 0.70f * frame.fog);
        if (density < 0.005f) {
            continue;
        }

        float nearDensity = anvilDensity(point + sun * 0.24f, true);
        float occlusion = density * 0.18f
            + nearDensity * 0.26f
            + anvilDensity(point + sun * 0.65f, true) * 0.53f
            + anvilDensity(point + sun * 1.6f, false) * 0.71f;
        float light = exp(-occlusion);
        float lavender = 0.60f + 0.40f * smoothstep(-0.9f, 1.4f, point.y);
        float fillDensity = anvilDensity(point + float3(-0.29f, 0.23f, -0.37f), true);
        float fill = exp(-fillDensity * 0.94f - density * 0.27f);
        float3 shade = (float3(0.028f, 0.024f, 0.063f) + fill * float3(0.11f, 0.13f, 0.22f)) * lavender;
        float rim = saturate((density - nearDensity) * 1.1f);
        float3 radiance = shade + light * float3(0.98f, 0.85f, 1.06f) * (0.78f + 0.39f * towardSun)
            + rim * light * pow(towardSun, 3.0f) * float3(0.69f, 0.26f, 0.14f);
        float pocket = studyNoise3(point.zyx * 0.5f + 5.1f, 8.0f);
        float discharge = smoothstep(0.68f, 0.83f, pocket) * frame.beat * frame.beat;
        radiance += float3(0.11f, 0.061f, 0.15f) * discharge * (1.0f - light);
        radiance = mix(radiance, sky * 0.87f, smoothstep(12.0f, 26.0f, distance) * 0.66f);
        float opacity = 1.0f - exp(-density * stride);
        color += transmittance * opacity * radiance;
        transmittance *= 1.0f - opacity;
    }
    color += transmittance * sky;
    return displayColor(color, pixel);
}

// Pigment Strata. Inverse advection of horizontal pigment interfaces through
// rotating cells. Heterogeneous angular speeds stretch the edges into filaments.
static float2 pigmentVortex(float2 p, float2 center, float radius, float turn) {
    float2 offset = p - center;
    float weight = (1.0f - smoothstep(0.1f, 1.0f, length(offset) / radius));
    float angle = turn * weight * weight;
    float2 rotated = float2(
        dot(offset, float2(cos(angle), -sin(angle))),
        dot(offset, float2(sin(angle), cos(angle)))
    );
    return center + rotated;
}

static float2 pigmentRow(float2 p, float height, float spacing, float phase, float offset) {
    float tile = floor(p.x / spacing + offset) - offset;
    float2 center = float2((tile + 0.5f) * spacing, height);
    float spin = 2.9f + 0.73f * sin(phase + offset * 4.1f)
        + 0.75f * sin(tile * 1.83f + offset);
    return pigmentVortex(p, center, spacing * 0.49f, spin);
}

static float4 pigmentStrataColor(float2 uv, uint2 pixel, StudyFrame frame) {
    float phase = frame.phase;
    float2 p = uv * float2(1.04f, 1.0f) / frame.scale;
    p.x += 0.25f * sin(phase + p.y * 2.6f);
    p.y += 0.12f * sin(1.7f * p.x + phase) + 0.065f * sin(4.4f * p.x - phase);
    p = pigmentRow(p, 0.47f, 1.10f, phase, 0.23f);
    p = pigmentRow(p, 0.10f, 1.65f, -phase, 0.66f);
    p = pigmentRow(p, -0.51f, 0.84f, phase, 0.81f);
    p = pigmentVortex(p, float2(0.17f, -0.23f), 0.83f, 7.8f + 2.3f * cos(phase));
    float wash = studyNoise3(float3(p * float2(3.3f, 22.0f) + float2(cos(phase), sin(phase)) * 0.37f, 4.3f));
    float grain = studyNoise3(float3(p * float2(18.0f, 78.0f), 12.1f));
    float boundary = p.y + (wash - 0.50f) * 0.075f + (grain - 0.50f) * 0.021f;
    float3 color = float3(0.06f, 0.077f, 0.18f);
    color = mix(color, float3(0.31f, 0.05f, 0.087f), smoothstep(-0.95f, -0.80f, boundary));
    color = mix(color, float3(0.78f, 0.28f, 0.10f), smoothstep(-0.62f, -0.49f, boundary));
    color = mix(color, float3(0.14f, 0.033f, 0.085f), smoothstep(-0.25f, -0.13f, boundary));
    color = mix(color, float3(1.20f, 0.72f, 0.35f), smoothstep(0.06f, 0.16f, boundary));
    color = mix(color, float3(0.25f, 0.141f, 0.235f), smoothstep(0.40f, 0.52f, boundary));
    color = mix(color, float3(0.024f, 0.045f, 0.11f), smoothstep(0.73f, 0.85f, boundary));
    float fibers = pow(0.5f + 0.5f * sin(boundary * 112.0f + wash * 5.0f), 10.0f);
    float granulation = studyNoise3(float3(p * float2(57.0f, 131.0f), 9.2f));
    float mineral = 0.69f + 0.34f * wash + 0.24f * grain + 0.16f * granulation;
    float luster = exp(-abs(boundary + 0.15f) * 20.0f) + exp(-abs(boundary - 0.15f) * 20.0f);
    float2 glintOffset = (uv - float2(-0.30f, 0.38f)) * float2(0.5f, 1.65f);
    float glint = exp(-dot(glintOffset, glintOffset) * 1.8f) * (0.2f + 0.8f * wash);
    color = color * mineral + (0.065f + 0.05f * frame.beat + glint * 0.12f)
        * luster * fibers * float3(1.0f, 0.72f, 0.32f);
    float falloff = 1.0f - 0.23f * smoothstep(0.25f, 1.85f, length(uv));
    return displayColor(color * falloff, pixel);
}

#if defined(PULSECANVAS_STUDY)
struct PreviewFrame { float phase; float beat; };
static float2 screenPoint(uint2 pixel, uint2 size) {
    float2 p = (float2(pixel) + 0.5f - 0.5f * float2(size)) * (2.0f / float(min(size.x, size.y)));
    return float2(p.x, -p.y);
}

#define STUDY_ENTRY(entry, color) \
kernel void entry(texture2d<float, access::write> output [[texture(0)]], \
                  constant PreviewFrame& preview [[buffer(0)]], uint2 pixel [[thread_position_in_grid]]) { \
    uint2 size = uint2(output.get_width(), output.get_height()); \
    if (any(pixel >= size)) { return; } \
    StudyFrame frame = {preview.phase, preview.beat, preview.phase, 1.0f, 0.5f}; \
    output.write(color(screenPoint(pixel, size), pixel, frame), pixel); \
}
#else
static float4 styleAtmosphere(float4 color, constant NativeFrame& f) {
    float3 rgb = color.rgb;
    // The catalog default uses the authored grade. Alternate palettes tint
    // the same lights and shadows using the standard five app color stops.
    if (f.colors[0].w > 0.5f) {
        float value = dot(rgb, float3(0.2126f, 0.7152f, 0.0722f));
        float3 tint = paint(value, f);
        rgb = mix(rgb, tint * value / max(max(tint.r, tint.g), max(tint.b, 0.01f)), 0.68f);
    }
    return float4(saturate(rgb * f.style.x), color.a);
}

#define STUDY_ENTRY(entry, color) \
fragment float4 entry##Fragment(float4 position [[position]], constant NativeFrame& f [[buffer(0)]]) { \
    Ctx c = makeContext(position.xy, f); \
    float phase = fract(c.t / 8.0f) * studyTurn; \
    float travel = fract(c.travel / 8.0f) * studyTurn; \
    float beat = saturate(c.hit * 0.4f + f.rhythm.z * 0.6f); \
    StudyFrame frame = {phase, beat, travel, c.size, c.fog}; \
    return styleAtmosphere(color(c.uv, uint2(position.xy), frame), f); \
}
#endif

STUDY_ENTRY(smokeFrame, backlitRiftColor)
STUDY_ENTRY(undersurface, undersurfaceColor)
STUDY_ENTRY(mercuryFold, mercuryFoldColor)
STUDY_ENTRY(emberFront, emberFrontColor)
STUDY_ENTRY(anvilFlyover, anvilFlyoverColor)
STUDY_ENTRY(pigmentStrata, pigmentStrataColor)
#undef STUDY_ENTRY
