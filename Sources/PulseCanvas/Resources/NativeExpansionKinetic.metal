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
        h += (1.8 + 2.6 * c.b.x) * exp(-dot(d, d) / (radius * radius));
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
    float lean = 1 + .18 * c.uv.y / c.extent.y;
    float cell = .088 * c.size;
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
        float e = clamp(.25 + kin_pinRelief(base, ext, c, age, strength), 0.f, 5.f);
        // a pin standing proud of the pin behind it faces the light
        float facing = n == 0 ? .5f : saturate(.5f + .45f * (e - behind));
        behind = e;
        float2 tip = base + e * float2(kin_pinSlant, 1);
        float id = hash21(float2(column, j));
        float ds = sdSegment(q, base, tip), across = saturate(ds / .065);
        float shaft = 1 - smoothstep(.065 - px, .065 + px, ds);
        float along = saturate(dot(q - base, float2(kin_pinSlant, 1)) / max(e * 1.0648f, .01f));
        float3 shaftColor = paint(.2 + .06 * e, f) * (.12 + .1 * e * along) * (1.3 - across * across) + paint(.9, f) * .1 * e * along * kin_sq(1 - across);
        col = mix(col, shaftColor, shaft);
        float radius = .34 + .02 * e;
        float2 dv = (q - tip) / radius;
        float rr = length(dv);
        float head = 1 - smoothstep(1 - px / radius, 1 + px / radius, rr);
        float3 normal = float3(dv, sqrt(max(0.f, 1 - rr * rr)));
        float diffuse = saturate(dot(normal, light));
        float spec = pow(saturate(dot(normal, halfway)), 36.f);
        float glint = c.b.w * 5 * pow(.5 + .5 * sin(c.t * 2.1 + id * 70), 30.f);
        float3 headColor = paint(.06 + .18 * e + .04 * id, f) * (.2 + .85 * diffuse) * (.22 + .3 * e) * (.55 + .9 * facing);
        headColor += paint(.97, f) * spec * (.25 + .18 * e + glint) + paint(.95, f) * glint * .15;
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
    float attack = kin_attack(c, f), age = kin_age(attack), strength = kin_strength(attack, f);
    float focal = 1.45 * max(1.f, c.extent.y * .82) * c.size;
    const float pitch = .3, spacing = .72;
    float cs = cos(pitch), sn = sin(pitch);
    float2 uv = c.uv;
    float3 ray = float3(uv.x, uv.y * cs - focal * sn, uv.y * sn + focal * cs);
    float3 col = paint(.95, f) * .03 + paint(.75, f) * .05 * exp(-kin_sq(uv.y - .25) * 2);
    for (int k = 0; k < 16; ++k) {
        float z = 1.1 + float(k) * .8;
        float x = (floor(z / ray.z * uv.x / spacing) + .5) * spacing;
        float2 g = float2(x, z);
        float surface = kin_rainSurface(g, c, age, strength);
        float y = -2 + surface;
        float yc = y * cs + z * sn, zc = -y * sn + z * cs;
        float2 drop = float2(x, yc) * focal / zc;
        float ty = y + 7, tzc = max(-ty * sn + z * cs, .3f);
        float2 anchor = float2(x, ty * cs + z * sn) * focal / tzc;
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
        col += fade * (tint * (core * 1.3 + halo * .6 + strand * (.1 + .5 * lit)) + paint(.98, f) * (spec * .7 + sparkle * core));
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
    float attack = kin_attack(c, f), age = kin_age(attack), strength = kin_strength(attack, f);
    float2 ext = c.extent;
    float radius = .95 * (min(ext.x, ext.y) + .3 * (max(ext.x, ext.y) - min(ext.x, ext.y))) * c.size;
    float2 p = c.uv;
    float r = length(p), a = atan2(p.y, p.x), rn = r / radius;
    float t = c.t * .3 + c.travel * .1;
    float inside = 1 - smoothstep(radius - c.px * 2, radius + c.px * 2, r);
    float3 col = deep(.35, f) * (.18 + .25 * rn * rn) * inside + paint(.25, f) * .1 * exp(-max(r - radius, 0.f) * 1.6) * (1 - inside);
    col += paint(.3, f) * .1 * inside * fbm2(p * 2.5 + float2(t, -t * .7), 3);
    for (int k = 0; k < 9; ++k) {
        float fk = float(k), band = c.b[k & 3];
        float tilt = .55 + .45 * sin(t * .4 + fk * 2.3);
        float reach = radius * (.62 + .36 * tilt) * (.9 + .12 * band);
        float s = r / reach;
        float heading = fk * TAU / 9 + .7 * sin(t * (.5 + .07 * fk) + fk * 1.7) + t * .25;
        float wander = (.3 + .5 * band) * s * sin(rn * 3.1 - c.t * .9 + fk * 3.1) + .06 * s * sin(r * 14 - c.t * 4 + fk * 5);
        float fork = smoothstep(.4f, 1.f, s);
        float ending = 1 - smoothstep(.97f, 1.03f, s);
        float contact = 1 + 3 * exp(-kin_sq((s - 1) * 14));
        for (int j = -1; j <= 1; ++j) {
            float fj = float(j);
            float branch = heading + wander + fj * fork * (.2 + .06 * sin(t * 2 + fk + fj)) + fork * fork * .08 * sin(r * 24 - c.t * 6 + fk * 3 + fj * 2);
            float d = abs(kin_wrap(a - branch)) * r;
            float weight = j == 0 ? 1.f : fork;
            float width = radius * (.004 + .006 * band) * (1.4 - .7 * s) * (j == 0 ? 1.f : .7f);
            float core = exp(-d * d / (width * width)), halo = glow(d, width * 6);
            col += (paint(.92, f) * core + paint(.42 + .12 * fj + .1 * band, f) * halo * .35) * weight * ending * contact * (.45 + 1.4 * band);
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
    col += paint(.88, f) * (fill(r - electrode, c.px * 2) * (.7 + .3 * noise2(p * 40 / radius + c.t)) + glow(r, electrode * 1.4) * (.6 + 1.5 * strength));
    col += paint(.8, f) * glow(r - radius, radius * .006) * .5 + paint(.95, f) * .35 * exp(-kin_sq((r - radius * .9) * 30 / radius)) * exp(-kin_sq(kin_wrap(a - 2.2) * 3));
    return col;
}
NATIVE_EFFECT(plasmaGlobe)

// ---------------------------------------------------------------- 323 Jacob's Ladder
// Rows of Jacob's ladders at three depths: electric arcs bridge pairs of diverging rails,
// climb as they stretch and bow upward, flicker and break at the top while the next arc
// strikes at the base. Bass thickens the arcs, each band powers its own ladders, highs
// make the arcs crackle and every attack strikes a fresh arc at the base with sparks.
float3 kin_ladderLayer(float2 uv, float scale, float period, float lift, float layer, Ctx c, constant NativeFrame &f, float age, float strength) {
    float2 p = uv / scale;
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
        float crackle = (.008 + .022 * c.b.w) * (sin(xs * 7 + c.t * 17 + fj * 5) + .5 * sin(xs * 19 - c.t * 29 + seed * 30));
        float curve = ya + (bow + sway * xs + crackle * (.4 + phase)) * (1 - xs * xs);
        float d = abs(y - curve) / (1 + abs(2 * bow * xs / halfSpan) * .7);
        float spanMask = 1 - smoothstep(.98f, 1.04f, abs(xs));
        float width = (.026 + .05 * c.b.x) * (1 - .35 * phase);
        float flicker = .8 + .2 * sin(c.t * 41 + fj * 9 + seed * 40);
        float energy = life * flicker * (.5 + 1.6 * band) * (1.15 - .4 * phase);
        col += (paint(.97, f) * exp(-d * d / (width * width * .3)) * 1.5 + paint(.7, f) * exp(-d * d / (width * width * 2.5)) * .7 + paint(.55, f) * glow(d, width * 4) * .45) * spanMask * energy;
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
    col = mix(col, paint(.3, f) * (.25 + .35 * sheen) + paint(.95, f) * min(heat, 2.f) * .7 * sheen, rail);
    col += paint(.5, f) * glow(railD, .025) * (.05 + .25 * min(heat, 2.f));
    col += paint(.95, f) * glow(length(float2(abs(lx) - gap - spread * height, y - height)), .03) * .25;
    float post = sdBox2(float2(abs(lx) - gap, y + .12), float2(.03, .12));
    col = mix(col, paint(.2, f) * .3, fill(post, px));
    return col;
}

float3 jacobsLadder(Ctx c, constant NativeFrame &f) {
    float attack = kin_attack(c, f), age = kin_age(attack), strength = kin_strength(attack, f);
    float2 uv = c.uv / c.size;
    float ey = c.extent.y / c.size;
    float3 col = deep(.25, f) * .16 + paint(.35, f) * .08 * exp(-kin_sq(uv.y / ey + .3) * 1.5);
    col += kin_ladderLayer(uv, .3 * ey, 1.9, -.9, 0, c, f, age, strength) * .35;
    col += kin_ladderLayer(uv, .55 * ey, 2.6, -1.25, 1, c, f, age, strength) * .65;
    col += kin_ladderLayer(uv, ey, 5, -1.08, 2, c, f, age, strength);
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


// ---------------------------------------------------------------- 325 Prism Carousel
// Glass prisms ride a slowly turning carousel and spin on their own axes, each splitting a
// light beam into a broad spectral fan that sweeps across the dark wall above and glints
// in the glossy floor below. Each prism follows its own band (its fan widens and
// brightens), highs sparkle in the glass and every attack flicks the front prisms so
// their fans sweep across the wall.
float3 kin_prismFans(float2 p, float yC, float rx, float ry, float flick, Ctx c, constant NativeFrame &f) {
    float3 col = 0.f;
    float texture = .82 + .18 * noise2(p * 9);
    for (int k = 0; k < 6; ++k) {
        float fk = float(k), band = c.b[k & 3];
        float around = fk * TAU / 6 + c.t * .09 + c.travel * .06;
        float near = .5 - .5 * sin(around);
        float2 origin = float2(rx * cos(around), yC + ry * sin(around));
        float spin = c.t * (.2 + .045 * fk) + fk * 1.7 + band * .9 + flick * near * near;
        float heading = PI * .5 + 1.15 * sin(spin);
        float spread = .2 + .08 * sin(spin * 1.3 + fk) + .22 * band;
        float2 d = p - origin;
        float dist = length(d);
        float s = kin_wrap(atan2(d.y, d.x) - heading) / spread;
        float reach = .5 + .35 * near + .4 * band;
        float fan = smoothstep(1.f, .7f, abs(s)) * smoothstep(.12f, .45f, dist) * exp(-kin_sq(max(dist - reach, 0.f)) * 1.2);
        float edge = exp(-kin_sq((abs(s) - .85) * 9)) * .5;
        col += (paint(.5 + .5 * s, f) * (1 + edge) + paint(.97, f) * edge * .3) * fan * (.35 + 1.2 * band) * (.6 + .4 * near) * texture / (.6 + dist * .9);
    }
    return col;
}

float3 prismCarouselScene(Ctx c, constant NativeFrame &f) {
    float attack = kin_attack(c, f), age = kin_age(attack), strength = kin_strength(attack, f);
    float2 p = c.uv / c.size, ext = c.extent / c.size;
    float yC = -ext.y * .5, rx = min(ext.x * .66, 1.25f), ry = .2;
    float flick = 2.6 * strength * sin(age * PI) + .5 * strength;
    float3 col = paint(.95, f) * .03 + deep(.9, f) * .06 * (1 - smoothstep(-1.f, 1.f, p.y / ext.y));
    float floorY = yC - ry - .06;
    if (p.y > floorY) {
        col += kin_prismFans(p, yC, rx, ry, flick, c, f);
    } else {
        float2 m = float2(p.x + .015 * sin(p.y * 50 + c.t), 2 * floorY - p.y);
        col += kin_prismFans(m, yC, rx, ry, flick, c, f) * .3 * exp((p.y - floorY) * 1.5);
        col *= .8 + .2 * sin(p.y * 90 / ext.y);
    }
    // the carousel: a glowing rim, spokes and the turning prisms
    float2 e = (p - float2(0, yC)) / float2(rx, ry);
    float rim = abs(length(e) - 1) * ry;
    col += paint(.85, f) * glow(rim, .005) * .5 + paint(.3, f) * glow(rim, .04) * .12;
    float hub = length(e);
    float spokes = abs(sin((atan2(e.y, e.x) - c.t * .09) * 3)) * hub * ry;
    col += paint(.7, f) * glow(spokes, .003) * .25 * step(hub, 1.f);
    for (int k = 0; k < 6; ++k) {
        float fk = float(k), band = c.b[k & 3];
        float around = fk * TAU / 6 + c.t * .09 + c.travel * .06;
        float near = .5 - .5 * sin(around);
        float2 origin = float2(rx * cos(around), yC + ry * sin(around));
        float spin = c.t * (.2 + .045 * fk) + fk * 1.7 + band * .9 + flick * near * near;
        float scale = .085 * (.7 + .45 * near);
        float2 q = p - origin - float2(0, scale * .55);
        float2 face = float2(q.x / max(abs(cos(spin)), .25f), q.y) / scale;
        float tri = max(abs(face.x) * .866 + face.y * .5, -face.y) - .5;
        float body = fill(tri * scale, c.px * 1.5);
        float glint = c.b.w * 2.5 * pow(.5 + .5 * sin(c.t * 3 + fk * 11), 12.f);
        float3 glass = paint(.5 + .35 * face.x, f) * (.35 + .6 * band) + paint(.97, f) * (glint + .5 * smoothstep(.15f, -.2f, face.x * sin(spin) + face.y * .4));
        col = mix(col, glass, body * .85);
        col += paint(.95, f) * glow(tri * scale, .006) * (.4 + .7 * band + strength * 3 * near * near);
    }
    return col;
}
// The reviewed look, with a faint palette floor so tall frames stay covered when zoomed out.
float3 prismCarousel(Ctx c, constant NativeFrame &f) { return max(prismCarouselScene(c, f), paint(.9, f) * .06); }
NATIVE_EFFECT(prismCarousel)

// ---------------------------------------------------------------- 326 Cone Splash
// A low close-up across a vibrating membrane covered in pools of coloured paint. Paint
// leaps off it in crowns with lobed rims, flung droplets and a central jet that rises as
// each crown collapses, while ripples run through the wet paint. Each paint colour rides
// its own band (its splashes leap higher and its pools pulse), bass flexes the membrane
// and every attack throws a large crown up from the front of the membrane.
constant float kin_splashEye = .55;

float3 kin_splashCrown(float2 uv, float horizon, float focal, float2 site, float age, float scale, float hue, float seed, Ctx c, constant NativeFrame &f) {
    float3 col = 0.f;
    float rc = scale * (.1 + .5 * sqrt(age));
    float crown = scale * .9 * sin(PI * min(age * 1.6 + .12, 1.f)) * (1 - .35 * age);
    float across = (uv.x * site.y / focal - site.x) / rc;
    if (abs(across) < 1.02) {
        float sx = sqrt(max(0.f, 1 - across * across));
        for (int side = 0; side < 2; ++side) {
            float facing = side == 0 ? 1.f : -1.f;
            float z = site.y + facing * rc * sx;
            float theta = atan2(facing * sx, across);
            float rim = crown * (.5 + .5 * pow(.5f + .5f * cos(9 * theta + seed * 20), 3.f));
            float vb = horizon - kin_splashEye * focal / z, vt = horizon + (rim - kin_splashEye) * focal / z;
            float sheet = smoothstep(vb - c.px, vb + c.px, uv.y) * (1 - smoothstep(vt - c.px * 2, vt + c.px, uv.y));
            float height = saturate((uv.y - vb) / max(vt - vb, 1e-4f));
            float3 tint = paint(hue, f) * (.35 + .55 * (.5 + .5 * across) + .4 * height) * (side == 0 ? .55f : 1.f);
            col = mix(col, tint, sheet * (side == 0 ? .7f : .9f));
            col += paint(hue + .1, f) * glow(uv.y - vt, .004 * focal / z) * .6 * step(vb, uv.y);
        }
    }
    float flight = max(age - .3, 0.f);
    float rd = rc + flight * scale * .9;
    float lift = crown * .9 + flight * scale * 2.4 - flight * flight * scale * 4;
    float across2 = (uv.x * site.y / focal - site.x) / rd;
    if (flight > 0 && abs(across2) < 1.1 && lift > -.1) {
        for (int side = 0; side < 2; ++side) {
            float facing = side == 0 ? 1.f : -1.f;
            float theta = atan2(facing * sqrt(max(0.f, 1 - across2 * across2)), across2);
            float lobe = round(theta * 9 / TAU + seed * 20 / TAU) - seed * 20 / TAU;
            float a = lobe * TAU / 9;
            float3 drop = float3(site.x + rd * cos(a), lift, site.y + rd * sin(a));
            float2 s = float2(drop.x, drop.y - kin_splashEye) * focal / drop.z + float2(0, horizon);
            float r = scale * .045 * focal / drop.z;
            float d = length(uv - s);
            col += paint(hue, f) * (smoothstep(r + c.px, r * .5, d) * .9 + glow(d, r * 1.5) * .25) + paint(.95, f) * exp(-length_squared(uv - s - r * float2(-.3, .3)) / kin_sq(r * .3)) * .5;
        }
    }
    float jet = max(age - .45, 0.f) / .55;
    if (jet > 0) {
        float hj = scale * 1.7 * sin(PI * jet);
        float2 b = float2(site.x, -kin_splashEye) * focal / site.y + float2(0, horizon);
        float2 tp = float2(site.x, hj - kin_splashEye) * focal / site.y + float2(0, horizon);
        float width = scale * .05 * focal / site.y;
        float d = sdSegment(uv, b, tp);
        col += paint(hue + .05, f) * (smoothstep(width + c.px, width * .3, d) * .9 + glow(d, width) * .2);
        float dt = length(uv - tp - float2(0, width * 1.6));
        col += paint(hue, f) * smoothstep(width * 1.6 + c.px, width * .6, dt) + paint(.95, f) * glow(dt, width * .5) * .3;
    }
    return col;
}

float3 coneSplashScene(Ctx c, constant NativeFrame &f) {
    float attack = kin_attack(c, f), age = kin_age(attack), strength = kin_strength(attack, f);
    float2 uv = c.uv;
    float focal = 1.5 * c.size * max(1.f, c.extent.y * .8);
    float horizon = c.extent.y * .22;
    // backdrop: dark studio with soft coloured light pools above the membrane's rim
    float3 col = paint(.95, f) * .025;
    for (int k = 0; k < 4; ++k) {
        float2 o = float2(sin(c.t * .05 + float(k) * 1.9) * c.extent.x * .8, horizon + .35 + .35 * sin(float(k) * 2.3 + c.t * .04));
        col += paint(float(k) * .25 + .05, f) * .06 * exp(-length_squared(uv - o) * 2.2);
    }
    float2 sites[6]; float ages[6], scales[6], hues[6], seeds[6];
    for (int k = 0; k < 5; ++k) {
        float clock = c.t * .1 + float(k) / 5;
        float id = floor(clock);
        float3 h = hash33(float3(id, float(k), 3.7));
        int paintIndex = int(h.z * 3.99);
        sites[k] = float2((h.x * 2 - 1) * .9 * c.extent.x, 1.7 + h.y * 2.6);
        ages[k] = fract(clock);
        scales[k] = (.8 + .35 * h.y) * (.65 + 1.2 * c.b[paintIndex]);
        hues[k] = float(paintIndex) * .25 + .05;
        seeds[k] = h.x + h.y;
    }
    sites[5] = float2(sin(c.t * .05) * .6 * c.extent.x, 1.8);
    ages[5] = age; scales[5] = strength * 2.4; hues[5] = .8; seeds[5] = .3;
    if (uv.y < horizon) {
        float z = kin_splashEye * focal / (horizon - uv.y);
        float2 g = float2(uv.x * z / focal, z);
        float2 m = g * .5 + float2(0, c.travel * .08);
        m += .7 * float2(fbm2(m * .7 + float2(c.t * .02, 0), 2), fbm2(m * .7 + 5.2, 2));
        float marble = noise2(m * 1.4) * 4;
        int paintIndex = min(int(marble), 3);
        float seam = smoothstep(0.f, .12f, .5f - abs(fract(marble) - .5f));
        float band = c.b[paintIndex];
        float ripple = 0;
        for (int k = 0; k < 6; ++k) {
            float r = length(g - sites[k]);
            float front = scales[k] * (.2 + 2.2 * ages[k]);
            ripple += sin((r - front) * 16) * exp(-kin_sq(r - front) * 5) * (1 - ages[k]) * min(scales[k], 1.2f);
        }
        ripple += c.b.x * .7 * sin(length(g - float2(0, 4)) * 5 - c.t * 3) + band * .5 * sin(g.x * 3 + g.y * 2 - c.t * 2);
        float fresnel = smoothstep(1.f, 7.f, z);
        float sheen = pow(saturate(.55 + .45 * sin(g.x * 1.3 + ripple * 1.8 + c.t * .2)), 5.f) * (.25 + .75 * fresnel);
        float fade = exp(-z * (.05 + .08 * c.fog));
        float3 tint = paint(float(paintIndex) * .25 + .05, f);
        float3 surface = (tint * seam * (.07 + .2 * band + .05 * ripple) + tint * sheen * seam * (.6 + .6 * band) + paint(.97, f) * pow(sheen, 4.f) * .35) * fade;
        col = mix(col, surface, smoothstep(0.f, .015f, horizon - uv.y));
    }
    for (int k = 0; k < 6; ++k) {
        if (scales[k] < .01) continue;
        col += kin_splashCrown(uv, horizon, focal, sites[k], ages[k], scales[k], hues[k], seeds[k], c, f) * (k == 5 ? 1.4f : 1.f);
    }
    return col;
}
// The reviewed look, with a faint palette floor so tall frames stay covered when zoomed out.
float3 coneSplash(Ctx c, constant NativeFrame &f) { return max(coneSplashScene(c, f), paint(.9, f) * .06); }
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
    float attack = kin_attack(c, f), age = kin_age(attack), strength = kin_strength(attack, f);
    float2 p = c.uv / c.size, ext = c.extent / c.size;
    float flow = 1 + .35 * c.b.x;
    const int count = 3;
    float2 centres[count] = {float2(-ext.x * .55, ext.y * .28), float2(ext.x * .3, ext.y * .5), float2(-ext.x * .05, -ext.y * .4)};
    float radii[count] = {.24, .13, .12};
    float shed[count] = {.5 + 1.2 * c.b.y, .4 + 1.2 * c.b.z, .25 + .6 * c.b.z};
    // smoke wobble in the wakes
    float2 q = p;
    for (int o = 0; o < count; ++o) {
        float behind = smoothstep(0.f, .4f, p.x - centres[o].x) * exp(-kin_sq((p.y - centres[o].y) / (radii[o] * 3)));
        q += behind * (.025 + .05 * c.b.w) * float2(noise2(p * 6 - float2(c.t * 2, 0)) - .5, noise2(p * 6 + 7.3 - float2(c.t * 2, 0)) - .5);
    }
    float psi = q.y * flow, along = q.x;
    for (int o = 0; o < count; ++o) {
        float2 d = q - centres[o];
        float r2 = max(dot(d, d), 1e-4f), R2 = radii[o] * radii[o];
        if (o == 2) { d = rot(d, .18); d.x *= .32; r2 = max(dot(d, d), 1e-4f); }
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
    psi += kin_windVortex(q, centres[2] + float2(-.03, .02), .12 + .25 * c.b.z, .05);
    float2 kickAt = centres[0] + float2(radii[0] * (1.3 + age * 4), radii[0] * .4);
    psi += kin_windVortex(q, kickAt, strength * 1.4 * radii[0], radii[0] * .4);
    float spacing = .075;
    float lines = psi / spacing, index = floor(lines + .5);
    float aa = max(fwidth(lines), 1e-4f);
    float offset = abs(lines - index);
    float core = 1 - smoothstep(.06f, .06f + aa * 1.5f, offset);
    float halo = exp(-offset * offset * 18);
    float dash = .55 + .45 * sin(along * 7 - c.t * 2.2 + index * 1.7);
    float sheet = .5 + .5 * cos(TAU * lines);
    float hue = fract(index * .137) * .7 + .15;
    float3 col = deep(.3, f) * .1 + paint(hue, f) * (.06 + .1 * sheet) + paint(hue, f) * (core * (.5 + .5 * dash) + halo * .35 * dash) * (.8 + .4 * c.b.x);
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
// A kinetic light sculpture in an empty room: perforated metal screens, tinted glass
// panels and rods orbit and spin around a bare lamp, and the room's walls and floor are
// swept by their moving projections: magnified grids of light spots, coloured panes and
// rod shadows. Each band turns its own screen and tints its own light, and every attack
// swings an extra perforated screen through the beam.
float kin_modulatorPattern(float2 l, int kind, float t) {
    if (kind == 0) { float4 h = hexCell(l * 14); return smoothstep(.3f, .24f, length(h.xy)); }
    if (kind == 1) return smoothstep(.15f, .3f, abs(fract(length(l) * 9 - t * .2) - .5));
    if (kind == 2) { float2 g = abs(fract(l * 6) - .5); return smoothstep(.32f, .28f, max(g.x, g.y)); }
    return smoothstep(.2f, .3f, abs(fract(atan2(l.y, l.x) * 1.91 + length(l) * 4) - .5));
}

float3 shadowModulator(Ctx c, constant NativeFrame &f) {
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
    float3 lamp = float3(0, .35, 2.2);
    float t = c.t * .2 + c.travel * .07;
    float3 toLamp = lamp - hit;
    float dist2 = dot(toLamp, toLamp);
    float lambert = saturate(dot(normal, toLamp) * rsqrt(dist2));
    float3 transmit = float3(1);
    float3 seen = float3(0); float seenAlpha = 0;
    for (int k = 0; k < 5; ++k) {
        float fk = float(k);
        float band = k < 4 ? c.b[k] : 0.f;
        float orbit = k < 4 ? fk * TAU / 4 + t * (.6 + .15 * fk) : -1.9 + .6 * sin(t * .7) + 2.6 * strength * (1 + sin(age * PI));
        float reach = k < 4 ? .38 + .07 * fk : .3;
        float3 centre = lamp + float3(reach * cos(orbit), .3 * sin(fk * 1.7 + t * .5), reach * sin(orbit));
        float spin = orbit + t * (1.1 + .3 * fk) * (k & 1 ? -1.f : 1.f) + band * 1.4;
        float lean = .35 * sin(t * .8 + fk * 2.1);
        float3 n = normalize(float3(cos(spin) * cos(lean), sin(lean), sin(spin) * cos(lean)));
        float3 e1 = normalize(cross(n, float3(0, 1, 0))), e2 = cross(e1, n);
        float size = k < 4 ? .2 + .03 * fk : .17;
        int kind = k < 4 ? k : 0;
        float3 tint = k == 1 || k == 3 ? paint(.15 + .3 * fk, f) * (.8 + .8 * band) : float3(1);
        // shadow on the room
        float3 ray = hit - lamp;
        float denom = dot(ray, n);
        float s = dot(centre - lamp, n) / (abs(denom) > 1e-4 ? denom : 1e-4);
        if (s > 0 && s < 1) {
            float3 at = lamp + ray * s - centre;
            float2 l = float2(dot(at, e1), dot(at, e2)) / size;
            float blur = .03 + .05 * (1 - s);
            float inside = smoothstep(1 + blur, 1 - blur, length(l));
            float open = kin_modulatorPattern(l, kind, c.t);
            float3 pass = k == 1 || k == 3 ? mix(tint, float3(1.4), open) : float3(open * 1.2);
            transmit *= mix(float3(1), pass, inside);
        }
        // the sculpture itself as seen by the camera
        float sv = dot(centre, n) / dot(dir, n);
        if (sv > 0 && sv < tw) {
            float3 at = dir * sv - centre;
            float2 l = float2(dot(at, e1), dot(at, e2)) / size;
            float inside = smoothstep(1.02f, .98f, length(l));
            float open = kin_modulatorPattern(l, kind, c.t);
            float lit = abs(dot(n, normalize(lamp - dir * sv)));
            float3 face = (k == 1 || k == 3 ? tint * .5 : paint(.3, f) * .25) * (.4 + lit) + paint(.85, f) * .3 * pow(lit, 8.f);
            float cover = inside * (1 - open * .85) * (1 - seenAlpha);
            seen += face * cover + paint(.9, f) * glow(abs(length(l) - 1) * size, .004) * .3;
            seenAlpha += cover;
        }
    }
    // rods sweeping around the lamp
    float shadowRods = 1;
    for (int k = 0; k < 3; ++k) {
        float fk = float(k);
        float around = fk * TAU / 3 - t * (.8 + .2 * c.b[(k + 1) & 3]);
        float3 a = lamp + float3(.6 * cos(around), -.55, .6 * sin(around));
        float3 b = a + float3(.25 * sin(t + fk), 1.2, .25 * cos(t * .7 + fk));
        float3 u = hit - lamp, v = b - a, w0 = lamp - a;
        float uu = dot(u, u), uv = dot(u, v), vv = dot(v, v), uw = dot(u, w0), vw = dot(v, w0);
        float den = max(uu * vv - uv * uv, 1e-5f);
        float sc = saturate((uv * vw - vv * uw) / den), tcl = saturate((uu * vw - uv * uw) / den);
        float d = length(w0 + u * sc - v * tcl);
        float r = .018 * (1 + 5 * (1 - sc));
        shadowRods *= mix(1.f, smoothstep(r * .5, r * 1.5, d), step(.05f, sc));
    }
    float3 lampColor = paint(.7, f);
    float3 col = lampColor * (1.6 * lambert / (.4 + dist2 * .35)) * transmit * shadowRods + deep(.4, f) * .05;
    col = mix(col, seen, saturate(seenAlpha));
    float2 lampScreen = lamp.xy * focal / lamp.z;
    col += paint(.9, f) * glow(length(c.uv - lampScreen), .03) * .8;
    return col;
}
NATIVE_EFFECT(shadowModulator)
