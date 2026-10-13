// Original PulseCanvas designs 330–339. Flights that are not roads: canopies, strata,
// pillar forests, parallax silhouettes, river deltas, auroras, waterfalls, orbits, comets
// and cloud seas. Every scene is analytic (plane, sphere and layer intersections); no
// preset formulas, textures or third-party shader sources are used.

// A point light inside a hashed grid cell. It fades to exactly zero before the cell
// border, so neighbouring cells never show seams.
float flight_spark(float d, float width, float reach) { return glow(d, width) * smoothstep(reach, reach * .4f, d); }

// ---------------------------------------------------------------- 330 Canopy Flight
// Rows of hanging crystals are evaluated analytically at their own depth. The floor is a
// dark mirror: the same rows are reused with world height reflected, and each crystal
// shows there as a soft vertical smear of its light. Bass sways the pendants, each
// crystal follows one band, and attacks run a ripple of light along the rows.

constant float CANOPY_CEIL = 1.f;
constant float CANOPY_FLOOR = -.85f;
constant float CANOPY_ROW = 1.15f;
constant float CANOPY_COL = .95f;

float canopy_rhombus(float2 q, float2 r) {
    q = abs(q);
    return (q.x * r.y + q.y * r.x - r.x * r.y) / length(r);
}

struct CanopyPendant { float2 anchor; float wire; float2 size; float sway; float energy; float3 tone; };

CanopyPendant canopy_make(float rowId, float cell, float stagger, Ctx c, constant NativeFrame &f) {
    CanopyPendant k;
    float3 h = hash33(float3(rowId, cell, 3.1));
    k.anchor = float2((cell + stagger + (h.x - .5f) * .3f) * CANOPY_COL, CANOPY_CEIL);
    k.wire = .05f + .38f * h.y;
    k.size = float2(.06f + .05f * h.z, .13f + .14f * hash21(float2(cell, rowId + .5f)));
    k.sway = (.07f + .34f * c.b.x) * sin(c.t * 1.05f + h.x * 6.28f + rowId * .4f) + .025f * sin(c.t * 2.3f + h.y * 9);
    float band = c.b[int(h.z * 3.99f)];
    float ripple = c.hit * pow(.5f + .5f * sin(rowId * .75f + cell * .45f - c.t * 2.4f), 6.f) * 3.2f;
    k.energy = .5f + 1.9f * band + ripple;
    k.tone = paint(h.x * .5f + rowId * .06f + cell * .11f, f);
    return k;
}

float3 canopy_pendant(float2 w, CanopyPendant k, float pw, Ctx c, constant NativeFrame &f) {
    float2 q = rot(w - k.anchor, -k.sway);
    float2 local = q - float2(0, -k.wire - k.size.y);
    float body = canopy_rhombus(local, k.size);
    float facet = local.x > 0 ? .45f : 1.f;
    float ridge = glow(local.x, pw * 1.5f + .004f) * .8f + glow(local.y, pw * 1.5f + .004f) * .5f;
    float core = exp(-dot(local / k.size, local / k.size) * 2.5f);
    float inside = fill(body, pw);
    float3 col = k.tone * inside * (facet * (.3f + .35f * (1 - abs(local.y) / k.size.y)) + ridge + core * .6f) * k.energy;
    col += k.tone * glow(body, .01f + pw) * .9f * k.energy;
    col += k.tone * glow(body, .09f) * .07f * k.energy;
    float wireD = sdSegment(q, float2(0), float2(0, -k.wire));
    col += k.tone * glow(wireD, pw + .003f) * .3f;
    float tip = length(q - float2(0, -k.wire - 2 * k.size.y));
    col += paint(.92f, f) * glow(tip, .008f + pw) * (.35f + 3 * c.b.w);
    return col;
}

// A crystal seen in the dark mirror: a soft vertical smear of its light.
float3 canopy_reflection(float2 w, CanopyPendant k) {
    float2 center = k.anchor + rot(float2(0, -k.wire - k.size.y), k.sway);
    float2 d = w - center;
    float spread = k.size.x * (1.4f + .5f * abs(d.y));
    float streak = exp(-d.x * d.x / (spread * spread)) * exp(-abs(d.y) * 1.1f) * smoothstep(CANOPY_FLOOR, CANOPY_FLOOR + .6f, w.y) * smoothstep(3.4f, 2.4f, w.y);
    return k.tone * streak * k.energy * .4f;
}

float3 canopy_ceiling(float2 w, float dz, Ctx c, constant NativeFrame &f) {
    float3 col = paint(.3f + .1f * sin(w.x * .4f + w.y * .2f), f) * .055f;
    float row0 = floor(w.y / CANOPY_ROW);
    for (int r = 0; r < 2; ++r) {
        float rowId = row0 + float(r);
        float stagger = hash11(rowId + .37f);
        float cellF = w.x / CANOPY_COL - stagger;
        float cell = floor(cellF + .5f);
        float other = cell + (cellF > cell ? 1 : -1);
        for (int m = 0; m < 2; ++m) {
            CanopyPendant k = canopy_make(rowId, m == 0 ? cell : other, stagger, c, f);
            float2 d = w - float2(k.anchor.x, rowId * CANOPY_ROW);
            float r2 = dot(d, d);
            col += k.tone * (exp(-r2 * 30) * .25f + glow(sqrt(r2), .02f) * .2f) * k.energy;
        }
    }
    return col * exp(-dz * (.05f + .1f * c.fog));
}

float3 canopyFlight(Ctx c, constant NativeFrame &f) {
    const float lens = 1.3f;
    const int rows = 12;
    float2 p = rot(c.uv, .06f * sin(c.travel * .05f + .8f)) / c.size;
    float camZ = c.travel * 2.4f;
    float camX = 1.1f * sin(c.travel * .06f) + .2f * sin(c.t * .04f);
    float ay = max(abs(p.y), .015f);
    float3 col;
    if (p.y > 0) {
        float dz = CANOPY_CEIL * lens / ay;
        col = canopy_ceiling(float2(p.x * dz / lens + camX, dz + camZ), dz, c, f);
    } else {
        float dzFloor = -CANOPY_FLOOR * lens / ay;
        float2 fw = float2(p.x * dzFloor / lens + camX, dzFloor + camZ);
        float wobble = .025f * sin(fw.y * 3.1f + sin(fw.x * 2.3f) + c.t * .9f);
        float dz = (CANOPY_CEIL - 2 * CANOPY_FLOOR) * lens / ay;
        col = canopy_ceiling(float2(p.x * dz / lens + camX + wobble * dz, dz + camZ), dz, c, f) * .35f;
        col += deep(.65f, f) * .05f * (.6f + .4f * noise2(fw * 2));
    }
    col += paint(.55f, f) * exp(-ay * 7.f) * .12f + paint(.8f, f) * glow(ay, .015f) * .08f;
    float base = floor(camZ / CANOPY_ROW);
    for (int j = rows; j >= 1; --j) {
        float rowId = base + float(j);
        float dz = rowId * CANOPY_ROW - camZ;
        float fade = smoothstep(float(rows) * CANOPY_ROW, float(rows - 5) * CANOPY_ROW, dz) * smoothstep(.25f, .9f, dz)
                   * exp(-dz * (.1f + .1f * c.fog));
        float scale = dz / lens;
        float2 w = float2(p.x * scale + camX, p.y * scale);
        bool mirrored = w.y < CANOPY_FLOOR;
        if (mirrored) {
            w.y = 2 * CANOPY_FLOOR - w.y;
            w.x += .05f * sin(w.y * 3 + rowId + c.t * 1.3f) * (1 - w.y);
        }
        if (mirrored ? w.y > 3.5f : (w.y < -.05f || w.y > CANOPY_CEIL + .1f)) continue;
        float stagger = hash11(rowId + .37f);
        float cellF = w.x / CANOPY_COL - stagger;
        float cell = floor(cellF + .5f);
        float other = cell + (cellF > cell ? 1 : -1);
        CanopyPendant a = canopy_make(rowId, cell, stagger, c, f);
        CanopyPendant b = canopy_make(rowId, other, stagger, c, f);
        float3 light;
        if (mirrored) light = canopy_reflection(w, a) + canopy_reflection(w, b);
        else {
            float pw = c.px * scale * 1.2f;
            light = canopy_pendant(w, a, pw, c, f) + canopy_pendant(w, b, pw, c, f);
        }
        col += light * fade;
    }
    return col;
}
NATIVE_EFFECT(canopyFlight)

// ---------------------------------------------------------------- 331 Strata Glide
// A thin gap between two vast planes. Each plane carries its own flowing strata: broad
// warm layers below, finer cross-cut layers above. Seams between layers glow.

float3 strata_plane(float2 w, float dz, bool upper, Ctx c, constant NativeFrame &f) {
    float s;
    if (upper) {
        s = (w.y - w.x) * .26f + 1.6f * fbm2(float2(w.x * .16f + c.t * .03f, w.y * .1f), 3) + c.t * .035f;
        s += c.b.z * .5f * sin(w.x * .55f - w.y * .3f + c.t * .5f);
        s *= 5.f;
    } else {
        s = (w.x + w.y) * .24f + 1.8f * fbm2(float2(w.x * .12f, w.y * .08f - c.t * .04f), 3) - c.t * .042f;
        s += c.b.y * .6f * sin(w.x * .5f + w.y * .3f + c.t * .45f);
        s *= 3.6f;
    }
    s += .3f * sin(s * 1.3f);
    float idx = floor(s), fr = fract(s);
    float aa = fwidth(s);
    float detail = 1 - smoothstep(.15f, .6f, aa);
    float seamD = min(fr, 1 - fr);
    float seam = (1 - smoothstep(0.f, .03f + aa * 1.5f, seamD)) * detail;
    float wide = exp(-seamD * 10);
    float phase = .12f + .6f * fract(idx * .23f + (upper ? .5f : 0.f));
    float grain = .75f + .25f * sin(fr * 23 + idx);
    float layer = mix(.11f, (.04f + .2f * fr * fr) * grain, detail);
    float3 col = paint(phase, f) * layer * (upper ? .6f + 1.6f * c.b.z : .7f + 1.5f * c.b.y);
    float hitSeam = (idx - 3 * floor(idx / 3)) == 0 ? 1.f : .2f;
    float run = pow(.5f + .5f * cos(dz * .5f - c.t * 4.f + idx * .3f), 4.f);
    col += paint(.88f + idx * .05f, f) * (seam * .9f + wide * .22f * detail) * (1 + c.hit * hitSeam * run * 5);
    float glint = pow(noise2(w * float2(3.f, 1.5f) + c.t * .3f), 10.f);
    col += paint(.95f, f) * glint * wide * c.b.w * 14 * detail * smoothstep(1.f, 2.5f, dz);
    return col;
}

float3 strataGlide(Ctx c, constant NativeFrame &f) {
    const float lens = 1.25f;
    float2 p = c.uv;
    float camZ = c.travel * 1.9f;
    float camX = .8f * sin(c.travel * .05f);
    float gap = .42f * (1 + .5f * c.b.x) * c.size;
    bool upper = p.y > 0;
    float ay = max(abs(p.y), .004f);
    float dz = gap * lens / ay;
    float2 w = float2(p.x * dz / lens + camX, dz + camZ);
    float3 col = strata_plane(w, dz, upper, c, f);
    float3 haze = mix(paint(.62f, f), paint(.8f, f), .5f + .5f * sin(p.x * .7f + c.t * .1f)) * .16f;
    col = mix(haze, col, exp(-dz * (.03f + .06f * c.fog)));
    col += paint(.85f, f) * (exp(-ay * 16) * .3f + glow(ay, .008f) * .35f);
    return col;
}
NATIVE_EFFECT(strataGlide)

// ---------------------------------------------------------------- 332 Pillar Forest
// The camera weaves along a clear path through an endless grid of luminous columns and
// looks slightly up, so the columns converge overhead. A 2D grid walk finds them front to
// back; height along each column comes from the ray. Each column follows one band and
// attacks send bright rings racing up the columns.

float pillar_path(float z) { return 1.3f * sin(z * .23f) + .55f * sin(z * .51f + 1.3f); }
float pillar_slope(float z) { return 1.3f * .23f * cos(z * .23f) + .55f * .51f * cos(z * .51f + 1.3f); }

float3 pillarForest(Ctx c, constant NativeFrame &f) {
    const float lens = 1.15f;
    float camZ = c.travel * 1.4f;
    float slope = pillar_slope(camZ);
    float2 p = rot(c.uv, -slope * .12f) / c.size;
    float yaw = atan(slope) * .75f;
    float camY = .3f * sin(c.t * .11f);
    float2 ro = float2(pillar_path(camZ), camZ);
    float pitch = .3f + .12f * sin(c.t * .07f);
    float up = p.y * cos(pitch) + lens * sin(pitch);
    float2 flat = rot(float2(p.x, lens * cos(pitch) - p.y * sin(pitch)), -yaw);
    float flatLength = max(length(flat), 1e-3f);
    float2 rd = flat / flatLength;
    rd = float2(abs(rd.x) < 1e-4f ? 1e-4f : rd.x, abs(rd.y) < 1e-4f ? 1e-4f : rd.y);
    float rise = up / flatLength;
    float elevation = atan2(up, flatLength);
    float fogK = .26f + .3f * c.fog;
    float3 fogColor = deep(.55f, f) * .05f + paint(.5f, f) * exp(-elevation * elevation * 9) * .12f + paint(.72f, f) * smoothstep(.4f, 1.4f, elevation) * .2f;
    float3 col = 0;
    float trans = 1;
    float2 cell = floor(ro);
    float2 stepDir = float2(rd.x > 0 ? 1 : -1, rd.y > 0 ? 1 : -1);
    float2 tDelta = abs(1 / rd);
    float2 tMax = (cell + max(stepDir, 0.f) - ro) / rd;
    for (int i = 0; i < 16; ++i) {
        float3 h = hash33(float3(cell, 3.7));
        float2 center = cell + .5f + (h.xy - .5f) * .2f;
        bool present = h.z > .55f && abs(center.x - pillar_path(center.y)) > .8f;
        if (present) {
            float r = .06f + .14f * fract(h.x * 7.31f);
            float2 o = ro - center;
            float s0 = -dot(o, rd);
            float side = o.x * rd.y - o.y * rd.x;
            float dPerp = abs(side);
            if (s0 > 0) {
                float aa = c.px * s0 / lens * 1.3f + .002f;
                float cover = smoothstep(r + aa, r - aa, dPerp);
                float u = clamp(side / r, -1.f, 1.f);
                float sHit = s0 - sqrt(max(r * r - dPerp * dPerp, 0.f));
                float y = camY + sHit * rise;
                float ndv = sqrt(max(1 - u * u, 0.f));
                float band = c.b[int(fract(h.z * 13.7f) * 3.99f)];
                float energy = .6f + 2.f * band;
                float rings = pow(.5f + .5f * cos((y * .55f - c.t * .5f + h.x * 5) * TAU), 18.f);
                float surge = pow(.5f + .5f * cos((y * .2f - c.t * 1.3f + h.y * 3) * TAU), 24.f);
                float3 tone = paint(.3f + h.x * .5f + y * .03f, f);
                float segment = .75f + .25f * sin(y * 1.7f + h.y * 9 + c.t * .3f);
                float3 pc = tone * (.22f + .3f * ndv) * energy * segment;
                pc += paint(.95f, f) * pow(ndv, 6.f) * .3f * energy;
                pc += paint(.92f + h.y * .08f, f) * (rings * (.5f + 2.5f * c.hit) + surge * c.hit * 4);
                float fog = exp(-sHit * fogK);
                col += trans * cover * mix(fogColor, pc, fog);
                col += trans * (1 - cover) * tone * (glow(dPerp - r, .04f + .04f * band) * .4f + glow(dPerp - r, .25f) * .06f) * energy * fog;
                trans *= 1 - cover;
            }
        }
        if (trans < .02f) break;
        if (tMax.x < tMax.y) { cell.x += stepDir.x; tMax.x += tDelta.x; }
        else { cell.y += stepDir.y; tMax.y += tDelta.y; }
    }
    return col + trans * fogColor;
}
NATIVE_EFFECT(pillarForest)

// ---------------------------------------------------------------- 333 Parallax Express
// A sideways window view: a far ridge, crystal spires, neon arches and near light bars
// slide laterally at increasing speeds. Each layer has its own band; attacks flare the
// near layer.

struct ExpressSpire { float height; float ridge; float id; };

ExpressSpire express_spires(float x, float width, float seed, float lift) {
    ExpressSpire s; s.height = -9; s.ridge = 9; s.id = 0;
    float cell = floor(x / width);
    for (int k = -1; k <= 1; ++k) {
        float id = cell + float(k);
        float3 h = hash33(float3(id, seed, 2.7));
        float apex = (id + .2f + .6f * h.x) * width;
        float tall = (.3f + .7f * h.y) * lift;
        float y = tall - abs(x - apex) * (2.4f + 2.6f * h.z);
        if (y > s.height) { s.height = y; s.ridge = x - apex; s.id = id; }
    }
    return s;
}

float express_hills(float x, float seed) {
    return .55f * noise2(float2(x * .45f, seed)) + .3f * noise2(float2(x * 1.2f, seed + 4)) + .15f * noise2(float2(x * 3.1f, seed + 9));
}

float3 parallaxExpress(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float span = c.extent.y / c.size;
    float y = p.y / span;
    float x = p.x;
    float run = c.travel * 1.1f;
    float px = c.px / span * 1.5f;
    // Sky: deep gradient with slow glowing ribbons and faint stars.
    float drift = noise2(float2(x * .35f - run * .04f, y * 2.5f));
    float3 col = mix(paint(.3f, f) * .3f, deep(.75f, f) * .07f, smoothstep(-.1f, 1.f, y));
    col += paint(.55f + y * .2f, f) * pow(.5f + .5f * sin(y * 9 + drift * 4 + c.t * .1f), 10.f) * .22f * smoothstep(0.f, .4f, y);
    float2 star = float2(x * 18 - run * .4f, y * 18);
    float2 sid = floor(star);
    float sh = hash21(sid);
    col += paint(.9f, f) * flight_spark(length(fract(star) - .5f - (hash22(sid) - .5f) * .6f), .04f, .2f) * step(.88f, sh) * (.3f + 2 * c.b.w * sh) * smoothstep(.1f, .5f, y);
    // Far ridge (bass).
    float xa = x * .8f + run * .12f;
    float ha = .05f + .4f * express_hills(xa, 1.3f) + .07f * c.b.x * sin(xa * 2.3f + c.t * .4f);
    float da = y - ha;
    col = mix(col, deep(.25f, f) * .12f + paint(.25f, f) * .18f * exp(da * 7), smoothstep(px, -px, da));
    col += paint(.22f + xa * .03f, f) * glow(da, .01f) * (.45f + 2.f * c.b.x);
    // Crystal spires (low-mid).
    float xb = x + run * .38f;
    ExpressSpire sp = express_spires(xb, .3f, 3, .8f + .4f * c.b.y);
    float hb = -.4f + sp.height;
    float db = y - hb;
    float3 sh3 = hash33(float3(sp.id, 5, 1));
    float3 spireTone = paint(.4f + sh3.x * .4f, f);
    float facet = sp.ridge > 0 ? .35f : 1.f;
    float3 spireFill = deep(.4f, f) * .06f + spireTone * (.03f + .16f * facet * exp(db * 4.f));
    spireFill += spireTone * glow(sp.ridge, .005f) * .5f * smoothstep(.0f, -.4f, db) * (.4f + 1.6f * c.b.y);
    col = mix(col, spireFill, smoothstep(px, -px, db));
    col += spireTone * glow(db, .007f) * (.6f + 2.f * c.b.y);
    // Neon arches (high-mid): outlines with a faint veil inside.
    float xc = x + run * .85f;
    float period = .9f;
    float u = (fract(xc / period) - .5f) * period;
    float aid = floor(xc / period);
    float radius = .27f + .08f * hash11(aid);
    float base = -.64f;
    float dome = length(float2(u, y - base)) - radius;
    float3 archTone = paint(.7f + hash11(aid + 3) * .25f, f);
    float above = step(base, y);
    col = mix(col, deep(.75f, f) * .05f, smoothstep(px, -px, y - base));
    col = mix(col, col * .55f + archTone * .05f, smoothstep(px, -px, dome) * above);
    col += archTone * glow(dome, .008f) * (.6f + 2.2f * c.b.z) * above;
    col += archTone * glow(dome + .06f, .005f) * (.25f + 1.4f * c.b.z) * above;
    col += archTone * glow(y - base, .008f) * .6f;
    // Near light bars streaking past, with a low ground edge (attacks flare them).
    float xd = x + run * 2.6f;
    float pid = floor(xd / 1.4f);
    float pu = (fract(xd / 1.4f) - .5f) * 1.4f;
    float ground = -.84f + .025f * sin(xd * 2.1f);
    float dg = y - ground;
    float flash = 1 + 4 * c.hit;
    float3 nearTone = paint(.15f + hash11(pid + 7) * .35f, f);
    float bar = glow(pu, .03f + .02f * hash11(pid)) * smoothstep(.95f, .2f, y);
    col += nearTone * bar * .35f * flash;
    float3 groundTone = paint(.2f + .15f * sin(xd * .7f), f);
    col = mix(col, deep(.15f, f) * .1f + groundTone * .14f * exp(dg * 5), smoothstep(px, -px, dg));
    col += groundTone * glow(dg, .01f) * .8f * flash;
    float streaks = pow(.5f + .5f * sin(y * 70 + hash11(floor(y * 11)) * 6), 20.f) * smoothstep(.0f, -.12f, dg);
    col += paint(.6f + hash11(floor(y * 11)) * .35f, f) * streaks * (.3f + 1.2f * c.b.w) * (.6f + .4f * sin(xd * 3 + y * 40)) * flash;
    return col;
}
NATIVE_EFFECT(parallaxExpress)

// ---------------------------------------------------------------- 334 Delta Flyover
// Looking straight down on a delta of light. Meandering trunks run downstream; each
// spawns distributaries that peel off, diverge and taper out, and twigs peel off those.
// Every channel has a world-space id, so the scroll never pops. Trunks, distributaries
// and twigs each follow one band; attacks send surges down the channels.

constant float DELTA_TRUNK = 2.3f;
constant float DELTA_CELL = 1.5f;

float delta_trunk(float i, float y) {
    float h = hash11(i + .71f);
    return (i + .5f) * DELTA_TRUNK + DELTA_TRUNK * (.26f * sin(y * .21f + h * 6.3f) + .12f * sin(y * .53f + h * 17));
}

float3 deltaFlyover(Ctx c, constant NativeFrame &f) {
    float zoom = exp2(.22f * sin(c.t * .031f));
    float2 p = rot(c.uv / c.size, .25f * sin(c.t * .023f)) * 2.2f * zoom;
    float2 w = p + float2(1.5f * sin(c.travel * .03f), c.travel * 1.4f);
    float px = c.px / c.size * 2.2f * zoom;
    float terrain = fbm2(w * float2(.8f, .45f), 3);
    float3 col = deep(.3f + terrain * .3f, f) * (.025f + .07f * terrain);
    float lagoon = fbm2(w * float2(.35f, .2f) + 11, 3);
    col += paint(.35f + lagoon * .3f, f) * smoothstep(.5f, .68f, lagoon) * .07f;
    col += paint(.55f, f) * glow(lagoon - .5f, .012f) * .06f;
    float surge = c.hit * 4;
    float trunkLight = 0, branchLight = 0, twigLight = 0, wet = 0;
    float i0 = floor(w.x / DELTA_TRUNK), j0 = floor(w.y / DELTA_CELL);
    for (int k = -1; k <= 1; ++k) {
        float i = i0 + float(k);
        float trunkX = delta_trunk(i, w.y);
        float trunkD = abs(w.x - trunkX);
        float pulse = pow(.5f + .5f * sin(w.y * 1.2f + c.t * 3 + i * 2.1f), 10.f);
        float flow = .7f + .3f * sin(w.y * 6 + c.t * 2.4f + i);
        trunkLight += (smoothstep(.085f + px, .085f - px, trunkD) * flow * .9f + glow(trunkD, .2f) * .45f) * (1 + surge * pulse);
        wet += exp(-trunkD * 1.5f);
        for (int m = 0; m < 4; ++m) {
            float j = j0 + float(m);
            float3 h = hash33(float3(i, j, 4.4));
            if (h.x < .3f) continue;
            float start = (j + .3f + .4f * h.y) * DELTA_CELL;
            float len = DELTA_CELL * (1.6f + 1.4f * h.z);
            float t = (start - w.y) / len;
            if (t < 0 || t > 1) continue;
            float side = h.x > .65f ? 1.f : -1.f;
            float spread = DELTA_TRUNK * (.25f + .3f * h.y) * pow(smoothstep(0.f, 1.f, t), .7f);
            float branchX = trunkX + side * spread + .08f * sin(w.y * 2.3f + h.z * 9) * t;
            float d = abs(w.x - branchX);
            float taper = (1 - t) * smoothstep(0.f, .08f, t);
            float width = .02f + .035f * (1 - t);
            float bpulse = pow(.5f + .5f * sin(w.y * 1.6f + c.t * 3.4f + j * 3.3f + i), 10.f);
            branchLight += (smoothstep(width + px, width - px, d) + glow(d, width * 3) * .45f) * taper * (1 + surge * bpulse);
            wet += exp(-d * 2.5f) * taper;
            // Twigs peel off the branch in short sub-cells.
            float sub = DELTA_CELL * .4f;
            float k0 = floor(w.y / sub);
            for (int q = 0; q < 3; ++q) {
                float kk = k0 + float(q);
                float3 g = hash33(float3(i * 7 + j, kk, 9.1));
                float tStart = (kk + .5f) * sub;
                float tLen = sub * (1.2f + g.z);
                float u = (tStart - w.y) / tLen;
                float parentT = (start - tStart) / len;
                if (g.x < .35f || u < 0 || u > 1 || parentT < .03f || parentT > .9f) continue;
                float tSide = g.y > .5f ? 1.f : -1.f;
                float twigX = branchX + tSide * (.18f + .2f * g.z) * pow(u, .7f);
                float td = abs(w.x - twigX);
                float tTaper = (1 - u) * smoothstep(0.f, .1f, u) * smoothstep(.03f, .15f, parentT) * smoothstep(.9f, .6f, parentT);
                twigLight += (smoothstep(.012f + px, .006f, td) + glow(td, .03f) * .35f) * tTaper;
            }
        }
    }
    col += paint(.92f, f) * trunkLight * (.45f + 1.8f * c.b.x);
    col += paint(.66f, f) * branchLight * (.45f + 1.9f * c.b.y);
    col += paint(.45f, f) * twigLight * (.35f + 2.f * c.b.z);
    col += deep(.6f, f) * min(wet, 1.5f) * .05f;
    float2 sparkleCell = floor(w * 7);
    float3 sh = hash33(float3(sparkleCell, 2.9));
    float sparkle = flight_spark(length(w * 7 - sparkleCell - .2f - sh.xy * .6f), .07f, .2f) * step(.75f, sh.z) * (.5f + .5f * sin(c.t * 4 + sh.x * 30));
    col += paint(.97f, f) * sparkle * min(trunkLight + branchLight, 1.f) * (.2f + 4 * c.b.w);
    return col;
}
NATIVE_EFFECT(deltaFlyover)

// ---------------------------------------------------------------- 335 Aurora Overpass
// Curtains hang across the sky at stable depths; each folds along its length, and folds
// seen edge-on glow brighter. The dark plain mirrors the same curtains.

float3 auroraOverpass(Ctx c, constant NativeFrame &f) {
    const float lens = 1.2f, camH = .6f, gapZ = 1.9f;
    const int sheets = 11;
    const float pitch = .3f;
    float2 p = c.uv / c.size;
    float3 d = float3(p.x, p.y * cos(pitch) + lens * sin(pitch), max(lens * cos(pitch) - p.y * sin(pitch), .05f));
    float vy = d.y / d.z * lens;
    bool ground = vy < 0;
    float camZ = c.travel * 2.1f;
    float camX = 1.2f * sin(c.travel * .045f);
    float3 col;
    if (ground) {
        float dg = camH * lens / max(-vy, .01f);
        float2 g = float2(d.x / d.z * dg + camX, dg + camZ);
        col = deep(.6f, f) * .06f + paint(.5f, f) * .05f * noise2(g * float2(1.5f, .6f));
        col += paint(.6f, f) * exp(vy * 9) * .2f;
    } else {
        col = mix(paint(.55f, f) * .2f, deep(.75f, f) * .12f, saturate(vy * .7f));
        float2 star = p * 24;
        float2 sid = floor(star);
        col += paint(.9f, f) * flight_spark(length(fract(star) - .5f), .05f, .45f) * step(.9f, hash21(sid)) * .5f;
    }
    float base = floor(camZ / gapZ);
    for (int j = sheets; j >= 1; --j) {
        float id = base + float(j);
        float dz0 = id * gapZ - camZ;
        float3 h = hash33(float3(id, 5.3, 1.9));
        float k1 = .5f + .35f * h.x, ph = h.y * TAU;
        float amp = .8f + 1.2f * c.b.x;
        float x0 = d.x / d.z * dz0 + camX;
        float arg = x0 * k1 + ph + c.t * .3f;
        float arg2 = x0 * k1 * 2.4f - c.t * .45f + ph * 2;
        float dz = dz0 + amp * (sin(arg) + .45f * sin(arg2));
        if (dz < .25f) continue;
        float x = d.x / d.z * dz + camX;
        float y = vy * dz / lens;
        float gain = 1;
        if (ground) { y = -2 * camH - y; x += .04f * sin(y * 3 + c.t); gain = .32f; }
        float lower = .65f + .55f * h.z + .3f * sin(x * .23f + id * 1.7f + c.t * .1f);
        float v = y - lower;
        float pw = c.px * dz / (d.z * d.z) * 2;
        float edge = ground ? exp(-abs(v) * .7f) * .8f : smoothstep(-.04f - pw, .04f + pw, v) * exp(-max(v, 0.f) * (1.1f + .6f * h.x));
        float slope = amp * k1 * (cos(arg) + 1.08f * cos(arg2));
        float fold = min(sqrt(1 + slope * slope) - 1, 2.5f);
        float ray = noise2(float2(x * 4.5f + id * 11, c.t * .18f + id));
        float rays = .12f + ray * ray * 1.5f * (.65f + .35f * sin(x * 13 + id * 5 + 1.7f * sin(x * 5.3f - c.t * .3f)));
        float band = c.b[int(h.z * 3.99f)];
        float lift = c.hit * pow(.5f + .5f * sin(x * .45f - c.t * .9f + id * 2.3f), 6.f) * (.5f + fold) * 2.5f;
        float fade = smoothstep(float(sheets) * gapZ, float(sheets - 3) * gapZ, dz0) * smoothstep(.25f, 1.2f, dz) * exp(-dz * (.02f + .06f * c.fog));
        float3 tone = paint(.75f - min(max(v, 0.f) * .2f, .45f) + h.x * .2f + id * .05f, f);
        float rim = ground ? 0.f : glow(v, .035f + pw) * smoothstep(-.4f, 0.f, v) * .6f;
        col += tone * (edge * rays * (.25f + .9f * fold) + rim) * (.35f + 1.6f * band + lift) * fade * gain;
    }
    return col;
}
NATIVE_EFFECT(auroraOverpass)

// ---------------------------------------------------------------- 336 Cascade Climb
// Climbing the face of a vast waterfall. Tiers of falls drop between wavy ledges; each
// fall is a column of downward-streaming light fed by one band, and mist boils up at
// its foot. The camera rises with travel and looks slightly up the wall.

constant float CASCADE_TIER = 2.4f;
constant float CASCADE_COLUMN = 1.15f;

float cascade_lip(float n, float x) { return n * CASCADE_TIER + .28f * sin(x * .7f + n * 1.9f) + .12f * sin(x * 1.9f + n); }

float3 cascadeClimb(Ctx c, constant NativeFrame &f) {
    const float lens = 1.25f, pitch = .24f, wallD = 2.f;
    float2 p = c.uv / c.size;
    float camY = c.travel * 1.5f;
    float camX = .6f * sin(c.travel * .05f);
    float cp = cos(pitch), sp = sin(pitch);
    float ry = p.y * cp + lens * sp, rz = lens * cp - p.y * sp;
    float s = wallD / max(rz, .03f);
    float x = camX + p.x * s, y = camY + ry * s;
    float n = floor(y / CASCADE_TIER);
    float lipBelow = cascade_lip(n, x);
    if (lipBelow > y) { n -= 1; lipBelow = cascade_lip(n, x); }
    float lipAbove = cascade_lip(n + 1, x);
    float above = y - lipBelow, below = lipAbove - y;
    // Rock face.
    float rock = fbm2(float2(x * 1.4f, y * 1.1f), 3);
    float3 col = deep(.35f + rock * .3f, f) * (.03f + .06f * rock) + paint(.4f, f) * pow(rock, 4.f) * .1f;
    // Falls: meandering columns that change from tier to tier.
    float xw = x + .07f * sin(y * .5f + n * 2.3f);
    float colId = floor(xw / CASCADE_COLUMN);
    float3 h = hash33(float3(colId, n, 6.6));
    float band = c.b[int(fract(h.z * 7.13f) * 3.99f)];
    float local = abs(fract(xw / CASCADE_COLUMN) - .5f) * CASCADE_COLUMN;
    float width = (h.x < .15f ? 0.f : .2f + .26f * h.y) + .08f * band;
    float fall = smoothstep(width, width - .08f, local) * smoothstep(0.f, .08f, below + .05f);
    float streakA = fbm2(float2(xw * 7.f, y * .32f + c.t * .9f + h.x * 9), 3);
    float streakB = noise2(float2(xw * 17.f, y * .55f + c.t * 1.5f));
    float speedUp = smoothstep(0.f, 1.4f, below);
    float water = pow(streakA, 1.6f) * 1.6f + streakB * .35f * speedUp;
    float edgeLight = exp(-(width - local) * 9);
    float3 waterTone = paint(.45f + h.x * .3f + streakA * .2f, f);
    float foam = smoothstep(.55f, .8f, streakA + streakB * .3f) * speedUp;
    col = mix(col, waterTone * (.04f + water * .34f + edgeLight * .16f) * (.5f + 1.7f * band) + paint(.9f, f) * foam * .28f, fall);
    // Lips glow where water curls over the ledge.
    float lipPx = c.px * wallD * lens / max(rz * rz, .01f);
    float lipLine = glow(below, .03f + lipPx) * (.4f + .8f * fall) + glow(above, .03f + lipPx) * .4f;
    col += paint(.9f, f) * lipLine * .8f;
    // Mist boils up from the foot of each fall; attacks burst it.
    float burst = c.hit * smoothstep(.15f, .85f, .5f + .5f * sin(n * 2.1f + colId * 1.3f + c.t * .35f));
    float mist = fbm2(float2(x * 1.2f, (y - c.t * .4f) * 1.3f), 3);
    float footing = smoothstep(width + .5f, width - .2f, local) * (h.x < .2f ? .3f : 1.f);
    float rise = exp(-max(above, 0.f) * (1.7f - 1.f * burst)) * smoothstep(-.05f, .05f, above);
    col += paint(.66f + mist * .25f, f) * smoothstep(.2f, .7f, mist) * rise * (.5f + 1.3f * footing) * (.9f + 3.f * burst);
    float churn = exp(-max(above, 0.f) * 5) * smoothstep(-.03f, .03f, above) * fall * (.5f + .5f * streakB);
    col += paint(.9f, f) * churn * (.7f + 1.4f * band + 2 * burst);
    col += paint(.85f, f) * exp(-max(below, 0.f) * 7) * fall * (.15f + .4f * streakA) * (.6f + band);
    float spray = flight_spark(length(fract(float2(x * 9, y * 9 - c.t * 6)) - .5f), .05f, .45f) * step(.8f, hash21(floor(float2(x * 9, y * 9 - c.t * 6))));
    col += paint(.95f, f) * spray * rise * footing * (.3f + 5 * c.b.w);
    // The far reaches dissolve into bright haze.
    float far = 1 - exp(-s * .05f);
    col = mix(col, paint(.5f, f) * .3f + paint(.8f, f) * .06f, saturate(far * (.75f + .4f * c.fog)));
    return col;
}
NATIVE_EFFECT(cascadeClimb)

// ---------------------------------------------------------------- 337 Night Orbit
// A low orbit over the dark side of a planet. A ray-sphere hit gives surface coordinates;
// two voronoi networks, nodes and dust glow on the surface, with a bright limb above.

float3 orbit_space(float3 rd, float spin, Ctx c, constant NativeFrame &f) {
    float3 rs = float3(rd.x, rd.y * cos(spin) - rd.z * sin(spin), rd.y * sin(spin) + rd.z * cos(spin));
    float3 col = deep(.7f, f) * .08f + paint(.65f, f) * .1f * noise3(rs * 2.5f) * noise3(rs * 5 + 3);
    float3 cell = floor(rs * 70);
    float3 hs = hash33(cell);
    float3 site = (cell + .25f + hs * .5f) / 70;
    float star = flight_spark(length(rs - site) * 70, .06f, .25f) * step(.8f, hs.x);
    col += paint(.85f + hs.y * .15f, f) * star * (.4f + .8f * hs.z);
    return col;
}

float3 nightOrbit(Ctx c, constant NativeFrame &f) {
    const float R = 5.f, H = .5f, lens = 1.25f, pitch = .6f;
    float2 p = rot(c.uv, .07f * sin(c.t * .05f)) / c.size;
    float cp = cos(pitch), sp = sin(pitch);
    float3 rd = normalize(float3(p.x, p.y * cp - lens * sp, lens * cp + p.y * sp));
    float3 ro = float3(0, R + H, 0);
    float orbit = c.travel * .9f;
    float b = dot(ro, rd), disc = b * b - (dot(ro, ro) - R * R);
    float closest = (b < 0 ? sqrt(max(dot(ro, ro) - b * b, 0.f)) : length(ro)) - R;
    float3 col;
    if (disc > 0 && -b - sqrt(disc) > 0) {
        float s = -b - sqrt(disc);
        float3 P = ro + rd * s, n = P / R;
        float facing = max(dot(n, -rd), .05f);
        float2 q = float2(atan2(P.z, P.y) * R + orbit, asin(clamp(n.x, -1.f, 1.f)) * R) * .9f;
        float foot = c.px * s / lens / facing * .9f;
        float detail = 1 - smoothstep(.02f, .1f, foot);
        float land = smoothstep(.26f, .46f, fbm2(q * .15f + 2, 3));
        float4 v1 = voronoi(q * 1.7f, .9f, 0);
        float4 v2 = voronoi(q * 5.f + 7, .9f, 0);
        float art = glow(v1.y - v1.x, .02f + foot * 1.7f) * (.4f + .6f * hash21(v1.zw));
        float web = glow(v2.y - v2.x, .025f + foot * 5.f) * detail;
        float node = glow(v1.x, .045f + foot * 1.7f) * step(.2f, hash21(v1.zw + 3));
        float2 dustCell = floor(q * 9);
        float3 dh = hash33(float3(dustCell, 1.7));
        float dust = flight_spark(length(q * 9 - dustCell - .2f - dh.xy * .6f), .08f, .2f) * step(.55f, dh.z) * detail * (.5f + .5f * sin(c.t * 3 + dh.x * 40));
        float2 rel = q - float2(orbit * .9f + 2.6f, 0);
        float dist = length(rel * float2(1, 1.3f));
        float ring = c.hit * pow(.5f + .5f * sin(dist * 2.2f - c.t * 3.2f), 10.f) * exp(-dist * .2f);
        float lift = 1 + 3 * ring;
        col = deep(.45f + land * .2f, f) * (.02f + .035f * land) + paint(.35f + .1f * art, f) * (1 - land) * (.03f + .03f * noise2(q * 2.5f));
        col += paint(.3f + hash21(v1.zw) * .25f, f) * (art * .8f + exp(-(v1.y - v1.x) * 7) * .12f) * (.25f + .75f * land) * (.45f + 1.9f * c.b.x) * lift;
        col += paint(.55f + hash21(v2.zw) * .2f, f) * web * (.35f + .65f * land) * (.35f + 1.9f * c.b.y) * lift * .6f;
        col += paint(.92f, f) * node * land * (.45f + 2.6f * c.b.z) * lift;
        col += paint(.8f, f) * dust * land * (.3f + 4 * c.b.w);
        col += paint(.5f, f) * ring * .35f;
        float haze = pow(1 - facing, 6.f);
        col = mix(col, paint(.3f, f) * .3f, haze * (.5f + .3f * c.fog));
    } else {
        col = orbit_space(rd, orbit / R, c, f);
    }
    float limbSide = .6f + .4f * sin(rd.x * 2.2f + c.t * .03f);
    float alt = abs(closest);
    float sky = closest > 0 ? 1.f : .25f;
    col += paint(.25f + alt * 2, f) * (exp(-alt * 22) * .8f + exp(-alt * 5) * .25f) * limbSide * sky;
    col += paint(.95f, f) * glow(closest, .006f) * .5f * limbSide;
    return col;
}
NATIVE_EFFECT(nightOrbit)

// ---------------------------------------------------------------- 338 Comet Chase
// Chasing a comet head that hangs ahead and to one side. The ion and dust tails stream
// out of it toward the camera; debris layers fly past on stable depth slots.

float3 cometChase(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float2 ext = c.extent / c.size;
    float2 head = float2(.36f * ext.x, .3f * ext.y) + .05f * float2(sin(c.t * .31f), cos(c.t * .23f));
    float2 d = p - head;
    float r = max(length(d), 1e-3f);
    float a = atan2(d.y, d.x);
    float lr = log(r);
    float axis = -2.6f + .08f * sin(c.t * .17f);
    float rel = a - axis;
    rel = atan2(sin(rel), cos(rel));
    // Background: nebula haze and fixed stars.
    float3 col = deep(.55f, f) * .05f + paint(.6f, f) * .05f * noise2(p * 1.3f + 4);
    float2 star = p * 30;
    float2 sid = floor(star);
    col += paint(.85f, f) * flight_spark(length(fract(star) - .5f - (hash22(sid) - .5f) * .6f), .05f, .2f) * step(.88f, hash21(sid)) * .45f;
    // Dust tail: broad, curved, striated.
    float curved = rel + .35f * lr;
    float dustWidth = .55f + .3f * c.b.x;
    float dust = exp(-curved * curved / (dustWidth * dustWidth));
    float striae = .55f + .45f * sin(curved * 26 + sin(lr * 3 - c.travel * 2) * 1.5f);
    float stream = .6f + .4f * pow(.5f + .5f * sin(lr * 7 - c.travel * 5 + curved * 3), 3.f);
    float reach = smoothstep(.02f, .2f, r);
    col += paint(.2f + curved * .25f + r * .1f, f) * dust * striae * stream * reach * (.45f + 1.6f * c.b.x);
    // Ion tail: narrow, straight filaments.
    float ion = rel + .55f;
    float ionCore = exp(-ion * ion * 40);
    float fil = pow(.5f + .5f * cos(ion * 110 + noise2(float2(lr * 3 - c.travel * 3, ion * 20)) * 6), 6.f);
    float kink = .5f + .5f * sin(lr * 11 - c.travel * 7 + ion * 30);
    col += paint(.62f + ion * .3f, f) * ionCore * (.25f + fil * (.6f + kink)) * reach * (.4f + 1.8f * c.b.y);
    // Coma, nucleus and jets.
    col += paint(.8f, f) * (glow(r, .07f) * .8f + exp(-r * 2.5f) * .2f);
    col += paint(.97f, f) * glow(r, .012f) * 1.2f;
    float sunward = smoothstep(.2f, -.7f, cos(rel));
    float jets = pow(.5f + .5f * cos(a * 7 + c.t * .5f), 8.f) * exp(-r * 8) * sunward;
    col += paint(.9f, f) * jets * (.3f + 2.4f * c.b.z);
    // Debris on forward-moving depth slots.
    for (int k = 0; k < 5; ++k) {
        float2 slot = layerSlot(k, 5, c.travel * .25f);
        float scale = layerScale(slot.x, 3.2f);
        float2 q = d * scale * 3 + float2(slot.y * 3.7f, slot.y * 1.9f);
        float2 cell = floor(q);
        float3 h = hash33(float3(cell, slot.y));
        float2 site = cell + .2f + h.xy * .6f;
        float glint = flight_spark(length(q - site), .035f + .02f * h.z, .2f) * step(.86f, h.z);
        float twinkle = .5f + .5f * sin(c.t * 3 + h.x * 20);
        col += paint(.85f + h.y * .15f, f) * glint * (.35f + twinkle * (.3f + 2.8f * c.b.w)) * layerFade(slot.x);
    }
    // Attack: a ring of fragments shed from the head.
    float sector = floor(a / (TAU / 18));
    float sh = hash11(sector + 3.3f);
    float fa = (sector + .5f) * (TAU / 18);
    float fr = .08f + (1.1f - c.hit) * (.5f + .5f * sh);
    float2 frag = head + float2(cos(fa), sin(fa)) * fr;
    col += paint(.92f, f) * flight_spark(length(p - frag), .02f, .16f * fr) * c.hit * 3.f;
    col += paint(.85f, f) * glow(r - fr, .03f) * c.hit * .6f * (.5f + .5f * sin(a * 9 + sh));
    return col;
}
NATIVE_EFFECT(cometChase)

// ---------------------------------------------------------------- 339 Cloud Sea
// Skimming a sea of cloud tops. The deck is a billowing height field traced with a short
// march; tops catch sky light, while coloured lights on a world grid glow up through the
// thin valleys between billows. Each light has its own band.

constant float CLOUD_LIGHT = 2.f;

float cloud_height(float2 w, float drift) {
    float2 q = w * 1.2f + float2(drift, 0);
    float a = abs(2 * noise2(q) - 1), b = abs(2 * noise2(q * 2.4f + 5.2f) - 1), d = abs(2 * noise2(q * 5.3f + 1.7f) - 1);
    return .26f * sqrt(a) + .1f * sqrt(b) + .035f * d;
}

float3 cloud_light(float2 w, Ctx c, constant NativeFrame &f) {
    float2 cell = floor(w / CLOUD_LIGHT);
    float2 d = w - (cell + .5f) * CLOUD_LIGHT;
    float3 h = hash33(float3(cell, 8.3));
    float falloff = 1 - smoothstep(0.f, CLOUD_LIGHT * .55f, length(d));
    float band = c.b[int(h.z * 3.99f)];
    float select = smoothstep(.55f, .95f, .5f + .5f * sin(h.x * TAU + c.t * .6f));
    float energy = .45f + 2.4f * band + c.hit * select * 6;
    return paint(.15f + h.x * .7f, f) * falloff * falloff * energy;
}

float3 cloudSea(Ctx c, constant NativeFrame &f) {
    const float lens = 1.2f, camH = .75f, top = .42f;
    float2 p = c.uv / c.size;
    float horizon = .34f;
    float vy = horizon - p.y;
    float camZ = c.travel * 1.5f;
    float camX = .9f * sin(c.travel * .05f);
    float drift = c.t * .04f;
    float3 haze = paint(.55f, f) * .28f + paint(.8f, f) * .05f;
    float3 col;
    if (vy > 0) {
        float3 rd = float3(p.x, -vy, lens);
        float t = (camH - top) / vy;
        float3 pos = float3(camX, camH, camZ) + rd * t;
        float gap = pos.y - cloud_height(pos.xz, drift);
        float prevT = t, prevGap = gap;
        for (int i = 0; i < 24 && gap > 0; ++i) {
            prevT = t; prevGap = gap;
            t += max(gap * .55f / vy, .015f + t * .012f);
            pos = float3(camX, camH, camZ) + rd * t;
            gap = pos.y - cloud_height(pos.xz, drift);
        }
        if (gap < 0) t = mix(prevT, t, prevGap / max(prevGap - gap, 1e-4f));
        pos = float3(camX, camH, camZ) + rd * t;
        float2 w = pos.xz;
        float e = .02f + t * .004f;
        float hc = cloud_height(w, drift);
        float3 n = normalize(float3(hc - cloud_height(w + float2(e, 0), drift), e, hc - cloud_height(w + float2(0, e), drift)));
        float thin = 1 - saturate(hc / .3f);
        float2 q = w * 1.2f + float2(drift, 0);
        float creaseA = abs(2 * noise2(q) - 1), creaseB = abs(2 * noise2(q * 2.4f + 5.2f) - 1);
        float crease = exp(-creaseA * 9) + .5f * exp(-creaseB * 12);
        float3 inner = cloud_light(w, c, f);
        float sky = saturate(n.y * .5f - n.z * .5f + .2f);
        float rim = pow(1 - saturate(dot(n, -normalize(rd))), 3.f);
        float3 lit = paint(.6f + hc * .8f, f) * sky * sky * .14f + inner * (.06f + thin * thin * .6f + crease * 1.8f)
                   + (paint(.88f, f) * .12f + inner * .35f) * rim * (.5f + 1.2f * c.b.x);
        float depth = t * lens;
        col = mix(haze, lit, exp(-depth * (.035f + .07f * c.fog)));
    } else {
        float up = -vy;
        col = mix(haze, deep(.8f, f) * .1f + paint(.75f, f) * .05f, saturate(up * 1.4f));
        float streak = pow(.5f + .5f * sin(up * 14 + noise2(float2(p.x * .8f - c.travel * .1f, up * 3)) * 3), 8.f);
        col += paint(.7f + up * .2f, f) * streak * .15f * exp(-up * 1.5f);
    }
    col += paint(.85f, f) * exp(-abs(vy) * 18) * .2f;
    return col;
}
NATIVE_EFFECT(cloudSea)
