// Second versions of designs whose original and final review clips were both red-tagged.
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


// ---------------------------------------------------------------- 332 Pillar Forest
// The camera weaves along a clear path through an endless grid of luminous columns and
// looks slightly up, so the columns converge overhead. A 2D grid walk finds them front to
// back; height along each column comes from the ray. Each column follows one band and
// attacks send bright rings racing up the columns.

float pillar_path(float z) { return 1.3f * sin(z * .23f) + .55f * sin(z * .51f + 1.3f); }
float pillar_slope(float z) { return 1.3f * .23f * cos(z * .23f) + .55f * .51f * cos(z * .51f + 1.3f); }


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


// ---------------------------------------------------------------- 335 Aurora Overpass
// Curtains hang across the sky at stable depths; each folds along its length, and folds
// seen edge-on glow brighter. The dark plain mirrors the same curtains.


// ---------------------------------------------------------------- 336 Cascade Climb
// Climbing the face of a vast waterfall. Tiers of falls drop between wavy ledges; each
// fall is a column of downward-streaming light fed by one band, and mist boils up at
// its foot. The camera rises with travel and looks slightly up the wall.

constant float CASCADE_TIER = 2.4f;
constant float CASCADE_COLUMN = 1.15f;

float cascade_lip(float n, float x) { return n * CASCADE_TIER + .28f * sin(x * .7f + n * 1.9f) + .12f * sin(x * 1.9f + n); }

float3 cascadeClimbII(Ctx c, constant NativeFrame &f) {
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
NATIVE_EFFECT(cascadeClimbII)

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

float3 nightOrbitII(Ctx c, constant NativeFrame &f) {
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
NATIVE_EFFECT(nightOrbitII)

// ---------------------------------------------------------------- 338 Comet Chase
// Chasing a comet head that hangs ahead and to one side. The ion and dust tails stream
// out of it toward the camera; debris layers fly past on stable depth slots.


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

float3 cloudSeaII(Ctx c, constant NativeFrame &f) {
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
NATIVE_EFFECT(cloudSeaII)
