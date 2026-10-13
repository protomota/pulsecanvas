// PulseCanvas native designs. Original procedural code; see NativeCommon.metal.

// Shared helpers for this file.
// Smooth per-element weight that drifts with the music clock (selects who reacts to an
// attack without ever switching abruptly).
float raveWeight(float m, float id, float sharpness) {
    return pow(.5f + .5f * cos(m * .9f + id * 2.39f), sharpness);
}
// The attack envelope rides on a steady swell; this keeps only the punchy part.
float raveKick(float hit) { return smoothstep(.12f, .7f, hit); }
// Distance from p to the ellipse center + a cos(phi) + b sin(phi) (the projection of a
// tilted circle). An affine angle estimate is refined with damped Newton steps; phi
// returns the angle of the closest point.
float raveEllipse(float2 p, float2 center, float2 a, float2 b, thread float &phi) {
    float det = a.x * b.y - a.y * b.x;
    det = abs(det) < 1e-5 ? 1e-5 : det;
    float2 d = p - center;
    float2 w = float2(d.x * b.y - d.y * b.x, -d.x * a.y + d.y * a.x) / det;
    phi = atan2(w.y, w.x);
    for (int i = 0; i < 3; ++i) {
        float cs = cos(phi), sn = sin(phi);
        float2 s = a * cs + b * sn, ds = b * cs - a * sn;
        float2 e = s - d;
        float g = dot(e, ds), gg = dot(ds, ds) - dot(e, s);
        phi -= clamp(g / max(abs(gg), 1e-5f), -.4f, .4f);
    }
    return length(d - a * cos(phi) - b * sin(phi));
}
// Orthonormal basis (e1, e2) of the plane with normal n.
void raveBasis(float3 n, thread float3 &e1, thread float3 &e2) {
    float3 helper = abs(n.y) < .9 ? float3(0, 1, 0) : float3(1, 0, 0);
    e1 = normalize(cross(helper, n));
    e2 = cross(n, e1);
}

// ---------------------------------------------------------------- Smoke Rings
// Vortex rings of luminous smoke drift through coloured beams in a dark room. Rings are
// launched on a staggered schedule from different directions, swell, wobble and slowly
// dissipate; their smoke rolls around the core. Zoom speed carries the camera through the
// dust in the beams. Bass thickens and brightens the rings, attacks launch a fast extra
// ring and highs glitter in the smoke.
constant float smokeFocal = 1.4;
float3 smokeRing(float2 uv, float3 start, float3 end, float age, float alpha, float id, float hue, float beam, float band, Ctx c, constant NativeFrame &f) {
    if (alpha <= .002) return 0;
    float travel = 1 - pow(1 - age, 1.7f);
    float3 center = mix(start, end, travel);
    float3 heading = normalize(end - start);
    float3 axis = normalize(float3(heading.xy * .7 + float2(.25 * sin(c.t * .9 + id), .2 * cos(c.t * .7 + id * 1.3)), -1));
    float3 e1, e2;
    raveBasis(axis, e1, e2);
    float radius = (.55 + .35 * hash11(id * 3.7)) * (1 + 1.1 * age) * c.size;
    float s = smokeFocal / max(center.z, .3f);
    float2 c2 = center.xy * s;
    float wobble = 1 + .05 * sin(c.t * 2.1 + id);
    float2 a2 = e1.xy * radius * s * wobble, b2 = e2.xy * radius * s / wobble;
    float thick = radius * (.2 + .12 * age) * (1 + c.b.x * .7 + band * .5) * s;
    if (length(uv - c2) > (radius * s) * 1.3 + thick * 4) return 0;
    float phi;
    float d = raveEllipse(uv, c2, a2, b2, phi);
    if (d > thick * 4) return 0;
    float2 onRing = c2 + a2 * cos(phi) + b2 * sin(phi);
    float inner = length(uv - c2) < length(onRing - c2) ? -1.f : 1.f;
    float across = inner * d / thick;
    float roll = fbm3(float3(cos(phi) * 1.7, sin(phi) * 1.7, across * .8 - c.t * 1.3 - c.m * 1.4 + id * 7.1), 3);
    float core = exp(-across * across * 1.5);
    float density = core * (.35 + 1.2 * roll * roll * 1.6) + exp(-abs(across) * 1.4) * .05;
    float3 tint = paint(hue + band * .3, f);
    float facing = .75 + .35 * dot(normalize(uv - c2 + 1e-4), float2(.35, .9));
    float depthFade = exp(-max(center.z - 2.f, 0.f) * (.06 + c.fog * .08));
    float3 color = tint * density * (.45 + .7 * beam) * facing + paint(.95, f) * pow(core * roll, 3.f) * .4;
    float glitter = step(.982f, hash21(floor(uv * 230) + floor(c.t * 12))) * core * c.b.w * 3;
    color += paint(.97, f) * glitter;
    return color * alpha * depthFade * (1 + c.b.x * .4 + band * 1.6);
}
float3 smokeRings(Ctx c, constant NativeFrame &f) {
    float2 drift = float2(sin(c.travel * .13) * .45, sin(c.travel * .09 + 1) * .2);
    float2 uv = c.uv + drift;
    // dark room, sweeping coloured beams and haze
    float haze = fbm2(uv * 1.2 + float2(c.t * .05, c.t * .02), 4);
    float3 color = deep(.55, f) * .06 + paint(.2, f) * .03;
    float beamSum = 0;
    float3 beamLight = 0;
    for (int b = 0; b < 3; ++b) {
        float fb = float(b);
        float2 origin = float2((fb - 1) * c.extent.x * .8, c.extent.y + .3);
        float2 d = uv - origin;
        float ang = atan2(d.x, -d.y) - (.35 * sin(c.t * (.13 + fb * .04) + c.m * .25 + fb * 2.1) - (fb - 1) * .25);
        float cone = exp(-ang * ang * 30) * smoothstep(5.f, .4f, length(d));
        beamSum += cone;
        beamLight += paint(.15 + fb * .33, f) * cone * (1 + c.b[b + 1] * 1.6);
    }
    color += beamLight * (.1 + .16 * haze);
    color += paint(.6, f) * .05 * haze;
    // dust motes drifting toward the camera
    for (int k = 0; k < 3; ++k) {
        float2 slot = layerSlot(k, 3, c.travel * .12);
        float phase = slot.x, id = slot.y;
        float scale = layerScale(phase, 2) * 6;
        float2 p = uv * scale + float2(id * 5.3, id * 2.9 + c.t * .1);
        float2 cell = floor(p), local = fract(p) - .5;
        float2 o = (hash22(cell + id) - .5) * .7;
        float mote = exp(-length(local - o) * scale * 9 / (1 + phase * 3));
        color += paint(.9, f) * mote * layerFade(phase) * beamSum * .9 * (1 + c.b.w * 4) * step(.75f, hash21(cell + id * 3));
    }
    // the rings: six staggered launches plus an attack ring
    const int count = 8;
    for (int k = 0; k < count; ++k) {
        float clock = c.t * .07 + c.m * .05 + float(k) / float(count);
        float age = fract(clock);
        float id = floor(clock) * 7 + float(k) * 13;
        float3 h = hash33(float3(id, 1.7, 3.1));
        float side = h.x < .5 ? -1.f : 1.f;
        float z0 = 7 + h.y * 3, z1 = 2.1 + h.x * 1.8;
        float2 from = float2(side * c.extent.x * (.5 + .4 * h.z), (h.z - .5) * 1.4 * c.extent.y);
        float2 to = float2(-side * c.extent.x * (.1 + .75 * h.y), (h.x - .5) * 1.7 * c.extent.y);
        float3 start = float3(from * z0 / smokeFocal, z0);
        float3 end = float3(to * z1 / smokeFocal, z1);
        float alpha = smoothstep(0.f, .1f, age) * (1 - smoothstep(.55f, 1.f, age));
        color += smokeRing(uv, start, end, age, alpha, id, h.z * 1.8, beamSum, c.b[k % 4], c, f);
    }
    float kick = raveKick(c.hit);
    float3 launch = float3(sin(c.m * .7) * 3, -2 + .5 * cos(c.m * .5), 8);
    float3 target = float3(-sin(c.m * .7) * .9, .5, 2.6);
    color += smokeRing(uv, launch, target, (1 - kick) * .7, kick, 97, .95, beamSum, c.b.x, c, f) * 1.3;
    return color;
}

// ---------------------------------------------------------------- Wand Orbs
// Long-exposure light painting: wireframe globes are traced arc by arc by spinning LED
// wands, each meridian a dashed, slightly jittery stroke with a colour gradient along it,
// then the globe hangs, glows and dissolves while the next one is painted. Orbs stand at
// two depths over a dark mirror floor and Zoom speed dollies past them. Bands tint the
// wand gradients, attacks flash a bright equator arc and highs sparkle along the arcs.
constant float orbFocal = 1.3;
float3 wandOrb(float2 uv, float2 center, float radius, float scale, float cell, float layer, Ctx c, constant NativeFrame &f) {
    float rs = radius * scale;
    if (length(uv - center) > rs * 1.35 + .15) return 0;
    float seed = hash11(cell * 1.31 + layer * 7.7);
    float clock = c.t * .1 + c.m * .07 + seed * 5;
    float band = c.b[int(fmod(abs(cell + layer * 2), 4.f))];
    float age = fract(clock);
    float cycle = floor(clock);
    float hueBase = hash11(cycle + cell * 3.1) * 1.6 + (c.b.y - c.b.z) * .35 + c.b.x * .2;
    float build = smoothstep(0.f, .55f, age);
    float dissolve = smoothstep(.78f, 1.f, age);
    float fadeIn = smoothstep(0.f, .03f, age);
    float yaw = c.t * .25 + c.m * .35 + seed * 6;
    float roll = .3 * sin(seed * 9 + c.t * .1);
    float2 axisX = rot(float2(1, 0), roll), axisY = rot(float2(0, 1), roll);
    float pixel = c.px * 1.2;
    float width = .006 * c.size * scale * (1 + c.b.x * .8 + band * .6);
    const int arcs = 9;
    float3 color = 0;
    float swell = 1 + .1 * dissolve;
    for (int k = 0; k < arcs; ++k) {
        float fk = float(k);
        float progress = clamp(build * float(arcs) - fk, 0.f, 1.f);
        if (progress <= 0) break;
        float theta = fk * PI / float(arcs) + yaw;
        float2 a = axisX * rs * cos(theta) * swell, b = axisY * rs * swell;
        float phi;
        float d = raveEllipse(uv, center, a, b, phi);
        if (d > .12) continue;
        float q = fract((phi + PI * .5) / TAU);
        float drawn = smoothstep(progress + .004f, progress - .004f, q);
        float jitter = 1 + .25 * sin(q * 47 + fk * 3.1 + cycle);
        float dash = .55 + .45 * smoothstep(.12f, .3f, fract(q * 40 + fk * .37));
        float front = .55 + .45 * cos(phi) * sin(theta) + .45;
        float headGlow = progress < 1 ? exp(-abs(q - progress) * 60) * 2.5 : 0.f;
        float3 tint = paint(hueBase + q * .7 + fk * .03, f);
        float stroke = (line(d, width * jitter, pixel) * 1.3 + exp(-d / (.018 * scale * (1 + band * 1.5))) * .28) * (1 + band * 2.4);
        float sparkle = pow(hash11(floor(q * 140) + fk * 17 + cycle), 18.f) * c.b.w * 3;
        color += tint * stroke * drawn * dash * front * (1 + headGlow) + paint(.97, f) * sparkle * drawn * exp(-d / .01);
    }
    // attack: a bright equator arc
    float flash = raveKick(c.hit) * raveWeight(c.m, cell + layer * 3, 2);
    if (flash > .01) {
        float phi;
        float d = raveEllipse(uv, center, axisX * rs * 1.08, axisY * rs * .28, phi);
        color += paint(.95, f) * (line(d, width * 1.6, pixel) * 1.5 + exp(-d / .03) * .5) * flash;
    }
    return color * fadeIn * (1 - dissolve);
}
float3 wandOrbs(Ctx c, constant NativeFrame &f) {
    float tall = clamp((c.extent.y / c.extent.x - 1) / .78f, 0.f, 1.f);
    float2 uv = (c.uv - float2(0, .3 * tall)) / (1 + .3 * tall);
    float camX = c.travel * .35 + sin(c.t * .05) * .4;
    float camY = .15;
    float horizon = -.05;
    float3 color = deep(.7, f) * .1 + paint(.2, f) * .05 * (1 + fbm2(uv * 1.5 + c.t * .03, 3)) + paint(.6, f) * .045;
    color += paint(.85, f) * .05 * exp(-abs(uv.x + .4 * sin(c.t * .07)) * 1.5) * smoothstep(horizon, horizon + 2.f, uv.y);
    color += paint(.6, f) * .06 * exp(-abs(uv.y - horizon) * 3);
    if (uv.y < horizon) {
        float depth = 1 / max(horizon - uv.y, .02f);
        float sheen = exp(-abs(fract((uv.x * depth + camX) * .5) - .5) * 30) * .03 * exp(-(horizon - uv.y) * 2);
        color = deep(.6, f) * .07 + paint(.6, f) * .04 + paint(.5, f) * sheen + paint(.6, f) * .05 * exp(-(horizon - uv.y) * 6);
    }
    for (int layer = 2; layer >= 0; --layer) {
        float fl = float(layer);
        float z = 2.3 + fl * 1.7 + fl * fl * .3;
        float s = orbFocal / z;
        float spacing = 2.5 - fl * .4;
        float xw = uv.x / s + camX * (1 - fl * .3);
        float cell = round(xw / spacing);
        float seed = hash11(cell * 1.7 + fl * 5.1);
        float radius = (.6 + .2 * seed) * c.size;
        float floorY = -1.1 - camY;
        float centerY = floorY + radius + .25 + fl * (.7 + .5 * seed) + .1 * sin(c.t * .4 + cell);
        float2 center = float2((cell * spacing + (seed - .5) * .5 - camX * (1 - fl * .3)) * s, centerY * s);
        float contact = floorY * s;
        float depthFade = exp(-fl * (.3 + c.fog * .4));
        if (uv.y >= contact) {
            color += wandOrb(uv, center, radius, s, cell, fl, c, f) * depthFade;
        } else {
            float2 mirrored = float2(uv.x + .004 * sin(uv.y * 90 + c.t), 2 * contact - uv.y);
            color += wandOrb(mirrored, center, radius, s, cell, fl, c, f) * depthFade * .35 * exp(-(contact - uv.y) * 2.5);
        }
    }
    return color;
}

// ---------------------------------------------------------------- Faraday Dish
// Macro view straight down into a shallow dish of liquid vibrated from below: Faraday
// standing waves form square, hexagonal and quasicrystal lattices of crests that morph
// into each other, mirroring coloured studio lights, with light focused onto the dish
// floor under every crest and droplets bouncing on the surface. Zoom speed drifts and
// zooms across the dish. Bass raises the waves, the band balance shifts the lattice scale,
// attacks spray droplets and highs glitter on the crests.


// ---------------------------------------------------------------- String Resonance
// A giant light harp: long glowing strings cross the frame at slight angles and depths,
// held by bright bridge pins, and every span rings in standing-wave modes, drawn as a
// long-exposure envelope (bright at the turning points) around the moving string. Spans
// are plucked on a staggered schedule; Zoom speed slides the camera along the strings.
// Each band keeps its own string group ringing, attacks pluck a cluster hard and highs
// shimmer along the strings.
float3 stringResonance(Ctx c, constant NativeFrame &f) {
    float2 uv = c.uv;
    float haze = fbm2(uv * 1.1 + float2(c.t * .03, -c.t * .015), 4);
    float3 color = deep(.25, f) * (.05 + .05 * haze) + paint(.1, f) * .025;
    float3 glowSum = 0;
    const int strings = 12;
    float kick = raveKick(c.hit);
    for (int i = 0; i < strings; ++i) {
        float fi = float(i);
        float3 h = hash33(float3(fi, 4.1, 9.3));
        float z = 1 + h.z * 1.6;
        float scale = 1 / z;
        float angle = (h.x - .5) * .32;
        float y0 = ((fi + .5) / float(strings) * 2 - 1) * c.extent.y * .95 + (h.y - .5) * .12;
        float2 local = rot(uv - float2(0, y0), -angle);
        float maxAmp = .2 * scale + .05;
        if (abs(local.y) > maxAmp + .25) continue;
        float spanLength = 2.4 + h.x;
        float xs = local.x * z + c.travel * .45 + h.y * 9;
        float span = floor(xs / spanLength);
        float s = xs / spanLength - span;
        float3 hs = hash33(float3(span, fi, 2.7));
        float rate = .18 + hs.x * .2;
        float clock = c.t * rate + c.m * rate * .9 + hs.y;
        float age = fract(clock) / rate;
        float pluck = smoothstep(0.f, .03f, age) * exp(-age * (.55 + hs.z * .4));
        int group = i % 4;
        float drive = c.b[group] * .9 + kick * raveWeight(c.m, fi * .6, 3) * 1.4;
        float strength = (pluck * .8 + drive) * scale;
        float pluckAt = .15 + .3 * hs.z;
        float a1 = .1 * strength * sin(PI * pluckAt);
        float a2 = .05 * strength * sin(2 * PI * pluckAt);
        float a3 = .03 * strength * sin(3 * PI * pluckAt);
        float w = 9 + hs.x * 4;
        float m1 = sin(PI * s), m2 = sin(2 * PI * s), m3 = sin(3 * PI * s);
        float envelope = abs(a1 * m1) + abs(a2 * m2) + abs(a3 * m3);
        float tv = c.t + c.m * .4;
        float y = a1 * m1 * cos(w * tv) + a2 * m2 * cos(2 * w * tv + 1) + a3 * m3 * cos(3 * w * tv + 2);
        float pixel = c.px * 1.2;
        float width = .004 * c.size * scale + pixel * .4;
        float ly = local.y;
        // long-exposure envelope: dwell is longest at the turning points
        float inside = smoothstep(envelope + pixel * 2, envelope - pixel, abs(ly));
        float dwell = envelope / sqrt(max(envelope * envelope - ly * ly, envelope * envelope * .02f) + 1e-6f);
        float band = inside * clamp(dwell * .12f, 0.f, .9f) * smoothstep(0.f, .004f, envelope);
        float3 tint = paint(.08 + fi / float(strings) * .85 + hs.z * .05, f);
        float core = line(ly - y, width, pixel);
        float bloom = exp(-abs(ly - y) / (.025 * scale + .01)) * .3 + exp(-max(abs(ly) - envelope, 0.f) / (.08 * scale)) * .08;
        float shimmer = pow(hash21(float2(floor(xs * 60), floor(c.t * 14) + fi)), 24.f) * c.b.w * 3 * exp(-abs(ly - y) / .01);
        float depthFade = exp(-(z - 1) * (.35 + c.fog * .4));
        float lit = .45 + 2.6 * strength;
        color += (tint * (core * 1.1 + band * .55 + bloom * .8) * lit + paint(.97, f) * shimmer) * depthFade;
        glowSum += tint * exp(-abs(ly) / .3) * .02 * lit * depthFade;
        // bridge pins at the ends of every span
        float pinX = (round(xs / spanLength) * spanLength - c.travel * .45 - h.y * 9) / z;
        float pin = length(float2(local.x - pinX, ly) / float2(1, 2.5));
        color += paint(.9, f) * (exp(-pin / (.012 * scale)) * .9 + exp(-pin / (.06 * scale)) * .15) * depthFade;
    }
    return color + glowSum * (.6 + haze);
}

// ---------------------------------------------------------------- Light Bars
// Kinetic light installation: four depth rows of hanging LED bars on fine wires rise,
// fall and tilt in travelling waves, each bar glowing along its length with a chasing
// gradient inside a lit haze. Zoom speed pans the camera along the rows (parallax). Each
// band lifts and tilts its own bar group, attacks flare a moving cluster of bars.
float3 lightBars(Ctx c, constant NativeFrame &f) {
    float tall = clamp((c.extent.y / c.extent.x - 1) / .78f, 0.f, 1.f);
    float camX = c.travel * .3 + sin(c.t * .05) * .5;
    float camY = sin(c.t * .09) * .1;
    float floorY = -.78 - .45 * tall;
    float2 uv = c.uv;
    bool mirror = uv.y < floorY;
    float depthBelow = max(floorY - uv.y, 0.f);
    if (mirror) uv = float2(uv.x + sin(depthBelow * 40 / (depthBelow + .1) + c.t) * .004, 2 * floorY - uv.y);
    float haze = fbm2(uv * 1.3 + float2(c.t * .04, -c.t * .02), 3);
    float3 color = deep(.35 + uv.y * .08, f) * (.1 + .08 * haze) + paint(.15, f) * .04;
    float3 hazeLight = 0;
    const int layers = 3;
    const float eye = -.12;
    for (int layer = layers - 1; layer >= 0; --layer) {
        float fl = float(layer);
        float z = 1 + fl * .75 + fl * fl * .25;
        float2 p = float2(uv.x * z + camX * (1 + fl * .2), (uv.y - eye) * z + eye + camY);
        float spacing = .26;
        float id0 = round(p.x / spacing);
        float pixel = c.px * z;
        float depthFade = exp(-fl * (.25 + c.fog * .45));
        float width = .02 * c.size;
        for (int k = -1; k <= 1; ++k) {
            float id = id0 + float(k);
            float x = id * spacing;
            int group = int(fmod(abs(id + fl), 4.f));
            float band = c.b[group];
            float lift = .4 * sin(x * .85 - c.t * 1.15 - c.m * .9 + fl * 1.1) + .12 * sin(x * .3 + c.t * .5 + fl) + band * .45 * (group % 2 == 0 ? 1.f : -1.f);
            float tilt = .13 * sin(x * .6 - c.t * .8 + fl * 1.3) + band * .2 * sin(float(group) * 1.7 + c.t * .8);
            float length2 = .3 + .18 * tall;
            float tier = (fmod(abs(id), 2.f) < .5 ? .42f : -.42f) * (1 + .7 * tall);
            float2 center = float2(x, eye + .05 + tier + lift * .75);
            float2 local = rot(p - center, -tilt);
            float d = length(max(abs(local) - float2(0, length2), 0.f)) - width;
            float along = local.y / length2;
            float flare = c.hit * raveWeight(c.m, id * .7 + fl * 1.9, 4);
            float chase = .5 + .5 * sin(along * 6 - c.t * 4 - c.m * 3 + id * 1.3);
            float3 led = paint(.25 + along * .22 + fl * .13 + sin(id * .4 + c.t * .2) * .2, f);
            float core = fill(d, pixel * 1.5);
            float brightness = (.45 + .55 * chase + band * .6) * (1 + flare * 3.5);
            color += led * (core * .9 + exp(-max(d, 0.f) / (.025 * c.size)) * .22) * brightness * depthFade;
            hazeLight += led * exp(-max(d, 0.f) / .35) * .035 * brightness * depthFade;
            float2 top = center + rot(float2(0, length2), tilt);
            float wire = sdSegment(p, top, float2(top.x, top.y + 8));
            color += paint(.6, f) * exp(-wire / (pixel * 1.1)) * .1 * depthFade;
        }
    }
    color += hazeLight * (.4 + 1.2 * haze);
    if (mirror) color = color * .55 * exp(-depthBelow * 1.1) + deep(.4, f) * .06 + paint(.7, f) * .15 * exp(-depthBelow / .01);
    return color;
}

// ---------------------------------------------------------------- Sequin Curtain
// A wall of thousands of two-sided flip sequins in offset rows. Travelling flip waves
// (sweeps, spirals and rings that crossfade) turn each disc over, edge-on discs darken
// and catch sharp glints as the fronts pass, and a slow cloth ripple rolls through the
// whole curtain. Zoom speed pans and slightly zooms along it. Each band drives its own
// wave front, attacks flip a ring outward from a point and highs add glints.
float sequinFlip(float2 p, Ctx c) {
    float tc = c.t * .05;
    float3 w = pow(.5f + .5f * cos(tc * TAU + float3(0, 2.094, 4.189)), float3(2.f)) + float3(c.b.x, c.b.y, c.b.z) * 1.2;
    float2 ctr = float2(sin(c.t * .11) * 1.2, cos(c.t * .09) * .6);
    float2 d = p - ctr;
    float sweep = sin(dot(p, normalize(float2(1, .35))) * 1.5 - c.t * 1.2);
    float spiral = sin(atan2(d.y, d.x) * 2 + length(d) * 2.6 - c.t * 1.4);
    float rings = sin(length(p - float2(-ctr.x, ctr.y * .5)) * 3.4 - c.t * 1.7 - c.m * .6);
    float s = (w.x * sweep + w.y * spiral + w.z * rings) / (w.x + w.y + w.z);
    s += c.b.w * .35 * sin(p.x * 5 + p.y * 3 - c.t * 3);
    float flip = smoothstep(-.4f, .4f, s);
    float kick = raveKick(c.hit);
    float2 origin = float2(sin(c.m * .7) * 1.1, cos(c.m * .5) * .5);
    float front = (1 - kick) * 2.4;
    float ring = exp(-pow((length(p - origin) - front) / .22, 2.f)) * kick;
    return mix(flip, 1 - flip, ring);
}
float3 sequinCurtain(Ctx c, constant NativeFrame &f) {
    float zoom = 1 + .08 * sin(c.travel * .1);
    float2 p = c.uv * zoom + float2(c.travel * .18, .1 * sin(c.travel * .07));
    float pitch = .075 * c.size;
    float fold = sin(p.x * 2.1 + 1.4 * sin(p.y * 1.2 + c.t * .35) + c.t * .5);
    p += float2(0, .015 * fold);
    float4 cell = hexCell(p / pitch);
    float2 q = cell.xy;
    float2 centerP = cell.zw * float2(1, 1.7320508) * pitch;
    float flip = sequinFlip(centerP, c);
    float theta = flip * PI;
    float ct = cos(theta), st = sin(theta);
    float squash = max(abs(ct), .06f);
    float2 sq = float2(q.x, q.y / squash);
    float r = length(sq);
    float pixel = c.px / pitch * 1.4;
    float disc = fill(r - .47, pixel / squash);
    float3 fabric = deep(.3, f) * .05 + paint(.7, f) * .02 * (1 + fold);
    // cupped disc tilted about its horizontal axis
    float3 n = normalize(float3(sq * .35 * float2(1, sign(ct)), 1));
    n = normalize(float3(n.x, n.y * ct + n.z * st, -n.y * st + n.z * ct));
    if (ct < 0) n = float3(n.x, -n.y, -n.z);
    n.z = abs(n.z);
    float2 jitter = hash22(cell.zw * 1.7) - .5;
    n = normalize(n + float3(jitter * .22, 0));
    float3 key = normalize(float3(-.35 + .2 * sin(c.t * .13), .55, .75));
    float3 rim = normalize(float3(.6, -.3, .55));
    float3 refl = float3(2 * n.z * n.x, 2 * n.z * n.y, 2 * n.z * n.z - 1);
    float spec = pow(max(dot(refl, key), 0.f), 40.f);
    float spec2 = pow(max(dot(refl, rim), 0.f), 40.f);
    float diffuse = max(dot(n, key), 0.f);
    float hueA = .08 + .12 * sin(centerP.x * .4 + centerP.y * .3), hueB = .62 + .1 * sin(centerP.y * .5 - c.t * .1);
    float3 side = ct > 0 ? paint(hueA, f) : paint(hueB, f);
    float edgeOn = 1 - smoothstep(.05f, .45f, abs(ct));
    float glitter = 1 + c.b.w * 3 * step(.6f, hash21(cell.zw + floor(c.t * 4)));
    float3 sequin = side * (.08 + .42 * diffuse) * (.8 + .25 * fold) * (1 - .6 * edgeOn) + side * side * .12;
    sequin += (paint(.97, f) * spec * 2.4 + side * spec * 1.2) * glitter + paint(hueB + .3, f) * spec2 * .7;
    sequin *= .9 + .2 * fill(r - .36, pixel) - .1;
    float shadow = 1 - .5 * exp(-pow(length(q - float2(.06, -.08)) - .45, 2.f) * 40) * (1 - disc);
    return mix(fabric * shadow, sequin, disc);
}

// ---------------------------------------------------------------- Torsion Wave
// Wave-machine sculptures: hundreds of thin polished rods mounted crosswise on long spines
// that recede diagonally into the dark. Torsion waves and their reflections travel along
// each spine, twisting the rods, whose glowing tips leave short light trails. Three
// machines sit at different depths and Zoom speed moves the camera along the spines.
// Bass deepens the twist, bands add their own wave groups, attacks launch a pulse from
// the near end and highs sparkle the tips.
constant float torsionFocal = 1.3;


// ---------------------------------------------------------------- Spin Paint
// Spin art in motion: each pour lands on a spinning disc and flings outward as a fan of
// thin glossy streaks curving along logarithmic spirals, thinning toward the rim and
// ending in droplets, while a ring of colour smears around the landing radius. Pours
// layer up and fade so the canvas never saturates; overlapping discs spin at their own
// speeds and Zoom speed zooms seamlessly into the canvas. Bands pick the colour that
// pours, attacks fling an extra burst of streaks and highs add fine speckles.


// ---------------------------------------------------------------- Stadium Wave
// A vast perspective field of glowing balls (a crowd of lights) rises and falls in
// travelling waves: a stadium wave sweeping sideways, a diagonal swell and a circular
// ripple interfere, and colour follows height. Zoom speed flies the camera over the
// field. Bass raises the waves, each attack launches a ring wave from a drifting point.
float stadiumHeight(float2 g, float camZ, Ctx c) {
    float sweep = pow(.5f + .5f * cos(g.x * .13 - c.t * 1.1 - c.m * .9 + g.y * .02), 12.f) * 1.4;
    float swell = pow(.5f + .5f * cos(g.x * .06 + g.y * .11 - c.t * .7), 6.f);
    float2 center = float2(sin(c.t * .13) * 6, camZ + 16);
    float ripple = .5 + .5 * sin(length(g - center) * .55 - c.t * 2.2 - c.m * 1.6);
    float h = (sweep * .9 + swell * .4 + ripple * .2) * (1 + c.b.x * 1.2);
    float kick = raveKick(c.hit);
    float2 origin = float2(sin(c.m * .7) * 7, camZ + 12 + 4 * cos(c.m * .5));
    float ring = (1 - kick) * 22 + 1;
    h += kick * 1.1 * exp(-pow(length(g - origin) - ring, 2.f) * .35);
    return h;
}
float3 stadiumWave(Ctx c, constant NativeFrame &f) {
    const float focal = 1.25, camH = 4.6, maxLift = 2.2;
    float horizon = c.extent.y * .62 + .3;
    float camZ = c.travel * 1.6;
    float camX = sin(c.t * .05) * 3;
    float2 uv = c.uv;
    float hz = horizon - uv.y;
    // night sky with stadium floodlight glow
    float3 color = deep(.7, f) * .08 + paint(.65, f) * .16 * exp(-abs(uv.y - horizon) * 4);
    for (int k = 0; k < 4; ++k) {
        float lx = (float(k) - 1.5) * c.extent.x * .6;
        color += paint(.9, f) * .3 * exp(-length((uv - float2(lx, horizon + .1)) * float2(1, 2.5)) * 9);
    }
    if (hz <= 0) return color;
    float zGround = camH * focal / hz;
    float zNear = (camH - maxLift) * focal / hz;
    float zCut = camH * focal / (horizon + c.extent.y + .3) * .8;
    float3 ground = deep(.6, f) * .05 + paint(.6, f) * .03 * exp(-zGround * .03);
    const float lattice = .62;
    float radius = .17 * c.size;
    float transmit = 1;
    float3 accum = 0;
    float j0 = ceil((max(zNear, zCut * .7f) + camZ - radius) / lattice), j1 = (zGround + camZ + radius) / lattice;
    float pix = c.px * 1.2;
    for (int k = 0; k < 30; ++k) {
        float row = j0 + float(k);
        if (row > j1) break;
        float zr = row * lattice - camZ;
        float nearFade = smoothstep(zCut * .7f, zCut, zr);
        if (nearFade <= 0) continue;
        float colX = round((uv.x * zr / focal + camX) / lattice) * lattice;
        float2 g = float2(colX, row * lattice);
        float h = stadiumHeight(g, camZ, c);
        float y = .3 + h;
        float s = focal / zr;
        float2 center = float2((colX - camX) * s, horizon - (camH - y) * s);
        float footY = horizon - camH * s;
        float rs = radius * s;
        float2 q = (uv - center) / rs;
        float d = length(q);
        float fade = exp(-zr * (.02 + c.fog * .035)) * nearFade;
        float3 tint = paint(.06 + h * .36, f);
        float stem = abs(uv.x - center.x) / rs;
        float onStem = step(footY, uv.y) * step(uv.y, center.y);
        accum += transmit * tint * exp(-stem * 8) * onStem * .16 * fade * min(rs / pix, 1.f);
        float2 foot = (uv - float2(center.x, footY)) / (rs * float2(1.6, .5));
        accum += transmit * tint * exp(-dot(foot, foot) * 1.5) * .2 * (.3 + h) * fade;
        accum += transmit * tint * exp(-max(d - 1, 0.f) * 3.5) * .08 * (.3 + h) * fade * min(rs / pix, 1.f);
        float cover = (1 - smoothstep(1 - pix / rs, 1 + pix / rs, d)) * nearFade;
        if (cover > 0) {
            float2 qn = q / max(d, 1.f);
            float nz = sqrt(max(1 - dot(qn, qn), 0.f));
            float3 ball = tint * (.25 + .5 * nz) * (.55 + .55 * h) + paint(.97, f) * pow(max(dot(float3(qn, nz), normalize(float3(-.4, .6, .7))), 0.f), 22.f) * .4;
            ball = mix(color * .4 + paint(.6, f) * .05, ball, fade);
            accum += transmit * cover * ball;
            transmit *= 1 - cover;
            if (transmit < .03) break;
        }
    }
    float fieldFog = 1 - exp(-zGround * (.02 + c.fog * .03));
    ground = mix(ground, paint(.6, f) * .1, fieldFog);
    return accum + transmit * ground;
}

// ---------------------------------------------------------------- Liquid Floor
// A glossy black liquid dance floor seen at an angle, mirroring the club ceiling (LED
// strips, fixtures and roaming light pools). Unseen dancers' steps send rings across the
// surface in choreographed phrases (walks, turns and side steps) that interfere and bend
// the reflections. Zoom speed glides the camera across the floor. Bass strengthens the
// ripples, attacks add a hard stomp ring and highs sparkle in the reflections.
float2 liquidStepPos(float i, float n) {
    float t = n / 1.6;
    float2 center = float2(1.2 * sin(t * .23 + i * 2.1), 1.5 + i * 1.1 + .5 * cos(t * .17 + i));
    float2 heading = normalize(float2(1.1 * .23 * cos(t * .23 + i * 2.1), -.5 * .17 * sin(t * .17 + i)) + 1e-4);
    float2 side = float2(-heading.y, heading.x);
    float foot = fmod(n, 2.f) < .5 ? -1.f : 1.f;
    float phrase = floor(hash11(floor(n / 8) + i * 7.3) * 3);
    if (phrase < .5) return center + side * foot * .12;
    if (phrase < 1.5) return center + .26 * float2(cos(n * .9), sin(n * .9));
    return center + side * foot * .28 + heading * .05 * sin(n);
}
float3 liquidCeiling(float3 origin, float3 dir, float camZ, Ctx c, constant NativeFrame &f) {
    // LED wall far ahead: vertical colour bars that chase
    float wallX = origin.x + dir.x / max(dir.z, .05f) * 12;
    float bars = .5 + .5 * sin(wallX * 2.2 - c.t * 1.5);
    float3 wall = paint(.1 + .8 * fract(floor(wallX * .7) * .37), f) * (.25 + .9 * pow(bars, 3.f)) * smoothstep(.0f, .12f, dir.y + .02f) * smoothstep(.45f, .05f, dir.y);
    if (dir.y <= .02) return paint(.55, f) * .12 + wall * .6;
    float t = (3.2 - origin.y) / dir.y;
    float2 q = origin.xz + dir.xz * t;
    float fade = exp(-t * .045);
    float3 color = paint(.3 + .25 * sin(q.x * .3 + q.y * .2 + c.t * .1), f) * .12;
    // rows of chasing LED strips across the room and dimmer strips along it
    float stripD = abs(fract(q.y / 1.1) - .5) * 1.1;
    float stripId = floor(q.y / 1.1);
    float chase = .5 + .5 * sin(q.x * 2.2 - c.t * 3 - c.m * 2.5 + stripId * 1.7);
    float stripBand = c.b[int(fmod(abs(stripId), 4.f))];
    color += paint(.1 + fract(stripId * .37) * .85, f) * (fill(stripD - .06, .015) * 1.5 + exp(-stripD / .15) * .4) * (.45 + .8 * chase) * (1 + stripBand * 2.2);
    float laneD = abs(fract(q.x / 2.2) - .5) * 2.2;
    float laneId = floor(q.x / 2.2);
    color += paint(.55 + fract(laneId * .29) * .4, f) * (fill(laneD - .04, .015) * .8 + exp(-laneD / .12) * .2) * (.6 + .4 * sin(q.y * 1.5 + c.t * 2 + c.m * 1.5 + laneId)) * (1 + c.b[int(fmod(abs(laneId) + 2, 4.f))] * 1.8);
    // fixtures
    float2 cell = floor(q / 1.1), local = fract(q / 1.1) - .5;
    float lamp = length(local);
    float fixture = (fill(lamp - .07, .015) * 2 + exp(-lamp / .12) * .5) * step(.4f, hash21(cell));
    color += paint(.75 + .25 * hash21(cell + 2), f) * fixture * (.7 + .3 * sin(c.t * 2.3 + cell.x * 1.3 + cell.y)) * (1 + c.b[int(hash21(cell + 5) * 3.99)] * 2.4);
    // sweeping beams and roaming pools of light
    for (int k = 0; k < 3; ++k) {
        float fk = float(k);
        float2 pivot = float2((fk - 1) * 3, camZ + 6 + fk * 1.5);
        float beamAngle = c.t * (.21 + fk * .05) + c.m * .3 + fk * 2.1;
        float2 dirB = float2(cos(beamAngle), sin(beamAngle));
        float beamD = abs(dot(q - pivot, float2(-dirB.y, dirB.x)));
        color += paint(.2 + fk * .3, f) * exp(-beamD / .3) * .45 * (1 + c.b[k + 1] * 2.2);
        float2 pool = float2(sin(c.t * (.2 + fk * .07) + fk * 2) * 2.5, camZ + 5 + fk * 2.5 + 1.5 * cos(c.t * .15 + fk));
        color += paint(.25 + fk * .3, f) * .4 * exp(-length(q - pool) * 1.2);
    }
    return color * fade + paint(.5, f) * .12 * (1 - fade) + wall;
}
float3 liquidFloor(Ctx c, constant NativeFrame &f) {
    const float focal = 1.3, height = 1.25;
    float tall = clamp((c.extent.y / c.extent.x - 1) / .78f, 0.f, 1.f);
    float horizon = c.extent.y * .78 + .1 - .2 * tall;
    float2 uv = c.uv;
    float camZ = c.travel * .8;
    float camX = sin(c.travel * .05) * 1.5;
    float3 color = paint(.5, f) * .12 * exp(-abs(uv.y - horizon) * 2) + deep(.6, f) * .04;
    if (uv.y >= horizon) return color;
    float z = height * focal / (horizon - uv.y);
    float2 g = float2(uv.x * z / focal, z);
    float3 eye = float3(camX, height, camZ);
    float3 hit = float3(g.x + camX, 0, g.y + camZ);
    float3 view = normalize(hit - eye);
    // ripple field from the dancers' recent steps
    float2 grad = 0;
    float scale = 1 / c.size;
    for (int i = 0; i < 3; ++i) {
        float fi = float(i);
        float clock = c.t * 1.6 + c.m * 1.0 + fi * .37;
        float now = floor(clock);
        for (int k = 0; k < 3; ++k) {
            float n = now - float(k);
            float tau = (clock - n) / 1.6;
            float2 source = liquidStepPos(fi, n);
            float2 d = g - source;
            float dist = length(d) * scale;
            float radius = tau * .6;
            float amp = (.5 + c.b.x * 1.3) * exp(-tau * 1.1) / (1 + radius * 2.5) * smoothstep(0.f, .05f, tau);
            float x = dist - radius;
            float env = exp(-x * x / .03);
            float slope = amp * (28 * cos(x * 28) - 2 * x / .03 * sin(x * 28)) * env;
            grad += slope * d / max(length(d), 1e-3f);
        }
    }
    float kick = raveKick(c.hit);
    if (kick > .01) {
        float2 d = g - float2(sin(c.m * .6) * .8, 2.6);
        float x = length(d) * scale - (1 - kick) * 1.4;
        float env = exp(-x * x / .05);
        grad += kick * 1.6 * (24 * cos(x * 24) - 2 * x / .05 * sin(x * 24)) * env * d / max(length(d), 1e-3f);
    }
    float3 n = normalize(float3(-grad.x * .02, 1, -grad.y * .02));
    float3 r = reflect(view, n);
    float fresnel = .05 + .95 * pow(1 - max(dot(-view, n), 0.f), 4.f);
    float3 env = liquidCeiling(hit, r, camZ, c, f);
    float3 surface = deep(.6, f) * .05 + env * (.34 + .5 * fresnel);
    // light pools gliding over the surface
    for (int k = 0; k < 2; ++k) {
        float fk = float(k);
        float2 pool = float2(sin(c.t * (.17 + fk * .06) + fk * 3) * 1.5, 2.5 + fk * 1.5 + cos(c.t * .13 + fk) * 1.2);
        surface += paint(.2 + fk * .5, f) * .08 * exp(-length(g - pool) * 1.6);
    }
    float glint = step(.97f, hash21(floor(uv * 180) + floor(c.t * 12))) * c.b.w * smoothstep(.3f, 1.2f, dot(env, float3(.33)));
    surface += paint(.97, f) * glint * 2;
    float haze = 1 - exp(-z * (.03 + c.fog * .03));
    return mix(surface, color + paint(.5, f) * .06, haze);
}

// ---------------------------------------------------------------- Confetti Storm
// Party confetti: layers of paper flakes and curly streamers flutter down through a
// bright stage glow, every flake spinning and tumbling so it flashes as it catches the
// light; Zoom speed carries the camera through the layers. Confetti cannons in the
// bottom corners fire on their own; bass launches extra bursts and attacks fire both.


// ---------------------------------------------------------------- Bokeh Club
// A nightclub seen through a fast lens wide open: layers of club lights and LED strips
// dissolve into large hexagonal bokeh with onion-ring texture and colour fringes at the
// rims, drifting and swirling in haze while the focus slowly racks through the layers.
// Zoom speed drifts the lens forward through them. Each band brightens its own group of
// lights, attacks flare a cluster and highs add tiny sharp sparkles.


// ---------------------------------------------------------------- Persistence Fans
// Holographic LED fans float in a dark room at different depths and angles; their
// spinning blades paint luminous shapes by persistence of vision (mandalas, a band-driven
// waveform ring, outward rings and starbursts that morph into each other), with faint
// blade sweeps, LED scanlines and flicker bands. Zoom speed dollies between the fans.
// The waveform ring follows the bands, attacks pop a starburst and highs sparkle LEDs.


// ---------------------------------------------------------------- Domino Run
// Glossy coloured dominoes stand in a long meandering line on a dark mirror floor; a
// toppling wave runs along it, each domino tipping onto the next with a glint, and every
// so often the chain forks into a side line that topples in step. The camera follows the
// falling front (Zoom speed sets how fast). The music clock pushes the wave, bands light
// the falling dominoes, attacks race a bright wave down the side line and highs glint.
constant float dominoSpacing = .3, dominoFork = 15;
float dominoPath(float z) { return 1.2 * sin(z * .19) + .5 * sin(z * .43 + 1.3); }
float dominoSlope(float z) { return 1.2 * .19 * cos(z * .19) + .5 * .43 * cos(z * .43 + 1.3); }
float dominoBranch(float z, thread float &side, thread float &along) {
    float k = floor((z - 6) / dominoFork);
    along = z - (k * dominoFork + 6);
    side = hash11(k * 3.7) < .5 ? -1.f : 1.f;
    if (along < .6 || along > 11) return 1e3;
    return dominoPath(z) + side * (1 - cos(min(along, 7.f) / 7 * PI)) * .72;
}
float dominoBox(float3 p, float x, float zi, float slope, float fallFront, float size) {
    float3 base = float3(x, 0, zi);
    float2 tangent = normalize(float2(slope, 1));
    float2 normal = float2(tangent.y, -tangent.x);
    float3 d = p - base;
    float3 q = float3(dot(d.xz, normal), d.y, dot(d.xz, tangent));
    float thick = .035 * size, tall = .24 * size, wide = .11 * size;
    float angle = clamp((fallFront - zi) / .45f, 0.f, 1.f) * 1.32;
    float qy = q.y, qz = q.z - thick;
    float ly = qy * cos(angle) + qz * sin(angle);
    float lz = -qy * sin(angle) + qz * cos(angle);
    return sdBox(float3(q.x, ly - tall, lz + thick), float3(wide, tall, thick)) - .006 * size;
}
constant float dominoLineGap = 3.4;
float dominoMap(float3 p, float front, float size, thread float &which, thread float &index) {
    float lane = round((p.x - dominoPath(p.z)) / dominoLineGap);
    float shift = lane * 7.3;
    float offset = lane * dominoLineGap;
    float lineFront = front - abs(lane) * 1.7;
    float3 lp = float3(p.x - offset, p.y, p.z);
    float i0 = round(lp.z / dominoSpacing);
    float best = 1e3;
    for (int k = 0; k < 2; ++k) {
        float i = i0 - float(k);
        float zi = i * dominoSpacing;
        float d = dominoBox(lp, dominoPath(zi), zi, dominoSlope(zi), lineFront, size);
        if (d < best) { best = d; which = lane * 2; index = i; }
        float side, along;
        float bx = dominoBranch(zi + shift, side, along);
        bx += dominoPath(zi) - dominoPath(zi + shift);
        if (bx < 100) {
            float slope = dominoSlope(zi) + side * sin(min(along, 7.f) / 7 * PI) * PI / 7 * .72 * step(along, 7.f);
            float db = dominoBox(lp, bx, zi, slope, lineFront, size);
            if (db < best) { best = db; which = lane * 2 + 1; index = i; }
        }
    }
    return best;
}
float3 dominoRun(Ctx c, constant NativeFrame &f) {
    float size = c.size;
    float front = c.t * 1.9 + c.travel * 1.5 + c.m * 1.1;
    float camZ = front - 3.2;
    float tall = clamp((c.extent.y / c.extent.x - 1) / .78f, 0.f, 1.f);
    float3 eye = float3(dominoPath(camZ) * .6 + .9, 1.7 + 1.1 * tall, camZ);
    float3 target = float3(dominoPath(camZ + 5) * .8, 0, camZ + 5.5);
    float3 rd = cameraRay(c.uv, target - eye, float3(0, 1, 0), 1.5);
    float3 sky = deep(.7, f) * .08 + paint(.6, f) * .14 * exp(-abs(rd.y + .04) * 7);
    if (rd.y >= -.005) return sky;
    float tFloor = eye.y / -rd.y;
    float tStart = (eye.y - .62 * size) / -rd.y;
    float t = max(tStart, 0.f);
    float which = 0, index = 0;
    bool hit = false;
    for (int s = 0; s < 44; ++s) {
        float3 p = eye + rd * t;
        float d = dominoMap(p, front, size, which, index);
        if (d < .002) { hit = true; break; }
        t += max(d * .9, .004f);
        if (t > tFloor) break;
    }
    float3 light = normalize(float3(-.5, .8, .35));
    float fog = exp(-max(min(t, tFloor) - 2, 0.f) * (.06 + c.fog * .06));
    if (hit) {
        float3 p = eye + rd * t;
        const float2 e = float2(.003, -.003);
        float dummyA, dummyB;
        float3 n = normalize(e.xyy * dominoMap(p + e.xyy, front, size, dummyA, dummyB) + e.yyx * dominoMap(p + e.yyx, front, size, dummyA, dummyB)
            + e.yxy * dominoMap(p + e.yxy, front, size, dummyA, dummyB) + e.xxx * dominoMap(p + e.xxx, front, size, dummyA, dummyB));
        float lane = round(which * .5 - .25);
        float zi = index * dominoSpacing;
        float falling = clamp((front - abs(lane) * 1.7 - zi) / .45f, 0.f, 1.f);
        float moving = falling * (1 - falling) * 4;
        float band = c.b[int(fmod(abs(index), 4.f))];
        float hue = fract(index * .061 + which * .37) * 1.8;
        float3 tint = paint(hue, f);
        float diffuse = max(dot(n, light), 0.f);
        float spec = pow(max(dot(reflect(rd, n), light), 0.f), 40.f);
        float rim = pow(1 - max(dot(-rd, n), 0.f), 3.f);
        float side, along;
        dominoBranch(index * dominoSpacing + lane * 7.3, side, along);
        float kick = raveKick(c.hit);
        float race = fmod(abs(which), 2.f) > .5 ? kick * exp(-pow(along - (1 - kick) * 11, 2.f) * .8) : 0.f;
        float glint = 1 + c.b.w * 3 * step(.8f, hash11(index * 1.7 + floor(c.t * 8)));
        float3 color = tint * (.12 + .7 * diffuse) * (1 + band * (1.2 + 1.6 * moving) + falling * .15) + paint(.97, f) * spec * 1.3 * glint + tint * rim * .35 * (1 + band * 2);
        color += paint(.95, f) * race * 1.5 + tint * moving * .35;
        return mix(sky, color, fog);
    }
    // mirror floor: soft reflections and contact shadows from the nearest dominoes
    float3 p = eye + rd * tFloor;
    float3 color = deep(.6, f) * .07 + paint(.6, f) * .03;
    float near = dominoMap(p + float3(0, .12 * size, 0), front, size, which, index);
    float zi = index * dominoSpacing;
    float3 tint = paint(fract(index * .061 + which * .37) * 1.8, f);
    float floorBand = c.b[int(fmod(abs(index), 4.f))];
    color += tint * (exp(-max(near, 0.f) * 9) * .45 + exp(-max(near, 0.f) * 2.5) * .06) * (1 + floorBand * 2.5);
    color *= .55 + .45 * smoothstep(0.f, .12f, dominoMap(p + light * .08, front, size, which, index));
    float2 g = p.xz;
    color += paint(.5, f) * .04 * exp(-abs(fract(g.x * .5) - .5) * 40) * exp(-tFloor * .1);
    float reflection = pow(1 - abs(rd.y), 5.f);
    color += sky * reflection * 1.5;
    return mix(sky, color, fog);
}

// ---------------------------------------------------------------- Aerial Silks
// Circus aerial silks under a big top: long doubled fabric drops hang from the rigging,
// swinging like pendulums with ripples running down them and twisting into spiral wraps,
// inside soft spotlight cones and haze under strings of lights. Zoom speed pans along the
// ring. Bass swings the silks wider, attacks unroll a drop so its wrap slides down and
// spins loose.


// ---------------------------------------------------------------- Hula Hoops
// Columns of glowing LED hoops gyrate in the dark at two depths, each hoop a tilted
// ellipse of chasing LEDs that leaves a long light-painted trail, with face-on hoops
// spinning above and everything mirrored in a glossy floor. Zoom speed pans along the
// line. Bass lights extra hoops low in each column, attacks toss a hoop upward and highs
// sparkle the LEDs.


#define RAVE_EFFECTS(X) X(smokeRings) X(wandOrbs)  X(stringResonance) X(lightBars) X(sequinCurtain)   X(stadiumWave) X(liquidFloor)    X(dominoRun)  
RAVE_EFFECTS(NATIVE_EFFECT)
