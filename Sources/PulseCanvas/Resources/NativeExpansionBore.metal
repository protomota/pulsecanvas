// Original PulseCanvas designs 300–309: tunnels with new structures. None of these is a
// centred polar tunnel with a pattern on its wall; each has its own geometry (a bending path,
// an off-axis camera, two bores, a coil, pleats, open sky, a vertical shaft, veils, pipes
// seen from outside, a twisting ribbon). Original procedural code; see the prelude.

// ---------------------------------------------------------------- shared helpers
float boreAttack(Ctx c) { return smoothstep(.04f, .7f, c.hit); }
float boreBand(Ctx c, float id) { return c.b[min(3, int(id - 4 * floor(id / 4)))]; }
float boreWrap(float x, float period) { return x - period * floor(x / period); }
float boreSq(float x) { return x * x; }
float boreTwinkle(float seed, float t) { return pow(.5f + .5f * sin(t * (4 + 5 * seed) + seed * 37), 6.f); }
// Exit distance from inside a cylinder of radius r around the z axis (o = origin in the cross-section).
float boreCylinder(float2 o, float3 rd, float r) {
    float a = max(dot(rd.xy, rd.xy), 1e-6f), b = dot(o, rd.xy), k = dot(o, o) - r * r;
    return (-b + sqrt(max(b * b - a * k, 0.f))) / a;
}

// ---------------------------------------------------------------- 300 Serpent Bore
// A scaled tube whose centreline winds through space. The camera rides the bends, so the
// far end swings around the frame while the walls sweep past. Overlapping glowing plates
// line the wall: bass lifts rows of plates, low-mids sweep a spiral sheen, high-mids light
// four dorsal stripes, highs glint the rims and attacks roll a lit wave toward the viewer.
float2 boreSerpentPath(float z) {
    return float2(1.9 * sin(z * .23) + .9 * sin(z * .41 + 1.3), 1.4 * sin(z * .19 + 2.1) + .8 * sin(z * .37 + .4));
}

float3 serpentBore(Ctx c, constant NativeFrame &f) {
    float camZ = c.travel * .85;
    // The view follows the path's recent heading, so the bends ahead swing the far end around the frame.
    float3 eye = float3(boreSerpentPath(camZ), camZ);
    float3 heading = float3(boreSerpentPath(camZ + .4) - boreSerpentPath(camZ - 1.6), 2);
    float roll = .4 * sin(c.t * .06);
    float3 rd = cameraRay(c.uv, heading, float3(sin(roll), cos(roll), 0), 1.2);
    float t = .02;
    for (int i = 0; i < 56; ++i) {
        float3 p = eye + rd * t;
        float d = 1 - length(p.xy - boreSerpentPath(p.z));
        if (d < .001 + t * .002 || t > 42) break;
        t += d * .65;
    }
    float3 p = eye + rd * t;
    float2 q = p.xy - boreSerpentPath(p.z);
    const float columns = 22;
    float density = 2.7 / c.size;
    float2 g = float2(atan2(q.y, q.x) * columns / TAU, p.z * density);
    // Staggered plates; the row further away lies on top, so every visible rim faces the viewer.
    float base = floor(g.y), cover = 9, lift = 0;
    float4 s = 0;
    for (int k = 1; k >= -1; --k) {
        float row = base + float(k), shift = .5 * boreWrap(row, 2);
        float col = floor(g.x - shift + .5);
        float rowLift = c.b.x * boreSq(boreSq(.5 + .5 * sin(row * .55 - c.t * 1.6)));
        float2 local = g - float2(col + shift, row);
        float d = length(local * float2(1, 1.08)) - (.72 + .1 * rowLift);
        s = float4(d, local.y, col, row); lift = rowLift;
        if (d < 0) break;
        cover = min(cover, d);
    }
    float colId = boreWrap(s.z, columns), row = s.w;
    float seed = hash21(float2(colId, row));
    float foot = t * c.px * density * 1.4 + .01;
    float inner = clamp(-s.x / .72, 0.f, 1.f);
    float rim = 1 - smoothstep(0.f, .08f + foot, -s.x);
    float shade = 1 - .7 * exp(-max(cover, 0.f) * 8);
    float sheen = .3 + .7 * boreSq(1 - inner);
    float hue = row * .031 + .22 * sin(colId * TAU / columns) + seed * .08;
    float spiral = c.b.y * pow(.5f + .5f * sin(colId * TAU / columns * 2 + row * .21 - c.t * .8), 6.f);
    float stripe = c.b.z * step(boreWrap(colId, 4), .5f);
    float wave = c.hit * exp(-boreSq((row / density - camZ - 1.2 - 9 * boreAttack(c)) / .8));
    float3 plate = paint(hue, f) * (.12 + .88 * sheen * sheen) * shade * (.62 + lift * 1.6 + spiral * 2 + stripe * 1.3 + wave * 2.2);
    plate += paint(hue + .3, f) * rim * shade * (.5 + lift * 1.2 + wave * 1.8);
    plate += paint(.92, f) * rim * c.b.w * boreTwinkle(seed, c.t) * 2.5;
    float3 haze = paint(.8 + .1 * sin(c.t * .1), f) * .4;
    return mix(haze, plate / (1 + t * .08), exp(-t * (.05 + c.fog * .04)));
}
NATIVE_EFFECT(serpentBore)

// ---------------------------------------------------------------- 301 Ringworld Drift
// Inside a vast cylinder habitat, standing just above its floor and looking down its axis.
// Terraced bands ring the habitat: each one hugs the floor below, curves up both sides and
// closes overhead, so they nest as eccentric arches around a vanishing point near the floor.
// The axial sun line hangs overhead. Each terrace's lamps pulse with its band, and attacks
// send light climbing up both sides of the nearer terraces to meet overhead.
float3 ringworldDrift(Ctx c, constant NativeFrame &f) {
    float stand = -PI * .5 + .45 * sin(c.t * .045) + .15 * sin(c.t * .11);
    float2 radial = float2(cos(stand), sin(stand)), side = float2(-radial.y, radial.x);
    float2 eye = radial * .84;
    float3 rd = cameraRay(c.uv, float3(-radial * .62 + side * .1 * sin(c.t * .07), 1), float3(-radial, 0), 1.05);
    float t = min(boreCylinder(eye, rd, 1), 90.f);
    float2 q = eye + rd.xy * t;
    float camZ = c.travel * 1.8, z = t * rd.z + camZ;
    float angle = atan2(q.y, q.x);
    float foot = t * c.px / 1.05;
    float graze = max(abs(dot(rd.xy, q)), .03f);
    // Terraces along the axis: a lit face rising to a bright lip, then a shadowed step.
    float span = 1.7 * c.size, u = z / span, terrace = floor(u), fr = u - terrace;
    float footU = foot / graze / span;
    float seed = hash11(terrace + 11), band = boreBand(c, terrace);
    float face = smoothstep(0.f, .08f + footU, fr) * (1 - smoothstep(.86f - footU, .9f, fr));
    float lip = glow(fr - .9, .018 + footU);
    // Each terrace is divided into fields around the habitat; some glow as panels of light.
    const float sectors = 18;
    float sector = angle * sectors / TAU, sectorId = boreWrap(floor(sector), sectors);
    float seam = glow(abs(fract(sector) - .5) - .5, .02 + foot * sectors / TAU / max(graze, .15f));
    float panelSeed = hash21(float2(terrace, sectorId));
    float panel = smoothstep(.3f, .65f, panelSeed) * (.6 + band * 2.2 * boreSq(.5 + .5 * sin(sectorId * 2.1 + terrace - c.t * 1.4)));
    float hue = .32 + .26 * sin(terrace * .7) + panelSeed * .25;
    float3 col = mix(deep(hue + .35, f), paint(hue, f), .3 + .7 * fr) * face * (.12 + (.3 + .7 * fr * fr) * panel) * (1 - seam * .75) + deep(.5, f) * .06;
    // Lamps around each lip, pulsing with the terrace's band.
    const float lamps = 56;
    float around = angle * lamps / TAU, lampId = floor(around + .5);
    float arc = (around - lampId) * TAU / lamps, gapZ = (fr - .9) * span;
    float w = .035 + foot;
    float lampGlow = exp(-(arc * arc + gapZ * gapZ) / (w * w)) * boreSq(.035 / w);
    float pulse = boreSq(.5 + .5 * sin(boreWrap(lampId, lamps) * .9 + terrace * 1.7 - c.t * 1.8));
    float nearFade = smoothstep(.3f, 1.8f, t);   // lips fade before they sweep past the camera
    col += (paint(.7 + seed * .2, f) * lip * (.45 + band * 1.6) + paint(.92, f) * lampGlow * (.8 + band * 6 * pulse)) * nearFade;
    // Attack: light climbs both sides of the nearer terraces from the floor to meet overhead.
    float h = boreAttack(c);
    float fromFloor = abs(atan2(sin(angle - stand), cos(angle - stand)));
    float climb = c.hit * exp(-boreSq((fromFloor - (1 - h) * PI) / .35)) * smoothstep(14.f, 3.f, z - camZ);
    col += paint(.9, f) * climb * (lip * 3 + face * .7);
    col = mix(paint(.6, f) * .5, col, exp(-t * (.03 + c.fog * .03)));
    // The axial sun line, with low-mid surges running along it.
    float s0 = -dot(eye, rd.xy) / max(dot(rd.xy, rd.xy), 1e-6f);
    float axis = length(eye + rd.xy * s0), sunZ = s0 * rd.z + camZ;
    float sun = glow(axis, .025 + s0 * c.px * .6) * step(0.f, s0);
    float surge = .5 + .3 * sin(sunZ * .25 - c.t * .3) + c.b.y * 3 * pow(.5f + .5f * sin(sunZ * .6 - c.t * 2.4), 6.f);
    return col + paint(.95, f) * sun * surge * exp(-s0 * .02);
}
NATIVE_EFFECT(ringworldDrift)

// ---------------------------------------------------------------- 302 Twin Bore
// Two bores side by side, each with its own vanishing point and ring cadence, separated by a
// glowing translucent membrane. Bass and low-mids drive the left bore's rings and ribs, the
// high-mids and highs drive the right bore's slats and sparks, and attacks ripple the membrane.
float3 twinBore(Ctx c, constant NativeFrame &f) {
    float spread = clamp(.36f * c.extent.x, .34f, .62f);
    float2 drift = .06 * float2(sin(c.t * .13), cos(c.t * .11));
    float2 vl = float2(-spread, .05 * sin(c.t * .09)) + drift, vr = float2(spread, -.05 * sin(c.t * .09)) + drift;
    float2 mid = (vl + vr) * .5, across = normalize(vr - vl);
    float2 dl = c.uv - vl, dr = c.uv - vr;
    float rl = max(length(dl), .015f), rr = max(length(dr), .015f);
    // Left bore: thick filled rings on a slow cadence, ribs along the bore.
    float zl = .8 / rl, al = atan2(dl.y, dl.x);
    float ringL = (zl + c.travel * 1.3) * 1.3 / c.size, idL = floor(ringL + .5);
    float swell = c.b.x * boreSq(.5 + .5 * sin(idL * 1.1 - c.t * 1.8));
    float eL = abs(fract(ringL + .5) - .5), aaL = fwidth(ringL);
    float bandL = 1 - smoothstep(.1f + .16f * swell, .14f + .16f * swell + aaL, eL);
    float ribs = glow(sin(al * 5 + zl * .15), .08) * (.15 + c.b.y * 2);
    float3 left = paint(.55 + .12 * sin(al) + ringL * .045, f) * (.1 + bandL * (.55 + swell * 1.8) + exp(-eL * eL * 30) * .25)
                + paint(.8, f) * ribs;
    left = mix(paint(.85, f) * .8, left, exp(-zl * .07));
    // Right bore: dense segmented rings of slats with sparks at the joints.
    float zr = .8 / rr, ar = atan2(dr.y, dr.x);
    float ringR = (zr + c.travel * 1.3) * 2.4 / c.size, idR = floor(ringR + .5);
    float eR = abs(fract(ringR + .5) - .5), aaR = fwidth(ringR);
    float slot = ar * 14 / TAU + idR * .5, slotId = boreWrap(floor(slot + .5), 14);
    float slat = smoothstep(.12f, .3f, abs(fract(slot) - .5)) * (1 - smoothstep(.12f, .2f + aaR, eR));
    float lift = c.b.z * boreSq(.5 + .5 * sin(idR * .7 + slotId * .9 - c.t * 2.2));
    float spark = exp(-(boreSq(fract(slot + .5) - .5) + eR * eR) * 60) * c.b.w * boreTwinkle(hash21(float2(slotId, idR)), c.t) * 4;
    float3 right = paint(.22 + .1 * sin(ar * 2) + ringR * .03, f) * (.09 + slat * (.5 + lift * 2.5)) + paint(.95, f) * spark;
    right = mix(paint(.4, f) * .8, right, exp(-zr * .07));
    // The membrane: the bisecting sheet, rippled by attacks as a wave running toward the viewer.
    float zs = .8 / max(length(float2(spread, dot(c.uv - mid, float2(-across.y, across.x)))), .02f);
    float front = .8 + 7 * boreAttack(c);
    float rippleEnvelope = c.hit * exp(-boreSq((zs - front) / 1.6));
    float bend = .14 * rippleEnvelope * sin(zs * 3 - c.t * 3) + .03 * sin(c.uv.y * 4 + c.t * .5);
    float mx = dot(c.uv - mid, across) - bend * min(1 / zs, 1.5f);
    float wm = .012 + .05 / zs;
    float sheet = exp(-abs(mx) / (wm * 3));
    float3 col = mix(left, right, smoothstep(-c.px * 1.5f, c.px * 1.5f, mx));
    col = mix(col, (left + right) * .5, sheet * .4);
    col += filmColor(zs * .15 + c.uv.y * .4 + c.t * .04, f) * (glow(mx, wm) * .9 + sheet * .25) * (1 + rippleEnvelope * 3);
    return col;
}
NATIVE_EFFECT(twinBore)

// ---------------------------------------------------------------- 303 Coil Run
// Flying off-axis inside a giant helical coil of flat light ribbon. Gaps between the turns
// open onto a deep nebula on a wider cylinder, which drifts past with its own parallax. Bass
// breathes the coil pitch in travelling waves, low-mids light the centre lane, high-mids the
// edge dashes, highs sparkle the nebula, and attacks chase a bright pulse along the ribbon.
float3 coilRun(Ctx c, constant NativeFrame &f) {
    float orbit = c.t * .04;
    float2 eye = .55 * float2(cos(orbit), sin(orbit));
    float roll = .3 * sin(c.t * .05);
    float3 rd = cameraRay(c.uv, float3(-eye * .35, 1), float3(-sin(roll), cos(roll), 0), 1.15);
    float camZ = c.travel * 1.6;
    float t = boreCylinder(eye, rd, 1);
    float2 q = eye + rd.xy * t;
    float zw = t * rd.z + camZ;
    float pitch = 1.5 * c.size, duty = .6;
    float breath = c.b.x * .3 * sin(zw * .55 - c.t * 1.4);
    float phase = zw / pitch + breath - atan2(q.y, q.x) / TAU;
    float u = fract(phase);
    float foot = t * c.px / 1.15;
    float aa = foot / max(abs(dot(rd.xy, q)), .03f) / pitch + foot / TAU + .004;
    float mask = smoothstep(0.f, aa, u) * (1 - smoothstep(duty - aa, duty, u));
    mask = mix(mask, duty, smoothstep(.15f, .5f, aa));
    float across = u / duty, along = zw / pitch + breath - u;
    float edge = glow(min(u, duty - u), .012 + aa);
    float lane = glow(across - .5, .03 + aa) * (.2 + c.b.y * 2.2);
    float dash = pow(.5f + .5f * cos(along * TAU * 6 - c.t * 3), 8.f) * edge * (.3 + c.b.z * 3);
    float h = boreAttack(c);
    float chase = c.hit * exp(-boreSq((along - camZ / pitch - .3 - (1 - h) * 7) / .16));
    float hue = along * .19 + across * .12;
    float rails = glow(abs(across - .5) - .32, .02 + aa) * .5;
    float3 ribbon = mix(deep(hue + .3, f), paint(hue, f), .4 + .6 * sin(across * PI)) * (.2 + .22 * sin(across * PI)) + paint(hue + .35, f) * (edge * .6 + rails)
                  + paint(.9, f) * (lane + dash + chase * 3);
    // Nebula on an outer cylinder seen through the gaps.
    float t2 = boreCylinder(eye, rd, 4);
    float2 q2 = eye + rd.xy * t2;
    float z2 = t2 * rd.z + camZ;
    float n = fbm3(float3(q2 * .45, z2 * .12 + c.t * .02), 3);
    float3 nebula = paint(n * 1.4 + .25, f) * (.05 + .9 * n * n) + deep(.3 + n, f) * .12;
    float2 starCell = float2(floor((atan2(q2.y, q2.x) + PI) / TAU * 90), floor(z2 * 3));
    float starSeed = hash21(starCell);
    float star = step(.86f, starSeed) * (.25 + c.b.w * 4 * boreTwinkle(starSeed, c.t));
    nebula += paint(.85, f) * star * exp(-boreSq(length(fract(float2((atan2(q2.y, q2.x) + PI) / TAU * 90, z2 * 3)) - .5) * 4));
    float3 col = mix(nebula, ribbon, mask * exp(-t * .03));
    return col;
}
NATIVE_EFFECT(coilRun)

// ---------------------------------------------------------------- 304 Bellows Passage
// A pleated rectangular bellows. Each pleat is real geometry: the wall folds in to a lit ridge
// and out to a shadowed valley, and the faces that turn away hide behind the ridges. Bass
// squeezes the pleats in waves rolling toward the viewer, low-mids smoulder in the valleys,
// high-mids light the corner creases, highs spark along the ridges and attacks flash a band
// of ridges.
float boreBellowsMetric(float2 d) {
    float2 a = abs(d) * float2(.82, 1.18);
    a *= a; a *= a;
    return sqrt(sqrt(a.x + a.y));
}

float3 bellowsPassage(Ctx c, constant NativeFrame &f) {
    float2 sway = .1 * float2(sin(c.t * .13), cos(c.t * .11));
    float2 dir = (c.uv - sway) / 1.1;
    float s = max(boreBellowsMetric(dir), 1e-4f);
    float camZ = c.travel * 1.1;
    float pitch = .42 * c.size, depthA = .24;
    float slope = depthA * 2 * (1 / pitch + .2) + s;
    // March to the first wall crossing; the Lipschitz step never skips a fold.
    float z = 1 / s;
    for (int i = 0; i < 32; ++i) {
        if (z > 34) break;
        float zw = z + camZ;
        float u = zw / pitch + c.b.x * .4 * sin(zw * .45 + c.t * 1.8);
        float wall = 1 + depthA * (1 - abs(2 * fract(u) - 1));
        z += max(wall - z * s, 0.f) / slope;
    }
    float zw = z + camZ;
    float u = zw / pitch + c.b.x * .4 * sin(zw * .45 + c.t * 1.8), fu = fract(u), ridgeId = floor(u + .5);
    float dw = depthA * (fu < .5 ? 2.f : -2.f) / pitch;
    float lambert = clamp((s - dw) / sqrt((1 + dw * dw) * (1 + s * s)), 0.f, 1.f);
    float aa = fwidth(u);
    float ramp = clamp(fu * 2 - 1, 0.f, 1.f), facing = smoothstep(.46f, .54f, fu);
    float ridge = 1 - smoothstep(0.f, .04f + aa * 1.5f, abs(fu - round(fu)));
    float valley = exp(-boreSq((fu - .5) / .07));
    float2 e = abs(dir) * float2(.82, 1.18) / s;
    float crease = glow(e.x - e.y, .025 + aa * .2) * (.15 + c.b.z * 2.5) * facing;
    float around = atan2(dir.y * 1.18, dir.x * .82);
    float sparks = pow(.5f + .5f * cos(around * 24 + ridgeId * 1.7 - c.t * 2), 12.f) * ridge * c.b.w * 3;
    float h = boreAttack(c);
    float flash = c.hit * exp(-boreSq((zw - camZ - 1.5 - h * 10) / 1.3));
    float hue = .12 + .1 * sin(ridgeId * .45) + .06 * sin(around * 2);
    float3 face = mix(deep(hue + .1, f), paint(hue, f), ramp) * (.1 + .6 * ramp) * (.35 + .65 * lambert);
    float3 col = mix(deep(hue + .1, f) * .3, face, facing);
    float valleyId = floor(u);
    col += paint(.3, f) * valley * c.b.y * 2.5 * (.4 + .6 * boreSq(sin(valleyId * .9 - c.t * 1.5)));
    col += paint(.8, f) * ridge * (.45 + flash * 4) + paint(.7, f) * crease + paint(.95, f) * sparks;
    return mix(paint(.6, f) * .45, col, exp(-z * (.06 + c.fog * .04)));
}
NATIVE_EFFECT(bellowsPassage)

// ---------------------------------------------------------------- 305 Branching Bore
// A bore that forks every few lengths. The camera follows one branch, swinging left and
// right at alternate forks; the branch not taken glows hot as it peels away to the side.
// Junction rims light with their band, ribs and grooves take bass and low-mids, and attacks
// send a ring racing down the branch ahead.
float2 boreBranchMain(float z) {
    float k = floor(z / 6), u = z / 6 - k, s = u * u * (3 - 2 * u);
    return float2(1.4 * (boreWrap(k, 2) < .5 ? s : 1 - s), .5 * sin(z * .17));
}
float2 boreBranchSide(float z, float k) {
    float u = max(z / 6 - k, 0.f), grow = u < 1 ? u * u : 2 * u - 1;
    float away = boreWrap(k, 2) < .5 ? -1 : 1;
    return float2(1.4 * (away < 0 ? 0 : 1) + away * 1.5 * grow, .5 * sin(z * .17) + .45 * grow * (hash11(k) - .5));
}
// x = interior field of the union, y = taken branch, z = branch not taken, w = its fork id.
float4 boreBranchField(float3 p) {
    float k = floor(p.z / 6);
    float main = 1 - length(p.xy - boreBranchMain(p.z));
    float sideA = 1 - length(p.xy - boreBranchSide(p.z, k));
    float sideB = 1 - length(p.xy - boreBranchSide(p.z, k - 1)) - max(0.f, (k - 1) * 6 - p.z) * 3;
    float side = max(sideA, sideB), fork = sideA > sideB ? k : k - 1;
    return float4(smax(main, side, .25), main, side, fork);
}

float3 branchingBore(Ctx c, constant NativeFrame &f) {
    float camZ = c.travel * 1.6;
    float3 eye = float3(boreBranchMain(camZ), camZ), ahead = float3(boreBranchMain(camZ + 2.5), camZ + 2.5);
    float roll = .25 * sin(c.t * .06);
    float3 rd = cameraRay(c.uv, ahead - eye, float3(sin(roll), cos(roll), 0), 1.15);
    float t = .02;
    float4 g = 0;
    for (int i = 0; i < 60; ++i) {
        g = boreBranchField(eye + rd * t);
        if (g.x < .001 + t * .0015 || t > 40) break;
        t += g.x * .75;
    }
    float3 p = eye + rd * t;
    float takenSide = smoothstep(-.03f, .03f, g.y - g.z);
    float fork = g.w, uSide = p.z / 6 - fork;
    float2 q = p.xy - (takenSide > .5 ? boreBranchMain(p.z) : boreBranchSide(p.z, fork));
    float around = atan2(q.y, q.x);
    float rib = p.z * 1.7 / c.size, ribId = floor(rib + .5), eRib = abs(fract(rib + .5) - .5);
    float foot = t * c.px * 1.7 / c.size + .01;
    float ribs = (1 - smoothstep(.06f, .1f + foot, eRib)) * (.4 + c.b.x * 2.5 * boreSq(.5 + .5 * sin(ribId * .8 - c.t * 1.7)));
    float veins = glow(sin(around * 4 + 1.3 * sin(p.z * .7 + around * 2) + p.z * .3), .12) * (.16 + c.b.y * 1.8);
    float h = boreAttack(c);
    float ring = c.hit * exp(-boreSq((p.z - camZ - 3.2 - (1 - h) * 18) / .5)) * takenSide;
    // The branch not taken burns hotter the deeper it runs.
    float heat = (1 - takenSide) * smoothstep(-.1f, 1.4f, uSide);
    float3 wall = paint(.08 + .07 * sin(around * 3 + p.z * .4), f) * (.26 + .12 * cos(around - 1));
    wall += paint(.35 + heat * .3, f) * ribs * (.5 + heat) + paint(.55, f) * veins + paint(.92, f) * ring * 3;
    wall += paint(.4 + .15 * sin(p.z * .6), f) * heat * (.4 + c.b.w * 1.2 * boreTwinkle(hash11(fork + 7), c.t));
    float split = length(boreBranchMain(p.z) - boreBranchSide(p.z, fork));
    float rim = glow(g.y - g.z, .04) * smoothstep(.35f, 1.f, split) * smoothstep(2.2f, 1.f, uSide);
    wall += paint(.65 + .2 * sin(fork * 1.7), f) * rim * (.5 + boreBand(c, fork) * 4);
    return mix(paint(.45, f) * .4, wall / (1 + t * .04), exp(-t * (.045 + c.fog * .04)));
}
NATIVE_EFFECT(branchingBore)

// ---------------------------------------------------------------- 306 Skyward Shaft
// Looking up a square shaft while rising through it. Four walls of lit apertures converge on
// a bright square of sky. Each wall's windows pulse with their own band, floor slabs mark the
// storeys, and attacks drop rings of light down the shaft toward the viewer.
float3 skywardShaft(Ctx c, constant NativeFrame &f) {
    float roll = c.t * .035;
    float2 eye = float2(.38 * sin(c.t * .07), .3 * cos(c.t * .09));
    float3 rd = cameraRay(c.uv, float3(-eye * .25 + .06 * float2(sin(c.t * .11), cos(c.t * .13)), 1), float3(-sin(roll), cos(roll), 0), 1);
    float2 safe = float2(abs(rd.x) < 1e-5 ? 1e-5 : rd.x, abs(rd.y) < 1e-5 ? 1e-5 : rd.y);
    float2 lim = (sign(safe) - eye) / safe;
    bool xWall = lim.x < lim.y;
    float t = min(lim.x, lim.y);
    float2 hit = eye + rd.xy * t;
    float height = t * rd.z, top = 12;
    float wallId = xWall ? (rd.x > 0 ? 0 : 1) : (rd.y > 0 ? 2 : 3);
    float acrossW = xWall ? hit.y : hit.x;
    float zw = height + c.travel * 1.5;
    float foot = t * c.px;
    float2 cellSize = float2(.5, .62) * c.size;
    float2 g = float2(acrossW + 1, zw) / cellSize, cell = floor(g), local = (fract(g) - .5) * cellSize;
    float seed = hash31(float3(cell, wallId));
    float box = sdBox2(local, cellSize * float2(.3, .3));
    float window = 1 - smoothstep(-foot, foot, box);
    float frame = glow(box, .008 + foot);
    float band = c.b[int(wallId)];
    float lit = step(.4f, seed) * (.25 + .75 * boreSq(.5 + .5 * sin(c.t * .6 + seed * 9)));
    float pulse = band * boreSq(.5 + .5 * sin(cell.y * .7 - c.t * 2 + seed * 3));
    float slab = 1 - smoothstep(.03f, .05f + foot / cellSize.y, abs(fract(g.y / 5 + .1) - .1));
    float h = boreAttack(c);
    float ring = c.hit * exp(-boreSq((height - 1.2 - h * (top - 3)) / .6));
    float spill = exp(-(top - height) * .18);
    float3 wall = deep(.35 + wallId * .08, f) * (.1 + .6 * spill) + paint(.45, f) * frame * .35 + deep(.6, f) * window * .12;
    wall += paint(.6 + seed * .35, f) * window * (lit * (.6 + pulse * 3.5) + ring * 2);
    wall += paint(.8, f) * slab * (.4 + spill) + paint(.92, f) * ring * 1.5;
    float rimLine = glow(top - height, .05 + foot);
    // Sky beyond the opening.
    float2 skyPoint = eye + rd.xy * (top + 8) / max(rd.z, .05f);
    float cloud = fbm2(skyPoint * .35 + float2(c.t * .02, 0), 3);
    float3 sky = paint(.9, f) * 1.3 + paint(.6 + cloud * .3, f) * cloud * .9;
    float3 col = height > top ? sky : wall * exp(-height * c.fog * .03) + paint(.95, f) * rimLine * 1.5;
    return col;
}
NATIVE_EFFECT(skywardShaft)

// ---------------------------------------------------------------- 307 Veil Passage
// Flying through a stack of translucent liquid veils. Each veil has an organic hole and the
// camera threads them one after another along a weaving path. Bass ripples the veils and
// bends the holes, low-mids light their folds, high-mids widen the rim halos, highs shimmer
// the surfaces, and attacks flare the hole rims in a wave running away from the viewer.
float2 boreVeilPath(float id) { return float2(.42 * sin(id * .9) + .2 * sin(id * .37 + 1), .32 * cos(id * .7 + .5)); }

float3 veilPassage(Ctx c, constant NativeFrame &f) {
    const int count = 7;
    float advance = c.travel * .11;
    float2 camera = boreVeilPath(float(count) - advance * float(count));
    float3 col = deep(.6, f) * .2 + paint(.9, f) * .3 * exp(-length(c.uv) * 1.5);
    float h = boreAttack(c);
    for (int k = 0; k < count; ++k) {
        float2 s = layerSlot(k, count, advance);
        float sc = layerScale(s.x, 3.2) / c.size, fade = layerFade(s.x);
        float2 p = c.uv * sc - (boreVeilPath(s.y) - camera);
        float a = atan2(p.y, p.x), r = length(p);
        float radius = 1.05 + .16 * sin(3 * a + s.y * 1.7 + c.t * .25) + .09 * sin(5 * a - s.y + c.t * .4)
                     + .1 * c.b.x * sin(7 * a + c.t * 2 + s.y);
        float d = r - radius, aa = c.px * sc * 1.5;
        float sheet = smoothstep(-aa, aa, d);
        float ripple = c.b.x * sin(d * 9 - c.t * 2.5) * exp(-max(d, 0.f) * 1.2);
        float thick = s.y * .17 + .12 * sin(p.x * .9 + s.y + sin(p.y * 1.1 + c.t * .3)) + .1 * sin(r * 2 - c.t * .6) + ripple * .2;
        float sheen = pow(.5f + .5f * sin(a * 2 + r * 1.5 + s.y * 2.3 + c.t * .2), 3.f);
        float2 glint = p * 6 + s.y * 3.1; float glintSeed = hash21(floor(glint) + s.y * 17);
        float shimmer = step(.72f, glintSeed) * exp(-boreSq(length(fract(glint) - .5) * 5)) * c.b.w * 4 * boreTwinkle(glintSeed, c.t);
        float lightness = (.1 + .45 * exp(-max(d, 0.f) * 2)) * (.45 + .55 * s.x);
        float3 veil = filmColor(thick, f) * lightness * (1 + ripple * .7 + sheen * (.3 + c.b.y * 2)) + paint(.9, f) * shimmer * lightness;
        float flare = c.hit * exp(-boreSq((s.x - (1 - h * .85)) / .14));
        float rim = glow(d, .03 + .04 * c.b.z) * (.8 + flare * 4) + glow(d, .2) * .15;
        col = mix(col, veil, sheet * .6 * fade);
        col += paint(.75 + s.y * .1, f) * rim * fade;
    }
    return col;
}
NATIVE_EFFECT(veilPassage)

// ---------------------------------------------------------------- 308 Glass Pipeworks
// Flying through a three-dimensional lattice of glass pipes seen from outside. The glass shows
// as bright rims and luminous fluid pulses through the cores: pipes along the flight carry the
// bass, cross pipes the low-mids and the risers the high-mids; highs fizz bubbles and attacks
// push bright slugs of fluid through the network.
float boreLattice(float x) { return x - 4 * floor(x * .25 + .5); }

float3 glassPipeworks(Ctx c, constant NativeFrame &f) {
    float camZ = c.travel * 1.9;
    float3 eye = float3(2 + .45 * sin(camZ * .12), 2 + .35 * sin(camZ * .15 + 1.2), camZ);
    float yaw = .35 * sin(c.t * .05), pitch = .22 * sin(c.t * .043 + 1), roll = .3 * sin(c.t * .031);
    float3 rd = cameraRay(c.uv, float3(sin(yaw), sin(pitch), 1), float3(sin(roll), cos(roll), 0), 1.15);
    float h = boreAttack(c), slugShift = (1 - h) * 12;
    float3 fluid = 0;
    float glassLight = 0, transmit = 1, t = .1;
    // Sphere-trace between pipes; at each pipe, shade it analytically and pass straight through.
    for (int i = 0; i < 34; ++i) {
        float3 p = eye + rd * t;
        float2 cellZ = floor(p.xy * .25 + .5), cellX = floor(p.yz * .25 + .5), cellY = floor((p.xz - float2(0, 2)) * .25 + .5);
        // Low-discrepancy pipe seeds (plastic-number sequence): cheap and evenly spread.
        float3 seeds = fract(float3(dot(cellZ, float2(.7549, .5698)) + .13, dot(cellX, float2(.5698, .7549)) + .41, dot(cellY, float2(.6180, .3820)) + .77));
        float2 offset = .7 * (float2(seeds.x, fract(seeds.x * 7.13)) - .5);
        float3 lattice = float3(boreLattice(p.x), boreLattice(p.y), boreLattice(p.z));
        float lz2 = boreLattice(p.z - 2);
        float2 qz = lattice.xy - offset, qx = lattice.yz, qy = float2(lattice.x, lz2);
        float3 radius = (.2 + .14 * seeds) * step(.38f, seeds);
        float3 gap = select(float3(9), float3(length(qz), length(qx), length(qy)) - radius, radius > 0);
        float d = min(gap.x, min(gap.y, gap.z));
        // Pipes in neighbouring cells sit at least this far beyond the cell walls.
        float3 wall = 2 - float3(max(abs(lattice.x), abs(lattice.y)), max(abs(lattice.y), abs(lattice.z)), max(abs(lattice.x), abs(lz2)));
        float reach = min(d, min(wall.x, min(wall.y, wall.z)) + 1.25);
        if (d < .1) {
            int k = gap.x <= d ? 0 : (gap.y <= d ? 1 : 2);
            float2 q = k == 0 ? qz : (k == 1 ? qx : qy);
            float2 v = k == 0 ? rd.xy : (k == 1 ? rd.yz : rd.xz);
            float vv = max(dot(v, v), 1e-4f), r = radius[k];
            float mid = -dot(q, v) / vv, miss = max(dot(q, q) - mid * mid * vv, 0.f);
            // A near miss skips past the pipe's closest approach instead of crawling along it.
            if (miss >= r * r || mid < 0) { t += min(max(mid, d), min(.8f, max(reach, .05f))) + .02; continue; }
            float exitAt = mid + sqrt(max(r * r - miss, 0.f) / vv);
            float coreR = r * .62, chord = 2 * sqrt(max(coreR * coreR - miss, 0.f) / vv);
            float3 pm = p + rd * max(mid, 0.f);
            float along = k == 0 ? pm.z : (k == 1 ? pm.x : pm.y), flow = k == 0 || seeds[k] > .6 ? 1 : -1;
            float wave = .5 + .5 * sin(along * 1.3 * flow - c.t * 2.2 + seeds[k] * 20);
            float pulse = wave * wave; pulse *= pulse * wave;
            float fizz = .5 + .5 * sin(along * 9 + seeds[k] * 40 - c.t * 5);
            fizz *= fizz; fizz *= fizz; fizz *= fizz;
            float level = .25 + pulse * (.4 + c.b[k] * 3.5) + fizz * fizz * c.b.w * 3;
            if (c.hit > .01) {
                float x = along * flow - seeds[k] * 20 - slugShift;
                x -= 20 * floor(x / 20 + .5);
                level += c.hit * exp(-x * x * 2) * 6;
            }
            float fade = exp(-t * (.07 + c.fog * .05)) * transmit;
            float lit = min(chord, 1.2f) * 2.2 + exp(-miss / (coreR * coreR)) * .35;
            fluid[k] += lit * level * fade;
            float edge = sqrt(miss) / r;
            edge *= edge; edge *= edge;
            glassLight += (edge * edge * 1.1 + .07) * fade;
            transmit *= .8;
            t += max(exitAt, 0.f) + .03;
            if (transmit < .25) break;
        } else {
            t += max(reach, .02f) * .9;
        }
        if (t > 30) break;
    }
    float3 back = deep(.4 + .1 * rd.y, f) * .14 + paint(.55, f) * .05 * (1 + rd.y);
    return back + paint(.3, f) * fluid.x * 1.2 + paint(.52, f) * fluid.y + paint(.72, f) * fluid.z + paint(.9, f) * glassLight * .85;
}
NATIVE_EFFECT(glassPipeworks)

// ---------------------------------------------------------------- 309 Möbius Ride
// Riding just above a wide ribbon of light that winds ahead and twists half a turn every
// stretch. The camera banks with the ribbon, so the sky rolls while the ribbon stays under
// you and flips over in the distance. Edge lights pulse with their bands, highs twinkle the
// sky and attacks fire chevrons racing away along the ribbon.
float2 boreRibbonPath(float z) { return float2(2.6 * sin(z * .12) + .9 * sin(z * .29 + 1), 1.4 * sin(z * .15 + 2) + .5 * sin(z * .33)); }
float boreRibbonTwist(float z) { return z * PI / 9 + .4 * sin(z * .2); }
float boreRibbonField(float3 p, thread float2 &local) {
    local = rot(p.xy - boreRibbonPath(p.z), -boreRibbonTwist(p.z));
    return sdBox2(local, float2(.9, .02)) - .01;
}

float3 mobiusRide(Ctx c, constant NativeFrame &f) {
    float camZ = c.travel * 1.6;
    float tw = boreRibbonTwist(camZ);
    float2 normal = float2(-sin(tw), cos(tw));
    float3 eye = float3(boreRibbonPath(camZ) + normal * .95, camZ);
    float3 target = float3(boreRibbonPath(camZ + 5), camZ + 5);
    float3 rd = cameraRay(c.uv, target - eye, float3(normal, 0), 1.1);
    float t = .05, d = 1, nearest = 9;
    float2 local = 0;
    for (int i = 0; i < 64; ++i) {
        d = boreRibbonField(eye + rd * t, local);
        nearest = min(nearest, d / (1 + t * .08));
        if (d < .0015 + t * .0015 || t > 45) break;
        t += d * .6;
    }
    // Sky: a soft nebula, stars that twinkle with the highs and the ribbon's own aura.
    float az = atan2(rd.x, rd.z), el = asin(clamp(rd.y, -1.f, 1.f));
    float n = fbm2(float2(az * 2.5, el * 2.5) + c.t * .01, 4);
    float2 starCell = floor(float2(az, el) * 60);
    float starSeed = hash21(starCell);
    float star = step(.9f, starSeed) * exp(-boreSq(length(fract(float2(az, el) * 60) - .5) * 5)) * (.4 + c.b.w * 4 * boreTwinkle(starSeed, c.t));
    float3 sky = paint(.15 + n * .5, f) * (.08 + .7 * n * n) + paint(.85, f) * star;
    sky += paint(.7, f) * glow(nearest, .12) * (.35 + c.b.x * .8);
    if (t > 45 || d > .05) return sky;
    float3 p = eye + rd * t;
    float zw = p.z, xs = local.x;
    bool under = local.y < 0;
    float foot = t * c.px / 1.1 + .005;
    // Chevron rungs roll with the bass; three lanes carry the low-mids.
    float rung = zw * .9 - abs(xs) * .45 - c.t * .5, rungId = floor(rung + .5);
    float rungs = (1 - smoothstep(.05f, .08f + foot, abs(rung - rungId))) * (.25 + c.b.x * 2.2 * boreSq(.5 + .5 * sin(rungId * .7 - c.t * 2)));
    float lanes = glow(min(abs(xs), abs(abs(xs) - .45)), .02 + foot) * (.25 + c.b.y * 2);
    // Lamps along both edges, each lamp on its own band.
    float lampRun = zw / .8 - c.t * .35, seg = floor(lampRun + .5), sideId = xs > 0 ? 2 : 0;
    float rail = glow(.9 - abs(xs), .07 + foot);
    float lamp = rail * pow(.5f + .5f * cos(fract(lampRun) * TAU), 4.f);
    float band = boreBand(c, seg + sideId);
    float h = boreAttack(c);
    float chev = zw - abs(xs) * .7 - camZ - 3 - (1 - h) * 24;
    float chevrons = c.hit * pow(.5f + .5f * cos(chev * TAU / 1.2), 8.f) * exp(-boreSq(chev / 2.4));
    float hue = (under ? .35 : .62) + xs * .1 + zw * .012;
    float sheen = .5 + .5 * cos(xs * 2.2 + zw * .3);
    float3 surface = mix(deep(hue + .3, f), paint(hue, f), .3 + .4 * sheen) * (under ? .14 : .22);
    surface += paint(hue + .2, f) * (lanes + rungs) + paint(.88, f) * (rail * .3 + lamp * (.8 + band * 4)) + paint(.95, f) * chevrons * 3;
    return mix(sky, surface, exp(-t * (.03 + c.fog * .03)));
}
NATIVE_EFFECT(mobiusRide)

// Coaster versions: the same designs riding the roller-coaster course.
NATIVE_COASTER(ringworldDrift, 301, false)
NATIVE_COASTER(twinBore, 302, false)
NATIVE_COASTER(coilRun, 303, false)
NATIVE_COASTER(bellowsPassage, 304, false)
NATIVE_COASTER(branchingBore, 305, false)
NATIVE_COASTER(skywardShaft, 306, false)
NATIVE_COASTER(veilPassage, 307, false)
