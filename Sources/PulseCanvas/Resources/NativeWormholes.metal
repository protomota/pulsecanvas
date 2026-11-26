// PulseCanvas native designs: tunnels and wormholes (scenes 117–133). Original procedural
// code; see NativeCommon.metal. Every design is a pure function of its uniforms and every
// audio term is zero at zero Chaos.

// ---------------------------------------------------------------- shared tube helpers
// Centreline offset of the bending tubes (in tube radii) at world depth z.
float2 whPath(float z, float bend) {
    return bend * float2(sin(z * .21) + .45 * sin(z * .13 + 1.7), .75 * cos(z * .17) + .35 * sin(z * .09 + .4));
}
// Screen offset of the bent tube centre at view depth d, for a camera riding the axis at
// world depth zc and looking along the local tangent.
float2 whCentre(float zc, float d, float bend, float lens) {
    float2 slope = whPath(zc + .5, bend) - whPath(zc - .5, bend);
    return (whPath(zc + d, bend) - whPath(zc, bend) - slope * d) * lens / max(d, 1e-3f);
}
// Lateral offset of the view ray from the bent tube centre at view depth d.
float2 whLateral(float2 uv, float d, float2 base, float2 slope, float zc, float bend, float lens) {
    return uv * d / lens - (whPath(zc + d, bend) - base - slope * d);
}
// View of a bending tube of the given radius: the first depth at which the view ray
// leaves the tube, found by a geometric march and a short bisection so the far throat
// stays stable. x = angle around the axis, y = world depth of the wall, z = view depth,
// w = screen radius of the wall circle at that depth.
float4 whTube(float2 uv, float zc, float bend, float lens, float radius) {
    float2 base = whPath(zc, bend), slope = whPath(zc + .5, bend) - whPath(zc - .5, bend);
    // Start the march near the straight-tube answer when the ray is still inside there.
    float guess = .5 * lens * radius / max(length(uv), 1e-3f);
    float d = length(whLateral(uv, guess, base, slope, zc, bend, lens)) < radius ? min(guess, 60.f) : .04 * radius;
    float lo = 0, hi = 80;
    for (int i = 0; i < 26; ++i) {
        if (length(whLateral(uv, d, base, slope, zc, bend, lens)) >= radius) { hi = d; break; }
        lo = d;
        d *= 1.35;
        if (d > 80) break;
    }
    if (hi < 80) {
        for (int i = 0; i < 7; ++i) {
            float mid = .5 * (lo + hi);
            if (length(whLateral(uv, mid, base, slope, zc, bend, lens)) >= radius) hi = mid; else lo = mid;
        }
    }
    d = min(.5 * (lo + hi), 80.f);
    float2 lateral = whLateral(uv, d, base, slope, zc, bend, lens);
    return float4(atan2(lateral.y, lateral.x), zc + d, d, lens * radius / d);
}
float whWrap(float a) { return a - TAU * floor(a / TAU + .5); }
// Value noise and fbm that repeat every `period` cells in x, for seamless angles.
float whNoiseP(float2 p, float period) {
    float2 i = floor(p), fr = fract(p), u = fr * fr * (3 - 2 * fr);
    float x0 = i.x - period * floor(i.x / period);
    float x1 = x0 + 1 < period ? x0 + 1 : 0.f;
    return mix(mix(hash21(float2(x0, i.y)), hash21(float2(x1, i.y)), u.x),
               mix(hash21(float2(x0, i.y + 1)), hash21(float2(x1, i.y + 1)), u.x), u.y);
}
float whFbmP(float2 p, float period, int octaves) {
    float sum = 0, amplitude = .5;
    for (int i = 0; i < octaves; ++i) {
        sum += amplitude * whNoiseP(p, period);
        p = p * 2 + float2(0, 1.37);
        period *= 2;
        amplitude *= .5;
    }
    return sum;
}
// Voronoi that repeats every `period` cells in x. x = nearest distance, y = second
// distance, zw = nearest cell id; toSite receives the offset to the nearest site.
float4 whVoronoiP(float2 p, float period, float jitter, thread float2 &toSite) {
    float2 cell = floor(p), fr = fract(p), winner = 0;
    float first = 8, second = 8;
    toSite = 0;
    for (int y = -1; y <= 1; ++y) for (int x = -1; x <= 1; ++x) {
        float2 g = float2(x, y), id = cell + g;
        id.x -= period * floor(id.x / period);
        float2 delta = g + .5 + jitter * (hash22(id) - .5) - fr;
        float dist = length(delta);
        if (dist < first) { second = first; first = dist; winner = id; toSite = delta; } else second = min(second, dist);
    }
    return float4(first, second, winner);
}
// Distance fog weight (1 near, 0 far).
float whFog(float d, Ctx c, float base, float range) { return exp(-d * (base + c.fog * range)); }

// ---------------------------------------------------------------- 117 Storm Eye
// Flying down the eye of a storm: a dense outer cloud wall and two sparse inner wisp
// shells in polar coordinates, lit softly from the calm, bright eye ahead. Attacks fire
// branching lightning inside the nearby cloud banks and light only the cloud around each
// bolt; highs bring fine rain. At zero Chaos the clouds keep a soft inner glow.
// Periodic fbm returning the full sum and the sum of its three broadest octaves.
float2 stormFbm(float2 p, int octaves) {
    float sum = 0, broad = 0, amplitude = .5, period = 8;
    for (int i = 0; i < octaves; ++i) {
        sum += amplitude * whNoiseP(p, period);
        if (i == 2) broad = sum;
        p = p * 2 + float2(0, 1.37);
        period *= 2;
        amplitude *= .5;
    }
    return float2(sum, broad);
}
float2 stormWarp(float2 w, float t) {
    return (float2(whFbmP(w * .5 + float2(0, t * .04), 4, 2), whFbmP(w * .5 + float2(2, 5.3 - t * .03), 4, 2)) - .5) * 2.8;
}
float stormJag(float s, float seed, float t) {
    float x = s * 4 + seed * 7, k = floor(x), fr = x - k;
    float coarse = mix(hash11(k + seed * 13), hash11(k + 1 + seed * 13), fr) - .5;
    float y = s * 13 + seed * 3, j = floor(y), fy = y - j;
    float fine = mix(hash11(j + seed * 29), hash11(j + 1 + seed * 29), fy) - .5;
    float wobble = mix(sin(t * 7 + k * 1.7 + seed), sin(t * 7 + (k + 1) * 1.7 + seed), fr);
    return coarse + fine * .45 + .12 * wobble;
}
// Distance from `local` (wall offset from the bolt centre) to a forked bolt.
float stormBolt(float2 local, float seed, float t) {
    float angle = PI * .5 + (hash11(seed * 1.7) - .5) * 1.5;
    float2 dir = float2(cos(angle), sin(angle)), nrm = float2(-dir.y, dir.x);
    float len = .75 + hash11(seed + 3.1) * .45;
    float s = dot(local, dir) / len, sc = clamp(s, -1.f, 1.f);
    float main = length(float2((s - sc) * len, dot(local, nrm) - stormJag(sc, seed, t) * .26 * len));
    float s0 = (hash11(seed + 5.3) - .5) * .9;
    float2 origin = dir * s0 * len + nrm * stormJag(s0, seed, t) * .26 * len;
    float turn = (hash11(seed + 8.9) > .5 ? 1 : -1) * (.5 + hash11(seed + 2.2) * .4);
    float2 bdir = float2(dir.x * cos(turn) - dir.y * sin(turn), dir.x * sin(turn) + dir.y * cos(turn));
    float blen = len * .55;
    float2 bl = local - origin;
    float bs = dot(bl, bdir) / blen, bsc = clamp(bs, 0.f, 1.f);
    float branch = length(float2((bs - bsc) * blen, dot(bl, float2(-bdir.y, bdir.x)) - stormJag(bsc, seed + 17, t) * .2 * blen * bsc));
    return min(main, branch * 1.25);
}
float3 stormEye(Ctx c, constant NativeFrame &f) {
    const float lens = 1.05, rowGap = 1.9;
    // The music clock adds to the forward motion, so energetic passages speed it up.
    float zc = c.travel * 1.6 + c.m * 1.2;
    float4 tube = whTube(c.uv, zc, .45, lens, 1);
    float a = tube.x, r = tube.w;
    float3 eye = paint(.78, f) * .5 + paint(.95, f) * .1;
    float3 color = 0;
    float transmit = 1;
    for (int s = 0; s < 3; ++s) {
        float radius = s == 0 ? .5 : (s == 1 ? .74 : 1.f);
        float d = min(lens * radius / max(r, 1e-3f), 80.f);
        float z = zc + d;
        // Fine cloud detail dissolves into the haze once it is smaller than a pixel.
        float foot = c.px * d * d / lens * 1.25 / c.size;
        float calm = smoothstep(.08f, .5f, foot);
        float2 w = float2(a / TAU * 8 + float(s) * 2, z * 1.25 / c.size + float(s) * 17.3);
        int octaves = s == 2 ? 6 : 3 + s;
        // One warp serves both samples; the lighting sample needs only the broad octaves.
        float2 warped = w + stormWarp(w, c.t + c.m * 2);
        float2 sample = stormFbm(warped, octaves);
        float dens = mix(sample.x, .5f, calm);
        float ahead = mix(whFbmP(warped + float2(0, .3), 8, 3) + sample.x - sample.y, .5f, calm);
        float rim = clamp((dens - ahead) * 5, -1.f, 1.f);
        float cover = s == 2 ? 1.f : smoothstep(s == 0 ? .6f : .52f, s == 0 ? .8f : .72f, dens) * (s == 0 ? .75f : .9f);
        float body = smoothstep(.2f, .85f, dens);
        float3 cloud = mix(deep(.3 + dens * .2, f) * .18, paint(.2 + dens * .45, f) * .42, body);
        cloud *= .45 + .9 * max(rim, 0.f) + .25 * body;
        cloud += paint(.75, f) * pow(max(rim, 0.f), 3.f) * body * (.35 + c.b.z * 1.4);
        // Soft inner glow drifting through the banks (always on, never music driven).
        float pocket = smoothstep(.55f, .9f, whNoiseP(w * .5 + float2(0, -c.t * .1), 4));
        // Low and low-mid bands swell the glow pockets in their own halves of the storm.
        float pocketBand = mix(c.b.x, c.b.y, step(0.f, sin(a)));
        cloud += paint(.62 + dens * .2, f) * pocket * body * (.55 + .45 * sin(c.t * .9 + w.y * .7) + pocketBand * 2.2) * .3;
        // Lightning in the nearest cloud cells (rows x four sectors): each bolt lights only
        // its own neighbourhood of cloud.
        float row = floor(z / rowGap);
        float sector = floor((a + PI) / TAU * 4);
        for (int k = -1; k <= 1; ++k) for (int m = -1; m <= 1; ++m) {
            float id = row + float(k), boltZ = (id + .5) * rowGap, gap = boltZ - zc;
            float cell = sector + float(m);
            cell -= 4 * floor(cell / 4);
            float seed = id * 4 + cell;
            float strength = c.hit * step(.55f, hash11(seed * 3.7)) * smoothstep(.2f, 1.2f, gap) * (1 - smoothstep(5.f, 7.5f, gap));
            if (strength <= 0) continue;
            strength *= .8 + .2 * sin(c.t * 31 + seed * 5);
            float boltAngle = (cell + .2 + .6 * hash11(seed * 7.1)) / 4 * TAU - PI;
            float3 offset = float3(whWrap(a - boltAngle), z - boltZ, (1 - radius) * 1.3);
            // Compact light pool: every bolt that can reach this pixel is evaluated.
            float reach = max(1 - length(offset * float3(1, .6, 1)), 0.f);
            float pool = reach * reach * strength;
            cloud += paint(.86, f) * pool * (.3 + body) * 1.2;
            if (s == 2 && length(offset.xy) < 1.9) {
                float width = max(c.px * d * d / lens, .006f);
                float bolt = stormBolt(float2(offset.x * radius, offset.y), seed, c.t);
                cloud += (paint(.96, f) * exp(-bolt / (width * 1.5)) + paint(.82, f) * exp(-bolt * 7) * .45) * strength * 2.4;
            }
        }
        float clear = whFog(d, c, .05, .1);
        cloud = mix(eye * (.3 + .7 * smoothstep(.2f, .9f, dens)), cloud, clear);
        color += transmit * cover * cloud;
        transmit *= 1 - cover;
    }
    color += paint(.88, f) * .3 * exp(-r * 5);
    // Fine rain streaks driven by the highs.
    if (c.b.w > .001) {
        float rain = 0;
        for (int layer = 0; layer < 2; ++layer) {
            float scale = 9 + float(layer) * 6;
            float2 p = c.uv * scale;
            p.x += p.y * .22;
            float column = floor(p.x), within = fract(p.x) - .5;
            float seed = hash11(column + float(layer) * 41);
            float y = fract(p.y * .12 + c.t * (1.4 + float(layer) * .6) + seed);
            rain += exp(-within * within * 900) * smoothstep(0.f, .05f, y) * (1 - smoothstep(.05f, .22f, y)) * step(.45f, seed);
        }
        color += paint(.92, f) * rain * c.b.w * .7;
    }
    return color * .85;
}

// ---------------------------------------------------------------- 118 Sonar Pipe
// Inside a brushed-metal pipe: fine circumferential grain, long anisotropic highlights,
// seams with rivets, and sonar pings (thin bright rings with trailing ripples) racing
// along the pipe in both directions so their ripples interfere. Bass strengthens the
// outbound pings, each attack launches a fresh ping from the camera, highs shimmer.
float sonarWave(float x, float spacing, float width, float outbound) {
    float fr = fract(x);
    float behind = (outbound > 0 ? 1 - fr : fr) * spacing;
    float nearest = min(fr, 1 - fr) * spacing;
    return exp(-nearest * nearest / (width * width)) + exp(-behind * .9) * cos(behind * 9) * .7;
}
float3 sonarPipe(Ctx c, constant NativeFrame &f) {
    const float lens = 1.1;
    // The music clock adds to the forward motion, so energetic passages speed it up.
    float zc = c.travel * 1.5 + c.m * 1.0;
    float4 tube = whTube(c.uv, zc, .3, lens, 1);
    float a = tube.x, z = tube.y, d = tube.z;
    float foot = c.px * d * d / lens;
    float sharp = exp(-foot * 40);
    // Brushed grain: fine lines running around the pipe.
    float grain = whNoiseP(float2(a / TAU * 3, z * 170), 3) * .45 + whNoiseP(float2(a / TAU * 5 + .5, z * 55), 5) * .35 + whNoiseP(float2(a / TAU * 2, z * 9), 2) * .2;
    grain = mix(.5, grain, sharp * .8 + .2 * exp(-foot * 6));
    // Seams every 1.25 with a rivet row on each side.
    float seamZ = z - round(z / 1.25) * 1.25;
    float seam = 1 - smoothstep(.006f, .014f + foot, abs(seamZ));
    float lip = smoothstep(.012f, .022f, abs(seamZ)) * (1 - smoothstep(.022f, .05f, abs(seamZ)));
    float cellAngle = (floor(a / TAU * 16) + .5) * TAU / 16;
    float2 rivet = float2(whWrap(a - cellAngle), (abs(seamZ) - .085) / clamp(d, .5f, 2.5f));
    float rivetR = length(rivet) / .032;
    float dome = sqrt(max(1 - rivetR * rivetR, 0.f));
    float rivetLit = dome > 0 ? (.25 + .75 * max(dot(normalize(float3(rivet / .032, dome)), normalize(float3(-.4, .6, .7))), 0.f)) : 0.f;
    float rivetSpec = dome > 0 ? pow(max(dot(normalize(float3(rivet / .032, dome)), normalize(float3(-.3, .45, .85))), 0.f), 24.f) : 0.f;
    float rivetEdge = smoothstep(1.f + foot * 30, 1.f, rivetR);
    // Anisotropic highlights: long streaks along the pipe, broken into rings by the grain.
    float streak = pow(max(cos(a - 1.75), 0.f), 14.f) + .55 * pow(max(cos(a + 1.35), 0.f), 8.f);
    float aniso = streak * (.25 + 1.6 * grain * grain) * (.45 + .55 * smoothstep(.3f, 3.f, d));
    float plate = hash11(round(z / 1.25) * 3.1);
    float3 metal = mix(deep(.2, f), paint(.28 + plate * .06, f), .45) * (.07 + .24 * grain) * (.85 + .3 * plate);
    metal += paint(.5 + grain * .25, f) * aniso * .85;
    metal *= 1 - seam * .85;
    metal += paint(.6, f) * lip * .1;
    metal = mix(metal, paint(.45, f) * rivetLit * .5 + paint(.95, f) * rivetSpec * .6, rivetEdge * sharp);
    // Sonar pings: an outbound and an inbound train interfere.
    float spacing = 2.6 * c.size, width = .028;
    float widthEff = max(width, foot * .8);
    float outbound = sonarWave((z - c.t * 2.4 - c.m * 2.5) / spacing, spacing, widthEff, 1) * (1 + c.b.x * 2.2);
    float inbound = sonarWave((z + c.t * 1.5 + c.m * 1.5) / (spacing * 1.47) + .31, spacing * 1.47, widthEff, -1) * (.8 + c.b.z * 1.6);
    float field = (outbound + inbound) * mix(1.f, width / widthEff, .7f);
    float ring = (field * field * .4 + max(field, 0.f) * .6) * smoothstep(.25f, 1.1f, d);
    // A fresh ping rides out from the camera as each attack envelope decays.
    float pingZ = zc + .7 + (1 - c.hit) * 9;
    float behindPing = pingZ - z;
    float ping = exp(-pow((z - pingZ) / widthEff, 2.f)) * 2 + step(0.f, behindPing) * exp(-behindPing * 1.2) * max(cos(behindPing * 9), 0.f) * .8;
    ping *= c.hit * c.hit;
    float shimmer = pow(whNoiseP(float2(a / TAU * 160, z * 140 + c.t * 5), 160), 10.f) * sharp * c.b.w * 2 * (.15 + aniso * 2.5);
    float clear = whFog(d, c, .03, .09);
    float3 color = metal * (.4 + .6 * clear);
    color += paint(.8 + clamp(ring, 0.f, 2.f) * .08, f) * ring * .4 * (.35 + .65 * clear);
    color += paint(.6, f) * max(ring, 0.f) * (aniso + .15) * .5;
    color += paint(.95, f) * ping * 1.4 * (.5 + .5 * clear);
    color += paint(.9, f) * shimmer * clear;
    color = mix(deep(.2, f) * .1, color, .2 + .8 * clear);
    return color * .78;
}

// ---------------------------------------------------------------- 119 Cube Helix
// Raymarched glossy cubes strung on a double helix around the flight path, each spinning
// on its own axis, faces painted from the palette with a rim light, two faint glowing
// rails tracing the strands, and dark space with stars beyond. Bass swells the cubes
// nearest the camera, highs glint along their edges and attacks flip them over.
constant float helixRadius = 1.15, helixGap = .42, helixTwist = .38;
float3 helixCentre(float i, float strand, float t) {
    float angle = i * helixTwist + strand * PI + t * .25;
    return float3(helixRadius * cos(angle), helixRadius * sin(angle), i * helixGap);
}
// Spin of one cube: returns the two rotation angles (xy plane, then yz plane).
float2 helixSpin(float id, Ctx c) {
    float seed = hash11(id * 1.37);
    float flip = c.hit * 1.7 * (seed > .5 ? 1 : -1);
    return float2(c.t * (.45 + seed * .8) + seed * 6.3 + flip, c.t * (.3 + seed * .5) + seed * 3.1 + flip * .6);
}
float helixSize(float i, Ctx c, float zc) {
    float bass = c.b.x * .55 * exp(-max(i * helixGap - zc, 0.f) * .35);
    return min(.15 * c.size, .3f) * (1 + bass);
}
float helixField(float3 p, Ctx c, float zc, thread float &which, thread float &rail) {
    float best = 1e3;
    float base = round(p.z / helixGap);
    for (int k = -1; k <= 1; ++k) for (int s = 0; s < 2; ++s) {
        float i = base + float(k), id = i * 2 + float(s);
        float3 q = p - helixCentre(i, float(s), c.t + c.m * 1.2);
        float2 spin = helixSpin(id, c);
        q.xy = rot(q.xy, spin.x);
        q.yz = rot(q.yz, spin.y);
        float size = helixSize(i, c, zc);
        float dist = sdBox(q, float3(size - .025)) - .025;
        if (dist < best) { best = dist; which = id; }
    }
    rail = 1e3;
    for (int s = 0; s < 2; ++s) {
        float angle = p.z / helixGap * helixTwist + float(s) * PI + (c.t + c.m * 1.2) * .25;
        rail = min(rail, length(p.xy - helixRadius * float2(cos(angle), sin(angle))));
    }
    return best;
}
float3 cubeHelix(Ctx c, constant NativeFrame &f) {
    // The music clock adds to the forward motion, so energetic passages speed it up.
    float zc = c.travel * 1.8 + c.m * 1.4;
    float3 ro = float3(sin(c.t * .23) * .12, cos(c.t * .19) * .12, zc);
    float3 forward = float3(sin(c.t * .11) * .12, cos(c.t * .13) * .1, 1);
    float3 rd = cameraRay(c.uv, forward, float3(sin(c.t * .07) * .4, 1, 0), 1.15);
    // Background: faint nebula and stars.
    float2 sky = rd.xy / max(rd.z, .05f);
    float cloud = fbm2(sky * 1.3 + c.t * .01, 3);
    float3 color = mix(paint(.97, f) * .07, paint(.03, f) * .06, smoothstep(.35f, .7f, cloud)) + paint(.8, f) * .04 * smoothstep(.55f, .8f, fbm2(sky * 2.1 + 4.2, 3));
    for (int layer = 0; layer < 2; ++layer) {
        float2 g = sky * (18 + float(layer) * 23);
        float2 cell = floor(g);
        float h = hash21(cell + float(layer) * 31);
        float2 at = hash22(cell + 7) - .5;
        float star = exp(-length(fract(g) - .5 - at * .6) * 16) * step(.9f, h);
        color += paint(.85 + h * .1, f) * star * (.5 + .5 * sin(c.t * (1 + h * 3) + h * 40)) * .8;
    }
    // March only through the annulus that holds the helix.
    float2 o = ro.xy, dxy = rd.xy;
    float a2 = dot(dxy, dxy), b = dot(o, dxy);
    float margin = .5;
    float inner = helixRadius - margin, outer = helixRadius + margin;
    float tIn = (-b + sqrt(max(b * b - a2 * (dot(o, o) - inner * inner), 0.f))) / max(a2, 1e-5f);
    float tOut = (-b + sqrt(max(b * b - a2 * (dot(o, o) - outer * outer), 0.f))) / max(a2, 1e-5f);
    tIn = max(tIn, 0.f);
    tOut = min(tOut, 32.f);
    float travel = tIn, which = 0, rail = 9, railGlow = 0;
    float3 glowSum = 0;
    bool hit = false;
    for (int i = 0; i < 56 && travel < tOut; ++i) {
        float3 p = ro + rd * travel;
        float d = helixField(p, c, zc, which, rail);
        float fade = whFog(travel, c, .02, .07);
        glowSum += paint(hash11(which * 1.37) * 1.1, f) * exp(-d * 9) * .022 * fade;
        railGlow += exp(-rail * 30) * .05 * fade;
        if (d < .002 * (1 + travel * .5)) { hit = true; break; }
        travel += max(d * .9, .01f);
    }
    color += glowSum * (1 + c.b.y * 1.5) + paint(.8, f) * railGlow * (1 + c.b.z * 3);
    if (hit) {
        float3 p = ro + rd * travel;
        float i = floor(which * .5), strand = which - i * 2;
        float3 q = p - helixCentre(i, strand, c.t + c.m * 1.2);
        float2 spin = helixSpin(which, c);
        q.xy = rot(q.xy, spin.x);
        q.yz = rot(q.yz, spin.y);
        float size = helixSize(i, c, zc);
        float3 aq = abs(q);
        float3 nl = aq.x > aq.y && aq.x > aq.z ? float3(sign(q.x), 0, 0) : (aq.y > aq.z ? float3(0, sign(q.y), 0) : float3(0, 0, sign(q.z)));
        float face = dot(nl, float3(1, 2, 3)) + 3;
        float3 n = nl;
        n.yz = rot(n.yz, -spin.y);
        n.xy = rot(n.xy, -spin.x);
        // Edge factor: the second largest coordinate approaches the half size.
        float second = max(min(aq.x, aq.y), min(max(aq.x, aq.y), aq.z));
        float edge = smoothstep(size * .78, size * .98, second);
        float seed = hash11(which * 1.37);
        float3 albedo = paint(seed * 1.1 + face * .05 + c.t * .015, f);
        float3 key = normalize(float3(.45, .75, -.45));
        float diffuse = max(dot(n, key), 0.f);
        float3 r = reflect(rd, n);
        float spec = pow(max(dot(r, key), 0.f), 40.f);
        float rim = pow(1 - max(dot(n, -rd), 0.f), 3.f);
        float3 env = deep(.3 + r.y * .2, f) * .4 + paint(.8, f) * pow(max(r.z, 0.f), 6.f) * .5;
        float3 cube = albedo * (.2 + .9 * diffuse) + env * .2 + paint(.95, f) * spec * .8 + albedo * rim * .45;
        cube += paint(.9, f) * edge * (.12 + c.b.w * 1.4 * (.6 + .4 * sin(c.t * 13 + seed * 50)));
        float fade = whFog(travel, c, .02, .07);
        color = mix(color, cube, fade) + glowSum * .5;
    }
    return color;
}

// ---------------------------------------------------------------- 120 Phyllo Tube
// Glowing beads set on the golden angle along the inside of a tube, so they form the
// interlocking 13 and 21 spirals of a sunflower head unrolled around the walls. The
// lattice turns as you travel; bead size swells and shrinks along the depth index.
// Each band brightens its own family of spiral arms; attacks swell two arms.
float3 phylloTube(Ctx c, constant NativeFrame &f) {
    const float lens = 1.0, alpha = .381966, rise = .016;
    // The music clock adds to the forward motion, so energetic passages speed it up.
    float zc = c.travel * 1.3 + c.m * 1.0;
    float4 tube = whTube(c.uv, zc, .3, lens, 1);
    float a = tube.x, z = tube.y, d = tube.z;
    float foot = c.px * d * d / lens;
    // Beads are round on screen: depth offsets are measured in view-scaled units.
    float squash = clamp(d, .35f, 2.2f);
    float2 p = float2((a / TAU - c.t * .035 - c.m * .04) * TAU, z);
    float2 A = float2((13 * alpha - 5) * TAU, 13 * rise), B = float2((21 * alpha - 8) * TAU, 21 * rise);
    float det = A.x * B.y - A.y * B.x;
    float2 lattice = float2(p.x * B.y - p.y * B.x, A.x * p.y - A.y * p.x) / det;
    float2 base = floor(lattice);
    float3 color = deep(.3 + z * .01, f) * .08 * (.6 + .4 * whNoiseP(float2(a / TAU * 16, z * 3), 16));
    // Faint grooves along one spiral family.
    float groove = abs(fract(lattice.y) - .5) * length(B) * .9;
    color += paint(.35, f) * exp(-groove / max(.012f, foot)) * .08;
    float best = 1e3;
    float3 halo = 0;
    for (int j = -1; j <= 1; ++j) for (int i = -1; i <= 1; ++i) {
        float2 id = base + float2(i, j);
        float n = 13 * id.x + 21 * id.y;
        float2 offset = p - (id.x * A + id.y * B);
        offset.y /= squash;
        float arm = n - 13 * floor(n / 13);
        int family = int(arm) % 4;
        float swell = .62 + .38 * sin(n * TAU / 233 + 1.3);
        float hitArm = (arm == 0 || arm == 7) ? c.hit : 0.f;
        float radius = min(.075 * c.size * swell * (1 + hitArm * .6), .16f);
        float dist = length(offset);
        float lit = 1 + c.b[family] * 1.8 + hitArm * 1.6;
        float3 tint = paint(fract(n * .0021 - c.t * .05) * 2 + arm * .02, f);
        halo += tint * exp(-max(dist - radius, 0.f) / (.03 + foot * .3)) * .2 * lit;
        float edgeWidth = foot / squash + .004;
        if (dist < radius + edgeWidth && dist < best) {
            best = dist;
            float2 nxy = offset / radius;
            float nz = sqrt(max(1 - dot(nxy, nxy), 0.f));
            // Lit from the camera side with a cool rim.
            float diffuse = max(dot(float3(nxy, nz), normalize(float3(-.45, .55, .8))), 0.f);
            float spec = exp(-dot(nxy - float2(-.32, .38), nxy - float2(-.32, .38)) * 26);
            float rim = pow(1 - nz, 3.f);
            float edge = smoothstep(radius + edgeWidth, radius - edgeWidth, dist);
            float3 sphere = tint * (.18 + .85 * diffuse) * lit + paint(.97, f) * spec * .8 + paint(fract(n * .0021) * 2 + .4, f) * rim * .35;
            color = mix(color, sphere, edge);
        }
    }
    color += halo;
    // Far beads blur into the glow of their spirals.
    float clear = whFog(d, c, .03, .1) * exp(-foot * 2);
    float3 far = paint(.55 + sin(c.t * .2) * .1, f) * .3;
    return mix(far, color, clear) + paint(.85, f) * .3 * exp(-tube.w * 6);
}

// ---------------------------------------------------------------- 121 Tesla Tube
// A dark ribbed metal tube studded with electrode knobs. Plasma arcs crackle between
// neighbouring electrodes as jagged glowing strokes that light the metal around them.
// Bass wakes more arcs and brightens them, highs spit corona sparks around the knobs and
// attacks fire a large arc straight across the tunnel a few metres ahead.
float teslaJag(float s, float seed, float t) {
    float x = s * 7, k = floor(x), fr = x - k;
    float a0 = hash11(k + seed * 17) - .5 + .25 * sin(t * 23 + k * 2.1 + seed);
    float a1 = hash11(k + 1 + seed * 17) - .5 + .25 * sin(t * 23 + (k + 1) * 2.1 + seed);
    float y = s * 19, j = floor(y), fy = y - j;
    float f0 = (hash11(j + seed * 31) - .5) * sin(t * 17 + j + seed);
    float f1 = (hash11(j + 1 + seed * 31) - .5) * sin(t * 17 + j + 1 + seed);
    return mix(a0, a1, fr) + mix(f0, f1, fy) * .35;
}
// Distance from p to a jagged arc from a to b.
float teslaArc(float2 p, float2 a, float2 b, float seed, float t) {
    float2 ab = b - a;
    float len = max(length(ab), 1e-3f);
    float2 dir = ab / len, nrm = float2(-dir.y, dir.x);
    float s = dot(p - a, dir) / len, sc = clamp(s, 0.f, 1.f);
    float offset = teslaJag(sc, seed, t) * .22 * len * sin(PI * sc);
    return length(float2((s - sc) * len, dot(p - a, nrm) - offset));
}
float3 teslaTube(Ctx c, constant NativeFrame &f) {
    const float lens = 1.05, rowGap = 1.6, perRing = 6, ribGap = .4;
    // The music clock adds to the forward motion, so energetic passages speed it up.
    float zc = c.travel * 1.4 + c.m * 1.0;
    float4 tube = whTube(c.uv, zc, .32, lens, 1);
    float a = tube.x, r = tube.w;
    // Ribs push the wall inward; refine the depth once against the ribbed radius.
    float rib = pow(.5 + .5 * cos((zc + tube.z) * TAU / ribGap), 2.f);
    float d = tube.z * (1 - .07 * rib);
    float z = zc + d;
    float phase = z * TAU / ribGap;
    rib = pow(.5 + .5 * cos(phase), 2.f);
    float foot = c.px * d * d / lens;
    float sharp = exp(-foot * 10);
    float facing = -sin(phase);   // > 0 on the rib flank that faces the camera
    float3 color = deep(.12, f) * .1 + paint(.2, f) * .03;
    // Low-mids run a glow wave along the ribs.
    float ribWave = c.b.y * pow(.5 + .5 * sin(z * .8 - c.t * 3 - c.m * 3), 2.f);
    float ribLight = mix(.35f, .6f + .9 * max(facing, 0.f) * rib + .25 * rib, sharp) * (1 + ribWave * 2.2);
    color += mix(deep(.25, f), paint(.3, f), .3) * ribLight * .18;
    color += paint(.55, f) * pow(max(cos(a - 1.8), 0.f), 14.f) * pow(rib, 3.f) * .35 * sharp;
    // Electrodes and the arcs between them.
    float row = floor(z / rowGap);
    float arcs = 0, glowLight = 0, corona = 0;
    float3 knobColor = 0;
    float knobMask = 0;
    float squash = clamp(d, .35f, 2.5f);
    for (int k = -1; k <= 1; ++k) {
        float rowId = row + float(k);
        float rowZ = rowId * rowGap;
        float shift = fmod(fabs(rowId), 2.f) * .5;
        float column = round(a / TAU * perRing - shift);
        for (int i = -1; i <= 1; ++i) {
            float colId = column + float(i);
            float wrapped = colId - perRing * floor(colId / perRing);
            float angle = (colId + shift) / perRing * TAU;
            float2 local = float2(whWrap(a - angle), z - rowZ);
            float seed = hash21(float2(wrapped, rowId));
            // Bass wakes more arcs; each arc also brightens with its own band.
            float band = c.b[int(fract(seed * 7.3) * 3.99)];
            float wake = .5 + .5 * sin(c.t * (.6 + seed * .8) + c.m * (.8 + seed) + seed * 40) + c.b.x * .9;
            float near = exp(-foot * 6) * smoothstep(7.f, 3.5f, d);
            float on = smoothstep(.55f, .8f, wake) * (.75 + .25 * sin(c.t * 37 + seed * 9)) * (1 + c.b.x * .5 + band * 1.2) * near;
            // Knob: a polished dome, round on screen.
            float2 kl = float2(local.x, local.y / squash) / .085;
            float kr = length(kl);
            float kz = sqrt(max(1 - kr * kr, 0.f));
            float edge = smoothstep(1 + foot * 12, 1.f, kr) * sharp * smoothstep(9.f, 4.f, d);
            float3 n = float3(kl, kz);
            float spec = pow(max(dot(n, normalize(float3(-.35, .45, .82))), 0.f), 18.f);
            float3 knob = deep(.3, f) * .3 + paint(.5, f) * spec * .9 + paint(.85, f) * on * (.6 + .4 * kz);
            knobColor += knob * edge;
            knobMask = max(knobMask, edge);
            float ring = exp(-max(kr - 1, 0.f) * 3) * (1 - edge);
            glowLight += ring * on * .5 * near;
            corona += pow(max(sin(atan2(kl.y, kl.x) * 7 + c.t * 9 + seed * 30), 0.f), 8.f) * exp(-abs(kr - 1.4) * 4) * c.b.w * near;
            // Arc to the next electrode around the ring, or to the next row.
            float2 target = hash11(seed * 9 + 1) > .45 ? float2(TAU / perRing, 0) : float2(TAU / perRing * .5 * (hash11(seed * 3) > .5 ? 1 : -1), rowGap);
            if (on > .001) {
                float dist = teslaArc(local, 0, target, seed * 13 + rowId, c.t);
                float width = max(.007f, foot * .6);
                arcs += (exp(-dist / width) + exp(-dist * 30) * .3) * on;
                glowLight += exp(-dist * 9) * on;
            }
        }
    }
    color = mix(color, knobColor, knobMask);
    color += paint(.72, f) * glowLight * .2 + paint(.6, f) * glowLight * glowLight * .06;
    color += paint(.92, f) * arcs * 1.2 + paint(.97, f) * corona * .7;
    // Attack: a big arc jumps straight across the tunnel a few metres ahead.
    if (c.hit > .001) {
        float first = ceil((zc + 1.5) / rowGap);
        for (int k = 0; k < 3; ++k) {
            float rowId = first + float(k);
            float gap = rowId * rowGap - zc;
            float window = smoothstep(1.5f, 2.5f, gap) * (1 - smoothstep(4.5f, 6.f, gap));
            if (window <= 0) continue;
            float2 centre = whCentre(zc, gap, .32, lens);
            float angle = hash11(rowId * 1.3) * TAU;
            float span = PI * (.75 + .3 * hash11(rowId * 2.9));
            float2 s0 = centre + lens / gap * float2(cos(angle), sin(angle));
            float2 s1 = centre + lens / gap * float2(cos(angle + span), sin(angle + span));
            float dist = teslaArc(c.uv, s0, s1, rowId * 3.3, c.t);
            float strength = c.hit * window;
            color += (paint(.95, f) * exp(-dist / (c.px * 2.5)) + paint(.75, f) * exp(-dist * 12) * .6) * strength * 1.8;
        }
    }
    float clear = whFog(d, c, .03, .09);
    return mix(deep(.25, f) * .12 + paint(.7, f) * .06, color, clear) + paint(.75, f) * .15 * exp(-r * 4);
}

// ---------------------------------------------------------------- 122 Fold Tunnel
// An origami tube in a twisted, Kresling-like fold: rings of vertices alternate between
// mountain and valley radii and each ring turns a little against the last, so the wall is
// a spiral of flat triangles, each with its own lighting, crisp crease lines and a paper
// grain. The folds breathe slowly; bass deepens them and each attack unfolds a ring of
// facets just ahead, which flattens and glows through.
constant float foldColumns = 15;   // a multiple of 3 keeps the vertex levels seamless
float foldDepth(float row, Ctx c, float zc, float rowH) {
    float breathe = .2 + .09 * sin(c.t * .55 + c.m * .8 + row * .29);
    float gap = row * rowH - zc;
    float unfold = c.hit * smoothstep(1.f, 2.f, gap) * (1 - smoothstep(3.2f, 4.6f, gap));
    return breathe * (1 + c.b.x * .8) * (1 - unfold * .95);
}
// Vertex levels cycle through three radii so the three corners of every facet differ.
float foldRadius(float2 v, Ctx c, float zc, float rowH) {
    float k = v.x + 2 * v.y;
    float level = k - 3 * floor(k / 3);
    return 1 - foldDepth(v.y, c, zc, rowH) * level * .5;
}
// Facet containing (angle, z): the three vertex lattice ids and barycentric weights.
void foldFacet(float angle, float z, float rowH, thread float2 &v0, thread float2 &v1, thread float2 &v2, thread float3 &w, thread bool &upper) {
    float y = z / rowH;
    float x = angle / TAU * foldColumns - y * .32;   // each ring twists against the last
    float2 lat = float2(x - .5 * y, y);
    float2 cell = floor(lat), uv = lat - cell;
    upper = uv.x + uv.y > 1;
    if (!upper) { v0 = cell; v1 = cell + float2(1, 0); v2 = cell + float2(0, 1); w = float3(1 - uv.x - uv.y, uv.x, uv.y); }
    else { v0 = cell + 1; v1 = cell + float2(0, 1); v2 = cell + float2(1, 0); w = float3(uv.x + uv.y - 1, 1 - uv.x, 1 - uv.y); }
}
float3 foldVertex(float2 v, float rowH, Ctx c, float zc) {
    float angle = (v.x + .82 * v.y) / foldColumns * TAU;
    float radius = foldRadius(v, c, zc, rowH);
    return float3(radius * cos(angle), radius * sin(angle), v.y * rowH);
}
float3 foldTunnel(Ctx c, constant NativeFrame &f) {
    const float lens = 1.05, bend = .35;
    float rowH = .4 * c.size;
    // The music clock adds to the forward motion, so energetic passages speed it up.
    float zc = c.travel * 1.35 + c.m * .8;
    float4 tube = whTube(c.uv, zc, bend, lens, 1);
    float a = tube.x, d0 = tube.z;
    float2 v0, v1, v2;
    float3 w;
    bool upper;
    // One damped refinement gives near facets some parallax without unstable jumps.
    foldFacet(a, zc + d0, rowH, v0, v1, v2, w, upper);
    float radius = w.x * foldRadius(v0, c, zc, rowH) + w.y * foldRadius(v1, c, zc, rowH) + w.z * foldRadius(v2, c, zc, rowH);
    float d = d0 * mix(1.f, radius, exp(-d0 * .8));
    float z = zc + d;
    foldFacet(a, z, rowH, v0, v1, v2, w, upper);
    float3 p0 = foldVertex(v0, rowH, c, zc), p1 = foldVertex(v1, rowH, c, zc), p2 = foldVertex(v2, rowH, c, zc);
    float3 centroid = (p0 + p1 + p2) / 3;
    float3 n = normalize(cross(p1 - p0, p2 - p0));
    if (dot(n, centroid * float3(1, 1, 0)) > 0) n = -n;
    // Lights: a headlamp at the camera, a key from above ahead and a low fill.
    float3 toCamera = normalize(float3(0, 0, zc) - centroid);
    float head = max(dot(n, toCamera), 0.f);
    float key = max(dot(n, normalize(float3(.3, -.8, -.5))), 0.f);
    float fill = max(dot(n, normalize(float3(-.6, .5, -.6))), 0.f);
    float column = v0.x - foldColumns * floor(v0.x / foldColumns);
    float facetId = hash21(float2(column + (upper ? 31 : 0), v0.y));
    float3 tint = paint(facetId * .9 + v0.y * .02 + c.t * .01, f);
    tint = mix(tint, paint(.97, f), .45 * hash11(facetId * 17));
    float foot = c.px * d * d / lens;
    float grain = mix(1.f, .9f + .2 * noise2(float2(a * 70, z * 60)), exp(-foot * 30));
    float3 color = tint * (.18 + .5 * head + .5 * key * key + .3 * fill) * grain;
    // Distant facets shrink below a pixel: settle them to their average shade.
    color = mix(tint * .5, color, exp(-foot / rowH * 1.5));
    // Creases: distance to the nearest facet edge in lattice units.
    float edgeDist = min(min(w.x, w.y), w.z);
    float crease = (1 - smoothstep(0.f, max(.03f, foot / rowH * 1.5), edgeDist)) * exp(-foot / rowH * 2);
    float valley = upper ? 1.f : 0.f;
    color *= 1 - crease * (.35 + .25 * valley);
    color += paint(.95, f) * crease * .12 * (1 - valley) * (head + key) * (1 + c.b.z * 4);
    // Low-mids light the paper from behind along a slow band of rows.
    float glowRow = pow(.5 + .5 * sin(v0.y * .5 - c.t * .8), 6.f);
    color += tint * glowRow * c.b.y * .5;
    // Light glowing through facets that are unfolding on an attack.
    float gap = v0.y * rowH - zc;
    float unfold = c.hit * smoothstep(1.f, 2.f, gap) * (1 - smoothstep(3.2f, 4.6f, gap));
    color += paint(.75 + facetId * .2, f) * unfold * .9;
    float clear = whFog(d, c, .035, .1);
    float3 haze = deep(.35, f) * .12 + paint(.7, f) * .06;
    return (mix(haze, color, clear) + paint(.85, f) * .28 * exp(-tube.w * 5)) * .54;
}

// ---------------------------------------------------------------- 123 Vector Tube
// A retro vector-display tunnel: glowing wireframe hoops and longitudinal beams with
// phosphor bloom and a slight beam jitter, the tube twisting and bending, with wireframe
// pyramids and cubes tumbling inside. Pure line art on black. Each band lights its own
// set of longitudinal beams; attacks fire a polygon ring burst down the tube.
float vectorBeam(float dist, float width) {
    return exp(-dist * dist / (width * width)) + exp(-dist / (width * 7)) * .22;
}
// Screen position of a point at tube-local offset `local` and view depth d.
float2 vectorProject(float3 local, float zc, float bend, float lens) {
    float d = max(local.z - zc, .05f);
    return whCentre(zc, d, bend, lens) + local.xy * lens / d;
}
float3 vectorTube(Ctx c, constant NativeFrame &f) {
    const float lens = 1.0, bend = .55, hoopGap = .9, beams = 16;
    // The music clock adds to the forward motion, so energetic passages speed it up.
    float zc = c.travel * 2 + c.m * 1.5;
    float2 jitter = float2(noise2(float2(c.t * 37, 1.3)), noise2(float2(5.1, c.t * 41))) - .5;
    float2 uv = c.uv + jitter * c.px * 1.2;
    float4 tube = whTube(uv, zc, bend, lens, 1);
    float a = tube.x, z = tube.y, d = tube.z, r = tube.w;
    float width = c.px * (.8 + .7 * c.size);
    float clear = whFog(d, c, .02, .06);
    float3 color = 0;
    // Hoops.
    float dz = z - round(z / hoopGap) * hoopGap;
    float hoopSpacing = hoopGap * r / d;
    float hoopFade = smoothstep(c.px * 4, c.px * 14, hoopSpacing) * clear;
    float hoopIndex = round(z / hoopGap);
    float major = fmod(fabs(hoopIndex), 4.f) < .5 ? 1.f : 0.f;
    color += paint(.55 + major * .1, f) * vectorBeam(fabs(dz) * r / d, width * (1 + major * .5)) * hoopFade * (.55 + major * .5);
    // Longitudinal beams, twisting along the tube and over time.
    float twist = z * .14 + c.t * .18 + c.m * .25;
    float slot = (a - twist) / TAU * beams;
    float beamId = round(slot);
    float beamDist = fabs(slot - beamId) * TAU / beams * r;
    float wrapped = beamId - beams * floor(beamId / beams);
    int family = int(wrapped) % 4;
    float beamSpacing = TAU / beams * r;
    float beamFade = smoothstep(c.px * 4, c.px * 16, beamSpacing) * clear;
    float level = .5 + c.b[family] * 2.2;
    color += paint(.08 + float(family) * .22, f) * vectorBeam(beamDist, width) * beamFade * level;
    // Far tube glow where lines merge.
    color += paint(.6, f) * .1 * exp(-r * 6);
    // Tumbling wireframe solids.
    float first = floor((zc + .4) / 3);
    for (int k = 0; k < 4; ++k) {
        float id = first + float(k);
        float objZ = (id + .5) * 3;
        float gap = objZ - zc;
        if (gap < .35) continue;
        float seed = hash11(id * 3.17);
        float place = seed * TAU;
        float3 centre = float3(.56 * cos(place), .56 * sin(place), objZ);
        float size = .24 + .06 * hash11(seed * 9);
        float2 screenCentre = vectorProject(centre, zc, bend, lens);
        float reach = size * 1.9 * lens / max(gap - size * 1.8, .05f);
        if (length(uv - screenCentre) > reach + c.px * 30) continue;
        float spinA = c.t * (.5 + seed) + seed * 7, spinB = c.t * (.35 + seed * .4) + seed * 3;
        bool cube = hash11(seed * 5.3) > .45;
        float3 verts[8];
        for (int v = 0; v < 8; ++v) {
            float3 corner;
            if (cube) corner = float3(v & 1 ? 1 : -1, v & 2 ? 1 : -1, v & 4 ? 1 : -1);
            else corner = v < 4 ? float3(v == 0 || v == 3 ? -1 : 1, -.8, v < 2 ? -1 : 1) : float3(0, 1.2, 0);
            corner *= size;
            corner.xy = rot(corner.xy, spinA);
            corner.yz = rot(corner.yz, spinB);
            verts[v] = corner + centre;
        }
        float best = 1e3;
        if (cube) {
            for (int e = 0; e < 12; ++e) {
                int axis = e / 4, rest = e % 4;
                int lo = axis == 0 ? (rest << 1) : (axis == 1 ? ((rest & 1) | ((rest & 2) << 1)) : rest);
                int hi = lo | (1 << axis);
                best = min(best, sdSegment(uv, vectorProject(verts[lo], zc, bend, lens), vectorProject(verts[hi], zc, bend, lens)));
            }
        } else {
            for (int e = 0; e < 4; ++e) {
                float2 base0 = vectorProject(verts[e], zc, bend, lens);
                best = min(best, sdSegment(uv, base0, vectorProject(verts[(e + 1) % 4], zc, bend, lens)));
                best = min(best, sdSegment(uv, base0, vectorProject(verts[4], zc, bend, lens)));
            }
        }
        float fade = smoothstep(.35f, 1.f, gap) * whFog(gap, c, .02, .06);
        color += paint(.82 + seed * .15, f) * vectorBeam(best, width * 1.2) * fade * 1.2;
    }
    // Attack: a polygon ring bursts out of the tube ahead and rushes past.
    if (c.hit > .001) {
        float ringD = .7 + (1 - c.hit) * 6;
        float2 q = uv - whCentre(zc, ringD, bend, lens);
        float radius = .82 * lens / ringD;
        float angle = atan2(q.y, q.x) + c.t * .5;
        float sector = TAU / 12;
        float local = angle - sector * floor(angle / sector) - sector * .5;
        float polygon = length(q) * cos(local) - radius * cos(sector * .5);
        float spoke = fabs(local) * length(q);
        float burst = vectorBeam(fabs(polygon), width * 1.5) + vectorBeam(spoke, width) * smoothstep(radius * .5, radius, length(q)) * (1 - smoothstep(radius, radius * 1.35, length(q))) * step(fabs(local), .2f);
        color += paint(.95, f) * burst * c.hit * 1.6;
    }
    return color;
}

// ---------------------------------------------------------------- 124 Orbital Corridor
// A space-station corridor, traced analytically: an octagonal hull with octagonal frames
// every few metres, inset wall panels, recessed light strips in the corners, a floor
// grating, a ceiling light panel, and windows on the right showing a banded planet and
// stars. Bass sends a travelling chase along the light strips, attacks light up panels
// just ahead, and highs blink the status lights.
float2 orbitalNormal(int i) { float a = float(i) * PI * .25; return float2(cos(a), sin(a)); }
// Exit distance from inside an octagonal prism of apothem `apothem`; face receives the index.
float orbitalExit(float2 o, float2 dxy, float apothem, thread int &face) {
    float best = 1e4;
    face = 0;
    for (int i = 0; i < 8; ++i) {
        float2 n = orbitalNormal(i);
        float den = dot(dxy, n);
        if (den > 1e-4) {
            float t = (apothem - dot(o, n)) / den;
            if (t < best) { best = t; face = i; }
        }
    }
    return best;
}
float3 orbitalSpace(float3 rd, Ctx c, constant NativeFrame &f) {
    float3 color = deep(.2 + rd.y * .1, f) * .05;
    float2 g = float2(atan2(rd.z, rd.x), rd.y) * 60;
    float h = hash21(floor(g));
    color += paint(.85 + h * .1, f) * step(.93f, h) * exp(-length(fract(g) - .5) * 9) * 1.2;
    float3 planetDir = normalize(float3(1, -.3, .75));
    float3 e1 = normalize(cross(planetDir, float3(0, 1, 0))), e2 = cross(e1, planetDir);
    float span = .42;
    float2 disk = float2(dot(rd, e1), dot(rd, e2)) / span;
    float rr = dot(disk, disk);
    float facing = dot(rd, planetDir);
    if (facing > 0) {
        float3 sun = normalize(float3(-.55, .45, .7));
        float atmosphere = exp(-fabs(sqrt(rr) - 1) * 18) * .5;
        if (rr < 1) {
            float3 n = float3(disk, sqrt(1 - rr));
            float lit = max(dot(n, sun), 0.f);
            float bands = disk.y * 7 + .35 * sin(disk.x * 5 + disk.y * 9 + c.t * .05) + fbm2(float2(disk.x * 3 + c.t * .02, disk.y * 12), 3) * 1.5;
            float3 surface = mix(paint(.25 + .1 * sin(bands), f), paint(.65 + .15 * sin(bands * 1.7), f), .5 + .5 * sin(bands * 2.3));
            color = surface * (.04 + lit * .9) + paint(.8, f) * pow(1 - n.z, 3.f) * lit * .6;
        }
        color += paint(.75, f) * atmosphere * (.3 + max(dot(normalize(disk + 1e-4), normalize(sun.xy)), 0.f));
    }
    return color;
}
float3 orbitalCorridor(Ctx c, constant NativeFrame &f) {
    const float apothem = 1, frameApothem = .84, halfFrame = .09;
    float bay = 2.4 * c.size;
    // The music clock adds to the forward drift, so energetic passages speed the flight.
    float zc = c.travel * 1.6 + c.m * 1.2;
    float3 ro = float3(sin(c.t * .21) * .12, -.1 + sin(c.t * .17) * .05, zc);
    float3 rd = cameraRay(c.uv, float3(sin(c.t * .09) * .12, sin(c.t * .07) * .05, 1), float3(sin(c.t * .13) * .06, 1, 0), 1.05);
    int face, frameFace;
    float tWall = min(orbitalExit(ro.xy, rd.xy, apothem, face), 80.f);
    float tFrame = orbitalExit(ro.xy, rd.xy, frameApothem, frameFace);
    float zFrame = ro.z + rd.z * tFrame;
    float slab = zFrame - round(zFrame / bay) * bay;
    int kind = 0;   // 0 wall, 1 frame soffit, 2 frame front face
    float t = tWall;
    if (tFrame < tWall && fabs(slab) < halfFrame) { kind = 1; t = tFrame; }
    else if (tFrame < tWall) {
        float front = ceil((zFrame + halfFrame) / bay) * bay - halfFrame;
        float tFront = (front - ro.z) / max(rd.z, 1e-4f);
        if (tFront < tWall) { kind = 2; t = tFront; }
    }
    float3 p = ro + rd * t;
    int id = kind == 1 ? frameFace : face;
    float2 n2 = orbitalNormal(id);
    float u = dot(p.xy, float2(-n2.y, n2.x));
    float bayIndex = floor((p.z + halfFrame) / bay);
    float lz = p.z + halfFrame - bayIndex * bay;    // 0..bay within the bay, frame at both ends
    float3 normal = kind == 2 ? float3(0, 0, -1) : float3(-n2, 0);
    float foot = c.px * t;
    float3 light = normalize(float3(-p.x * .6, .85 - p.y, -.3));
    float diffuse = .3 + .7 * max(dot(normal, light), 0.f);
    float3 metal = mix(deep(.25, f), paint(.3, f), .35);
    float3 color = metal * .12 * diffuse;
    float3 glowAdd = 0;
    if (kind == 0) {
        float panelZ = lz / (bay * .5);
        float panelId = floor(panelZ);
        float2 cellLocal = float2(u / .36, fract(panelZ) * 2 - 1);
        float seed = hash31(float3(float(id), bayIndex, panelId));
        float inset = sdBox2(cellLocal, float2(.86, .82));
        float groove = 1 - smoothstep(0.f, .05f + foot * 4, fabs(inset));
        float bevel = smoothstep(-.12f, 0.f, inset) * (inset < 0 ? 1.f : 0.f);
        if (id == 6) {
            // Floor grating with a dim glow beneath.
            float2 grid = float2(u * 16, p.z * 8);
            float2 bars = abs(fract(grid) - .5);
            float hole = smoothstep(.32f, .26f, max(bars.x * .9, bars.y * 1.4));
            hole *= exp(-foot * 6);
            // The glow under the grating rides a travelling wave that the bass feeds.
            float underWave = .6 + .4 * sin(p.z * .7 - c.t - c.m * 2);
            color = mix(metal * .16 * diffuse, deep(.4, f) * .12 + paint(.35, f) * (.08 + c.b.x * .45) * underWave, hole);
            color += paint(.6, f) * .04 * (1 - smoothstep(.02f, .04f, fabs(fabs(u) - .2)));
        } else if (id == 2) {
            // Ceiling light panel, broken at each frame.
            float strip = smoothstep(.2f, .17f, fabs(u)) * smoothstep(.1f, .25f, lz) * smoothstep(bay - .1f, bay - .25f, lz);
            // Low-mids send a slow swell along the ceiling panels.
            float swell = pow(.5 + .5 * sin(p.z * .5 - c.t * 2), 4.f) * c.b.y;
            color = metal * .12 * diffuse + paint(.82, f) * strip * (.75 + c.b.y * .8 + swell * 1.5);
        } else if (id == 0 && fabs(u) < .3 && lz > .25 && lz < bay - .25) {
            // Window onto the planet.
            float edge = min(.3 - fabs(u), min(lz - .25, bay - .25 - lz));
            float rim = 1 - smoothstep(0.f, .025f + foot * 2, edge);
            color = orbitalSpace(rd, c, f) * (1 - rim) + paint(.5, f) * rim * .25;
        } else {
            color = metal * (.1 + .07 * seed) * diffuse * (1 - groove * .7) + paint(.4, f) * bevel * .05 * diffuse;
            // Status lights blink smoothly; highs make them flicker brighter.
            float2 ledAt = float2(.6, .55);
            float led = exp(-length((cellLocal - ledAt) * float2(1, .9)) * 22);
            float blink = pow(.5 + .5 * sin(c.t * (1.3 + seed * 3) + c.m * 2 + seed * 40), 6.f);
            glowAdd += paint(fract(seed * 7) < .5 ? .15f : .55f, f) * led * blink * (.4 + c.b.w * 3.5) * step(.3f, seed);
            // Attack: panels just ahead glow from inside.
            float gap = p.z - zc;
            float open = c.hit * step(.55f, seed) * smoothstep(.8f, 2.f, gap) * (1 - smoothstep(4.5f, 7.f, gap));
            glowAdd += paint(.7 + seed * .25, f) * open * (inset < 0 ? .9f : 0.f) * (.6 + .4 * smoothstep(0.f, -.6f, inset));
            // Every wall panel is backlit and pulses with its own band.
            float panelBand = c.b[int(fract(seed * 5.3) * 3.99)];
            glowAdd += paint(.5 + seed * .35, f) * panelBand * .2 * (inset < 0 ? .4 + .6 * smoothstep(0.f, -.5f, inset) : 0.f);
        }
        // Recessed light strips along the corners of the diagonal faces.
        if (id % 2 == 1) {
            float strip = smoothstep(.375f, .395f, fabs(u));
            float chase = pow(.5 + .5 * sin(p.z * 1.4 - c.t * 5 - c.m * 3), 10.f);
            glowAdd += paint(.5 + float(id) * .04, f) * strip * (.5 + c.b.x * .9 + chase * c.b.x * 3);
        }
    } else if (kind == 1) {
        float lip = smoothstep(halfFrame - .02f, halfFrame, fabs(slab));
        color = metal * .22 * diffuse + paint(.6, f) * lip * (.25 + c.b.w * 1.2);
        float bolt = exp(-length(float2(fract(u * 6) - .5, slab * 6)) * 12);
        color += paint(.9, f) * bolt * .25 * exp(-foot * 8);
    } else {
        // Frame front face: brushed ring with a glowing inner edge.
        float2 q = p.xy;
        float oct = 0;
        for (int i = 0; i < 8; ++i) oct = max(oct, dot(q, orbitalNormal(i)));
        float inner = 1 - smoothstep(0.f, .025f + foot * 2, oct - frameApothem);
        float outer = 1 - smoothstep(0.f, .02f + foot * 2, apothem - oct);
        color = metal * (.18 + .08 * sin(oct * 80)) * diffuse + paint(.7, f) * inner * (.7 + c.b.z * 1.5) + paint(.4, f) * outer * .2;
        float marks = step(.5f, fract((atan2(q.y, q.x) / TAU) * 32)) * smoothstep(.9f, .92f, oct) * (1 - smoothstep(.95f, .97f, oct));
        color += paint(.15, f) * marks * .25;
    }
    // Attack: a wave of light runs down the corridor along the strips and frames.
    float waveZ = zc + .5 + (1 - c.hit) * 12;
    float lightWave = c.hit * exp(-pow((p.z - waveZ) * 1.4, 2.f));
    glowAdd += paint(.9, f) * lightWave * (kind == 0 ? .35f : .8f);
    color += glowAdd;
    float clear = whFog(t, c, .02, .07);
    float3 haze = deep(.35, f) * .1 + paint(.7, f) * .1 * exp(-length(c.uv) * 1.5);
    return mix(haze, color, clear);
}

// ---------------------------------------------------------------- 125 Mirrorball Tunnel
// A tube lined with small square mirror tiles, each tilted a little differently, so every
// tile catches its own reflection of a roaming spotlight environment and glints on its
// own, while coloured light spots sweep around the walls. Bass brightens the spots, highs
// sparkle individual tiles and each attack sends a wave of glints racing down the tube.
float3 mirrorballTunnel(Ctx c, constant NativeFrame &f) {
    const float lens = 1.05;
    // The music clock adds to the forward motion, so energetic passages speed it up.
    float zc = c.travel * 1.5 + c.m * 1.0;
    float4 tube = whTube(c.uv, zc, .35, lens, 1);
    float a = tube.x, z = tube.y, d = tube.z, r = tube.w;
    float columns = clamp(floor(44 / c.size + .5), 16.f, 96.f);
    float tileH = TAU / columns;
    float spin = c.t * .05;
    float2 g = float2((a / TAU - spin) * columns, z / tileH);
    float2 cell = floor(g), local = fract(g);
    float column = cell.x - columns * floor(cell.x / columns);
    float seed = hash21(float2(column, cell.y));
    float2 tilt = (hash22(float2(column, cell.y) + 3.7) - .5) * .32;
    float centreAngle = (cell.x + .5) / columns * TAU + spin * TAU;
    float3 inward = -float3(cos(centreAngle), sin(centreAngle), 0);
    float3 tangent = float3(-sin(centreAngle), cos(centreAngle), 0);
    float3 n = normalize(inward + tangent * tilt.x + float3(0, 0, 1) * tilt.y);
    float3 view = normalize(float3(cos(a), sin(a), d));
    float3 refl = reflect(view, n);
    // Reflected environment: a dim gradient and five roaming spotlights.
    float3 env = deep(.3 + refl.z * .25, f) * .14;
    float spotBoost = 1 + c.b.x * 1.6;
    for (int k = 0; k < 5; ++k) {
        float fk = float(k);
        float around = (c.t + c.m * .8) * (.35 + fk * .08) * (k % 2 == 0 ? 1 : -1) + fk * 1.26;
        float3 dir = normalize(float3(cos(around), sin(around), .6 * sin(c.t * .37 + fk * 2.1)));
        env += paint(fk * .21 + .05, f) * pow(max(dot(refl, dir), 0.f), 22.f) * 1.8 * (spotBoost + c.b[k % 4] * .8);
    }
    // Light pools sweeping over the walls.
    float3 pool = 0;
    for (int m = 0; m < 3; ++m) {
        float fm = float(m);
        float centre = (c.t + c.m * .8) * (.45 + fm * .17) * (m == 1 ? -1 : 1) + fm * 2.1;
        float depth = 2.2 + 1.3 * sin(c.t * .31 + fm * 1.7) + fm * .8;
        float2 offset = float2(whWrap(a - centre), (z - zc - depth) * .55);
        pool += paint(.15 + fm * .3, f) * exp(-dot(offset, offset) * 5) * spotBoost;
    }
    float poolLevel = dot(pool, float3(.33));
    // Highs sparkle single tiles; attacks send a glint wave down the tube.
    float twinkle = pow(.5 + .5 * sin(c.t * (5 + seed * 7) + seed * 60), 24.f) * c.b.w * 3;
    float waveZ = zc + .3 + (1 - c.hit) * 7;
    float wave = c.hit * exp(-pow((z - waveZ) * 1.6, 2.f));
    float glint = dot(env, float3(.33));
    float3 tile = env * (.55 + .9 * glint) + pool * (.5 + glint * 2.5) + mix(env, paint(.95, f), .5) * (twinkle + wave * 2.5);
    tile *= .85 + .3 * seed;
    // Bevelled edges and dark grout between tiles.
    float2 edge = min(local, 1 - local);
    float edgeMin = min(edge.x, edge.y);
    float foot = c.px * d * d / lens / tileH;
    float grout = smoothstep(.04f, .09f + foot, edgeMin);
    float3 color = mix(deep(.4, f) * .05 + pool * .08, tile, grout);
    float star = (twinkle + wave * 2) * exp(-min(fabs(local.x - .5), fabs(local.y - .5)) * 30) * exp(-length(local - .5) * 4);
    color += paint(.95, f) * star * .6;
    // Tiles smaller than a few pixels blend into their average glow.
    float tilePixels = tileH * r / d / c.px;
    float3 farGlow = paint(a / TAU * 2 + c.t * .06, f) * .22 + deep(.3, f) * .06;
    float3 average = env * .5 + pool * .8 + farGlow + paint(.9, f) * wave * 1.2;
    color = mix(average, color, smoothstep(2.f, 5.f, tilePixels));
    float clear = whFog(d, c, .03, .09);
    return mix(farGlow, color, clear) + paint(.9, f) * .25 * exp(-r * 7);
}

// ---------------------------------------------------------------- 126 Fractal Throat
// Raymarched: a kaleidoscopic folded-box fractal (abs folds, sorting folds and rotations)
// repeating along the flight path, with a winding corridor carved through it. Sharp
// crystalline edges glow in orbit-trap colours and the far throat sinks into deep fog.
// Bass swells the fold glow; attacks spark the edges nearest the camera.


// ---------------------------------------------------------------- 127 Chroma Pipe
// Inside a polished chrome pipe. The wall mirrors a dark surround laced with neon stripe
// bands, and gentle dents in the metal bend the reflection into liquid, curving bands,
// with sharp specular glints on the dents. Chromatic rings, split into three palette
// channels, travel along the pipe and glint in the chrome. Bass deepens the dents so the
// stripes bend harder, highs sharpen and multiply the rings, and each attack emits a
// bright split ring from the camera.
float3 chromaEnvironment(float3 dir, Ctx c, constant NativeFrame &f) {
    // Neon stripe bands around the reflected direction, on black.
    float around = atan2(dir.y, dir.x) / TAU;
    float stripe = around * 6 + dir.z * 2.6 - c.t * .22 - c.m * .35;
    float id = floor(stripe);
    id -= 6 * floor(id / 6);
    float band = fract(stripe);
    float neon = exp(-pow((band - .5) / .16, 2.f));
    float core = exp(-pow((band - .5) / .045, 2.f));
    float3 color = paint(id * .19 + .03, f) * (neon * (.9 + c.b[int(id) % 4] * 1.2) + core * .5);
    color += paint(.6, f) * .05 * (.5 + .5 * dir.z);
    return color;
}
float3 chromaRings(float z, Ctx c, constant NativeFrame &f, float width) {
    float split = .07 * c.size;
    float3 total = 0;
    for (int train = 0; train < 2; ++train) {
        float spacing = train == 0 ? 2.4f : 1.2f;
        float level = train == 0 ? 1.f : c.b.w * 1.4;
        if (level < .001) continue;
        float phase = (z - (c.t + c.m * 1.2) * (train == 0 ? 1.6f : 2.3f)) / spacing + (train == 0 ? 0.f : .37f);
        float dist = (fract(phase + .5) - .5) * spacing;
        float w = width * (1 - .45 * c.b.w);
        total += (paint(.02, f) * exp(-pow((dist + split) / w, 2.f)) + paint(.5, f) * exp(-pow(dist / w, 2.f)) + paint(.8, f) * exp(-pow((dist - split) / w, 2.f))) * level;
    }
    return total;
}
float3 chromaPipe(Ctx c, constant NativeFrame &f) {
    const float lens = 1.05;
    // The music clock adds to the forward motion, so energetic passages speed it up.
    float zc = c.travel * 1.6 + c.m * 1.0;
    float4 tube = whTube(c.uv, zc, .3, lens, 1);
    float a = tube.x, z = tube.y, d = tube.z, r = tube.w;
    float foot = c.px * d * d / lens;
    float sharp = exp(-foot * 4);
    float3 view = normalize(float3(cos(a), sin(a), d));
    // Dents: a smooth height field around and along the pipe; bass deepens it.
    float depth = (.22 + c.b.x * .5) * sharp;
    float phaseA = a * 3 + sin(z * .9 + c.t * .4) * 1.5;
    float phaseZ = z * 2.1 - c.t * .6 + sin(a * 2 + z * .5) * .8;
    float dA = cos(phaseA) * sin(phaseZ) * 3, dZ = sin(phaseA) * cos(phaseZ) * 2.1;
    float3 inward = -float3(cos(a), sin(a), 0), tangent = float3(-sin(a), cos(a), 0);
    float3 n = normalize(inward + (tangent * dA + float3(0, 0, 1) * dZ) * depth);
    float3 refl = reflect(view, n);
    float3 color = chromaEnvironment(refl, c, f);
    // The rings show up in the chrome where the reflection crosses them.
    float t2 = -2 * dot(float2(cos(a), sin(a)), refl.xy) / max(dot(refl.xy, refl.xy), 1e-4f);
    float z2 = z + refl.z * min(t2, 30.f);
    color += chromaRings(z2, c, f, .05 * c.size) * .5;
    float fresnel = .6 + .4 * pow(1 - max(dot(-view, n), 0.f), 3.f);
    color *= fresnel;
    float glint = pow(max(dot(refl, normalize(float3(.25, .45, 1))), 0.f), 60.f) + pow(max(dot(refl, normalize(float3(-.5, -.3, 1))), 0.f), 90.f);
    color += paint(.95, f) * glint * (.7 + c.b.z * 1.5) * sharp;
    // Far down the pipe the reflections blur into a soft average.
    color = mix(paint(.5 + .1 * sin(c.t * .2), f) * .18, color, exp(-foot * 1.5));
    // Seams on the chrome give scale.
    float seam = 1 - smoothstep(.004f, .012f + foot, fabs(z - round(z / 1.6) * 1.6));
    color *= 1 - seam * .7;
    // The rings glow on the wall itself.
    float width = .05 * c.size;
    color += chromaRings(z, c, f, max(width, foot * .8)) * min(1.f, width / max(foot * .8, 1e-4f)) * .9;
    float pingZ = zc + .7 + (1 - c.hit) * 8;
    float dz = z - pingZ, split = .09;
    float w = max(.06f, foot);
    color += (paint(.02, f) * exp(-pow((dz + split) / w, 2.f)) + paint(.5, f) * exp(-pow(dz / w, 2.f)) + paint(.8, f) * exp(-pow((dz - split) / w, 2.f))) * c.hit * 2.2;
    float clear = whFog(d, c, .03, .08);
    return (mix(paint(.55, f) * .1 + deep(.3, f) * .08, color, clear) + paint(.9, f) * .2 * exp(-r * 6)) * .68;
}

// ---------------------------------------------------------------- 128 Coral Burrow
// An undersea burrow: lumpy walls of porous coral (corallite cells with raised rims)
// rippled by caustic light, set with bioluminescent polyps (glowing discs ringed by
// swaying tentacles) and glowing plankton drifting past. Bass opens the polyps, highs
// make the plankton twinkle and each attack flashes a ring of polyps just ahead.


// ---------------------------------------------------------------- 129 Rainbow Slide
// Riding down a translucent waterslide tube in sunshine. The rider sits low in the tube,
// banked turns roll the view, helical panels of saturated colour glow with the sun
// shining through the plastic, flanged seams ring each section, and a sheet of water
// with bright foam rushes along the bottom. Bass splashes the water higher up the walls,
// highs spit droplets and attacks throw spray across the camera side.
float2 slidePath(float z) { return float2(sin(z * .19) * 1.4 + sin(z * .083) * .8, cos(z * .15) * .7); }
float3 rainbowSlide(Ctx c, constant NativeFrame &f) {
    const float lens = .95, sit = .38;
    float radius = c.size;
    // The music clock adds to the forward motion, so energetic passages speed it up.
    float zc = c.travel * 1.9 + c.m * 1.5;
    // Bank into the turns: lateral curvature rolls the rider and the water up the wall.
    float curve = slidePath(zc + 1.2).x - 2 * slidePath(zc).x + slidePath(zc - 1.2).x;
    float bank = clamp(-curve * 1.6, -1.f, 1.f);
    float2 uv = rot(c.uv, -bank);
    float2 down = float2(sin(bank), -cos(bank));
    float2 cam = down * sit * radius;
    float2 slope = slidePath(zc + .5) - slidePath(zc - .5);
    float d = 2, angle = 0;
    float2 wall = 0;
    for (int i = 0; i < 3; ++i) {
        float2 centre = (slidePath(zc + d) - slidePath(zc) - slope * d) * lens / max(d, 1e-3f);
        float2 v = (uv - centre) / lens;
        float vv = max(dot(v, v), 1e-6f), vc = dot(v, cam);
        d = (-vc + sqrt(max(vc * vc - vv * (dot(cam, cam) - radius * radius), 0.f))) / vv;
        d = min(d, 70.f);
        wall = cam + v * d;
    }
    angle = atan2(wall.y, wall.x);
    float z = zc + d;
    float foot = c.px * d * d / lens;
    float sharp = exp(-foot * 6);
    // Helical colour panels with flanged seams.
    float section = 1.1;
    float stripe = angle / TAU * 6 + z / section * .35;
    float id = floor(stripe);
    id -= 6 * floor(id / 6);
    float segment = floor(z / section);
    float3 panel = paint(id < 4.5 ? id * .25 : .375f, f);   // palette stops stay pure
    float edge = fract(stripe);
    float joint = (1 - smoothstep(0.f, .04f + foot * 3, edge)) + (1 - smoothstep(1.f, .96f - foot * 3, edge));
    panel *= 1 - joint * .55 * sharp;
    // Moulded ribs inside each panel catch the light.
    float rib = pow(.5 + .5 * cos(fract(z / section) * TAU * 3), 12.f) * sharp;
    panel *= .85 + .3 * rib;
    // Sun through the plastic: the side facing the sun glows, with a soft hot spot.
    float2 outward = wall / radius;
    float2 sunDir = normalize(float2(.45, .9));
    float through = .15 + .85 * pow(max(dot(outward, sunDir) * .5 + .5, 0.f), 2.f);
    float hotspot = exp(-pow(whWrap(angle - atan2(sunDir.y, sunDir.x) - .3 * sin(z * .2)), 2.f) * 6) * (.6 + .4 * sin(z * .9 - c.t * .5));
    float ripple = whNoiseP(float2(angle / TAU * 24, z * 2 + c.t * .4), 24);
    float caustic = pow(1 - fabs(whNoiseP(float2(angle / TAU * 16, z * 1.4 - c.t * .8), 16) * 2 - 1), 6.f) * sharp;
    // Low-mids pulse light through the panels section by section; high-mids sharpen the caustics.
    float sectionPulse = pow(.5 + .5 * sin(segment * 1.3 - c.t * 3), 4.f) * c.b.y;
    float3 color = panel * (.08 + .8 * through + hotspot * .4 + caustic * (.35 + c.b.z * .8) * through + sectionPulse * .6) + panel * ripple * .08 * sharp;
    float sheen = pow(max(cos(angle - 2.3), 0.f), 90.f) + pow(max(cos(angle + .6), 0.f), 120.f) * .6;
    color += mix(panel, paint(.97, f), .5) * sheen * .35 * sharp;
    float seamZ = z - round(z / section) * section;
    float flange = (1 - smoothstep(.018f, .03f + foot, fabs(seamZ))) * sharp;
    color = mix(color, panel * .15 + paint(.95, f) * .2 * through, flange * .8);
    float bolts = exp(-length(float2(whWrap(angle - (floor(angle / TAU * 16) + .5) * TAU / 16) * radius, seamZ)) * 60) * sharp;
    color += paint(.97, f) * bolts * .4;
    // Water sheet along the bottom (which tilts with the bank), with foam at its edges.
    float waterAngle = atan2(down.y, down.x);
    float off = fabs(whWrap(angle - waterAngle));
    float slosh = .5 + .12 * sin(z * .6 - c.t * 1.3) + .08 * sin(z * 1.7 + c.t * 2.1);
    float reach = slosh + c.b.x * .55 * (.6 + .4 * sin(z * 2.3 - c.t * 4));
    float water = smoothstep(reach, reach - .08f, off);
    float flow = z * 2.2 - zc * 2.6 - c.t * 2;
    float streaks = whNoiseP(float2(angle / TAU * 60, flow), 60) * .6 + whNoiseP(float2(angle / TAU * 20, flow * .4), 20) * .4;
    streaks = mix(.5f, streaks, sharp);
    float foam = smoothstep(.12f, 0.f, fabs(off - reach)) * (.5 + .5 * whNoiseP(float2(angle / TAU * 40, flow * 1.5), 40));
    float glitter = pow(whNoiseP(float2(angle / TAU * 90, flow * 3 + c.t), 90), 14.f) * sharp;
    float3 spray = mix(paint(.0, f), paint(.5, f), .35);
    float3 waterColor = panel * .25 + paint(.0, f) * .14 + spray * (pow(streaks, 4.f) * .8 + glitter * 1.6);
    color = mix(color, waterColor, water * .85);
    color += spray * foam * .6 * sharp;
    float clear = whFog(d, c, .02, .06);
    color = mix(paint(.8, f) * .22 + paint(.3, f) * .06, color, clear * exp(-foot * .8) + (1 - exp(-foot * .8)) * 0);
    // Droplets in the air (highs) and spray across the camera side (attacks).
    if (c.b.w > .001) {
        float2 q = uv * 7 + float2(0, c.t * 2.5);
        float2 cell = floor(q);
        float h = hash21(cell);
        float2 at = hash22(cell + 4.1) - .5;
        float drop = exp(-pow(length(fract(q) - .5 - at * .7) / .045, 2.f)) * step(.86f, h);
        color += paint(.97, f) * drop * c.b.w * 1.4;
    }
    if (c.hit > .001) {
        float spray = 0;
        for (int k = 0; k < 9; ++k) {
            float seed = hash11(float(k) * 7.31 + 2);
            float dirAngle = -PI * .5 + (seed - .5) * 2.6;
            float2 at = float2(0, -1.05) + float2(cos(dirAngle), sin(dirAngle) * .5 + .6) * (.25 + (1 - c.hit) * (.6 + seed * .5));
            at.x *= c.extent.x;
            float size = .04 + .05 * hash11(seed * 13);
            float rr = length(uv - at) / size;
            spray += (smoothstep(1.f, .85f, rr) * .25 + exp(-pow((rr - .85) / .12, 2.f)) * .9);
        }
        color += paint(.95, f) * spray * c.hit * c.hit * 1.2;
    }
    return color * .62;
}

// ---------------------------------------------------------------- 130 Pulse Arteries
// Flowing through a blood vessel: a soft, moist wall laced with branching veins and
// capillaries, side vessels opening off it, and biconcave cells tumbling past toward the
// camera. Bass drives a heartbeat dilation wave that travels along the wall, the cell
// flow surges with the music clock, and each attack spawns a cluster of cells ahead.
float4 arteryCell(float2 q, float2 centre, float radius, float seed, float t) {
    // Returns colour weight (x), rim (y), coverage (z) of a tumbling biconcave disc.
    float tilt = t * (.4 + seed * .6) + seed * 9;
    float spin = t * (.3 + seed * .3) + seed * 17;
    float2 local = rot(q - centre, -spin);
    float squeeze = max(fabs(cos(tilt)), .18f);
    float e = length(float2(local.x, local.y / squeeze)) / radius;
    float cover = smoothstep(1.f, .9f, e);
    float dimple = smoothstep(.15f, .75f, e) * (.55 + .45 * squeeze);
    float rim = exp(-pow((e - .8) / .18, 2.f));
    return float4(dimple, rim, cover, e);
}
float3 pulseArteries(Ctx c, constant NativeFrame &f) {
    const float lens = 1.0, bend = .6;
    float vessel = c.size;
    // The music clock adds to the flow, so energetic passages rush the camera along.
    float zc = c.travel * 1.3 + c.m * .8;
    float4 tube = whTube(c.uv, zc, bend, lens, vessel);
    float a = tube.x, d0 = tube.z, r = tube.w;
    // Heartbeat dilation: a travelling bulge, stronger with bass.
    float pulseClock = c.t * 1.6 + c.m * 2.5;
    float beatPhase = (zc + d0) * .55 - pulseClock;
    float beat = pow(.5 + .5 * sin(beatPhase), 3.f);
    float dilate = 1 + (.03 + c.b.x * .24) * beat;
    float d = d0 * dilate;
    float z = zc + d;
    beat = pow(.5 + .5 * sin(z * .55 - pulseClock), 3.f);
    float foot = c.px * d * d / lens;
    float sharp = exp(-foot * 6);
    // Moist wall with folds, veins and capillaries.
    float2 w = float2(a / TAU * 8, z * 1.3 / vessel);
    float folds = whFbmP(w + float2(0, c.t * .05), 8, 4);
    float2 toSite;
    float2 warp = float2(whFbmP(w * 1.5 + 7.3, 12, 2), whFbmP(w * 1.5 + 2.1, 12, 2)) - .5;
    // Veins: wandering ridged lines of a warped noise field.
    float veinField = whFbmP(float2(a / TAU * 6, z * .9 / vessel) + warp * .9, 6, 3);
    float vein = 1 - smoothstep(0.f, .025f + foot * .3, fabs(veinField - .5));
    float veinPulse = c.b.y * pow(.5 + .5 * sin(z * 1.1 - c.t * 2.4 - c.m * 3), 3.f);
    float4 capCells = whVoronoiP(float2(a / TAU * 30, z * 4.5 / vessel) + warp * 1.2, 30, .9, toSite);
    float capillary = (1 - smoothstep(0.f, .06f, capCells.y - capCells.x)) * sharp;
    float3 tissue = mix(deep(.08 + folds * .15, f) * .55, paint(.18 + folds * .3, f) * .55, smoothstep(.3f, .75f, folds));
    tissue *= .55 + .6 * folds;
    tissue = mix(tissue, deep(.02, f) * .25 + paint(.05, f) * .12 + paint(.35, f) * veinPulse * 1.6, vein * .75 * (.4 + .6 * sharp));
    tissue = mix(tissue, paint(.12, f) * .3 + paint(.4, f) * c.b.w * .35, capillary * (.18 + c.b.w * .25));
    float sheen = smoothstep(.55f, .8f, folds) * pow(max(cos(a - 1.9), 0.f), 3.f) * sharp;
    tissue += paint(.6, f) * sheen * (.12 + c.b.z * .7);
    // The heartbeat wave flushes the wall it passes: brighter and warmer with the bass.
    tissue = tissue * (1 + beat * c.b.x * 1.1) + paint(.35, f) * beat * (.06 + c.b.x * .5);
    // Low-mids swell slow patches of the wall in and out of shadow.
    tissue *= 1 + c.b.y * .55 * smoothstep(.45f, .75f, whNoiseP(float2(a / TAU * 4, z * .35 - c.t * .2), 4));
    // Side vessels branching off the wall.
    float holeRow = floor(z / 3.2);
    for (int k = 0; k <= 1; ++k) {
        float id = holeRow + float(k);
        float holeZ = (id + .5) * 3.2, holeA = hash11(id * 4.7) * TAU - PI;
        float2 o = float2(whWrap(a - holeA) * vessel, (z - holeZ) * .8);
        float hr = length(o) / (.32 * vessel);
        float inside = smoothstep(1.f, .85f, hr);
        float lip = exp(-pow((hr - 1) / .12, 2.f));
        tissue = mix(tissue, deep(.05, f) * .12 + paint(.1, f) * .2 * (1 - hr) * (1 - hr), inside);
        tissue += paint(.4, f) * lip * (.25 + c.b.z * .8);
    }
    float clear = whFog(d, c, .05, .1);
    float3 haze = deep(.1, f) * .25 + paint(.15, f) * .12;
    float3 color = mix(haze, tissue, clear);
    // Cells tumbling toward the camera, composited front to back.
    float flow = c.travel * .3 + c.t * .1 + c.m * .25;
    float3 cells = 0;
    float transmit = 1;
    const int layers = 9;
    for (int k = layers - 1; k >= 0; --k) {
        float2 slot = layerSlot(k, layers, flow);
        float depth = mix(11.f, .45f, slot.x);
        float fade = layerFade(slot.x) * whFog(depth, c, .05, .1);
        float2 centreOffset = whCentre(zc, depth, bend, lens);
        float2 q = (c.uv - centreOffset) * depth / lens;
        float grid = .48 * vessel;
        float2 cell = floor(q / grid);
        float seed = hash21(cell + slot.y * 13.1);
        float2 centre = (cell + .5 + (hash22(cell + slot.y * 7.7) - .5) * .3) * grid;
        if (seed < .2 || length(centre) > .8 * vessel) continue;
        float4 disc = arteryCell(q, centre, .15 * vessel, seed, c.t);
        float alpha = disc.z * fade;
        float cellBand = c.b[int(fract(seed * 6.1) * 3.99)];
        float3 tint = paint(.04 + seed * .14 + cellBand * .12, f) * (.35 + .65 * disc.x) * (1 + cellBand * 1.1) + paint(.5, f) * disc.y * (.35 + c.b.z * 1.2);
        cells += transmit * alpha * tint;
        transmit *= 1 - alpha;
    }
    // Attack: a cluster of cells bursts out of a point ahead and spreads.
    if (c.hit > .001) {
        // The Coaster version bursts nearer, so the cells stay in view as the tube bends away.
        float depth = f.scene == 130 ? 2.6 : 1.2;
        float2 centreOffset = whCentre(zc, depth, bend, lens);
        float2 q = (c.uv - centreOffset) * depth / lens;
        float2 hub = .35 * vessel * float2(cos(c.t * .4), sin(c.t * .4));
        for (int k = 0; k < 7; ++k) {
            float seed = hash11(float(k) * 3.3 + 1);
            float angle = float(k) / 7 * TAU + seed;
            float2 centre = hub + float2(cos(angle), sin(angle)) * (.08 + (1 - c.hit) * .45) * vessel;
            float4 disc = arteryCell(q, centre, .1 * vessel, seed, c.t);
            float alpha = disc.z * c.hit;
            cells += transmit * alpha * (paint(.08 + seed * .1, f) * (.45 + .6 * disc.x) + paint(.6, f) * disc.y * .5);
            transmit *= 1 - alpha;
        }
    }
    return cells + transmit * color + paint(.35, f) * .15 * exp(-r * 4);
}

// ---------------------------------------------------------------- 131 Zebra Warp
// An op-art tunnel: bold stripes in log-polar coordinates spiral out of a drifting
// vanishing point and bend in sinusoidal warps, alternating black with two vivid palette
// colours for a strong motion illusion. Bass deepens the warp inside a slowly turning
// sector, highs thread thin bright lines through the black stripes and each attack
// inverts a band of stripes that rushes outward.
float3 zebraWarp(Ctx c, constant NativeFrame &f) {
    float2 vanish = float2(sin(c.t * .19) * .3, cos(c.t * .15) * .2 - .05);
    float2 q = c.uv - vanish;
    float r = max(length(q), 1e-4f), angle = atan2(q.y, q.x);
    float density = 8.5 / c.size;
    float lr = log(r);
    float sector = pow(.5 + .5 * cos(whWrap(angle - c.t * .35)), 3.f);
    float amp = .3 + .15 * sin(c.t * .3) + c.b.x * 1.2 * sector;
    float warp = amp * sin(angle * 3 + lr * 2.5 - c.t * .8 - c.m * .6) + .22 * sin(angle * 5 - lr * 1.5 + c.t * .5);
    // The music clock adds to the inward rush of the stripes.
    float s = lr * density - c.travel * 1.7 - c.m * 1.5 + angle / TAU * 4 + warp;
    float w = (density + 3 * amp + 2) / r * c.px;      // stripe units per pixel
    float mask = smoothstep(-PI * w, PI * w, sin(PI * s));
    // Attack: a band of inverted stripes rushes outward as the envelope decays.
    float bandR = .1 + (1 - c.hit) * 3.5;
    float invert = smoothstep(0.f, .6f, c.hit) * .85 * smoothstep(.24f, .18f, fabs(lr - log(bandR)));
    mask = mix(mask, 1 - mask, invert);
    float pick = floor((s + .5) * .5);
    pick -= 2 * floor(pick * .5);
    float3 colorA = paint(.25 + .03 * sin(c.t * .11), f), colorB = paint(.75 + .03 * sin(c.t * .13 + 1), f);
    // Low-mids and high-mids each brighten one stripe colour.
    float3 stripeColor = pick < .5 ? colorA * (1 + c.b.y * .5) : colorB * (1 + c.b.z * .5);
    float3 dark = deep(.4, f) * .03;
    float3 color = mix(dark, stripeColor, mask);
    // Highs: thin bright threads through the black stripes.
    float strand = fabs(fract(s * .5 + .25) - .5) * 2;
    color += mix(colorA, colorB, .5) * exp(-pow(strand / (.03 + w * .7), 2.f)) * (1 - mask) * c.b.w * 2.2 * smoothstep(.35f, .1f, w);
    // Stripes finer than a pixel settle to their average; the throat darkens with depth.
    float3 average = (colorA + colorB) * .25 + dark * .5;
    color = mix(color, average, smoothstep(.25f, .7f, w));
    color *= .35 + .65 * smoothstep(0.f, .8f, r);
    return color * .62 + paint(.85, f) * .12 * exp(-r * 8);
}

// ---------------------------------------------------------------- 132 Pixel Tunnel
// A quantized light tunnel. A square tunnel is sampled at the centre of chunky screen
// pixels. Its dark walls carry crisp emissive pixel strips whose light runs like
// pixel-sorted streaks (each run ramps from a dim tail to a bright head) flowing toward
// the camera, and their glow spreads over the walls as dithered gradients quantized to a
// few levels. Thin pixel rings mark the depth and the far end resolves into a stepped,
// glowing core. Each band lights its own family of strips, bass sends a chase along the
// pixel rows and each attack flashes a ring of pixels just ahead.
float pixelBayer(float2 cell) {
    int x = int(cell.x - 4 * floor(cell.x / 4)), y = int(cell.y - 4 * floor(cell.y / 4));
    const int m[16] = {0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5};
    return (float(m[y * 4 + x]) + .5) / 16;
}
// Light carried by strip column `colId` at depth z (0 when the column is dark).
float pixelStrip(float colId, float z, Ctx c) {
    float seed = hash11(colId * 1.37 + 3);
    if (seed < .4) return 0;
    float speed = 3 + seed * 3;
    float runLength = 2 + 2.5 * hash11(colId * 2.1);
    float s = (z + (c.t + c.m * .8) * speed) / runLength + hash11(colId * 4.7);
    float along = fract(s);
    float on = step(.3f, hash11(floor(s) + colId * 13.1));
    float ramp = floor(along * along * 6) / 6;               // the run steps up toward its head
    float head = step(.9f, along);
    float band = c.b[int(fract(seed * 7.1) * 3.99)];
    return on * (ramp * .8 + head * 1.2) * (.7 + band * 1.8);
}
float3 pixelTunnel(Ctx c, constant NativeFrame &f) {
    // Chunky pixels stay square on screen whatever the camera rotation or zoom.
    float2 res = max(f.resolution, float2(1));
    float shortSide = min(res.x, res.y);
    float block = max(2.f, floor(shortSide / 90 * c.size + .5));
    float2 cellId = floor(c.screen * res / block);
    float2 uv = ((cellId + .5) * block - res * .5) / (shortSide * .5);
    uv.y = -uv.y;
    float zoom = clamp(f.style.w, .3f, 2.f);
    uv = rot(uv, f.camera.x) / zoom;
    const float lens = 1.1, columns = 12, rowH = .5;
    // The music clock adds to the forward motion, so energetic passages speed it up.
    float zc = c.travel * 2.4 + c.m * 1.5;
    uv -= float2(sin(c.t * .31) * .08, cos(c.t * .23) * .05);
    uv = rot(uv, c.t * .04);
    // The Coaster version rides the course at each chunky pixel's centre, so blocks stay square.
    if (f.scene != 132) {
        Ctx cell = c;
        cell.uv = uv;
        uv = coasterRide(cell, 132, true).uv;
    }
    float m = max(fabs(uv.x), fabs(uv.y));
    float d = min(lens / max(m, 1e-3f), 60.f);
    float z = zc + d;
    bool side = fabs(uv.x) > fabs(uv.y);
    float face = side ? (uv.x > 0 ? 0.f : 2.f) : (uv.y > 0 ? 1.f : 3.f);
    float across = (side ? uv.y : uv.x) / m;              // -1..1 along the face
    float slot = (across + 1) * .5 * columns;
    float col = floor(slot), within = slot - col;
    float dither = pixelBayer(cellId);
    float clear = whFog(d, c, .045, .09);
    // How many screen pixels one strip column spans: thin far strips merge into glow.
    float chunk = block * c.px;                            // one chunky pixel in uv units
    float colPixels = 2 / columns * m / chunk;
    float resolve = smoothstep(1.5f, 3.f, colPixels);
    // The strip in this column (a crisp core) and dithered glow from it and its neighbours.
    float core = 0, glowAmount = 0, hueSeed = 0;
    for (int k = -1; k <= 1; ++k) {
        float cc = col + float(k);
        if (cc < 0 || cc >= columns) continue;
        float colId = face * columns + cc;
        // Strips sweeping right past the lens fade so no huge block flips in one frame.
        float level = pixelStrip(colId, z, c) * mix(.3f, 1.f, smoothstep(.45f, 1.3f, d));
        float dist = fabs(slot - (cc + .5));
        if (k == 0) { core = level * step(fabs(within - .5), .22f) * resolve; hueSeed = hash11(colId * 5.3); }
        glowAmount += level * exp(-dist * 2.2) * .45;
    }
    // Thin rings every few metres and a bass chase along the pixel rows.
    float row = floor(z / rowH);
    float ringDist = fabs(z - round(z / 4) * 4);
    float ring = step(ringDist, max(.05f, chunk * d * d / lens * .6)) * .8 * smoothstep(.7f, 1.8f, d);
    float chase = pow(.5 + .5 * sin(row * .6 - c.t * 5 - c.m * 3), 8.f) * c.b.x * 1.2;
    float gap = (row + .5) * rowH - zc;
    float flash = c.hit * 1.6 * smoothstep(1.4f, 2.2f, gap) * (1 - smoothstep(3.2f, 4.2f, gap));
    // Quantize everything to a few dithered levels of palette colour.
    const float steps = 5;
    float glowLevel = floor(min((glowAmount + chase * .5 + flash * .6) * clear, 1.2f) * steps + dither) / steps;
    float coreLevel = floor(min((core + ring + chase * .6 + flash) * clear, 1.5f) * steps + dither) / steps;
    float hue = floor((z * .03 + face * .25 + c.t * .02) * 5 + dither) / 5;
    // Walls: a dithered gradient that brightens toward the glowing core.
    float ambient = floor((.32 + .55 * exp(-m * 2)) * 4 + dither) / 4;
    float3 wall = mix(deep(.3 + face * .1, f), paint(hue + .5, f), .45) * ambient * .3;
    float3 color = wall + paint(hue + hueSeed * .25, f) * glowLevel * .35 + paint(hue + hueSeed * .25 + .08, f) * coreLevel * .9;
    // Stepped glowing core at the far end.
    float coreGlow = floor(exp(-m * 4.5) * 6 + dither) / 6;
    color += paint(.85 + .1 * sin(c.t * .2), f) * coreGlow * .55;
    return color;
}

// ---------------------------------------------------------------- 133 Geode Passage
// Flying through the hollow of a giant geode: walls bristling with crystal points that
// radiate inward. Each voronoi cell is raised into a pyramid whose flat facets slope down
// toward its neighbours, so every crystal shows crisp, individually lit faces and a
// glowing tip; dark crevices separate the crystals, and patches of banded agate show
// where the shell breaks through. Bass makes the crystals nearest the camera glow from
// inside, highs sparkle on single facets and each attack lights a cluster of crystals.
// Nearest and second-nearest site offsets of a voronoi field that repeats every
// `period` cells in x; id receives the nearest cell.
float4 geodeCells(float2 p, float period, thread float2 &id) {
    float2 cell = floor(p), fr = fract(p), near1 = 0, near2 = 0;
    float first = 64, second = 64;
    id = 0;
    for (int y = -1; y <= 1; ++y) for (int x = -1; x <= 1; ++x) {
        float2 g = float2(x, y), cid = cell + g;
        cid.x -= period * floor(cid.x / period);
        float2 delta = g + .5 + .8 * (hash22(cid) - .5) - fr;
        float dd = dot(delta, delta);
        if (dd < first) { second = first; near2 = near1; first = dd; near1 = delta; id = cid; }
        else if (dd < second) { second = dd; near2 = delta; }
    }
    return float4(near1, near2);
}
float3 geodePassage(Ctx c, constant NativeFrame &f) {
    const float lens = 1.05, columns = 22;
    // The music clock adds to the forward motion, so energetic passages speed it up.
    float zc = c.travel * 1.2 + c.m * .8;
    float4 tube = whTube(c.uv, zc, .42, lens, 1);
    float a = tube.x, d0 = tube.z, r = tube.w;
    // The geode turns slowly around the flight path; `spin` addresses its surface.
    float spin = a - c.t * .06 - c.m * .05;
    float zScale = 3.4 / c.size;
    float2 id;
    float4 sites = geodeCells(float2(spin / TAU * columns, (zc + d0) * zScale), columns, id);
    float edge = (dot(sites.zw, sites.zw) - dot(sites.xy, sites.xy)) / (2 * max(length(sites.zw - sites.xy), 1e-4f));
    float zone = smoothstep(.36f, .48f, whFbmP(float2(spin / TAU * 5, (zc + d0) * .45), 5, 3));
    float height = clamp(edge * 2.4, 0.f, 1.f) * zone;
    // Crystal tips stand in from the wall: one damped refinement adds parallax.
    float seed = hash21(id);
    float d = d0 * (1 - (.16 + .2 * seed) * height * exp(-d0 * .4));
    float z = zc + d;
    sites = geodeCells(float2(spin / TAU * columns, z * zScale), columns, id);
    seed = hash21(id);
    edge = (dot(sites.zw, sites.zw) - dot(sites.xy, sites.xy)) / (2 * max(length(sites.zw - sites.xy), 1e-4f));
    float shell = whFbmP(float2(spin / TAU * 5, z * .45), 5, 3);
    zone = smoothstep(.36f, .48f, shell);
    height = clamp(edge * 2.4, 0.f, 1.f) * zone;
    float foot = c.px * d * d / lens;
    float sharp = exp(-foot * 5);
    // The facet faces the neighbour that shares this edge: its normal leans that way.
    float2 slopeDir = normalize(sites.zw - sites.xy + 1e-5);
    float3 inward = -float3(cos(a), sin(a), 0);
    float3 tangent = float3(-sin(a), cos(a), 0), along = float3(0, 0, 1);
    float lean = .8 + .7 * seed;
    float3 n = normalize(inward + (tangent * slopeDir.x + along * slopeDir.y) * lean);
    float facetSeed = hash21(floor((sites.zw - sites.xy) * 7.3) + id);
    float3 view = normalize(float3(cos(a), sin(a), d));
    float3 key = normalize(float3(.35, .6, -.7));
    float diffuse = max(dot(n, key), 0.f), front = max(dot(n, -view), 0.f);
    float3 refl = reflect(view, n);
    float spec = pow(max(dot(refl, key), 0.f), 40.f) + pow(max(dot(refl, -view), 0.f), 60.f) * .5;
    float3 tint = paint(.45 + seed * .45, f);
    // Internal glow: a hot tip, a slow pulse; bass lights the nearest crystals from inside.
    float inner = pow(height, 3.f) * (.4 + .25 * sin(c.t * .7 + seed * 20) + c.b.z * .8);
    inner += (.3 + .7 * height) * c.b.x * 1.5 * exp(-d * .45) * zone;
    float clusterRow = floor(z / 4);
    float burst = 0;
    for (int k = -1; k <= 1; ++k) {
        float row = clusterRow + float(k);
        float cz = (row + .5) * 4, ca = hash11(row * 5.3) * TAU - PI;
        float window = smoothstep(.8f, 1.8f, cz - zc) * (1 - smoothstep(4.5f, 6.f, cz - zc));
        float2 o = float2(whWrap(spin - ca), (z - cz) * .7);
        burst += window * max(1 - length(o) / 1.1, 0.f);
    }
    inner += c.hit * smoothstep(0.f, .3f, burst) * (.3 + .7 * height) * 2.4 * zone;
    float sparkle = pow(.5 + .5 * sin(c.t * (4 + facetSeed * 6) + facetSeed * 60), 20.f) * c.b.w * 2.5 * step(.55f, facetSeed);
    float facetShade = .05 + .8 * pow(diffuse, 1.5f) + .3 * front * front * (.3 + .7 * facetSeed);
    float3 crystal = tint * facetShade + paint(.93, f) * spec * .6 * sharp + paint(.78 + seed * .17, f) * inner * .6;
    crystal += paint(.97, f) * sparkle * smoothstep(.2f, .6f, height) * sharp;
    // Dark crevices where neighbouring crystals meet.
    float crevice = 1 - smoothstep(0.f, .05f + foot * 1.5, edge);
    crystal = mix(crystal, deep(.4, f) * .04, crevice * .85 * sharp);
    // Banded agate where the shell breaks through the crystal fields.
    float2 aw = float2(spin / TAU * 6, z * .9);
    float bands = whFbmP(aw, 6, 4) * 30 + shell * 12;
    float stripe = smoothstep(.35f, .65f, .5 + .5 * sin(bands * TAU));
    float bandTone = fract(floor(bands) * .37);
    float3 light = bandTone < .55 ? paint(.95, f) * .45 : paint(.25 + bandTone * .5, f) * .55;
    float3 agate = mix(deep(.15 + shell * .3, f) * .18, light * (1 + c.b.y * .8), stripe * mix(1.f, .5f, 1 - sharp));
    agate = mix(paint(.3, f) * .22, agate, sharp);
    float3 color = mix(agate, crystal, smoothstep(.15f, .4f, zone));
    float clear = whFog(d, c, .045, .1);
    float3 haze = deep(.3, f) * .14 + paint(.7, f) * .07;
    return (mix(haze, color, clear) + paint(.85, f) * .25 * exp(-r * 5)) * .88;
}

#define WORMHOLE_EFFECTS(X) X(stormEye) X(sonarPipe) X(cubeHelix) X(phylloTube) X(teslaTube) X(foldTunnel) X(vectorTube) X(orbitalCorridor) X(mirrorballTunnel)  X(chromaPipe)  X(rainbowSlide) X(pulseArteries) X(zebraWarp) X(pixelTunnel) X(geodePassage)
WORMHOLE_EFFECTS(NATIVE_EFFECT)

// Coaster versions: the same designs riding the roller-coaster course.
NATIVE_COASTER(stormEye, 117, false)
NATIVE_COASTER(sonarPipe, 118, false)
NATIVE_COASTER(phylloTube, 120, false)
NATIVE_COASTER(teslaTube, 121, false)
NATIVE_COASTER(foldTunnel, 122, false)
NATIVE_COASTER(vectorTube, 123, false)
NATIVE_COASTER(mirrorballTunnel, 125, false)
NATIVE_COASTER(chromaPipe, 127, false)
NATIVE_COASTER(rainbowSlide, 129, false)
NATIVE_COASTER(pulseArteries, 130, false)
NATIVE_COASTER(pixelTunnel, 132, true)
NATIVE_COASTER(geodePassage, 133, false)
