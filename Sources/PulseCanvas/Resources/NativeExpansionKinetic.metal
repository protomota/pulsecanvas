// Original PulseCanvas designs 320–329. Dancing visuals as physical-material choreography:
// kinetic installations and physical phenomena that move with the music. Every design is
// a pure function of its uniforms. Procedural time (which already integrates the music
// clock) drives the main motion; each band drives its own group of elements and every
// attack starts a local event (a ring, a strike, a splash, a pluck) that runs outward
// while the attack envelope decays.

// ---------------------------------------------------------------- shared helpers
// Attack envelope normalised by Chaos: 1 at an attack onset, decaying to 0.
float kin_attack(Ctx c, constant NativeFrame &f) { return saturate(c.hit / max(f.camera.y, .05f)); }
// Progress of the latest attack's event: 0 at the onset, running toward 1 as it decays.
float kin_age(float attack) { return 1 - pow(attack, .35f); }
// Strength of the attack's event: fades with the envelope and scales with Chaos.
float kin_strength(float attack, constant NativeFrame &f) { return sqrt(attack) * f.camera.y; }
float kin_sq(float x) { return x * x; }
float kin_wrap(float a) { return a - TAU * floor(a / TAU + .5); }
// The prelude's field groove recomputed from the unwarped canvas position with its attack
// and band terms scaled down: rigid structures keep a gentle groove but are not torn apart
// by each attack; their own local attack events and band-driven parts carry the music.
float2 kin_groove(Ctx c, constant NativeFrame &f, float attackScale, float bandScale) {
    float2 res = max(f.resolution, float2(1));
    float2 uv = (c.screen * res - res * .5) / (min(res.x, res.y) * .5);
    uv.y = -uv.y;
    float2 p = rot(uv, f.camera.x) / clamp(f.style.w, .3f, 2.f);
    float variant = float((f.scene - 100) % 7);
    float bass = c.b.x * c.b.x * bandScale, body = c.b.y * c.b.y * bandScale, fine = (c.b.z * c.b.z + c.b.w * c.b.w) * bandScale;
    float2 wave = float2(sin(p.y * (3.2 + variant * .2) + p.x * 1.7 + c.t * .6), cos(p.x * (3.8 + variant * .2) - p.y * 2.1 - c.t * .5));
    float hit = c.hit * attackScale;
    return p + wave * float2(hit * .30 + bass * .12, hit * .22 + body * .16) + fine * .055 * float2(sin(p.y * 13 - c.t), cos(p.x * 11 + c.t));
}

// ---------------------------------------------------------------- 320 Pin Art
// A pin-screen relief seen at an angle: a dense lattice of polished pins whose heads are
// pushed out by unseen forms gliding behind the screen, so a relief of pin heads and
// exposed shafts rises and falls. Bass presses the broad forms further out, the low mids
// roll a long swell across the screen, the high mids ring fine ripples, highs glint pin
// heads and every attack presses a sharp ring through that spreads from a drifting point.
constant float kin_pinSlant = .36;

float kin_pinRelief(float2 q, float2 ext, Ctx c, float age, float strength) {
    float t = c.t * .13 + c.travel * .05, span = min(ext.x, ext.y);
    float h = 0;
    for (int k = 0; k < 3; ++k) {
        float fk = float(k);
        float2 centre = float2(sin(t * (1.1 + fk * .23) + fk * 2.1), sin(t * (.83 + fk * .17) + fk * 4.3)) * ext * .6;
        float radius = span * (.42 + .1 * sin(t * .7 + fk * 1.9));
        float2 d = q - centre;
        h += (2.3 + 2.4 * c.b.x) * exp(-dot(d, d) / (radius * radius));
    }
    h += (.2 + 1.7 * c.b.y) * kin_sq(.5 + .5 * sin(dot(q, float2(.2, .13)) - c.t * .8));
    float2 o = float2(sin(t * 1.7), cos(t * 1.3)) * ext * .4;
    float r = length(q - o);
    h += c.b.z * 1.6 * (.5 + .5 * sin(r * 1.3 - c.t * 3)) * exp(-r / span * 1.2);
    float2 a = float2(sin(t * 2.3 + 1), cos(t * 1.9)) * ext * .35;
    float ring = abs(length(q - a) - (1 + age * span * .9)) - .9;
    h += strength * 5 * (1 - smoothstep(-.3f, .3f, ring));
    return h;
}

float3 pinArt(Ctx c, constant NativeFrame &f) {
    c.uv = kin_groove(c, f, .25, .6);
    float lean = 1 + .18 * c.uv.y / c.extent.y;
    float cell = .105 * c.size;
    float2 q = c.uv * lean / cell, ext = c.extent / cell;
    float px = c.px * lean / cell;
    float attack = kin_attack(c, f), age = kin_age(attack), strength = kin_strength(attack, f);
    float column = floor(q.x - kin_pinSlant * q.y + .5), row = floor(q.y + .5);
    float2 hole = q - float2(column + kin_pinSlant * row, row);
    float bounce = kin_pinRelief(q, ext, c, age, strength);
    // the dark perforated plate, warmed by light thrown back from the raised pins
    float3 col = deep(.25, f) * .1 + paint(.3, f) * .035 * bounce;
    col *= .4 + .6 * smoothstep(.1f, .16f, length(hole));
    int top = int(floor(q.y + .45));
    const float3 light = normalize(float3(-.5, .45, .75));
    const float3 halfway = normalize(light + float3(0, 0, 1));
    float behind = 0;
    for (int n = 0; n < 6; ++n) {
        float j = float(top - n);
        float2 base = float2(column + kin_pinSlant * j, j);
        float e = 5 * tanh((.25 + kin_pinRelief(base, ext, c, age, strength)) * .22f);
        // a pin standing proud of the pin behind it faces the light
        float facing = n == 0 ? .5f : saturate(.5f + .45f * (e - behind));
        behind = e;
        float2 tip = base + e * float2(kin_pinSlant, 1);
        float id = hash21(float2(column, j));
        float ds = sdSegment(q, base, tip), across = saturate(ds / .065);
        float shaft = 1 - smoothstep(.065 - px, .065 + px, ds);
        float along = saturate(dot(q - base, float2(kin_pinSlant, 1)) / max(e * 1.0648f, .01f));
        float3 shaftColor = paint(.2 + .06 * e, f) * (.05 + .14 * e * along) * (1.3 - across * across) + paint(.9, f) * .12 * e * along * kin_sq(1 - across);
        col = mix(col, shaftColor, shaft);
        float radius = .34 + .02 * e;
        float2 dv = (q - tip) / radius;
        float rr = length(dv);
        float head = 1 - smoothstep(1 - px / radius, 1 + px / radius, rr);
        float3 normal = float3(dv, sqrt(max(0.f, 1 - rr * rr)));
        float diffuse = saturate(dot(normal, light));
        float spec = pow(saturate(dot(normal, halfway)), 36.f);
        float glint = c.b.w * 5 * pow(.5 + .5 * sin(c.t * 2.1 + id * 70), 30.f);
        float3 headColor = paint(.04 + .19 * e + .04 * id, f) * (.2 + .85 * diffuse) * (.06 + .1 * e + .07 * e * e) * (.55 + .9 * facing);
        headColor += paint(.97, f) * spec * (.1 + .25 * e + glint) + paint(.95, f) * glint * .15;
        col = mix(col, headColor, head);
    }
    return col;
}
NATIVE_EFFECT(pinArt)

// ---------------------------------------------------------------- 321 Kinetic Rain
// A kinetic installation: hundreds of glowing drops hang on fine threads in a deep grid,
// seen from slightly above, and their heights trace one morphing surface coloured by
// height. Each band shapes its own wave in the surface (bass a broad swell, low mids a
// diagonal roll, high mids a tight cross ripple, highs a sparkle on the drops) and each
// attack sends a raised, flaring ring wave across the grid.
float kin_rainSurface(float2 g, Ctx c, float age, float strength) {
    float t = c.t * .4 + c.travel * .15;
    float y = .5 * sin(g.x * .38 + t * .9) * cos(g.y * .33 - t * .6) + .3 * sin((g.x + g.y) * .24 - t * .7);
    y += c.b.x * 1.1 * sin(length(g - float2(0, 8)) * .42 - c.t * 1.2);
    y += c.b.y * .75 * sin(g.x * .62 - g.y * .3 + c.t * 1.05);
    y += c.b.z * .4 * sin(g.y * 1.15 + g.x * .3 - c.t * 2.2);
    float r = length(g - float2(sin(c.t * .13) * 3, 6.5));
    y += strength * 1.6 * exp(-kin_sq(r - age * 13) * .4);
    return y;
}

float3 kineticRain(Ctx c, constant NativeFrame &f) {
    c.uv = kin_groove(c, f, .30, .45);
    float attack = kin_attack(c, f), age = kin_age(attack), strength = kin_strength(attack, f);
    float focal = 1.45 * max(1.f, c.extent.y * .82) * c.size;
    const float pitch = .3, spacing = .72;
    float cs = cos(pitch), sn = sin(pitch);
    float2 uv = c.uv;
    float3 ray = float3(uv.x, uv.y * cs - focal * sn, uv.y * sn + focal * cs);
    float3 col = paint(.95, f) * .03 + paint(.75, f) * .05 * exp(-kin_sq(uv.y - .25) * 2);
    for (int k = 0; k < 16; ++k) {
        float z = 1.1 + float(k) * .8;
        // each row is shifted by its own offset so no aisle between columns lines up with the view
        float shift = fract(float(k) * .618034f + .3f);
        float x = (round(z / ray.z * uv.x / spacing - shift) + shift) * spacing;
        float2 g = float2(x, z);
        float surface = kin_rainSurface(g, c, age, strength);
        float y = -2 + surface;
        float yc = y * cs + z * sn, zc = -y * sn + z * cs;
        float2 drop = float2(x, yc) * focal / zc;
        const float ceiling = 2.8;
        float tzc = max(-ceiling * sn + z * cs, .3f);
        float2 anchor = float2(x, ceiling * cs + z * sn) * focal / tzc;
        float rs = .085 * focal / zc;
        float d = length(uv - drop);
        float fade = exp(-float(k) * (.03 + .05 * c.fog));
        float3 tint = paint(.08 + surface * .5 + .5 + float(k) * .01, f);
        float core = smoothstep(rs + c.px, rs * .4, d);
        float halo = exp(-d * d / (rs * rs * 2.8));
        float spec = exp(-length_squared(uv - drop - rs * float2(-.3, .35)) / kin_sq(rs * .3));
        float sparkle = c.b.w * 3 * pow(.5 + .5 * sin(c.t * 2.7 + hash21(g) * 80), 24.f);
        float thickness = .006 * focal / zc, width = max(thickness, c.px * .8);
        float strand = (1 - smoothstep(width * .5, width * 1.5, sdSegment(uv, drop, anchor))) * thickness / width;
        float lit = exp(-max(uv.y - drop.y, 0.f) * 1.6);
        float motor = exp(-length_squared(uv - anchor) / kin_sq(rs * .35));
        col += fade * (tint * (core * 1.3 + halo * .6 + strand * (.12 + .5 * lit) + motor * .6) + paint(.98, f) * (spec * .7 + sparkle * core));
    }
    return col;
}
NATIVE_EFFECT(kineticRain)

// ---------------------------------------------------------------- 322 Plasma Globe
// A large glass plasma globe seen close up: luminous filaments reach from the central
// electrode to the glass, wander slowly, fan into branches near the glass and burn bright
// where they touch it, inside a violet gas glow. Each band strengthens, thickens and
// stirs its own filaments and every attack fires a burst of fresh filaments outward.
float3 plasmaGlobe(Ctx c, constant NativeFrame &f) {
    c.uv = kin_groove(c, f, .3, .4);
    float attack = kin_attack(c, f), age = kin_age(attack), strength = kin_strength(attack, f);
    float2 ext = c.extent;
    float radius = .95 * (min(ext.x, ext.y) + .3 * (max(ext.x, ext.y) - min(ext.x, ext.y))) * c.size;
    float2 p = c.uv;
    float r = length(p), a = atan2(p.y, p.x), rn = r / radius;
    float t = c.t * .3 + c.travel * .1;
    float inside = 1 - smoothstep(radius - c.px * 2, radius + c.px * 2, r);
    float3 col = deep(.35, f) * (.06 + .26 * rn * rn * rn) * inside + paint(.25, f) * .1 * exp(-max(r - radius, 0.f) * 1.6) * (1 - inside);
    col += paint(.3, f) * .12 * inside * kin_sq(fbm2(p * 2.5 / radius + float2(t, -t * .7), 3) * 1.6) * (.3 + rn);
    for (int k = 0; k < 9; ++k) {
        float fk = float(k), band = c.b[k & 3];
        float tilt = .55 + .45 * sin(t * .4 + fk * 2.3);
        float reach = radius * (.62 + .36 * tilt) * (.9 + .12 * band);
        float s = r / reach;
        float heading = fk * TAU / 9 + .7 * sin(t * (.5 + .07 * fk) + fk * 1.7) + t * .25;
        float wander = (.3 + .18 * band) * s * sin(rn * 3.1 - c.t * .9 + fk * 3.1) + .035 * s * sin(r * 11 / radius - c.t * 4 + fk * 5);
        float fork = smoothstep(.4f, 1.f, s);
        float ending = 1 - smoothstep(.97f, 1.03f, s);
        float contact = 1 + 3 * exp(-kin_sq((s - 1) * 14));
        for (int j = -1; j <= 1; ++j) {
            float fj = float(j);
            float branch = heading + wander + fj * fork * (.2 + .06 * sin(t * 2 + fk + fj)) + fork * fork * .05 * sin(r * 16 / radius - c.t * 5 + fk * 3 + fj * 2);
            float d = abs(kin_wrap(a - branch)) * r;
            float weight = j == 0 ? 1.f : fork;
            float width = radius * (.0035 + .006 * band) * (1.4 - .7 * s) * (j == 0 ? 1.f : .7f);
            float core = exp(-d * d / (width * width)), halo = glow(d, width * 6);
            col += (paint(.92, f) * core * 1.2 + paint(.42 + .12 * fj + .1 * band, f) * halo * .45) * weight * ending * contact * (.45 + 1.4 * band);
        }
    }
    for (int k = 0; k < 6; ++k) {
        float fk = float(k);
        float heading = fk * TAU / 6 + t * 1.3 + .4 * sin(fk * 4.1);
        float reach = radius * (.3 + .7 * sqrt(age));
        float s = r / reach;
        float branch = heading + .25 * s * sin(rn * 5 - c.t * 3 + fk * 2);
        float d = abs(kin_wrap(a - branch)) * r, width = radius * .009 * (1.3 - .6 * s);
        col += (paint(.97, f) * exp(-d * d / (width * width)) + paint(.6, f) * glow(d, width * 5) * .4) * (1 - smoothstep(.95f, 1.05f, s)) * strength * 3;
    }
    float electrode = radius * .09;
    col += paint(.88, f) * (fill(r - electrode, c.px * 2) * (.7 + .3 * noise2(p * 40 / radius + c.t)) + glow(r, electrode * 1.2) * (.45 + 1.5 * strength));
    col += paint(.8, f) * glow(r - radius, radius * .006) * .5 + paint(.95, f) * .35 * exp(-kin_sq((r - radius * .9) * 30 / radius)) * exp(-kin_sq(kin_wrap(a - 2.2) * 3));
    return col;
}
NATIVE_EFFECT(plasmaGlobe)

// ---------------------------------------------------------------- 323 Jacob's Ladder
// Rows of Jacob's ladders at three depths: electric arcs bridge pairs of diverging rails,
// climb as they stretch and bow upward, flicker and break at the top while the next arc
// strikes at the base. Bass thickens the arcs, each band powers its own ladders, highs
// make the arcs crackle and every attack strikes a fresh arc at the base with sparks.
float3 kin_ladderLayer(float2 uv, float scale, float squeeze, float period, float lift, float layer, Ctx c, constant NativeFrame &f, float age, float strength) {
    float2 p = uv / float2(scale * squeeze, scale);
    p.y -= lift;
    p.x += (layer == 1 ? period * .5 : layer * .13) + c.travel * (.03 + .02 * layer);
    float cell = floor(p.x / period + .5);
    float lx = p.x - cell * period, y = p.y;
    float seed = hash21(float2(cell, layer * 7.1));
    float band = c.b[int(abs(cell) + layer) & 3];
    float px = c.px / scale;
    const float gap = .045, spread = .17, height = 2.1;
    float3 col = 0.f;
    float heat = 0;
    for (int j = 0; j < 2; ++j) {
        float fj = float(j);
        float phase = fract(c.t * (.12 + .04 * seed) + fj * .5 + seed);
        float life = smoothstep(0.f, .05f, phase) * (1 - smoothstep(.84f, .98f, phase));
        float ya = .08 + phase * (height - .45);
        float halfSpan = gap + spread * ya, xs = lx / halfSpan;
        float bow = (.1 + 1.5 * phase * phase) * halfSpan;
        float sway = .22 * sin(c.t * 3.1 + fj * 2 + seed * 9) * phase * halfSpan;
        float crackle = (.012 + .03 * c.b.w) * (sin(xs * 7 + c.t * 17 + fj * 5) + .55 * sin(xs * 19 - c.t * 29 + seed * 30) + .3 * sin(xs * 43 + c.t * 53 + fj * 3));
        float curve = ya + (bow + sway * xs + crackle * (.4 + phase)) * (1 - xs * xs);
        float d = abs(y - curve) / (1 + abs(2 * bow * xs / halfSpan) * .7);
        float spanMask = 1 - smoothstep(.98f, 1.04f, abs(xs));
        float width = (.026 + .05 * c.b.x) * (1 - .35 * phase);
        float flicker = .8 + .2 * sin(c.t * 41 + fj * 9 + seed * 40);
        float energy = life * flicker * (.5 + 1.6 * band) * (1.15 - .4 * phase);
        col += (paint(.97, f) * exp(-d * d / (width * width * .3)) * 1.8 + paint(.72, f) * exp(-d * d / (width * width * 2.5)) * .9 + paint(.55, f) * glow(d, width * 4) * .5) * spanMask * energy;
        col += paint(.4, f) * glow(d, .35) * .08 * smoothstep(1.8f, 1.f, abs(xs)) * energy;
        heat += exp(-kin_sq(y - ya) * 50) * energy;
        // the arc breaks into sparks at the top
        float breakup = smoothstep(.8f, .92f, phase) * life;
        float2 sparkAt = float2(lx, y) - float2(sin(seed * 20 + fj) * halfSpan * .6, curve * 0 + ya + bow + .1 * (phase - .8) * 6);
        col += paint(.9, f) * glow(length(sparkAt), .02) * breakup * band;
    }
    // A fresh arc strikes at the base on each attack and throws sparks upward.
    {
        float ya = .05 + age * .45, halfSpan = gap + spread * ya, xs = lx / halfSpan;
        float curve = ya + (.12 + .06 * sin(xs * 11 + c.t * 29)) * halfSpan * (1 - xs * xs);
        float d = abs(y - curve), width = .025 + .03 * strength;
        col += (paint(.99, f) * exp(-d * d / (width * width)) * 1.4 + paint(.65, f) * glow(d, width * 4) * .6) * (1 - smoothstep(.98f, 1.04f, abs(xs))) * strength * 4;
        heat += exp(-kin_sq(y - ya) * 50) * strength * 3;
        for (int k = 0; k < 5; ++k) {
            float3 h = hash33(float3(cell, layer, float(k)));
            float2 spark = float2((h.x - .5) * .9 * age, .05 + age * (.5 + h.y * 1.1) - age * age * .6);
            col += paint(.92, f) * glow(length(float2(lx, y) - spark), .014) * strength * 1.6;
        }
    }
    float yc = clamp(y, 0.f, height);
    float railD = abs(abs(lx) - (gap + spread * yc)) * .986 + max(-y, 0.f) + max(y - height, 0.f);
    float rail = 1 - smoothstep(.016 - px, .016 + px, railD);
    float sheen = 1 - kin_sq(saturate(railD / .016));
    col = mix(col, paint(.45, f) * (.12 + .45 * sheen) + paint(.95, f) * min(heat, 2.f) * .8 * sheen, rail);
    col += paint(.5, f) * glow(railD, .025) * (.05 + .25 * min(heat, 2.f));
    col += paint(.95, f) * glow(length(float2(abs(lx) - gap - spread * height, y - height)), .03) * .25;
    float post = sdBox2(float2(abs(lx) - gap, y + .12), float2(.03, .12));
    col = mix(col, paint(.2, f) * .3, fill(post, px));
    return col;
}

float3 jacobsLadder(Ctx c, constant NativeFrame &f) {
    c.uv = kin_groove(c, f, .30, .45);
    float attack = kin_attack(c, f), age = kin_age(attack), strength = kin_strength(attack, f);
    float2 uv = c.uv / c.size;
    float ey = c.extent.y / c.size, squeeze = min(1.f, 1.45f * c.extent.x / c.extent.y);
    float3 col = deep(.25, f) * .05 + paint(.3, f) * .09 * exp(-kin_sq(uv.y / ey + .45) * 1.6);
    col += kin_ladderLayer(uv, .3 * ey, squeeze, 1.9, -.9, 0, c, f, age, strength) * .35;
    col += kin_ladderLayer(uv, .55 * ey, squeeze, 2.6, -1.25, 1, c, f, age, strength) * .65;
    col += kin_ladderLayer(uv, ey, squeeze, 5, -1.08, 2, c, f, age, strength);
    return col;
}
NATIVE_EFFECT(jacobsLadder)

// ---------------------------------------------------------------- 324 Hanging Mobile
// A large balanced hanging mobile in front of a lit wall: nested wire arms turn on their
// pivots and carry glowing flat shapes that spin on their own wires, while each translucent
// shape throws a soft coloured shadow on the wall behind. Each arm swings with its own
// band, shapes brighten with their arm's band and every attack sets one arm spinning.
constant float kin_mobileFocal = 3.2, kin_mobileWall = 1.4;
constant float3 kin_mobileLight = float3(-1.6, 2.6, -9);

float2 kin_mobileProject(float3 p) { return p.xy * kin_mobileFocal / (kin_mobileFocal + p.z); }
float2 kin_mobileShadow(float3 p) {
    float3 s = p + (p - kin_mobileLight) * (kin_mobileWall - p.z) / (p.z - kin_mobileLight.z);
    return kin_mobileProject(s);
}
float kin_mobileOutline(float2 q, int kind) {
    if (kind == 0) return length(q) - 1;
    if (kind == 1) return max(length(q - float2(.6, 0)), length(q + float2(.6, 0))) - 1.1;
    if (kind == 2) return max(length(q) - 1, .85 - length(q - float2(.5, .3)));
    float2 r = abs(q); return max(r.x * .866 + q.y * .5, -q.y) - .55;
}
float3 kin_mobileArm(float3 pivot, float angle, float tilt, float left, float right, thread float3 &leftEnd) {
    float2 dir = float2(cos(angle), sin(angle));
    leftEnd = pivot + float3(-dir.x * left, tilt * left, -dir.y * left);
    return pivot + float3(dir.x * right, -tilt * right, dir.y * right);
}

float3 hangingMobile(Ctx c, constant NativeFrame &f) {
    c.uv = kin_groove(c, f, .2, .15);
    float attack = kin_attack(c, f), age = kin_age(attack), strength = kin_strength(attack, f);
    float2 uv = c.uv;
    float w = min(c.extent.x * .68, c.extent.y * .95) * c.size, h = c.extent.y * c.size, unit = min(c.extent.x, c.extent.y) * c.size;
    float t = c.t * .2 + c.travel * .08;
    float kick = 3.2 * strength * sin(age * PI);
    float angles[5] = {
        .55 * sin(t * .45) + (.15 + .9 * c.b.x) * sin(t * .9),
        .9 * sin(t * .6 + 1) + (.3 + 1.5 * c.b.y) * sin(t * 1.3 + 1),
        t * .45 + 2.1 + (.3 + 1.5 * c.b.z) * sin(t * 1.1 + 2) + kick,
        -t * .9 + .4 + (.3 + 1.6 * c.b.w) * sin(t * 1.7 + 3),
        t * 1.1 + 3.3 + (.3 + 1.6 * c.b.y) * sin(t * 1.5 + 4)};
    float bands[5] = {c.b.x, c.b.y, c.b.z, c.b.w, c.b.y};
    float3 pivots[5], ends[10];
    pivots[0] = float3(-.05 * w, h * .7, 0);
    ends[1] = kin_mobileArm(pivots[0], angles[0], .05 * sin(t * .7), w * 1.0, w * .85, ends[0]);
    pivots[1] = ends[0] - float3(0, h * .36, 0);
    ends[3] = kin_mobileArm(pivots[1], angles[1], .06 * sin(t * .9 + 1), w * .5, w * .55, ends[2]);
    pivots[2] = ends[1] - float3(0, h * .26, 0);
    ends[5] = kin_mobileArm(pivots[2], angles[2], .06 * sin(t * .8 + 2), w * .55, w * .5, ends[4]);
    pivots[3] = ends[3] - float3(0, h * .42, 0);
    ends[7] = kin_mobileArm(pivots[3], angles[3], .07 * sin(t * 1.1 + 3), w * .4, w * .36, ends[6]);
    pivots[4] = ends[5] - float3(0, h * .5, 0);
    ends[9] = kin_mobileArm(pivots[4], angles[4], .07 * sin(t * 1.2 + 4), w * .36, w * .42, ends[8]);
    // shapes hang below the free ends: B left, D both, C left, E both
    const int shapeEnd[6] = {2, 6, 7, 4, 8, 9};
    const int shapeArm[6] = {1, 3, 3, 2, 4, 4};
    const float drop[6] = {.2, .28, .22, .22, .26, .3};
    const float size[6] = {.26, .19, .2, .28, .18, .22};
    // the wall: a dark room with a broad pool of light that takes the coloured shadows
    float2 spot = (uv - float2(.2 * c.extent.x, .1 * c.extent.y)) / unit;
    float pool = exp(-dot(spot, spot) * .5);
    float3 col = paint(.1, f) * .035 + deep(.6, f) * .03 + paint(.35, f) * .15 * pool;
    float3 hook = float3(0, h * 1.05, 0);
    float lineWidth = max(.004 * unit, c.px * .8);
    float shade = 0;
    for (int k = 0; k < 5; ++k) {
        float2 a = kin_mobileShadow(ends[2 * k]), b = kin_mobileShadow(ends[2 * k + 1]);
        shade = max(shade, 1 - smoothstep(lineWidth, lineWidth * 4, sdSegment(uv, a, b)));
    }
    col *= 1 - .6 * shade;
    for (int k = 0; k < 6; ++k) {
        float3 centre = ends[shapeEnd[k]] - float3(0, h * drop[k], 0);
        float spin = t * (1.2 + .3 * float(k)) + float(k) * 1.9 + bands[shapeArm[k]] * 1.5;
        float squash = max(abs(cos(spin)), .07f);
        float sscale = size[k] * unit * 1.1;
        float2 sq = (uv - kin_mobileShadow(centre)) / sscale; sq.x /= squash;
        float sd = kin_mobileOutline(rot(sq, .2 * sin(spin * .5)), k & 3) * sscale * squash;
        float patch = 1 - smoothstep(-.015f * unit, .025f * unit, sd);
        col = mix(col, col * .3 + paint(.3 + .12 * float(k), f) * (.05 + .2 * bands[shapeArm[k]]) * (.4 + .6 * pool), patch * .9);
    }
    // wires, arms and shapes in front of the wall
    col += paint(.8, f) * .5 * (1 - smoothstep(lineWidth * .4, lineWidth * 1.2, sdSegment(uv, kin_mobileProject(hook), kin_mobileProject(pivots[0]))));
    for (int k = 0; k < 5; ++k) {
        float2 a = kin_mobileProject(ends[2 * k]), b = kin_mobileProject(ends[2 * k + 1]);
        float d = sdSegment(uv, a, b);
        float2 pv = kin_mobileProject(pivots[k]);
        if (k > 0) {
            float3 from = k == 1 ? ends[0] : k == 2 ? ends[1] : k == 3 ? ends[3] : ends[5];
            col += paint(.8, f) * .45 * (1 - smoothstep(lineWidth * .4, lineWidth * 1.2, sdSegment(uv, kin_mobileProject(from), pv)));
        }
        col = mix(col, paint(.85, f) * (.55 + .9 * bands[k]), 1 - smoothstep(lineWidth, lineWidth * 1.8, d));
        col += paint(.7, f) * glow(d, lineWidth * 3) * (.1 + .3 * bands[k]);
        col += paint(.95, f) * glow(length(uv - pv), lineWidth * 1.5) * .5;
    }
    for (int k = 0; k < 6; ++k) {
        float3 anchor = ends[shapeEnd[k]];
        float3 centre = anchor - float3(0, h * drop[k], 0);
        float spin = t * (1.2 + .3 * float(k)) + float(k) * 1.9 + bands[shapeArm[k]] * 1.5;
        float cs = cos(spin), squash = max(abs(cs), .07f);
        float persp = kin_mobileFocal / (kin_mobileFocal + centre.z);
        float radius = size[k] * unit * persp;
        float2 sc = kin_mobileProject(centre);
        col += paint(.8, f) * .45 * (1 - smoothstep(lineWidth * .4, lineWidth * 1.2, sdSegment(uv, kin_mobileProject(anchor), sc)));
        float2 q = (uv - sc) / radius; q.x /= squash;
        float sd = kin_mobileOutline(rot(q, .2 * sin(spin * .5)), k & 3) * radius * squash;
        float body = 1 - smoothstep(-c.px, c.px, sd);
        float band = bands[shapeArm[k]];
        float flare = shapeArm[k] == 2 || shapeArm[k] == 4 ? strength * 2.5 : 0.f;
        float3 face = cs > 0 ? paint(.32 + .09 * float(k), f) : paint(.12 + .07 * float(k), f);
        float sheen = pow(abs(sin(spin)), 3.f) * saturate(.6 + .5 * q.y - .3 * q.x);
        float edge = 1 - smoothstep(0.f, .012f * unit, -sd);
        float3 shapeColor = face * (.55 + 1.0 * band + flare) * (.75 + .35 * q.y) + paint(.97, f) * (sheen * .4 + edge * .45);
        col = mix(col, shapeColor, body);
        col += paint(.75, f) * glow(max(sd, 0.f), .02 * unit) * (.18 + .5 * band + flare);
    }
    return col;
}
NATIVE_EFFECT(hangingMobile)

// ---------------------------------------------------------------- 325 Prism Carousel
// Tall glass prisms ride a slowly turning carousel low in the frame and spin on their own
// axes. Each splits a light beam into a spectral band thrown onto the dark wall behind, so
// long rainbow streaks slide, stretch and tilt across the wall as the prisms turn, and glint
// in the glossy floor. Each prism follows its own band (its streak widens, lengthens and
// brightens), highs run sparkles along the streaks and through the glass, and every attack
// flicks the front prisms so their streaks whip across the wall.
struct kin_Prism { float2 origin; float spin, near, band; };

kin_Prism kin_prismAt(int k, float flick, Ctx c, float yC, float rx, float ry) {
    kin_Prism prism;
    float fk = float(k);
    float around = fk * TAU / 6 + c.t * .09 + c.travel * .06;
    prism.near = .5 - .5 * sin(around);
    prism.origin = float2(rx * cos(around), yC + ry * sin(around));
    prism.band = c.b[k & 3];
    prism.spin = c.t * (.2 + .045 * fk) + fk * 1.7 + prism.band * .35 + flick * prism.near * prism.near;
    return prism;
}

// The spectral streak one prism throws on the wall: hue runs across the streak.
float3 kin_prismStreak(float2 p, float2 ext, kin_Prism prism, int k, Ctx c, constant NativeFrame &f) {
    float fk = float(k);
    float heading = 1.15 * sin(prism.spin);
    float2 centre = float2(prism.origin.x * .4 + ext.x * .75 * sin(heading), ext.y * (-.05 + .16 * fk) + .18 * sin(prism.spin * .7 + fk));
    float angle = .45 * sin(prism.spin * .8 + fk * 1.3) + ((k & 1) == 1 ? .25f : -.25f);
    float2 axis = float2(cos(angle), sin(angle));
    float2 d = p - centre;
    float u = dot(d, axis), v = axis.x * d.y - axis.y * d.x;
    float reach = ext.x * (.4 + .25 * prism.near + .3 * prism.band);
    float width = .07 + .07 * prism.band + .03 * prism.near;
    float s = (v - .2 * u * u / reach) / width;
    float across = abs(s);
    float ends = smoothstep(1.f, .45f, abs(u) / reach);
    float streak = smoothstep(1.f, .8f, across) * ends;
    float spill = exp(-max(across - 1, 0.f) * 1.4) * ends * .12;
    float striation = .7 + .3 * noise2(float2(u * 2.2 + fk * 7, s * 3));
    float sparkle = c.b.w * 2.5 * pow(.5f + .5f * sin(u * 9 - c.t * 4 + fk * 3), 24.f);
    float level = (.28 + 1.1 * prism.band) * (.65 + .35 * prism.near);
    return (paint(.5 + .48 * clamp(s, -1.f, 1.f), f) * (streak * striation + spill) + paint(.97, f) * sparkle * streak * .5) * level;
}

// A vertical glass prism with a triangular section, spinning on its axis.
float3 kin_prismGlass(float2 q, float radius, float px, kin_Prism prism, float flare, Ctx c, constant NativeFrame &f, thread float &cover) {
    float tall = radius * 4.2;
    cover = 0;
    if (abs(q.x) > radius * 1.6 || q.y < -radius || q.y > tall + radius) return 0.f;
    float lx = q.x / radius, pxr = px / radius;
    float3 col = 0.f;
    for (int i = 0; i < 3; ++i) {
        float a0 = prism.spin + float(i) * TAU / 3, normal = a0 + TAU / 6;
        if (sin(normal) > 0) continue;
        float xa = cos(a0), xb = cos(a0 + TAU / 3);
        float face = smoothstep(min(xa, xb) - pxr, min(xa, xb) + pxr, lx) * (1 - smoothstep(max(xa, xb) - pxr, max(xa, xb) + pxr, lx));
        float along = saturate((lx - xa) / (xb - xa));
        float facing = cos(normal);
        float3 glass = paint(.5 + .4 * facing + .25 * along, f) * (.25 + .7 * prism.band) + paint(.97, f) * pow(saturate(-facing * .9 + .1f), 6.f) * .7;
        col += glass * face;
        cover = max(cover, face);
        col += paint(.95, f) * (glow(abs(lx - xa) * radius, px * 1.5) + glow(abs(lx - xb) * radius, px * 1.5)) * .35 * face;
    }
    float column = smoothstep(-px, px, q.y) * (1 - smoothstep(tall - px, tall + px, q.y));
    float glint = c.b.w * 2.5 * pow(.5f + .5f * sin(c.t * 3 + prism.spin * 2), 12.f) * exp(-kin_sq(q.y / tall - .6) * 8);
    cover *= column;
    col = col * column + paint(.95, f) * glint * cover;
    col += paint(.97, f) * glow(length(float2(q.x * .4, q.y - tall)), radius * .5) * (.25 + flare) * step(abs(q.x), radius);
    return col;
}

float3 prismCarousel(Ctx c, constant NativeFrame &f) {
    c.uv = kin_groove(c, f, .25, .3);
    float attack = kin_attack(c, f), age = kin_age(attack), strength = kin_strength(attack, f);
    float2 p = c.uv / c.size, ext = c.extent / c.size;
    float yC = -ext.y * .6, rx = min(ext.x * .62, 1.3f), ry = .16;
    float flick = 2.6 * strength * sin(age * PI) + .5 * strength;
    kin_Prism prisms[6];
    for (int k = 0; k < 6; ++k) prisms[k] = kin_prismAt(k, flick, c, yC, rx, ry);
    // the dark wall, faintly textured, with the streaks thrown across it; the floor mirrors them
    float floorY = yC - ry - .05;
    bool onFloor = p.y < floorY;
    float2 w = onFloor ? float2(p.x + .012 * sin(p.y * 60 + c.t), 2 * floorY - p.y) : p;
    float3 wall = deep(.3, f) * .05 + paint(.85, f) * .05 * exp(-kin_sq(w.y - yC) * .8) * (.85 + .15 * noise2(w * 14));
    for (int k = 0; k < 6; ++k) wall += kin_prismStreak(w, ext, prisms[k], k, c, f);
    float3 col = onFloor ? wall * .35 * exp((p.y - floorY) * 1.8) + deep(.3, f) * .03 : wall;
    // the carousel deck and rim
    float2 e = (p - float2(0, yC)) / float2(rx, ry);
    float rim = abs(length(e) - 1) * ry;
    float deck = 1 - smoothstep(.97f, 1.03f, length(e));
    col = mix(col, col * .5 + paint(.9, f) * .03 * (1 - e.y), deck * .6);
    col += paint(.85, f) * glow(rim, .005) * .5 + paint(.3, f) * glow(rim, .04) * .1;
    // prisms, back to front
    int order[6] = {0, 1, 2, 3, 4, 5};
    for (int a = 0; a < 5; ++a)
        for (int b = 0; b < 5 - a; ++b)
            if (prisms[order[b]].near > prisms[order[b + 1]].near) { int swap = order[b]; order[b] = order[b + 1]; order[b + 1] = swap; }
    for (int k = 0; k < 6; ++k) {
        kin_Prism prism = prisms[order[k]];
        float radius = .06 * (.7 + .45 * prism.near);
        float cover;
        float3 glass = kin_prismGlass(p - prism.origin, radius, c.px / c.size, prism, strength * 2 * prism.near * prism.near, c, f, cover);
        col = col * (1 - .7 * cover) + glass;
    }
    return col;
}
NATIVE_EFFECT(prismCarousel)

// ---------------------------------------------------------------- 326 Cone Splash
// A low close-up across a vibrating speaker membrane covered in pools of wet paint. Paint
// leaps off it in crowns: a lobed cup whose rim throws up tapering fingers, each carrying a
// bead that tears free as a droplet, and a central jet rises as the crown collapses, while
// ripples glint across the wet paint. Each paint colour rides its own band (its splashes leap
// higher and its pools swell), bass rolls rings out from the cone's centre and every attack
// throws a large crown up from the front of the membrane.
constant float kin_splashEye = .55;
constant float kin_splashHue[4] = {.05, .3, .78, .95};

float2 kin_splashProject(float3 p, float horizon, float focal) {
    return float2(p.x, p.y - kin_splashEye) * focal / max(p.z, .3f) + float2(0, horizon);
}
// Tapered capsule from a (radius ra) to b (radius rb): x = signed distance, y = local radius.
float2 kin_splashTaper(float2 p, float2 a, float2 b, float ra, float rb) {
    float2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-8f), 0.f, 1.f);
    float r = mix(ra, rb, h);
    return float2(length(pa - ba * h) - r, r);
}
// Glossy paint: a lit body with a hot core and a tight glow around it.
void kin_splashPaint(thread float3 &col, float sd, float radius, float hue, float alpha, float px, constant NativeFrame &f) {
    radius = max(radius, 1e-5f);
    float core = saturate(-sd / radius);
    float3 body = paint(hue, f) * (.28 + .75 * core) + paint(hue + .12, f) * .3 * (1 - core) + paint(.97, f) * pow(core, 8.f) * .3;
    col = mix(col, body, fill(sd, px) * alpha);
    col += paint(hue, f) * exp(-max(sd, 0.f) / (radius * .8f)) * .3 * alpha;
}

void kin_splashCrown(thread float3 &col, float2 uv, float horizon, float focal, float2 site, float age, float scale, float hue, float seed, float px, constant NativeFrame &f) {
    float rise = 4 * age * (1 - age);
    float grow = smoothstep(0.f, .12f, age), fade = 1 - smoothstep(.8f, 1.f, age);
    float rc = scale * (.12 + .32 * sqrt(age));
    // skip pixels far from this splash
    float reach = rc + scale * .9, zn = max(site.y - reach, .5f), zf = site.y + reach;
    float margin = scale * .5 * focal / zn, top = scale * 2.4 - kin_splashEye;
    float xMin = min((site.x - reach) / zn, (site.x - reach) / zf) * focal, xMax = max((site.x + reach) / zn, (site.x + reach) / zf) * focal;
    float yMin = horizon - kin_splashEye * focal / zn, yMax = horizon + max(top / zn, top / zf) * focal;
    if (uv.x < xMin - margin || uv.x > xMax + margin || uv.y < yMin - margin || uv.y > yMax + margin) return;
    float spin = (fract(seed * 7.3) - .5) * .7;
    float wall = scale * .3 * rise;
    // the crown's cup: a thin translucent sheet with a lobed, glowing rim
    float across = (uv.x * site.y / focal - site.x) / rc;
    if (abs(across) < 1) {
        float sx = sqrt(1 - across * across);
        for (int side = 0; side < 2; ++side) {
            float facing = side == 0 ? 1.f : -1.f;
            float z = site.y + facing * rc * sx;
            float theta = atan2(facing * sx, across);
            float rim = wall * (.65 + .35 * cos(8 * (theta - PI * .5 - spin)));
            float vb = horizon - kin_splashEye * focal / z, vt = horizon + (rim - kin_splashEye) * focal / z;
            float sheet = smoothstep(vb - px, vb + px, uv.y) * (1 - smoothstep(vt - px, vt + px, uv.y));
            float height = saturate((uv.y - vb) / max(vt - vb, 1e-4f));
            col = mix(col, paint(hue, f) * (.25 + .55 * height + .3 * sx), sheet * (side == 0 ? .45f : .7f) * fade);
            col += paint(hue + .08, f) * exp(-abs(uv.y - vt) / (.012 * scale * focal / z)) * .8 * fade * grow * step(vb, uv.y);
        }
    }
    // fingers thrown up from the rim lobes, back to front, each carrying a bead that tears free
    for (int j = 0; j < 8; ++j) {
        float k = float((j + 1) / 2) * ((j & 1) == 1 ? 1.f : -1.f);
        float theta = PI * .5 + spin + k * TAU / 8;
        float h = hash21(float2(seed * 13.7, float(j)));
        float2 out = float2(cos(theta), sin(theta));
        float tall = scale * (.75 + .6 * h) * 1.2 * rise;
        float flare = scale * (.08 + .5 * age) * (.6 + .5 * h);
        float3 base = float3(site.x + rc * out.x, wall * .85, site.y + rc * out.y);
        float3 mid = base + float3(out.x * flare * .3, tall * .55, out.y * flare * .3);
        float3 tip = base + float3(out.x * flare, tall, out.y * flare);
        float zs = focal / base.z * grow;
        float2 s1 = kin_splashTaper(uv, kin_splashProject(base, horizon, focal), kin_splashProject(mid, horizon, focal), scale * .06 * zs, scale * .04 * zs);
        float2 s2 = kin_splashTaper(uv, kin_splashProject(mid, horizon, focal), kin_splashProject(tip, horizon, focal), scale * .04 * zs, scale * .024 * zs);
        float2 s = s1.x < s2.x ? s1 : s2;
        float free = max(age - .38, 0.f);
        float3 bead = tip + float3(out.x * flare * free * 1.5, scale * (2.2 * free - 2.8 * free * free) * (.8 + .4 * h), out.y * flare * free * 1.5);
        float rBead = scale * .055 * (.8 + .4 * h) * focal / bead.z * grow;
        float db = length(uv - kin_splashProject(bead, horizon, focal)) - rBead;
        float neck = max(scale * .04 * zs * (1 - smoothstep(0.f, .08f, free)), 1e-4f);
        float sd = smin(s.x, db, neck);
        kin_splashPaint(col, sd, db < s.x ? rBead : s.y, hue + .04 * (h - .5), fade, px, f);
        float rSat = rBead * .45 * smoothstep(.04f, .14f, free);
        if (rSat > 0) kin_splashPaint(col, length(uv - kin_splashProject(mix(tip, bead, .55), horizon, focal)) - rSat, rSat, hue, fade, px, f);
    }
    // the central jet rises as the crown collapses
    float jet = max(age - .5, 0.f) / .5;
    if (jet > 0) {
        float hj = scale * 1.5 * sin(PI * jet);
        float zs = focal / site.y;
        float2 b = kin_splashProject(float3(site.x, 0, site.y), horizon, focal), tp = kin_splashProject(float3(site.x, hj, site.y), horizon, focal);
        float2 s = kin_splashTaper(uv, b, tp, scale * .1 * zs, scale * .05 * zs);
        float rTop = scale * .08 * zs * smoothstep(0.f, .2f, jet);
        float dt = length(uv - tp - float2(0, rTop * .6)) - rTop;
        kin_splashPaint(col, smin(s.x, dt, rTop * .5 + 1e-4f), dt < s.x ? rTop : s.y, hue + .06, fade * smoothstep(0.f, .1f, jet), px, f);
    }
}

float3 coneSplash(Ctx c, constant NativeFrame &f) {
    c.uv = kin_groove(c, f, .2, .35);
    float attack = kin_attack(c, f), age = kin_age(attack), strength = kin_strength(attack, f);
    float2 uv = c.uv;
    float focal = 1.8 * c.size * max(1.f, c.extent.y * .8);
    float horizon = c.extent.y * .25;
    // backdrop: a dark studio with soft coloured light pools above the membrane's rim
    float3 col = deep(.9, f) * .03 + paint(.85, f) * .08 * exp(-max(uv.y - horizon, 0.f) * 1.4);
    for (int k = 0; k < 4; ++k) {
        float2 o = float2(sin(c.t * .05 + float(k) * 1.9) * c.extent.x * .8, horizon + .45 + .4 * sin(float(k) * 2.3 + c.t * .04));
        col += paint(kin_splashHue[k], f) * (.07 + .08 * c.b[k]) * exp(-length_squared(uv - o) * 5);
    }
    float2 sites[6]; float ages[6], scales[6], hues[6], seeds[6];
    for (int k = 0; k < 5; ++k) {
        float clock = c.t * .1 + float(k) / 5;
        float3 h = hash33(float3(floor(clock), float(k), 3.7));
        int paintIndex = int(h.z * 3.99);
        float z = 1.7 + h.y * 2.6;
        sites[k] = float2((h.x * 2 - 1) * .8 * c.extent.x * z / focal, z);
        ages[k] = fract(clock);
        scales[k] = (.55 + .3 * h.y) * (.7 + 1.1 * c.b[paintIndex]);
        hues[k] = kin_splashHue[paintIndex];
        seeds[k] = h.x + h.y;
    }
    sites[5] = float2(sin(c.t * .05) * .5 * c.extent.x * 1.9 / focal, 1.9);
    ages[5] = age; scales[5] = strength * 2; hues[5] = .82; seeds[5] = .3;
    if (uv.y < horizon) {
        float z = kin_splashEye * focal / max(horizon - uv.y, 1e-3f);
        float2 g = float2(uv.x * z / focal, z);
        // ripples from every splash and rings rolled out from the cone's centre by the bass
        float2 slope = 0;
        for (int k = 0; k < 6; ++k) {
            float2 d = g - sites[k];
            float r = length(d), front = scales[k] * (.25 + 2.2 * ages[k]);
            float envelope = exp(-kin_sq(r - front) * 5) * (1 - ages[k]) * smoothstep(0.f, .1f, ages[k]) * min(scales[k], 1.2f);
            slope += d / max(r, 1e-3f) * cos((r - front) * 16) * envelope * 2.5;
        }
        float2 cone = g - float2(0, 7.5);
        float coneR = length(cone);
        slope += cone / max(coneR, 1e-3f) * sin(coneR * 4 - c.t * 2.5) * c.b.x * 1.6;
        // marbled pools of four paints; each pool swells with its own band
        float2 m = g * .95 + float2(0, c.travel * .08);
        m += .9 * float2(fbm2(m * .5 + float2(c.t * .02, 0), 2), fbm2(m * .5 + 5.2, 2));
        float marble = noise2(m * 1.3) * 4;
        int paintIndex = min(int(marble), 3);
        float seam = .7 + .3 * smoothstep(0.f, .08f, .5f - abs(fract(marble) - .5f));
        float band = c.b[paintIndex];
        slope += float2(cos(g.x * 3 + g.y * 2 - c.t * 2), sin(g.y * 2.5 - g.x - c.t * 1.6)) * band * .9;
        float3 n = normalize(float3(-slope.x * .3, 1, -slope.y * .3));
        float3 view = normalize(float3(g.x, -kin_splashEye, z));
        float3 bounce = reflect(view, n);
        float spec = pow(saturate(dot(bounce, normalize(float3(-.25, .3, 1)))), 30.f) + .6 * pow(saturate(dot(bounce, normalize(float3(.7, .45, .55)))), 40.f);
        float fresnel = .3 + .7 * smoothstep(1.f, 8.f, z);
        float fade = exp(-z * (.05 + .08 * c.fog));
        float3 tint = paint(kin_splashHue[paintIndex], f);
        float3 surface = tint * seam * (.035 + .17 * band) + tint * seam * spec * fresnel * 1.3 + paint(.97, f) * pow(spec, 3.f) * fresnel * .4;
        col = mix(col, surface * fade + deep(.3, f) * .02, smoothstep(0.f, .015f, horizon - uv.y));
    }
    // splashes, far to near
    int order[6] = {0, 1, 2, 3, 4, 5};
    for (int a = 0; a < 5; ++a)
        for (int b = 0; b < 5 - a; ++b)
            if (sites[order[b]].y < sites[order[b + 1]].y) { int swap = order[b]; order[b] = order[b + 1]; order[b + 1] = swap; }
    for (int k = 0; k < 6; ++k) {
        int i = order[k];
        if (scales[i] < .01) continue;
        kin_splashCrown(col, uv, horizon, focal, sites[i], ages[i], scales[i], hues[i], seeds[i], c.px, f);
    }
    return col;
}
NATIVE_EFFECT(coneSplash)

// ---------------------------------------------------------------- 327 Wind Tunnel
// A side view into a wind tunnel: dyed smoke streamlines flow past a cylinder, an airfoil
// and a small post, bending around them and rolling up into alternating vortex streets in
// their wakes. Bass raises the flow speed (the streamlines tighten and stream faster), the
// low and high mids strengthen the shedding behind the two cylinders, highs shimmer in the
// wakes and every attack sheds one strong vortex behind the cylinder.
float kin_windVortex(float2 p, float2 centre, float strength, float core) {
    float2 d = p - centre;
    return strength * .5 * log(dot(d, d) + core * core);
}

float3 windTunnel(Ctx c, constant NativeFrame &f) {
    c.uv = kin_groove(c, f, .25, .3);
    float attack = kin_attack(c, f), age = kin_age(attack), strength = kin_strength(attack, f);
    float2 p = c.uv / c.size, ext = c.extent / c.size;
    const float flow = 1;
    const int count = 3;
    float2 centres[count] = {float2(-ext.x * .55, ext.y * .28), float2(ext.x * .3, ext.y * .5), float2(-ext.x * .05, -ext.y * .4)};
    float radii[count] = {.24, .13, .07};
    float shed[count] = {.9 + 1.6 * c.b.y, .8 + 1.6 * c.b.z, .3 + .6 * c.b.z};
    // smoke wobble in the wakes
    float2 q = p;
    for (int o = 0; o < count; ++o) {
        float behind = smoothstep(0.f, .4f, p.x - centres[o].x) * exp(-kin_sq((p.y - centres[o].y) / (radii[o] * 3)));
        q += behind * (.02 + .03 * c.b.x + .04 * c.b.w) * float2(noise2(p * 6 - float2(c.t * 2, 0)) - .5, noise2(p * 6 + 7.3 - float2(c.t * 2, 0)) - .5);
    }
    float psi = q.y * flow, along = q.x;
    for (int o = 0; o < count; ++o) {
        float2 d = q - centres[o];
        float r2 = max(dot(d, d), 1e-4f), R2 = radii[o] * radii[o];
        if (o == 2) { d = rot(d, .18); d.x *= .19; r2 = max(dot(d, d), 1e-4f); }
        psi -= flow * R2 * d.y / r2;
        along += R2 * d.x / r2;
        float clock = c.t * .32 + float(o) * .37;
        for (int j = 0; j < 4; ++j) {
            float n = floor(clock) - float(j);
            float ageV = fract(clock) + float(j);
            float sign = n - 2 * floor(n * .5) < .5 ? 1.f : -1.f;
            float2 pos = centres[o] + float2(radii[o] * (1.3 + ageV * 2.4), sign * radii[o] * .5);
            float fade = smoothstep(0.f, .7f, ageV) * (1 - smoothstep(2.6f, 4.f, ageV));
            psi += kin_windVortex(q, pos, sign * shed[o] * fade * radii[o], radii[o] * .45);
        }
    }
    psi += kin_windVortex(q, centres[2] + float2(-.03, 0), .05 + .1 * c.b.z, .14);
    float2 kickAt = centres[0] + float2(radii[0] * (1.3 + age * 4), radii[0] * .4);
    psi += kin_windVortex(q, kickAt, strength * 1.4 * radii[0], radii[0] * .4);
    float spacing = .075;
    float lines = psi / spacing, index = floor(lines + .5);
    float aa = max(fwidth(lines), 1e-4f);
    float offset = abs(lines - index);
    float core = 1 - smoothstep(.06f, .06f + aa * 1.5f, offset);
    float halo = exp(-offset * offset * 30);
    float dash = .55 + .45 * sin(along * 7 - c.t * 2.2 + index * 1.7);
    // bass speeds up the flow: fast bright tracers race along the streamlines
    float tracer = pow(.5f + .5f * sin(along * 2.6f - c.t * 5.f + index * 2.3f), 10.f) * c.b.x * 2.2;
    float sheet = .5 + .5 * cos(TAU * lines);
    float hue = fract(index * .137) * .7 + .15;
    float3 col = deep(.3, f) * .08 + paint(hue, f) * (.03 + .07 * sheet) + paint(hue, f) * (core * (.4 + .6 * dash + tracer) + halo * (.3 * dash + .5 * tracer)) * (.8 + .25 * c.b.x);
    col += paint(.95, f) * glow(length(p - kickAt), .06) * strength * 1.2;
    col += paint(.9, f) * c.b.w * .6 * pow(noise2(p * 30 + float2(-c.t * 3, 0)), 8.f) * core;
    // obstacles: dark solids with bright rims and a stagnation glint
    for (int o = 0; o < count; ++o) {
        float2 d = p - centres[o];
        float sd;
        if (o == 2) {
            float2 l = rot(d, .18);
            float x = saturate(l.x / .72 + .5);
            float thick = .55 * (.2969 * sqrt(x) - .126 * x - .3516 * x * x + .2843 * x * x * x - .1015 * x * x * x * x);
            sd = max(abs(l.y) - thick * .72, abs(l.x) - .36);
        } else sd = length(d) - radii[o];
        float solid = fill(sd, c.px);
        col = mix(col, deep(.2, f) * .15, solid);
        col += paint(.85, f) * glow(sd, .006) * .5 + paint(.95, f) * glow(length(d + float2(radii[o], 0)), .02) * .3 * (1 - solid);
    }
    return col;
}
NATIVE_EFFECT(windTunnel)

// ---------------------------------------------------------------- 328 Tensegrity Pulse
// A slowly turning tensegrity sculpture: six glowing struts float apart, held only by a
// web of taut cables, with guy cables running out to the room. Each band tightens its own
// cable group (the cables glow and ring in fast standing waves), bass makes the struts
// burn brighter and every attack plucks a cable hard while a ripple runs through the
// whole structure.
constant float3 kin_tensVertex[12] = {
    float3(0, 1, 1.618034), float3(0, 1, -1.618034), float3(0, -1, 1.618034), float3(0, -1, -1.618034),
    float3(1.618034, 0, 1), float3(-1.618034, 0, 1), float3(1.618034, 0, -1), float3(-1.618034, 0, -1),
    float3(1, 1.618034, 0), float3(1, -1.618034, 0), float3(-1, 1.618034, 0), float3(-1, -1.618034, 0)};
constant int kin_tensCable[48] = {0, 4, 0, 5, 0, 8, 0, 10, 1, 6, 1, 7, 1, 8, 1, 10, 2, 4, 2, 5, 2, 9, 2, 11,
    3, 6, 3, 7, 3, 9, 3, 11, 4, 8, 4, 9, 5, 10, 5, 11, 6, 8, 6, 9, 7, 10, 7, 11};

float3 tensegrityPulse(Ctx c, constant NativeFrame &f) {
    c.uv = kin_groove(c, f, .15, .15);
    float attack = kin_attack(c, f), age = kin_age(attack), strength = kin_strength(attack, f);
    float2 uv = c.uv;
    float unit = min(c.extent.x, c.extent.y) * c.size;
    float yaw = c.t * .1 + c.travel * .06, pitch = .45 + .2 * sin(c.t * .05);
    float cy = cos(yaw), sy = sin(yaw), cp = cos(pitch), sp = sin(pitch);
    float2 screen[12]; float depth[12];
    for (int i = 0; i < 12; ++i) {
        float3 v = kin_tensVertex[i];
        v *= 1 + strength * .12 * sin(age * 9 - float(i) * 1.3);
        v = float3(v.x * cy + v.z * sy, v.y, -v.x * sy + v.z * cy);
        v = float3(v.x, v.y * cp - v.z * sp, v.y * sp + v.z * cp);
        float s = 6 / (6 + v.z);
        screen[i] = v.xy * s * unit * .46;
        depth[i] = s;
    }
    float3 col = deep(.3, f) * .12 + paint(.25, f) * .08 * exp(-dot(uv, uv) / (unit * unit) * .6);
    int plucked = int(floor(c.t * .37)) % 24;
    float lineWidth = max(.0035 * unit, c.px * .7);
    for (int m = 0; m < 24; ++m) {
        float2 a = screen[kin_tensCable[2 * m]], b = screen[kin_tensCable[2 * m + 1]];
        float band = c.b[m & 3];
        float2 ab = b - a;
        float len = length(ab);
        float2 dir = ab / len;
        float2 rel = uv - a;
        float along = saturate(dot(rel, dir) / len);
        float side = dir.x * rel.y - dir.y * rel.x;
        float pluck = m == plucked ? strength * 2.5 : 0.f;
        float amp = len * (.004 + .035 * band + .05 * pluck) * sin(PI * along * (1 + float(m % 3))) * cos(c.t * (7 + float(m % 5)) + float(m));
        float d = length(float2(max(abs(dot(rel, dir) - len * .5) - len * .5, 0.f), side - amp));
        float shade = .6 + .4 * (depth[kin_tensCable[2 * m]] + depth[kin_tensCable[2 * m + 1]] - 1.6);
        col += paint(.55 + .35 * band + .1 * float(m & 3) * .5, f) * ((1 - smoothstep(lineWidth * .5, lineWidth * 1.5, d)) * (.5 + 1.1 * band + pluck) + glow(d, lineWidth * 4) * (.12 + .5 * band + pluck)) * shade;
    }
    // guy cables out to the room
    for (int g = 0; g < 6; ++g) {
        int v = g == 0 ? 8 : g == 1 ? 10 : g == 2 ? 9 : g == 3 ? 11 : g == 4 ? 4 : 7;
        float2 anchor = float2(g == 4 ? 1.1 : g == 5 ? -1.1 : (g % 2 == 0 ? .6 : -.6), g < 2 ? 1.1 : g < 4 ? -1.1 : .1) * c.extent * 1.05;
        float d = sdSegment(uv, screen[v], anchor);
        float band = c.b[g & 3];
        col += paint(.3 + .15 * float(g & 3), f) * ((1 - smoothstep(lineWidth * .4, lineWidth * 1.2, d)) * (.25 + .6 * band) + glow(d, lineWidth * 5) * (.05 + .2 * band));
    }
    for (int s = 0; s < 6; ++s) {
        int i0 = 2 * s, i1 = 2 * s + 1;
        float2 a = screen[i0], b = screen[i1];
        float persp = (depth[i0] + depth[i1]) * .5;
        float radius = .03 * unit * persp;
        float d = sdSegment(uv, a, b);
        float across = saturate(d / radius);
        float body = 1 - smoothstep(radius - c.px, radius + c.px, d);
        float3 strut = paint(.82 + .08 * float(s & 1), f) * (.6 + .9 * c.b.x) * (1.2 - across * across) * (.5 + .6 * persp);
        col = mix(col, strut, body);
        col += paint(.7, f) * glow(d - radius, radius * .9) * (.2 + .5 * c.b.x);
        col += paint(.95, f) * (glow(length(uv - a), radius * .8) + glow(length(uv - b), radius * .8)) * .35;
    }
    return col;
}
NATIVE_EFFECT(tensegrityPulse)

// ---------------------------------------------------------------- 329 Shadow Modulator
// A kinetic light sculpture in a dark room: a shrouded lamp shines through perforated,
// tinted glass screens that orbit and spin around it on their own axes, while rods sweep
// past, so magnified grids of light spots, rings, lattices and spirals in coloured light
// slide, stretch and skew across the walls, floor and ceiling, crossed by rod shadows.
// Each band turns its own screen and brightens its own light, bass widens the slots in
// the lamp's shroud and every attack swings an extra perforated screen through the beam.
float kin_modulatorPattern(float2 l, int kind, float t) {
    if (kind == 0) { float4 h = hexCell(l * 11); return smoothstep(.32f, .25f, length(h.xy)); }
    if (kind == 1) return smoothstep(.12f, .26f, abs(fract(length(l) * 7 - t * .2) - .5));
    if (kind == 2) { float2 g = abs(fract(l * 5) - .5); return smoothstep(.36f, .3f, max(g.x, g.y)); }
    return smoothstep(.18f, .3f, abs(fract(atan2(l.y, l.x) * 1.91 + length(l) * 4) - .5));
}

float3 shadowModulator(Ctx c, constant NativeFrame &f) {
    c.uv = kin_groove(c, f, .35, .5);
    float attack = kin_attack(c, f), age = kin_age(attack), strength = kin_strength(attack, f);
    float focal = 1.25 * c.size;
    float3 dir = float3(c.uv, focal);
    // room: back wall, floor, ceiling and side walls
    float tb = 4.2 / dir.z;
    float tf = dir.y < 0 ? -1.25 / dir.y : 1e5;
    float tc = dir.y > 0 ? 2.6 / dir.y : 1e5;
    float ts = 3.8 / max(abs(dir.x), 1e-4f);
    float tw = min(min(tb, ts), min(tf, tc));
    float3 hit = dir * tw;
    float3 normal = tw == tb ? float3(0, 0, -1) : tw == tf ? float3(0, 1, 0) : tw == tc ? float3(0, -1, 0) : float3(-sign(dir.x), 0, 0);
    float3 lamp = float3(0, .3, 2.1);
    float t = c.t * .2 + c.travel * .07;
    float3 toLamp = lamp - hit;
    float dist2 = dot(toLamp, toLamp);
    float lambert = saturate(dot(normal, toLamp) * rsqrt(dist2));
    float3 outward = -toLamp * rsqrt(dist2);
    // light leaking from the lamp's shroud through a slowly turning band of slots
    float slots = atan2(outward.z, outward.x) * 9 / TAU + outward.y * .8 + t * .6;
    float opening = .5f - .2f * c.b.x;
    float leak = (.08 + .2 * smoothstep(opening - .12f, opening, abs(fract(slots) - .5f))) * (.4 + .6 * smoothstep(.8f, .1f, abs(outward.y)));
    float3 light = paint(.75, f) * leak;
    float3 seen = float3(0);
    float seenAlpha = 0;
    float kick = strength * 2.2 * (.4 + sin(age * PI));
    for (int k = 0; k < 5; ++k) {
        float fk = float(k);
        float band = k < 4 ? c.b[k] : 0.f;
        float orbit = k < 4 ? PI * .5 + 1.25 * sin(t * (.45 + .1 * fk) + fk * 1.6) : -.6 + .5 * sin(t * .7) + kick;
        float reach = k < 4 ? .26 + .05 * fk : .22;
        float3 centre = lamp + float3(reach * cos(orbit), .18 * sin(fk * 1.7 + t * .5), reach * sin(orbit));
        float spin = orbit + 1.1 * sin(t * (.9 + .25 * fk) + fk * 2.3) + band * .5;
        float lean = .35 * sin(t * .8 + fk * 2.1);
        float3 n = normalize(float3(cos(spin) * cos(lean), sin(lean), sin(spin) * cos(lean)));
        float3 e1 = normalize(cross(n, float3(0, 1, 0))), e2 = cross(e1, n);
        float size = k < 4 ? .2 + .025 * fk : .16;
        int kind = k < 4 ? k : 0;
        float3 tint = paint(k < 4 ? .1 + .27 * fk : .9, f);
        float gain = k < 4 ? .7 + 1.4 * band : 1 + 3 * strength;
        // the screen's projection on the room: tinted glass with clear perforations
        float3 ray = hit - lamp;
        float denom = dot(ray, n);
        float s = dot(centre - lamp, n) / (abs(denom) > 1e-4 ? denom : 1e-4);
        if (s > 0 && s < 1) {
            float3 at = lamp + ray * s - centre;
            float2 l = float2(dot(at, e1), dot(at, e2)) / size;
            float blur = .015 + .04 * (1 - s);
            float inside = smoothstep(1 + blur, 1 - blur, length(l));
            float open = kin_modulatorPattern(l, kind, c.t);
            light += (tint * .5 + mix(tint, paint(.97, f), .2) * open * 1.5) * inside * gain;
        }
        // the sculpture as seen by the camera: backlit tinted glass with a bright rim
        float sv = dot(centre, n) / dot(dir, n);
        if (sv > 0 && sv < tw) {
            float3 at = dir * sv - centre;
            float2 l = float2(dot(at, e1), dot(at, e2)) / size;
            float inside = smoothstep(1.02f, .98f, length(l));
            float open = kin_modulatorPattern(l, kind, c.t);
            float cover = inside * .6 * (1 - seenAlpha);
            seen += tint * (.25 + .4 * open) * gain * cover + paint(.95, f) * glow(abs(length(l) - 1) * size, .003) * .4 * (1 - seenAlpha);
            seenAlpha += cover;
        }
    }
    // rods sweeping around the lamp
    float shadowRods = 1;
    for (int k = 0; k < 3; ++k) {
        float fk = float(k);
        float around = fk * TAU / 3 - t * (.8 + .2 * c.b[(k + 1) & 3]);
        float3 a = lamp + float3(.45 * cos(around), -.5, .45 * sin(around));
        float3 b = a + float3(.25 * sin(t + fk), 1.1, .25 * cos(t * .7 + fk));
        float3 u = hit - lamp, v = b - a, w0 = lamp - a;
        float uu = dot(u, u), uvv = dot(u, v), vv = dot(v, v), uw = dot(u, w0), vw = dot(v, w0);
        float den = max(uu * vv - uvv * uvv, 1e-5f);
        float sc = saturate((uvv * vw - vv * uw) / den), tcl = saturate((uu * vw - uvv * uw) / den);
        float d = length(w0 + u * sc - v * tcl);
        shadowRods *= mix(1.f, smoothstep(.007f, .018f, d), step(.02f, sc));
    }
    float3 col = light * (2.2 * lambert / (.35 + dist2 * .45)) * shadowRods + deep(.35, f) * .03;
    col = col * (1 - saturate(seenAlpha)) + seen;
    float2 lampScreen = lamp.xy * focal / lamp.z;
    col += paint(.92, f) * glow(length(c.uv - lampScreen), .025) * .7 + paint(.6, f) * glow(length(c.uv - lampScreen), .2) * .1;
    return col;
}
NATIVE_EFFECT(shadowModulator)
