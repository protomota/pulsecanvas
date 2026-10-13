// Original dancing fields: geometry, local choreography and analytic lighting.
// Optional forward zoom is supplied by PulseCanvas's continuous scene compositor.

float3 velvetSamba(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float3 color = deep(.5, f) * .18;
    for (int k = 0; k < 7; ++k) {
        float layer = float(k);
        float y = p.y + sin(p.x * (1.6 + layer * .12) + c.t * (.7 + layer * .08) + layer) * (.25 + c.b[k % 4] * .3);
        y += sin(p.x * 4 - c.t + layer * 1.7) * .09;
        float band = y - (layer - 3) * .42;
        float fabric = glow(band, .085);
        float stitches = pow(.5 + .5 * sin(p.x * 18 + layer * 3 + c.t), 4.f);
        color += paint(layer * .13 + p.x * .04, f) * fabric * (.8 + stitches * .4);
    }
    return color;
}

float3 neonCaper(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv * 2.2 / c.size;
    float2 id = floor(p), q = fract(p) - .5;
    float phase = id.x * 1.3 + id.y * 2.1;
    float band = c.b[int(abs(id.x - id.y)) % 4];
    q = rot(q, c.t * .7 + phase + band * sin(phase));
    float spokes = cos(atan2(q.y, q.x) * 6 + c.t * .4);
    float radius = .2 + .06 * spokes + .055 * sin(c.t * 1.5 + phase) + band * .08;
    float distance = length(q) - radius;
    float body = fill(distance, c.px * 2.2);
    float border = glow(distance, .025);
    float3 color = paint(phase * .09, f) * (body * .45 + border * 1.7);
    color += paint(.7 + id.x * .08, f) * .13 * (.5 + .5 * cos(q.x * 7 + q.y * 6));
    return color;
}

float3 carnivalPulse(Ctx c, constant NativeFrame &f) {
    float2 p = rot(c.uv / c.size, c.t * .12);
    float radius = length(p), angle = atan2(p.y, p.x);
    float3 color = paint(.3, f) * .08;
    for (int k = 0; k < 4; ++k) {
        float offset = float(k) * .65;
        float wave = sin(angle * (5 + float(k)) + c.t * (k % 2 == 0 ? .6 : -.5));
        float petal = radius - (.6 + offset + wave * (.16 + c.b[k] * .22));
        float fringe = .75 + .25 * sin(angle * 32 + c.t * 2 + offset);
        color += paint(angle / TAU + float(k) * .2, f) * glow(petal, .08) * fringe;
    }
    return color + paint(radius * .16, f) * .12;
}

float3 ribbonRumba(Ctx c, constant NativeFrame &f) {
    float2 p = rot(c.uv / c.size, .4);
    float3 color = deep(.1, f) * .16;
    for (int k = -3; k <= 3; ++k) {
        float z = float(k);
        float curve = sin(p.y * 1.7 + c.t * .8 + z) * .32 + cos(p.y * 3.2 - c.t * .5 + z * 2) * .1;
        float d = p.x - z * .52 - curve - c.b[(k + 4) % 4] * sin(p.y * 6 + z) * .18;
        float width = .11 + .045 * cos(p.y * 2 + c.t + z);
        float silk = 1 - smoothstep(width, width + c.px, abs(d));
        float shade = .4 + .6 * pow(max(0.f, 1 - abs(d) / max(.025f, width)), .7f);
        color += paint(z * .12 + p.y * .05 + .5, f) * silk * shade;
        color += paint(.85, f) * glow(abs(d) - width, .013) * .3;
    }
    return color;
}

float3 elasticJive(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv * 2 / c.size;
    float2 base = floor(p);
    float3 color = deep(.3, f) * .22;
    for (int y = -1; y <= 1; ++y) for (int x = -1; x <= 1; ++x) {
        float2 id = base + float2(x, y);
        float phase = dot(id, float2(1.6, 2.3));
        float band = c.b[int(abs(id.x + id.y)) % 4];
        float2 center = id + .5 + float2(sin(c.t * 1.4 + phase), cos(c.t * 1.1 - phase)) * (.1 + band * .14);
        float2 q = p - center;
        float ball = glow(length(q), .085 + band * .05);
        float links = glow(q.y - sin(q.x * PI + c.t + phase) * (.08 + band * .12), .025) * exp(-abs(q.x) * 3);
        links += glow(q.x - sin(q.y * PI - c.t + phase) * .08, .025) * exp(-abs(q.y) * 3);
        color += paint(phase * .07, f) * (ball * 1.4 + links * .45);
    }
    return color;
}

float3 liquidTango(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv * 1.8 / c.size;
    float2 base = floor(p);
    float field = 0, colorPhase = 0;
    for (int y = -1; y <= 1; ++y) for (int x = -1; x <= 1; ++x) {
        float2 id = base + float2(x, y);
        float phase = dot(id, float2(1.9, .8));
        float band = c.b[int(abs(id.x * 2 + id.y)) % 4];
        float2 q = rot(p - id - .5, c.t * .65 + phase);
        float orbit = .16 + .055 * sin(c.t * 1.7 + phase) + band * .09;
        float left = dot(q - float2(orbit, 0), q - float2(orbit, 0));
        float right = dot(q + float2(orbit, 0), q + float2(orbit, 0));
        float contribution = .024 / (.008 + left) + .024 / (.008 + right);
        field += contribution; colorPhase += phase * contribution;
    }
    float liquid = smoothstep(.55f, .9f, field);
    float rim = glow(field - .72, .15);
    float specular = pow(.5 + .5 * sin(field * 4 + p.x - p.y), 18.f) * liquid;
    return paint(colorPhase / max(.1f, field) * .1, f) * (.1 + liquid * .65) + paint(.85, f) * (rim * .8 + specular);
}

float3 prismPirouette(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv * 1.7 / c.size;
    float2 id = floor(p), q = fract(p) - .5;
    float phase = id.x * 1.7 + id.y * .8;
    float band = c.b[int(abs(id.x + id.y)) % 4];
    float3 color = paint(phase * .1, f) * .12;
    for (int k = 0; k < 3; ++k) {
        float2 r = rot(q, c.t * (.4 + float(k) * .15) + phase + float(k) * TAU / 3);
        float d = max(abs(r.x) * .866 + r.y * .5, -r.y) - (.17 + band * .06);
        float shard = fill(d, c.px * 1.7) * exp(-length(r) * 1.3);
        float crease = glow(r.x + r.y * .6, .018) * shard;
        color += paint(float(k) * .26 + phase * .06, f) * shard * .65 + paint(.9, f) * crease * .45;
    }
    return color;
}


float3 moltenMambo(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv * 2 / c.size;
    float carrier = p.x + sin(p.y * 1.7 + c.t * .6) * .8;
    carrier += sin(p.x * 1.3 - p.y * 1.2 - c.t * .5) * .5;
    carrier += c.b.x * sin(p.y * 5 + c.t) * .4 + c.b.z * sin(p.x * 7 - c.t) * .15;
    float wave = sin(carrier * 4 + p.y);
    float rim = pow(.5 + .5 * cos(carrier * 8 + sin(p.y * 3 + c.t)), 10.f);
    float shimmer = pow(.5 + .5 * sin(carrier * 3 - p.y * 2 + c.t * .3), 8.f);
    float3 color = paint(carrier * .08 + .45, f) * (.18 + (.5 + .5 * wave) * .65);
    return color + paint(.95, f) * (rim * .7 + shimmer * .4);
}


NATIVE_EFFECT(velvetSamba)
NATIVE_EFFECT(neonCaper)
NATIVE_EFFECT(carnivalPulse)
NATIVE_EFFECT(ribbonRumba)
NATIVE_EFFECT(elasticJive)
NATIVE_EFFECT(liquidTango)
NATIVE_EFFECT(prismPirouette)

NATIVE_EFFECT(moltenMambo)

