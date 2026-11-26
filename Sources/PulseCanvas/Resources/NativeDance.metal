// PulseCanvas native designs: dancing and club visuals (scenes 167-183). Original
// procedural code; see NativeCommon.metal. Every design is a pure function of its
// uniforms. Choreography runs on procedural time (c.t) at zero Chaos; above zero the
// music clock (c.m) adds tempo, bands enlarge specific moves and lights, and attacks
// trigger local accents (a jump, a flick, a ripple) that ease out with the envelope.

// ---------------------------------------------------------------- shared helpers
float dnBeat(Ctx c, float rate, float music) { return c.t * rate + c.m * music; }
// Attack envelope normalised by Chaos (0...1); only used through dnAccent.
float dnHit(Ctx c, constant NativeFrame &f) { return saturate(c.hit / max(f.camera.y, .05f)); }
// Smooth accent for moving geometry: zero at the attack onset and at rest, peaking as
// the envelope decays, so attacks never make shapes jump. Scales with Chaos.
float dnAccent(Ctx c, constant NativeFrame &f) { float h = dnHit(c, f); return 4 * h * (1 - h) * saturate(f.camera.y * 1.7f); }

float2 dnMul(float2 a, float2 b) { return float2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x); }
float2 dnPolar(float a) { return float2(cos(a), sin(a)); }
float dnSq(float x) { return x * x; }
// Camera (focal length 2) pitched down over a ground plane so the horizon sits at
// screen height `horizon` (keep it above the canvas). Returns world x, forward z and
// the ray parameter t (world units per uv unit across the screen).
constant float DN_FOCAL = 2;

// Projects a point (x, height, z) given relative to the dnFloor camera position. Returns
// screen xy and a depth z such that a world length L appears L / z long on screen.

// Soft cone of light from src along dir.


// ---------------------------------------------------------------- 167 Groove Tiles
// An illuminated glass dance floor seen at an angle. Tiles glow from beneath in moving
// patterns (checker, diagonals, ripples, spirals) that crossfade over time; band groups
// light blocks of tiles; a ring of tiles ripples out from a wandering spot on the music
// clock and attacks light it up with a spark at its origin, while mirror-ball specks
// and soft pools of shadow sweep across the glass. Zoom speed slides the floor.


// ---------------------------------------------------------------- 168 Mirror Ball
// A big faceted mirror ball turns high in a hazy room. Each square facet reflects the
// coloured spotlights aimed at it and twinkles; hundreds of reflected specks sweep the
// walls. Bass brightens the beams, highs make facets sparkle, attacks bring out extra
// specks and light a ring of specks flung outward on the music clock. Zoom speed pans
// the room and turns the ball.


// ---------------------------------------------------------------- 169 Drone Ballet
// Two hundred and fifty-six light drones perform above dark water, flowing between
// formations (sphere, helix bundle, rippling sheet, nested rings, torus knot). Groups
// of drones morph on staggered schedules and arc out of each other's way, each drone a
// glowing point with a soft halo and a short trail, mirrored as shimmering streaks on
// the water above a faint far skyline. Bands brighten drone rows and sweep colour
// across the swarm, attacks light a ripple of brightness and displacement through it,
// the music clock speeds the morphs and Zoom speed orbits and dollies the camera.
constant int DRONE_U = 32, DRONE_V = 8, DRONE_PU = 4, DRONE_PV = 2;

struct DroneSwarm { int from, to; float morph, t, rippleR, accent, bass, beat; float2 spin; };
// A patch of drones morphs together: its blend and the arc it lifts along while
// changing formation are shared, so each patch travels its own path.
struct DronePatch { float blend; float3 lift; };

// World position (relative to the swarm centre, already spun) of the drone or patch
// centre at grid coordinate (u, v).


// ---------------------------------------------------------------- 170 Ribbon Gymnast
// Rhythmic-gymnastics ribbons loop, spiral and snake through the air over a dark stage.
// Each ribbon is the recent path of its stick tip (a sum of rotating phasors whose
// shape morphs between circles, figure eights and loops), drawn as a twisting band
// with a bright front and a darker back. Bass widens the loops; attacks whip the
// tail into a coil. Zoom speed drifts the camera.


// ---------------------------------------------------------------- 171 Laser Haze
// A club laser show: rows of emitters below and above fan thin beams through drifting
// haze, sweeping, fanning and converging into cones, with hot spots where beams strike
// the ceiling, above a dark stage edge with a soft footlight glow. Bands widen each
// emitter's fan, attacks flick fans to a new angle and Zoom speed pans along the rig.


// ---------------------------------------------------------------- 172 Moving Heads
// A concert rig: moving-head fixtures hang from a truss and swing their cones across
// the stage in choreographed sweeps, projecting rotating gobo patterns onto the floor
// through haze, with a chasing row of stage-edge lights. Bass widens the cones, highs
// twinkle the gobos and attacks sweep every head toward centre stage in unison.


// ---------------------------------------------------------------- 173 Conga Orbs
// A conga line of glossy orbs hops along a snaking, looping path across a polished
// dance floor, each orb squashing on landing and stretching as it springs, with a
// shadow, a mirror reflection and a glowing track joining the line. Bass raises the
// hops, highs sparkle the highlights, spinning flips ripple down the line with the
// music clock and attacks add a hop and light the track. Zoom speed dollies the camera.


// ---------------------------------------------------------------- 174 Headspin
// Breaking moves as pure light painting: four lights carried by an unseen dancer trace
// two-tone trails that cycle through spin figures every few seconds (stacked head-spin
// rings with epicycloid loops, windmill circles, figure-eight sweeps, low floor sweeps),
// crossfading between figures while trails build up and decay. Every so often the spin
// slows to a freeze and the lights flare. Sparks skid off the floor. Bass brightens the
// trails and attacks flare the lights and light a ring on the floor.
struct SpinLimbs { float3 p[4]; };
// One figure for a foot or hand light, split into the part that flips sign for the
// opposite light (odd in the spin phasor) and the part both share (even). xy are screen
// offsets from the spin centre, z is nearness to the camera.
struct SpinPart { float3 odd, even; };


// Feet (0, 1) sit opposite each other on the spin, hands (2, 3) a quarter turn away.

// The spin slows to a near freeze every 24 seconds: rate = TAU * (1.25 - .95 * freeze).
constant float SPIN_FREEZE = TAU / 24;


// ---------------------------------------------------------------- 175 Waltz Pairs
// A ballroom seen from above: pairs of glowing partners turn around each other with
// soft trails while the couples travel counter-clockwise around a polished parquet
// floor that mirrors the chandeliers. The turn accelerates on beat one of each bar of
// three; bass widens the turns and attacks spin a couple out. Zoom speed slowly turns
// and dollies the overhead camera.


// ---------------------------------------------------------------- 176 Pigment Burst
// Slow-motion bursts of coloured powder bloom against a dark backdrop, like high-speed
// photographs of thrown pigment. Six plumes launch on a staggered schedule from points
// along the lower frame, each billowing outward (self-similar noise that expands with
// the cloud), curling, lit from one side with a glowing rim, and fading while newer
// plumes take over, so the frame is always full; overlapping plumes mix their colours.
// Bass swells and speeds the youngest plume, attacks push it outward, highs add
// glittering grains and Zoom speed drifts the camera through the clouds.
float3 pigmentBurst(Ctx c, constant NativeFrame &f) {
    float zoom = 1 + .08 * sin(c.travel * .08);
    float2 uv = c.uv / zoom + float2(sin(c.travel * .05) * .35, sin(c.travel * .037) * .15);
    float3 color = deep(.4 + uv.y * .05, f) * .035 + paint(.5, f) * .05 * exp(-length(uv * float2(.6, 1)) * 1.2);
    // Fine pigment dust hangs everywhere from earlier bursts.
    float dust = fbm2(uv * .9 + float2(c.t * .02, -c.t * .015), 3);
    color += paint(dust * 1.2 + .1, f) * (.035 + .05 * dust);
    const int plumes = 6;
    const float life = 7.5;
    float clock = (c.t + c.m * 1.6) / life;
    float accent = dnAccent(c, f);
    float2 light = normalize(float2(-.6, .8));
    float density = 0;
    // Oldest plume first so younger plumes billow in front.
    int oldest = (plumes - 1 - int(floor(fract(clock) * plumes))) % plumes;
    for (int m = 0; m < plumes; ++m) {
        int k = (oldest - m + plumes) % plumes;
        float phase = clock + float(k) / plumes;
        float age = fract(phase);
        float generation = floor(phase);
        float3 seed = hash33(float3(generation, float(k), 7.1));
        float young = exp(-age * 5);
        float grow = 1 - exp(-age * (3.2 + 2.5 * c.b.x * young));
        float2 launch = float2(((float(k) + seed.x) / plumes * 2 - 1) * .9 * c.extent.x, c.extent.y * (seed.y * 1.1 - .85));
        float2 dir = normalize(float2(-launch.x * .3 + (seed.z - .5) * .9, .8 - launch.y * .4));
        float2 center = launch + dir * grow * (.45 + .35 * seed.y) * c.extent.y;
        float R = (.2 + .8 * grow) * c.size * (1 + .45 * c.b.x * young + .35 * accent * young) * 1.1;
        float2 q = rot(uv - center, (seed.z - .5) * 1.6 * age + seed.x * 6) / R;
        float r = length(q);
        if (r > 1.7) continue;
        float fade = smoothstep(0.f, .06f, age) * pow(1 - age, 1.3f);
        // Billows: noise that expands with the plume and drifts outward as it grows.
        float2 nq = q * 1.7 * (1 - .35 * age) + seed.xy * 20;
        float billow = fbm2(nq, 5);
        float bump = (billow - fbm2(nq + light * .07, 5)) * 5;
        float edge = r + (billow - .5) * 1.25 + (noise2(nq * 3.3) - .5) * .3;
        float body = smoothstep(1.f, .72f, edge);
        float thick = smoothstep(1.f, .2f, edge);
        float2 lq = q + light * .16;
        float lit = fbm2(lq * 1.7 * (1 - .35 * age) + seed.xy * 20, 3);
        float toward = smoothstep(1.f, .2f, length(lq) + (lit - .5) * 1.25);
        float shade = saturate(.5 + (thick - toward) * 2.2 + dot(q, light) * .25 + bump);
        float rim = smoothstep(.6f, 1.f, edge) * body;
        float plumeBand = c.b[k % 4];
        float hue = seed.x * .9 + float(k) * .17 + plumeBand * .2;
        float3 tint = paint(hue, f) * (1 + plumeBand * .6);
        float3 plume = mix(deep(hue, f) * .45, tint, shade) + mix(tint, paint(.95, f), .3) * rim * .4;
        plume *= (.75 + .45 * billow) * (.7 + .4 * thick);
        color += tint * smoothstep(1.7f, .6f, r) * fade * .05;
        float alpha = body * fade * .95;
        color = mix(color, plume, alpha);
        density = max(density, alpha);
    }
    // Glittering grains caught in the clouds.
    float2 g = uv * 95;
    float2 gid = floor(g);
    float gh = hash21(gid);
    float grain = step(.93f, gh) * pow(.5 + .5 * sin(c.t * (5 + gh * 7) + gh * 60), 10.f);
    float dotMask = smoothstep(.35f, .1f, length(fract(g) - .5));
    color += paint(.9 + gh * .1, f) * grain * dotMask * density * (.35 + c.b.w * 3 + c.hit * 2.5);
    return color;
}

// ---------------------------------------------------------------- 177 Pirouette Bloom
// Spinning tulle skirts seen from above, abstracted into flowers: layered frills turn
// and their pleats flare wider the faster each bloom spins, sequins glint on the hems
// and a rosette of sequins glows at each heart, every bloom in its own spotlight pool.
// Bass flares the pleats, attacks pop the sequins and Zoom speed drifts the camera.


// ---------------------------------------------------------------- 178 Stretch Membrane
// One taut, glossy stretch-fabric sheet fills the frame. Unseen performers press into
// it from behind: seven knee-, shoulder- and palm-sized pushes glide and twist in slow
// phrases as low, flat-topped swells, with soft broad wrinkles pulled between
// neighbouring pushes. Everything is shaded from the sheet's own normals: a fine weave
// everywhere, a warm grazing light from one side and a cool one from the other, long
// anisotropic stretch highlights along the tension around each push and a coloured
// rim where the fabric bends at its base. Bass deepens the pushes, attacks raise a
// small sharp push, highs ripple the sheen and Zoom speed slides the pushes and lights.
float3 stretchMembrane(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv;
    float slide = c.travel * .07;
    float phrase = dnBeat(c, .3, .8);
    float depthBoost = 1 + c.b.x * .6;
    const int pushes = 7;
    float2 centers[pushes];
    float amps[pushes];
    float2 grad = 0.f;
    float height = 0, rim = 0;
    float3 tension = 0.f;   // structure tensor (xx, yy, xy) of the stretch directions
    for (int k = 0; k < pushes; ++k) {
        float fk = float(k);
        float3 seed = hash33(float3(fk, 3.1, 7.7));
        float2 center = float2(sin(phrase * (.8 + seed.x * .6) + fk * 2.3 + slide) * .82 * c.extent.x,
                               sin(phrase * (.65 + seed.y * .5) + fk * 1.7 + slide * .6) * .78 * c.extent.y);
        float press = .35 + .65 * smoothstep(.1f, .8f, .5 + .5 * sin(phrase * 1.2 + fk * 1.9));
        float size = (.2 + .22 * seed.z) * c.size;
        float2 axes = float2(size * (1 + .6 * seed.x), size);
        float twist = c.t * (seed.y - .5) * .8 + fk * 1.3;
        float A = press * (.7 + .3 * seed.y) * depthBoost * (1 + c.b[k % 4] * 1.2) * size * .62;
        // A low swell with a flat top that eases out slowly into the sheet.
        float2 q = rot(p - center, -twist) / axes;
        float q2 = dot(q, q);
        float g = 1 / (1 + q2 * q2);
        height += A * g;
        float2 slope = rot(-4 * A * g * g * q2 * q / axes, twist);
        grad += slope;
        float w = dot(slope, slope);
        float2 dir = slope * rsqrt(max(w, 1e-8f));
        tension += float3(dir.x * dir.x, dir.y * dir.y, dir.x * dir.y) * w;
        rim += exp(-dnSq((sqrt(q2) - 1.15) / .45)) * press;
        centers[k] = center;
        amps[k] = A / size;
    }
    // Soft, broad wrinkles pulled taut between neighbouring pushes.
    for (int k = 0; k < pushes; ++k) {
        int j = (k + 1) % pushes;
        float2 a = centers[k], b = centers[j];
        float2 ab = b - a;
        float len = length(ab);
        float strength = smoothstep(1.7f, .5f, len) * min(amps[k], amps[j]);
        if (strength < 1e-4) continue;
        float h = saturate(dot(p - a, ab) / max(len * len, 1e-4f));
        float2 along = ab / max(len, 1e-4f), across = float2(-along.y, along.x);
        float side = dot(p - a - ab * h, across);
        float width = .16 + .1 * len;
        float env = sin(PI * h) * exp(-side * side / (width * width)) * strength;
        float wave = side * 55 + h * 3;
        float wrinkle = .006 * (1 + c.b.y * 1.6);
        height += wrinkle * cos(wave) * env;
        grad += across * (-wrinkle * 55 * sin(wave) * env);
        tension += float3(along.x * along.x, along.y * along.y, along.x * along.y) * env * env * .2;
    }
    // A small sharp push springs up where the music clock points when an attack lands.
    float2 hitAt = float2(sin(c.m * .9 + 1) * .6 * c.extent.x, cos(c.m * .7) * .5 * c.extent.y);
    float2 hq = (p - hitAt) / (.1 * c.size);
    float hinv = 1 / (1 + dot(hq, hq));
    float hA = dnAccent(c, f) * .1 * c.size * .5;
    height += hA * hinv * hinv;
    grad += -4 * hA * hinv * hinv * hinv * hq / (.1 * c.size);
    // The woven surface: a rib and a fine weave tilt the normals everywhere.
    float2 warp = normalize(float2(1, .35)), weft = float2(-warp.y, warp.x);
    float shimmer = 1 + c.b.w * .8 * sin(dot(p, float2(23, 9)) - c.t * 7);
    float fineWeave = saturate(1.6f - c.px * 420 * .9f);
    float ribFade = saturate(1.6f - c.px * 150 * .9f);
    float2 weave = (warp * cos(dot(p, warp) * 420) + weft * cos(dot(p, weft) * 420)) * .05 * fineWeave
                 + warp * cos(dot(p, warp) * 150 + sin(dot(p, weft) * 3) * 2) * .03 * ribFade;
    float3 n = normalize(float3(-(grad + weave * shimmer), 1));
    // Stretch direction: the dominant eigenvector of the tension tensor. Fibres run across
    // it, so highlights streak along the stretch.
    float stretchAngle = .5 * atan2(2 * tension.z, tension.x - tension.y);
    float2 stretchDir = float2(cos(stretchAngle), sin(stretchAngle));
    float stretchAmount = saturate(sqrt(dnSq(tension.x - tension.y) + 4 * tension.z * tension.z) * 5) * smoothstep(.04f, .22f, length(grad));
    float3 fibre = float3(-stretchDir.y, stretchDir.x, 0);
    fibre = normalize(fibre - n * dot(fibre, n));
    float3 view = float3(0, 0, 1);
    float swing = sin(c.travel * .05) * .25 + sin(c.t * .07) * .15;
    float3 warmL = normalize(float3(-cos(swing) * .93, .2 + sin(swing) * .3, .36));
    float3 coolL = normalize(float3(cos(swing) * .93, -.15 + sin(swing) * .2, .36));
    float3 warmT = paint(.75 + c.b.x * .2, f), coolT = paint(.12 + c.b.z * .25, f) * 1.5;
    float across = saturate(.5 - .5 * p.x / c.extent.x + .15 * sin(swing * 2));
    float3 lights[2] = {warmL, coolL};
    float3 tints[2] = {warmT, coolT};
    float reach[2] = {.2 + .8 * across, .2 + .8 * (1 - across)};
    float3 color = deep(.5, f) * .04;
    for (int i = 0; i < 2; ++i) {
        float3 L = lights[i];
        float3 hv = normalize(L + view);
        float diffuse = max(dot(n, L), 0.f);
        float sheen = pow(max(dot(n, hv), 0.f), 5.f);
        float spec = pow(max(dot(n, hv), 0.f), 45.f);
        float th = dot(fibre, hv);
        float aniso = pow(sqrt(max(1 - th * th, 0.f)), 140.f) * stretchAmount;
        color += tints[i] * (diffuse * diffuse * .55 + sheen * .12 + spec * .2 + aniso * 1.5) * reach[i];
    }
    // A coloured rim where the fabric bends at the base of each push, and a faint glow
    // where it is stretched thinnest.
    color += mix(coolT, warmT, across) * rim * .07 * (1 + .5 * stretchAmount);
    color += paint(.9, f) * dnSq(saturate(height * 9)) * .12;
    color += paint(.9, f) * hinv * hinv * c.hit * .45;
    return color;
}

// ---------------------------------------------------------------- 179 Kinetic Mirrors
// A large kinetic wall of small square mirrors on pivots, seen at a slight angle. The
// tiles tilt in travelling waves (diagonals, rings, spirals), so each reflects a
// different part of a colourful stage behind the viewer (drifting colour spots, sweeping
// beams, pin lights) and shimmering waves of colour roll across the wall between thin
// dark gaps and bevelled edges. Bands drive the different wave patterns, attacks send a
// ripple of tilts out from a point, highs add glints and Zoom speed pans along the wall.
float3 mirrorStage(float3 d, Ctx c, constant NativeFrame &f) {
    float3 color = deep(.4 + d.y * .2, f) * .07 + paint(.3, f) * .025 * (1 + d.y);
    for (int k = 0; k < 5; ++k) {
        float fk = float(k);
        float3 spot = normalize(float3(sin(c.t * (.17 + fk * .03) + fk * 1.3) * .9, sin(c.t * (.13 + fk * .02) + fk * 2.1) * .45 + .05, -1));
        float a = max(dot(d, spot), 0.f);
        color += paint(fk * .21 + .05, f) * (pow(a, 34.f) * .75 + pow(a, 400.f) * 2.5);
    }
    float az = atan2(d.x, -d.z);
    float beams = pow(.5 + .5 * cos(az * 7 - c.t * 1.1 + d.y * 2), 24.f) * smoothstep(-.3f, .5f, d.y);
    color += paint(.55 + .2 * sin(az * 2 + c.t * .2), f) * beams * .45;
    float2 pin = float2(az * 9, d.y * 9);
    float2 pid = floor(pin);
    float ph = hash21(pid);
    float twinkle = pow(.5 + .5 * sin(c.t * (2 + ph * 4) + ph * 30), 6.f);
    color += paint(.9, f) * exp(-dot(fract(pin) - .5, fract(pin) - .5) * 60) * step(.7f, ph) * twinkle * (.6 + c.b.w * 3);
    return color;
}
float3 kineticMirrors(Ctx c, constant NativeFrame &f) {
    float yaw = .3 + .05 * sin(c.t * .07);
    float3 rd = normalize(float3(c.uv, 2.2));
    float3 N0 = float3(-sin(yaw), 0, -cos(yaw));
    float3 T = float3(cos(yaw), 0, -sin(yaw));
    const float D = 3;
    float t = dot(float3(0, 0, D), N0) / dot(rd, N0);
    float3 hit = rd * t;
    float2 w = float2(dot(hit - float3(0, 0, D), T), hit.y) + float2(c.travel * .15, 0);
    float tile = .16 * c.size;
    float2 cell = w / tile;
    float2 id = floor(cell), lq = fract(cell) - .5;
    float2 wc = (id + .5) * tile;
    // Travelling tilt waves; each band drives its own pattern.
    float2 ringC = float2(sin(c.t * .13) * 1.5 + c.travel * .15, cos(c.t * .11) * .6);
    float2 rv = wc - ringC;
    float rr = length(rv);
    float diag = sin(dot(wc, float2(1.4, .9)) * 2.2 - c.t * 1.7 - c.m * 2.2);
    float ringW = sin(rr * 4.5 - c.t * 2.3 - c.m * 2.8);
    float spiral = sin(atan2(rv.y, rv.x) * 3 + rr * 3.2 - c.t * 1.5 - c.m * 1.8);
    float mixA = .5 + .5 * sin(c.t * .09), mixB = .5 + .5 * sin(c.t * .07 + 2);
    float wDiag = .45 * mixA + c.b.x * .6, wRing = .45 * (1 - mixA) + c.b.y * .6, wSpiral = .35 * mixB + c.b.z * .6;
    float2 tilt = float2(diag * wDiag + ringW * wRing * rv.x / max(rr, .2f) + spiral * wSpiral * .7,
                         diag * wDiag * .6 + ringW * wRing * rv.y / max(rr, .2f) + spiral * wSpiral * .7 * cos(rr * 2)) * .3;
    // Attack ripple from a point on the wall, riding the music clock.
    float2 hitC = float2(sin(c.m * .8) * 1.2 + c.travel * .15, cos(c.m * .6) * .5);
    float2 hv = wc - hitC;
    float hr = length(hv);
    float front = fract(c.m * .45) * 3;
    float ripple = exp(-dnSq((hr - front) / .25)) * (1 - front / 3);
    tilt += hv / max(hr, .05f) * ripple * dnAccent(c, f) * .45;
    // Bevelled tile edges and dark gaps.
    float edge = max(abs(lq.x), abs(lq.y));
    float bevel = smoothstep(.36f, .46f, edge);
    float2 lean = tilt + sign(lq) * step(abs(lq.yx), abs(lq)) * bevel * .5;
    float3 n = normalize(N0 + T * lean.x + float3(0, 1, 0) * lean.y);
    float3 r = reflect(rd, n);
    float3 color = mirrorStage(r, c, f);
    color *= .75 + .25 * smoothstep(.5f, .2f, edge);
    color += paint(.9, f) * c.hit * ripple * 1.2;
    float px = c.px * t * 1.2 / tile;
    float gap = smoothstep(.47f - px, .47f + px, edge);
    color = mix(color, deep(.3, f) * .02, gap * .9);
    return color * (1 - .35 * smoothstep(3.f, 8.f, t) * c.fog * 2);
}

// ---------------------------------------------------------------- 180 Fire Dance
// Fire poi on a night beach, the performers implied only by the light: flaming heads
// trace circles, flowers and figure eights with flickering fire trails, shedding sparks
// while embers rise and the sand glows. Bass enlarges the flames, attacks flare the poi heads and light bursts
// of sparks around them, and highs make the embers flicker. Zoom speed pans the beach.
float3 fireDance(Ctx c, constant NativeFrame &f) {
    float2 uv = c.uv;
    float pan = c.travel * .1;
    float seaY = .1 * c.extent.y, shoreY = -.22 * c.extent.y;
    float2 moon = float2(.6 * c.extent.x - sin(pan * .3) * .1, .65 * c.extent.y);
    float3 color;
    if (uv.y > seaY) {
        color = deep(.15 + uv.y * .05, f) * .05 + paint(.3, f) * .07 * exp(-(uv.y - seaY) * 3);
        float2 star = uv * 90;
        color += paint(.9, f) * pow(hash21(floor(star)), 90.f) * smoothstep(.3f, .1f, length(fract(star) - .5)) * 1.5;
        color += paint(.95, f) * (fill(length(uv - moon) - .07, c.px) * .6 + exp(-length(uv - moon) * 6) * .12);
    } else if (uv.y > shoreY) {
        float depth = seaY - uv.y;
        float glint = pow(noise2(float2(uv.x * 4 + pan, depth * 60 / (depth + .1) - c.t * .6)), 6.f);
        color = deep(.2, f) * .05 + paint(.6, f) * glint * .35 * exp(-depth * 3);
        color += paint(.9, f) * glint * exp(-abs(uv.x - moon.x) * 4) * (.5 + c.b.z * 1.5);
        color += paint(.7, f) * .1 * exp(-dnSq((uv.y - shoreY) / .012)) * (.6 + .4 * sin(uv.x * 9 + c.t * .7));
    } else {
        float grain = noise2(uv * 140) * .5 + noise2(uv * 9 + 3) * .5;
        color = deep(.55, f) * (.045 + .03 * grain) + paint(.35, f) * .025;
    }
    const float H = .95;
    float feetY = shoreY - .42 * min(c.extent.y, 1.4f);
    const float sp = 1.45;
    float slot = floor((uv.x + pan) / sp + .5);
    float flameScale = c.size * (1 + c.b.x * .55);
    float3 fire = 0.f, sparks = 0.f;
    const int N = 18;
    const float span = .36;
    float fades[N + 1];
    for (int i = 0; i <= N; ++i) fades[i] = 1.2 * log(max(1 - float(i) / float(N), 1e-3f));
    for (int k = -1; k <= 1; ++k) {
        float id = slot + float(k);
        float seed = hash11(id * 2.9 + 1);
        float2 feet = float2(id * sp - pan, feetY);
        if (abs(uv.x - feet.x) > 1.05) continue;
        float omega = TAU * (1 + .2 * seed) * (seed > .5 ? 1.f : -1.f);
        float mode = .5 + .5 * sin(c.t * .15 + seed * 6);
        float extension = mix(1.f, .35f, mode), flower = mode * .55;
        float tauNow = c.t + c.m * 3 / TAU;
        for (int side = 0; side < 2; ++side) {
            float sgn = side == 0 ? -1.f : 1.f;
            float2 hc = feet + float2(.3 * sgn, .64) * H;
            float poiBand = c.b[(side + int(seed * 3.99)) % 4];
            float poiScale = flameScale * (1 + poiBand * .8);
            // The poi head is a hand circle plus a tether made of two rotating phasors.
            float2 A = dnPolar(omega * tauNow * sgn), B = float2(A.x, -A.y);
            B = dnMul(dnMul(B, B), B);
            float2 A0 = A, B0 = B;
            const float2 lead = float2(.8775826, .4794255);
            float2 prev = hc + .12 * A + .36 * (extension * dnMul(A, lead) + flower * B);
            float2 head = prev;
            fire += paint(.97, f) * exp(-length(uv - head) / (.016 * poiScale)) * 1.4;
            fire += paint(.6, f) * exp(-length(uv - head) / (.12 * poiScale)) * (.16 + c.hit * .5);
            if (length(uv - hc) > 1.1) continue;
            // Flame trail: the recent path of the poi head.
            float2 rA = dnPolar(-omega * span / float(N) * sgn), rB = float2(rA.x, -rA.y);
            rB = dnMul(dnMul(rB, rB), rB);
            float score = -1e4, sAt = 1, dAt = 9, dMin = 1e3, sMin = 1;
            float prevW = .018 * poiScale;
            for (int i = 1; i <= N; ++i) {
                float s = float(i) / float(N);
                A = dnMul(A, rA); B = dnMul(B, rB);
                float2 pt = hc + .12 * A + .36 * (extension * dnMul(A, lead) + flower * B) + float2(0, s * s * .07);
                float2 pa = uv - prev, ba = pt - prev;
                float hh = saturate(dot(pa, ba) / max(dot(ba, ba), 1e-7f));
                float d = length(pa - ba * hh);
                float curW = (.018 + .04 * s) * poiScale;
                float dw = d / mix(prevW, curW, hh);
                float sc = -dw * dw * 1.3 + mix(fades[i - 1], fades[i], hh);
                if (sc > score) { score = sc; sAt = (float(i - 1) + hh) / float(N); dAt = dw; }
                if (d < dMin) { dMin = d; sMin = (float(i - 1) + hh) / float(N); }
                prev = pt;
                prevW = curW;
            }
            float glowBest = exp(-dAt * dAt * 1.3) * pow(1 - sAt, 1.2f);
            float flick = noise2(float2(sAt * 9 - c.t * 7 + id * 3 + sgn, dAt * 2 + c.t * 3));
            float tongues = noise2(uv * float2(16, 9) + float2(id * 5 + sgn * 3, -c.t * 6));
            float heat = glowBest * (.55 + .9 * flick);
            fire += paint(mix(.98f, .25f, saturate(sAt * 1.1 + dAt * .3)), f) * heat * (1.5 + poiBand * 1.2);
            float aura = exp(-dMin / (.055 * poiScale)) * dnSq(1 - sMin) * smoothstep(.35f, .8f, tongues);
            fire += paint(.3 + .3 * (1 - sMin), f) * aura * .55;
            // Sparks shed from the poi path, and a burst from the head on attacks.
            for (int k2 = 0; k2 < 4; ++k2) {
                float hk = hash11(id * 13 + float(k2) * 3.7 + sgn);
                float age = fract(c.t * 1.2 + hk);
                float2 back = dnPolar(-omega * age * .6 * sgn), backB = float2(back.x, -back.y);
                float2 Aa = dnMul(A0, back), Ba = dnMul(B0, dnMul(dnMul(backB, backB), backB));
                float2 origin = hc + .12 * Aa + .36 * (extension * dnMul(Aa, lead) + flower * Ba);
                float2 vel = (float2(hk, hash11(hk * 9)) - .5) * .5 + float2(0, .25);
                float2 a = origin + vel * age - float2(0, .7 * age * age);
                float2 b = a - (vel - float2(0, 1.4 * age)) * .03;
                sparks += paint(.85, f) * exp(-sdSegment(uv, a, b) / .003) * dnSq(1 - age) * .9;
            }
            for (int k2 = 0; k2 < 5; ++k2) {
                float hk = hash11(id * 7 + float(k2) * 5.1 + sgn * 3);
                float2 dir = dnPolar(hk * TAU + float(k2));
                float age = fract(c.m * .8 + hk);
                float2 a = head + dir * age * (.35 + .25 * hk) - float2(0, .3 * age * age);
                sparks += paint(.9, f) * exp(-sdSegment(uv, a, a - dir * .04) / .004) * c.hit * 2.2 * (1 - age * .6) * smoothstep(0.f, .15f, age) * (1 - smoothstep(.75f, 1.f, age));
            }
        }
        color += paint(.6, f) * exp(-length((uv - feet) * float2(1, 3.5)) * 2.2) * .35 * (uv.y < shoreY ? 1.f : .4f) * (1 + c.b.x * 2.5);
    }
    // Embers rising over the whole beach.
    float2 eq = (uv + float2(pan * .5, -c.t * .12)) * 11;
    float2 eid = floor(eq);
    float2 eh = hash22(eid + 5);
    float2 ep = fract(eq) - .5 - (eh - .5) * .6 + .15 * float2(sin(c.t * 2 + eh.x * 9), 0);
    float flickE = .55 + .45 * sin(c.t * (6 + eh.y * 8) + eh.x * 20) * (1 + c.b.w * 2.5);
    float ember = exp(-dot(ep, ep) * 260 / (1 + c.b.w * 1.5)) * step(.6f - c.b.w * .2f, eh.x) * flickE * smoothstep(.9f, -.4f, uv.y / c.extent.y);
    return color + fire + sparks + paint(.7 + eh.y * .25, f) * ember * .9;
}

// ---------------------------------------------------------------- 181 Chiffon Swirl
// A long-exposure photograph of a twirling chiffon skirt without the dancer: four sheer
// layers flare around an invisible vertical axis in spiral folds, translucent where they
// overlap, rim-lit, with fine fabric grain and luminous hems, under a single spotlight
// in stage haze. The spin speeds up and slows in phrases and the skirt flares with it;
// bass flares the swirl wider, attacks flick a hem outward, highs make the hems glitter
// and Zoom speed slowly dollies around the swirl.
struct ChiffonLayer { float3 color; float alpha; };


// ---------------------------------------------------------------- 182 Fountain Show
// A musical fountain at night: a row of jets throws columns and arcs of streaky water
// lit from below in shifting palette colours, with mist, splashes and reflections in
// the pool in front of a city skyline. Jets choreograph procedurally; bands drive the
// heights of their jet groups and attacks shoot the central jets high. Zoom speed pans.
float3 fountainJets(float2 p, float waterY, float pan, Ctx c, constant NativeFrame &f) {
    float3 light = 0.f;
    const float sp = .34;
    float slot = floor((p.x + pan) / sp + .5);
    float arcs = smoothstep(.25f, .75f, .5 + .5 * sin(c.t * .13));
    float modeA = .5 + .5 * sin(c.t * .07), modeB = .5 + .5 * sin(c.t * .11 + 2);
    float tall = .8 + .55 * saturate(c.extent.y - 1);
    float y = p.y - waterY;
    for (int k = -3; k <= 3; ++k) {
        float j = slot + float(k);
        float xj = j * sp - pan;
        float dx = p.x - xj;
        int group = int(j - floor(j / 4) * 4);
        float wave = .5 + .35 * sin(c.t * 1.5 + c.m * 2.4 - j * .6);
        float alternate = .45 + .35 * sin(c.t * 2.1 + c.m * 3) * (fmod(abs(j), 2.f) < 1 ? 1.f : -1.f);
        float pulse = .55 + .3 * sin(c.t * 1.1 + c.m * 1.8);
        float H = mix(mix(wave, alternate, modeA), pulse, modeB * .5);
        float central = exp(-dnSq(xj / .5));
        H = (H + c.b[group] * .5 + dnAccent(c, f) * .9 * central) * tall;
        float3 tint = paint(j * .13 + c.t * .05, f) * (1 + c.hit * central);
        if (abs(dx) < .2 && y > -.03 && y < H + .25) {
            float frac = saturate(y / max(H, .05f));
            float w = (.012 + .03 * frac * frac) * c.size;
            float core = exp(-dnSq(dx / w));
            float streak = noise2(float2(dx / w * 1.3 + j * 7, y * 10 - c.t * 7));
            float column = core * (.45 + .8 * streak) * smoothstep(H + .12f, H * .75f, y);
            float crown = exp(-dnSq((y - H) / (.06 + .08 * frac)) - dnSq(dx / (w * 3))) * .5;
            light += tint * (column + crown) * (1.5 - .7 * frac) * (1 - arcs * .5);
            light += paint(.95, f) * core * core * .35 * (1 - frac) * (1 - arcs * .5);
        }
        for (int side = 0; side < 2; ++side) {
            float dir = side == 0 ? -1.f : 1.f;
            float reach = (.42 + .2 * sin(c.t * .4 + j)) * (.7 + .3 * H);
            float u = dx * dir / reach;
            if (u < 0 || u > 1.08) continue;
            float apex = H * .75;
            float yc = 4 * apex * u * (1 - u);
            float slope = 4 * apex * (1 - 2 * u) / reach;
            float dist = (y - yc) / sqrt(1 + slope * slope);
            float w = (.006 + .018 * u) * c.size;
            float drops = noise2(float2(u * 26 - c.t * 6 + j * 3, dist * 70));
            float stream = exp(-dnSq(dist / w)) * (.35 + .9 * drops) * smoothstep(1.08f, .95f, u);
            light += tint * stream * arcs * 1.3;
            float2 splash = float2(dx - dir * reach, y);
            light += tint * exp(-dot(splash, splash) / .002) * arcs * .5;
        }
        light += tint * exp(-dnSq(dx / .14) - y * y / .003) * .35;
    }
    return light;
}
float3 fountainShow(Ctx c, constant NativeFrame &f) {
    float2 uv = c.uv;
    float pan = c.travel * .06;
    float waterY = -.32 * c.extent.y;
    float3 color;
    if (uv.y > waterY) {
        color = mix(paint(.15, f) * .1, deep(.1, f) * .05, smoothstep(waterY, c.extent.y, uv.y));
        float clouds = fbm2(float2(uv.x * .9 + pan * .1 + c.t * .01, uv.y * 2.2), 4);
        color += paint(.35, f) * smoothstep(.45f, .8f, clouds) * .1 * smoothstep(waterY, waterY + .6f, uv.y);
        float2 star = uv * 80;
        color += paint(.9, f) * pow(hash21(floor(star)), 60.f) * smoothstep(.35f, .1f, length(fract(star) - .5)) * smoothstep(waterY + .4f, waterY + 1.f, uv.y);
        float x = uv.x + pan * .3;
        float bw = .16;
        float bid = floor(x / bw);
        float hb = hash11(bid * 1.7 + 3);
        float top = waterY + .05 + (.12 + .55 * hb * hb) * min(c.extent.y, 1.4f);
        if (uv.y < top) {
            float2 win = float2(fract(x / .026), fract((uv.y - waterY) / .036));
            float2 wid = float2(floor(x / .026), floor((uv.y - waterY) / .036));
            float on = step(.62f, hash21(wid + bid)) * step(.25f, win.x) * step(win.x, .75f) * step(.3f, win.y) * step(win.y, .7f);
            color = deep(.3, f) * .035 + paint(.75 + hash21(wid) * .25, f) * on * .3;
        }
        float bokeh = pow(noise2(float2(x * 14, 3)), 4.f) * exp(-(uv.y - waterY) * 30);
        color += paint(.8, f) * bokeh * .4;
        color += fountainJets(uv, waterY, pan, c, f);
        color += paint(.4, f) * exp(-(uv.y - waterY) / .06) * .08;
    } else {
        float depth = waterY - uv.y;
        float ripple = sin(depth * 70 / (depth + .15) + c.t * 2 + uv.x * 3) * .012 * min(depth * 6, 1.f);
        float2 mirror = float2(uv.x + ripple, waterY + depth * .9);
        color = deep(.25, f) * .04 + fountainJets(mirror, waterY, pan, c, f) * .45 * exp(-depth * 1.5);
        color += paint(.3, f) * .04 * (.5 + .5 * sin(depth * 40 - c.t + uv.x * 5));
        float rimY = -c.extent.y + .07;
        color = mix(color, deep(.4, f) * .08 + paint(.5, f) * .06, smoothstep(rimY + .01f, rimY - .01f, uv.y));
    }
    return color;
}

// ---------------------------------------------------------------- 183 Glowstick Rave
// A dark rave: dozens of glowsticks wave in circles and figure eights, held by a crowd
// you never see, leaving short light trails in drifting smoke. Each stick's motion is
// procedural; bands energize their stick groups and attacks throw some sticks spinning
// up into the air. Zoom speed drifts the view through the crowd.
float3 glowstickRave(Ctx c, constant NativeFrame &f) {
    float2 uv = c.uv;
    float pan = c.travel * .08;
    float smoke = fbm2(uv * 1.2 + float2(c.t * .04 + pan * .3, c.t * .02), 3);
    float3 color = deep(.4 + uv.y * .05, f) * (.03 + .05 * smoke);
    float throwArc = dnAccent(c, f);
    float3 sticks = 0.f;
    for (int layer = 0; layer < 2; ++layer) {
        float fl = float(layer);
        float cell = layer == 0 ? .26 : .42;
        float2 q = (uv + float2(pan * (.6 + fl * .7), 0)) / cell + fl * float2(.37, .51);
        float2 base = floor(q);
        float w = (layer == 0 ? .04 : .05) * c.size;
        for (int j = -2; j <= 1; ++j) for (int i = -1; i <= 1; ++i) {
            float2 id = base + float2(i, j);
            float2 h = hash22(id + fl * 17);
            float h3 = hash21(id * 1.7 + fl * 5 + 3);
            if (h.x < (layer == 0 ? .5 : .3)) continue;
            float band = c.b[int(h3 * 3.99)];
            float dirSpin = h3 > .5 ? 1.f : -1.f;
            float omega = (2.6 + 2 * h.y) * dirSpin;
            float theta = omega * c.t + c.m * 2.2 * dirSpin + h.x * TAU;
            float A = .28 * (1 + band * .7);
            float eight = smoothstep(.3f, .7f, h.y);
            bool thrown = hash21(id + fl * 3 + 11) > .78;
            float lift = thrown ? throwArc * 1.7 : 0.f;
            float spinUp = thrown ? TAU * 1.5 * throwArc : 0.f;
            float2 hand = id + .5 + (h - .5) * .35 + float2(0, lift);
            bool twirl = h.y > .8;
            float3 tint = paint(h3 * 1.1 + fl * .2, f);
            float energy = (1 + band * 1.6 + (thrown ? c.hit * 2 : 0.f)) * (layer == 0 ? .3f : .6f);
            float dHand = length(q - hand);
            sticks += tint * exp(-dHand / .45) * .05 * (.5 + smoke) * energy;
            if (dHand > A + .7) continue;
            float2 e = dnPolar(theta), step = dnPolar(-.1 * dirSpin);
            float stickLen = layer == 0 ? .3f : .36f;
            for (int g = 0; g < 4; ++g) {
                float2 pos = hand + A * mix(e, float2(e.y, e.x * e.y), eight);
                float ang = PI * .5 + .7 * e.y + spinUp;
                float2 dir = dnPolar(ang) * stickLen;
                if (twirl) dir = dnMul(dir, dnMul(e, e));
                float d = sdSegment(q, pos - dir, pos + dir);
                float ghost = g == 0 ? 1.f : dnSq(1 - float(g) / 4) * .55;
                float core = 1 - smoothstep(w * .45f, w, d);
                float halo = exp(-d / (w * 2.2)) * .3;
                sticks += (tint * (halo + core * .8) + paint(.95, f) * core * .6) * ghost * energy;
                e = dnMul(e, step);
            }
        }
    }
    return color + sticks;
}

#define DANCE_EFFECTS(X)          X(pigmentBurst)  X(stretchMembrane) X(kineticMirrors) X(fireDance)  X(fountainShow) X(glowstickRave)
DANCE_EFFECTS(NATIVE_EFFECT)
