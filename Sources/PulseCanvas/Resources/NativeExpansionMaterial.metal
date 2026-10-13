// Original PulseCanvas designs 340–349. Full-frame materials in motion: liquids, films and crafts with vivid color, in the spirit of the kept Flow designs (Silk Cascade, Ink Bloom, Oil Marble, Chrome Metaballs) but with new materials.
// Every design is Form scale: the material itself moves with procedural time and the music;
// audio terms are zero at zero Chaos.

// ---------------------------------------------------------------- shared helpers
// A wandering point for attack events: a smooth path of the music clock, so each attack
// lands somewhere new without anything jumping between frames.
float2 mat_eventPoint(Ctx c, float seed, float reach) {
    return float2(sin(c.m * 2.3 + seed * 4.1), sin(c.m * 1.7 + seed * 2.7 + 1.3)) * c.extent / c.size * reach;
}
// Picks a changing subset of elements for each attack; continuous in the music clock.
float mat_pick(float seed, Ctx c) {
    float s = .5 + .5 * sin(c.m * 3.7 + seed * TAU);
    return s * s * s;
}

// ---------------------------------------------------------------- 340 Acrylic Cells
// A poured acrylic skin: opaque streams of saturated paint and dark ground run across the
// canvas, cells open in the cell-forming streams (a bright core, a coloured ring and a dark
// wall) and fine lacing webs the light layers. Bass opens the cells, low-mids push the pour,
// high-mids thicken the lacing, highs freckle micro-cells; attacks open a bloom of fresh cells.
float3 acr_layer(float index, constant NativeFrame &f) {
    float kind = hash11(index * 2.71 + 8.3);
    // Each paint is one tube colour: a palette stop, never a muddy in-between.
    float hue = floor(hash11(index * 1.37 + 2.9) * 4.99) * .25;
    if (kind < .3) return deep(hue + .5, f) * .07;
    return paint(hue, f) * (.6 + .3 * kind);
}
float3 acrylicCells(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float t = c.t;
    float2 base = p * .8 + float2(t * .03 + c.travel * .06, -t * .012);
    float2 warp = float2(fbm2(base * .9 + float2(0, t * .02), 3), fbm2(base * .9 + float2(4.3, 1.7 - t * .018), 3));
    float2 q = base + (warp - .5) * (1.45 + c.b.y * 1.5);
    // Stacked pour layers of varying width run along the flow.
    float s = q.y * 1.1 + q.x * .42 + .3 * sin(q.x * 1.2 + t * .04);
    float layer = s * 2.7 + .3 * sin(s * 1.9 + 1.3);
    float index = floor(layer), fr = fract(layer);
    // Layer edges stay a constant few pixels wide however far the pour stretches them.
    float aa = clamp(fwidth(layer) * 1.2, 1e-4f, .3f);
    float3 color = mix(acr_layer(index, f), acr_layer(index + 1, f), smoothstep(1 - aa, 1.f, fr));
    color *= .82 + .25 * sin(fr * PI);
    // Cells: voronoi stretched along the flow, open only in the cell-forming streams.
    float2 along = normalize(float2(1.1, -.42));
    // Cells ride the pour but stay round, only a little stretched along it.
    float2 cp = base + (warp - .5) * (.5 + c.b.y * .5);
    float2 cq = float2(dot(cp, along) * 2.6, dot(cp, float2(-along.y, along.x)) * 3.4);
    float4 v = voronoi(cq, .85, t * .12);
    float2 seed = hash22(v.zw);
    float region = smoothstep(.3f, .55f, noise2(cp * .9 + 11.3));
    float2 event = mat_eventPoint(c, .3, .6);
    float near = exp(-dot(p - event, p - event) * 2.4);
    float pick = mat_pick(seed.x, c);
    float radius = (.1 + .24 * seed.y) * region * (.65 + c.b.x * 1.3);
    radius += (.14 + .14 * seed.y) * c.hit * (pick * .5 + near * 1.8);
    radius = min(radius, .46f);
    float present = smoothstep(0.f, .04f, radius);
    float aac = c.px / c.size * 4 * 1.5;
    float3 core = paint(floor(seed.x * 4.99) * .25, f) * 1.05;
    float3 ring = paint(floor(seed.y * 4.99) * .25 + .5, f) * .8;
    float3 wall = deep(seed.x, f) * .05;
    float u = v.x;
    float3 cell = mix(core, ring, smoothstep(radius * .5 - aac, radius * .5 + aac, u));
    cell = mix(cell, wall, smoothstep(radius * .8 - aac, radius * .8 + aac, u));
    float2 local = cq - v.zw - .5 - .425 * sin(t * .12 + seed * TAU);
    float2 lit = local + float2(.32, -.32) * radius;
    cell += paint(.5, f) * (1 - smoothstep(radius * .1 - aac, radius * .1 + aac, length(lit))) * .45;
    float inside = (1 - smoothstep(radius - aac, radius + aac, u)) * present;
    float rim = exp(-abs(u - radius) / .02) * present * (1 - inside);
    color = mix(color, cell, inside);
    color += paint(.5, f) * rim * (.25 + c.hit * (pick + near) * 1.4);
    // Lacing and micro-cells on a finer web.
    float4 web = voronoi(cq * 2.3 + 5.1, .85, t * .1);
    float lace = 1 - smoothstep(.01f, .035f + c.b.z * .06f, web.y - web.x);
    float laceRegion = smoothstep(.45f, .7f, noise2(q * 1.1 + 4.7)) * (1 - inside);
    color = mix(color, paint(.5, f) * 1.1, lace * laceRegion * (.35 + c.b.z * 1.1));
    float freckle = 1 - smoothstep(.04 + .12 * c.b.w, .07 + .12 * c.b.w, web.x);
    color = mix(color, paint(hash21(web.zw), f) * .9, freckle * step(.6f, hash21(web.zw + 3.7)) * smoothstep(.02f, .1f, c.b.w) * (1 - inside) * region);
    // Wet gloss: a slow window reflection across the pour.
    float gloss = exp(-pow(dot(p, float2(.6, .8)) - 1.3 * sin(t * .045), 2.f) * 4);
    color += paint(.5, f) * gloss * .07;
    return color * .72;
}
NATIVE_EFFECT(acrylicCells)

// ---------------------------------------------------------------- 341 Molten Glass
// Thick canes of molten glass are pulled across a dark furnace. Each cane has an
// incandescent core, a cooling glossy skin and twisted threads inside. Bass stretches the
// canes and necks them thin, low-mids sway them, high-mids light the threads, highs glint
// trapped seeds; attacks fold a kink into the canes and flare it white-hot.
float3 moltenGlass(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float2 ext = c.extent / c.size;
    float t = c.t;
    float stretch = 1 + c.b.x * .9;
    float3 color = deep(.03, f) * .04 + paint(.03, f) * .06 * fbm2(p * 1.4 + float2(t * .02, -t * .05), 3);
    float2 event = mat_eventPoint(c, 1.7, .7);
    const int count = 5;
    for (int k = 0; k < count; ++k) {
        float fk = float(k);
        float seed = hash11(fk * 3.71 + .37);
        float side = (k & 1) == 0 ? 1. : -1.;
        float angle = side * (.12 + .3 * seed) + .1 * sin(t * .04 + fk * 1.3);
        float2 center = float2(.25 * sin(fk * 2.1), (fk - 2) / 2 * ext.y * .78);
        float2 q = rot(p - center, -angle);
        float2 eq = rot(event - center, -angle);
        float pick = mat_pick(seed, c);
        float level = c.b[k % 4];
        float x = q.x / stretch;
        float amp = .08 + .06 * seed + c.b.y * .16;
        float frequency = 1.1 + .9 * seed;
        float phase = t * (.16 + .08 * seed) + seed * 9;
        float yc = amp * sin(x * frequency + phase) + .05 * sin(x * 2.7 - phase * 1.3);
        float slope = (amp * frequency * cos(x * frequency + phase) + .135 * cos(x * 2.7 - phase * 1.3)) / stretch;
        float kink = exp(-pow((q.x - eq.x) / .4, 2.f)) * c.hit * (.45 + pick);
        yc += kink * .35 * sin((q.x - eq.x) * 5);
        float neckAt = sin(t * .05 + seed * 6) * ext.x * .6;
        float neck = exp(-pow((q.x - neckAt) / (.55 * stretch), 2.f)) * (.15 + c.b.x * .5);
        float width = (.13 + .07 * seed) * (1 - neck);
        float u = (q.y - yc) / sqrt(1 + slope * slope) / width;
        float aa = c.px / c.size / width * 1.5;
        float body = 1 - smoothstep(1 - aa, 1 + aa, abs(u));
        float uc = clamp(u, -1.f, 1.f);
        float nz = sqrt(max(0.f, 1 - uc * uc));
        float heat = (.6 + .3 * sin(x * .8 - t * .1 + seed * 7) + .35 * level) * (1 - neck * .6) + kink * 2.2;
        // Glowing glass: emission peaks inside the cane, so there is no dark side.
        float emission = heat * (.3 + .7 * nz * nz);
        float twist = asin(uc) * 2 + x * (7 + 4 * seed) * side - t * (.35 + seed * .3);
        float strand = smoothstep(.35f, .75f, sin(twist)) * nz;
        float3 glass = paint(.12 + .72 * min(emission, 1.2f), f) * min(emission, 1.3f) * 1.05;
        glass += paint(.88, f) * strand * (.08 + c.b.z * .9) * heat;
        float3 n = float3(0, uc, nz);
        float specular = pow(max(0.f, dot(n, normalize(float3(0, .58, .81)))), 220.f);
        glass += paint(.95, f) * specular * 1.3;
        glass += paint(.35, f) * pow(1 - nz, 8.f) * .35 * heat;
        // Trapped seeds (tiny bubbles) glint with the highs.
        float segment = floor(x * 2.5 + seed * 17);
        float2 bubbleSeed = hash22(float2(segment, fk));
        float2 bubble = float2((fract(x * 2.5 + seed * 17) - .2 - .6 * bubbleSeed.x) * .4 * stretch, (u - (bubbleSeed.y - .5) * 1.2) * width);
        glass += paint(.95, f) * glow(length(bubble) - .01, .005) * (.04 + c.b.w * 2.4) * nz * sin(PI * fract(x * 2.5 + seed * 17));
        // Translucent: canes behind still glow through, dimmed by the glass in front.
        float outside = max(abs(u) - 1, 0.f) * width;
        color += paint(.2 + .3 * min(heat, 1.f), f) * exp(-outside * 10) * .14 * heat * (1 - body);
        color = color * (1 - .6 * body) + glass * body;
    }
    return color;
}
NATIVE_EFFECT(moltenGlass)

// ---------------------------------------------------------------- 342 Liquid Crystal
// A nematic film between crossed polarisers: interference colours set by the film's
// retardation, dark brushes radiating from drifting defects. Each band twists the director
// in its own region; attacks tear a defect pair out of the uniform field.
float lc_pair(float2 p, float2 center, float2 offset) {
    // +1/2 at center + offset and -1/2 at center - offset. Exactly zero when the offset is
    // zero, so pairs can be born and annihilate continuously.
    float2 a = p - center - offset, b = p - center + offset;
    return .5 * atan2(a.y * b.x - a.x * b.y, a.x * b.x + a.y * b.y);
}
float3 liquidCrystal(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float2 ext = c.extent / c.size;
    float t = c.t;
    float theta = 1.3 * fbm2(p * .8 + float2(t * .02, -t * .015), 3) + .3 * sin(p.x * .8 + t * .06) + .25 * cos(p.y * 1.1 - t * .05);
    theta += .22 * noise2(p * 4 + float2(t * .05, 0));
    bool wide = ext.x >= ext.y;
    int columns = wide ? 4 : 2, rows = wide ? 2 : 4;
    for (int i = 0; i < 8; ++i) {
        float fi = float(i);
        int column = i % columns, row = i / columns;
        float2 seed = hash22(float2(fi, 3.1));
        float2 cell = float2((float(column) + .5) / float(columns), (float(row) + .5) / float(rows)) * 2 - 1;
        float2 at = cell * ext * .85 + (seed - .5) * .5 + float2(sin(t * (.05 + seed.x * .04) + fi * 2.1), cos(t * (.045 + seed.y * .04) + fi * 1.3)) * .3;
        float charge = ((column + row) & 1) == 0 ? .5 : -.5;
        if (i == 1) charge = 1;
        if (i == 6) charge = -1;
        theta += charge * atan2(p.y - at.y, p.x - at.x);
    }
    for (int k = 0; k < 4; ++k) {
        float angle = float(k) * 1.5708 + .7 + t * .03;
        float2 at = float2(cos(angle), sin(angle)) * ext * .55;
        theta += c.b[k] * 1.5 * exp(-dot(p - at, p - at) * 1.1);
    }
    float flare = 0;
    for (int j = 0; j < 3; ++j) {
        float fj = float(j);
        float pick = mat_pick(fj * .31 + .1, c);
        float2 at = mat_eventPoint(c, fj * 2.3, .6);
        float separation = (c.hit * .35 + c.e * .08) * (.3 + pick);
        float2 direction = float2(cos(fj * 2.1 + t * .1), sin(fj * 2.1 + t * .1));
        theta += lc_pair(p, at, direction * separation);
        flare += c.hit * (.3 + pick) * exp(-dot(p - at, p - at) * 4);
    }
    float polarizer = t * .04;
    float brush = sin(2 * (theta - polarizer));
    float intensity = brush * brush;
    float retardation = 1 + 5.5 * fbm2(p * .6 + float2(t * .015, 3.7), 3) + .5 * length(p) + .12 * sin(t * .07);
    float3 color = filmColor(retardation, f) * (.02 + .9 * pow(intensity, 1.3f));
    color += paint(.9, f) * pow(intensity, 12.f) * .1;
    color += paint(.85, f) * flare * intensity * .9;
    return color;
}
NATIVE_EFFECT(liquidCrystal)

// ---------------------------------------------------------------- 343 Incense Drift
// Ribbons of incense smoke rise from below the frame, twist as thin lit sheets and curl
// into loops on rising eddies before melting into a lit haze. Each plume follows its band,
// bass thickens them all, low-mids spin the eddies; attacks curl a new loop.
float3 incenseDrift(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float2 ext = c.extent / c.size;
    float t = c.t;
    float h = clamp(p.y / ext.y * .5 + .5, 0.f, 1.f);
    float2 q = p + curl2(p * 1.1 + float2(0, -t * .12)) * (.015 + .09 * h * h);
    for (int j = 0; j < 4; ++j) {
        float fj = float(j);
        float cycle = t * .022 + fj * .25;
        float life = fract(cycle);
        float2 seed = hash22(float2(floor(cycle), fj));
        float2 at = float2((seed.x - .5) * 1.7 * ext.x, mix(-.4, 1.1, life) * ext.y);
        float spin = (1.6 + c.b.y * 1.6) * sin(PI * life) * (seed.y < .5 ? -1. : 1.);
        float2 d = q - at;
        q = at + rot(d, spin * exp(-dot(d, d) * 5));
    }
    float2 event = mat_eventPoint(c, .7, .55);
    float2 de = q - event;
    q = event + rot(de, c.hit * 3.4 * exp(-dot(de, de) * 7));
    float boost = 1 + c.hit * 2.5 * exp(-dot(p - event, p - event) * 6);
    float haze = fbm2(q * 1.3 + float2(0, -t * .04), 4);
    // A dark room: a little light pools low where the sticks burn, and the haze above
    // holds a soft glow, so the lit ribbons stand out against depth rather than a flat wash.
    float pool = exp(-pow(h + .1f, 2.f) * 4) * (.6 + .4 * sin(p.x * 1.3 + t * .03));
    float3 color = deep(.08 + h * .1, f) * (.1 + .12 * pool) + paint(.25 + haze * .35, f) * haze * haze * (.05 + .32 * h);
    for (int k = 0; k < 4; ++k) {
        float fk = float(k);
        float x0 = ((fk + .5) / 4 * 2 - 1) * ext.x * .82 + .12 * sin(t * .05 + fk * 2);
        float sway = (.03 + .25 * h * h) * sin(q.y * 2.1 - t * .35 + fk * 1.9) + .1 * h * sin(q.y * 4.3 - t * .6 + fk);
        float dx = q.x - x0 - sway;
        float level = c.b[k];
        float width = (.012 + .11 * h * h) * (1 + c.b.x * 1.4);
        float twist = q.y * 5 - t * .8 + fk * 1.7;
        float strands = 0;
        for (int i = 0; i < 3; ++i) strands += glow(dx - width * sin(twist + float(i) * 2.094), .0035 + .012 * h);
        float sheet = exp(-dx * dx / (width * width * 1.2 + 1e-4));
        float fade = 1 - .7 * smoothstep(.6f, 1.f, h);
        float3 tint = paint(.2 + fk * .17 + h * .35, f);
        color += tint * (strands * .42 + sheet * .3) * fade * (.5 + level * 1.9) * boost;
        color += paint(.95, f) * strands * strands * .05 * fade * (.5 + level) * boost;
    }
    return color;
}
NATIVE_EFFECT(incenseDrift)

// ---------------------------------------------------------------- 344 Shibori Bloom
// Resist-dyed cloth: indigo ground with arashi pleats, kumo blooms of feathered rings and
// radial creases, dye bleeding outward over time. Each bloom bleeds with its band; attacks
// blot a fresh ring through the picked blooms.
float3 shiboriBloom(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float t = c.t;
    float2 cloth = p + float2(c.travel * .04, t * .004);
    float2 d = rot(cloth, .55);
    float pleat = d.y * 6.5 + .45 * sin(d.x * 1.7 + t * .06) + .5 * fbm2(d * float2(.6, 3.5), 3);
    float fold = abs(fract(pleat) - .5) * 2;
    float3 indigo = deep(0, f) * .45 + paint(0, f) * .07;
    float3 color = mix(paint(.55, f) * .4, indigo, smoothstep(.04f, .3f, fold + .15 * noise2(d * float2(2, 14))));
    // Kumo blooms.
    float2 bq = cloth * .8;
    float4 v = voronoi(bq, .75, 0);
    float2 seed = hash22(v.zw);
    float2 site = v.zw + .5 + .375 * sin(seed * TAU);
    float2 local = (bq - site) / .8;
    float r = length(local);
    float level = c.b[int(seed.x * 3.99)];
    float pick = mat_pick(seed.y, c);
    float radius = (.36 + .14 * seed.y) * (1 + level * .25);
    float2 direction = local / max(r, 1e-4f);
    float wobble = noise2(direction * 2.2 + seed * 13) - .5;
    float rr = r * (1 + .2 * wobble) / radius;
    float ringPhase = rr * 5 - t * .1 * (1 + seed.x) - level * .8;
    float ring = .5 + .5 * cos(ringPhase * TAU) + .3 * (noise2(local * 11 + seed * 7) - .5);
    float bleed = .08 + level * .4 + rr * .15;
    float resist = smoothstep(.62 - bleed, .62 + bleed * .4, ring);
    float a = atan2(local.y, local.x);
    float spokes = 10 + floor(seed.y * 6);
    float crease = smoothstep(.55f, 1.f, abs(cos(a * spokes * .5))) * smoothstep(.05f, .3f, rr);
    resist *= 1 - .75 * crease;
    resist = max(resist, smoothstep(.2f, .08f, rr));
    float3 dye = paint(.3 + seed.x * .45, f) * (.6 + level * .6);
    float3 bloom = mix(indigo, dye, smoothstep(.3f, .7f, sin(ringPhase * PI * .5 + seed.y * 4) * .5 + .5) * .8);
    bloom = mix(bloom, paint(.9, f) * .72, resist);
    float blot = c.hit * (.35 + pick) * exp(-pow((rr - (1.05 - c.hit * .8)) * 7, 2.f));
    bloom += paint(.85, f) * blot * 1.1;
    float inside = 1 - smoothstep(.85f, 1.05f, rr);
    float edgeHalo = exp(-pow((rr - 1) * 5, 2.f)) * (.2 + level * .5);
    color = mix(color, bloom, inside);
    color = mix(color, paint(.5, f) * .5, edgeHalo * (1 - inside * .5));
    float weave = 1 + .06 * sin(cloth.x * 260) * sin(cloth.y * 260) * smoothstep(.01f, .004f, c.px / c.size);
    return color * weave;
}
NATIVE_EFFECT(shiboriBloom)

// ---------------------------------------------------------------- 345 Heat Haze
// A false-colour thermal view of a convection tank: rolls turn across the frame, hot plumes
// rise where they meet and carry mushroom thermals upward through shimmering isotherms.
// Bass heats every plume, each plume also follows its own band, highs add shimmer; attacks
// release a hot bubble at the plume roots.
float3 heatHaze(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float2 ext = c.extent / c.size;
    float t = c.t;
    float h = p.y / ext.y * .5 + .5;
    float hc = clamp(h, 0.f, 1.f);
    float2 shimmer = float2(fbm2(p * 2.4 + float2(0, -t * .3), 3), fbm2(p * 2.4 + float2(5.1, -t * .26), 3)) - .5;
    float2 q = p + shimmer * (.07 + c.b.w * .28);
    const float span = .6;
    float xr = q.x / span + t * .01;
    float T = .36 - .38 * hc;
    // Counter-rotating convection rolls wrap warm streaks into spirals between the plumes.
    float roll = floor(xr * .5);
    float2 rl = float2((xr * .5 - roll - .5) * 2, (q.y / ext.y - .1 * sin(roll * 2.3)) * 1.4);
    float rr = length(rl);
    float turn = (int(roll) & 1) == 0 ? 1. : -1.;
    float spiral = sin(atan2(rl.y, rl.x) + rr * 8 * turn - t * .7 * turn);
    T += (.13 + c.b.y * .16) * spiral * smoothstep(1.05f, .25f, rr) * smoothstep(0.f, .2f, rr);
    // Plumes rise where neighbouring rolls meet.
    float plume = floor(xr * .5 + .5);
    float dxr = (xr * .5 - plume) * 2 * span;
    float seed = hash11(plume * 1.7 + .3);
    float level = c.b[int(abs(plume)) % 4];
    float sway = .07 * hc * sin(q.y * 2.3 - t * .4 + seed * 6) + .04 * hc * sin(q.y * 5 - t * .7 + seed * 3);
    float dx = dxr - sway;
    float wide = .035 + .07 * hc;
    float strength = .32 + .2 * seed + c.b.x * .5 + level * .4;
    T += strength * exp(-dx * dx / (wide * wide)) * (1.1 - .55 * hc);
    // Mushroom thermals climb each plume.
    for (int j = 0; j < 3; ++j) {
        float life = fract(t * .045 + seed + float(j) / 3);
        float y = mix(-1.25, 1.25, life) * ext.y;
        float2 head = float2(dx, q.y - y);
        float capWidth = .08 + .12 * life;
        float cap = exp(-head.x * head.x / (capWidth * capWidth) - head.y * head.y / .01);
        float curl = exp(-pow(abs(head.x) - capWidth, 2.f) / .003 - pow(head.y + .05, 2.f) / .006);
        float stem = exp(-dx * dx / (wide * wide * .5)) * smoothstep(.0f, -.25f, head.y) * smoothstep(-.6f, -.2f, head.y);
        T += (cap * .5 + curl * .38 + stem * .15) * strength * (1 - .3 * life);
    }
    float pick = mat_pick(seed, c);
    float bubbleY = -ext.y * .72 + (1 - c.hit) * .45;
    T += c.hit * (.6 + pick * 1.4) * exp(-(dx * dx + pow(q.y - bubbleY, 2.f)) / .025);
    T += .05 * (fbm2(q * 3 + float2(0, -t * .2), 3) - .5);
    float temp = clamp(T, 0.f, 1.4f);
    // False colour: cool is dark red, warm a saturated orange, and only the hottest cores
    // climb through gold to white, so mid temperatures never wash out to khaki.
    float hue = .02 + .56 * smoothstep(0.f, .8f, temp) + .37 * smoothstep(.8f, 1.3f, temp);
    float3 color = paint(hue, f) * (.03 + 1.1 * smoothstep(.03f, .45f, temp) + .4 * max(temp - .8f, 0.f));
    // Isotherms: thin, evenly wide contour lines however steep the temperature gradient.
    float contour = T * 10;
    float iso = fract(contour);
    float isoWidth = clamp(fwidth(contour), 1e-3f, .45f);
    // Where contours crowd together they fade out instead of greying the hot cores.
    float isoLine = (1 - smoothstep(isoWidth * .6f, isoWidth * 1.6f, min(iso, 1 - iso))) * (1 - smoothstep(.12f, .3f, isoWidth));
    color *= 1 - .3 * isoLine * smoothstep(.05f, .2f, temp) * (1 - smoothstep(.55f, .85f, temp));
    color += paint(.9, f) * isoLine * .1 * temp * temp;
    return color;
}
NATIVE_EFFECT(heatHaze)

// ---------------------------------------------------------------- 346 Gel Overlap
// Translucent colour gels lie on a light table; where they overlap their colours multiply.
// Each gel drifts and thickens with its band, the cut edges catch the light, and the music
// clock slides a long strip over the stack; attacks shove it and flash its edges.
float gel_sdf(float2 p, int k, float3 seed, float2 ext) {
    if (k == 1 || k == 4 || k == 7) return length(p) - (.48 + .25 * seed.x);
    if (k == 2) return sdBox2(p, float2(2.2 * max(ext.x, ext.y), .17 + .05 * seed.y)) - .02;
    return sdBox2(p, float2(.55 + .35 * seed.y, .38 + .22 * seed.z)) - .06;
}
float3 gelOverlap(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float2 ext = c.extent / c.size;
    float t = c.t;
    float px = c.px / c.size * 1.5;
    float glowField = .18 + 1.05 * exp(-dot(p / ext, p / ext) * 1.3);
    float3 table = (paint(.5, f) + paint(.75, f) + paint(.95, f)) / 3;
    float3 filter = float3(1);
    float cover = 0, shade = 1;
    float3 edges = 0;
    for (int k = 0; k < 9; ++k) {
        float fk = float(k);
        float3 seed = hash33(float3(fk, 2.7, 9.1));
        float level = k < 8 ? c.b[k % 4] : 0.;
        float2 center;
        float angle;
        int shape = k;
        if (k < 8) {
            float2 home = (seed.xy - .5) * ext * 1.4;
            float2 drift = float2(sin(t * (.04 + seed.z * .03) + fk * 1.7), cos(t * (.035 + seed.x * .03) + fk * 2.3)) * ext * .35;
            float2 push = float2(cos(fk * 2.4), sin(fk * 2.4)) * level * .55;
            center = home + drift + push;
            angle = t * .03 * (seed.z - .5) + fk;
        } else {
            // The slider: a long strip glides back and forth on the music clock; attacks shove it.
            center = float2(sin(c.m * .9 + 1.2) * ext.x * .75 + c.hit * .35, 0);
            angle = 1.35;
            shape = 2;
        }
        float2 local = rot(p - center, angle);
        float d = gel_sdf(local, shape, seed, ext);
        float shadow = 1 - smoothstep(-.02f, .09f, gel_sdf(rot(p - center - float2(.05, -.06), angle), shape, seed, ext));
        float mask = fill(d, px);
        float3 tint = paint(fk * .19 + .08 + .05 * sin(t * .02 + fk), f);
        tint = pow(tint / max(max(tint.r, tint.g), max(tint.b, 1e-3f)), float3(2.6));
        float density = .86 + level * .14;
        filter *= mix(float3(1), tint, mask * density);
        cover += mask;
        shade *= 1 - .35 * shadow * (1 - mask);
        float rim = line(d, .006, px) + glow(d, .01) * .3;
        float sheen = mask * smoothstep(.2f, 1.f, sin(dot(local, float2(1.3, .8)) * 2 + t * .1 + fk)) * .1;
        edges += (table * .35 + paint(.9, f) * .1) * (rim * (.16 + level * .9 + (k == 8 ? c.hit * 3 : 0.)) + sheen);
    }
    float covered = min(cover, 1.f);
    float3 color = mix(table * .42, filter * (.8 + .25 * min(cover - 1, 1.f)), covered) * glowField * shade;
    return color + edges;
}
NATIVE_EFFECT(gelOverlap)

// ---------------------------------------------------------------- 347 Holo Foil
// A sheet of crumpled holographic foil fills the frame: long straight folds, each dying out
// somewhere in the sheet, split it into flat tilted facets whose diffraction rainbow slides
// as the sheet flexes and the light moves. Bass deepens the folds, low-mids bend the sheet,
// high-mids widen the rainbow, highs sparkle glitter flakes; attacks sweep a highlight.
float3 holoFoil(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float2 ext = c.extent / c.size;
    float t = c.t;
    float px = c.px / c.size;
    float2 sp = p * 1.5 + float2(c.travel * .05 + t * .004, -t * .002);
    float reachAll = length(ext) * 1.5;
    float flex = .6 + .25 * sin(t * .17) + c.b.x * 1.1;
    float2 grad = 0;
    float ridge = 0, valley = 0;
    // Folds are spread over a jittered grid so every part of the canvas is crumpled.
    bool wide = ext.x >= ext.y;
    int columns = wide ? 6 : 4;
    for (int k = 0; k < 24; ++k) {
        float fk = float(k);
        float3 seed = hash33(float3(fk, 4.1, 7.3));
        float2 cell = float2(float(k % columns) + .5, float(k / columns) + .5) / float2(float(columns), float(24 / columns));
        float2 center = (cell * 2 - 1 + (seed.yz - .5) * .3) * ext * 1.5 + float2(c.travel * .05 + t * .004, -t * .002);
        float angle = seed.x * PI + .12 * sin(t * (.03 + .02 * seed.y) + fk * 1.7);
        float2 n = float2(cos(angle), sin(angle));
        float2 along = float2(-n.y, n.x);
        float d = dot(sp - center, n);
        // Each fold runs only part way across the sheet before it relaxes.
        float a = dot(sp - center, along);
        float span = .45 + 1.2 * fract(seed.x * 7.3 + seed.z * 3.1);
        float reach = exp(-a * a / (span * span));
        float depth = (.25 + .35 * seed.z) * flex * reach;
        float side = d / sqrt(d * d + px * px * 4.5f);
        float mountain = fract(seed.y * 5.7) < .5 ? 1. : -1.;
        grad += depth * side * n * mountain;
        float creaseLine = exp(-abs(d) / (px * 2.4 + .003)) * reach;
        if (mountain > 0) ridge += creaseLine; else valley += creaseLine;
    }
    float bend = .1 + c.b.y * .45;
    grad += bend * float2(cos(p.x * 1.3 + t * .11) * sin(p.y * .9 - t * .07), .7 * sin(p.x * 1.3 + t * .11) * cos(p.y * .9 - t * .07));
    float3 n = normalize(float3(-grad * .9, 1));
    float3 light = normalize(float3(cos(t * .09) * .6, sin(t * .07) * .5, 1));
    float3 r = reflect(float3(0, 0, -1), n);
    float facing = max(dot(r, light), 0.f);
    // Diffraction: the rainbow order depends on the facet's tilt against the light.
    float spread = 3.2 + c.b.z * 2.4;
    float phase = dot(n.xy - light.xy * .4, float2(.85, .55)) * spread + dot(p, float2(.18, .12)) + t * .02;
    float3 color = filmColor(phase, f) * (.07 + 1.05 * facing * facing * facing);
    color += paint(.9, f) * pow(facing, 24.f) * .45;
    color += paint(.92, f) * min(ridge, 1.f) * (.2 + .35 * facing);
    color *= 1 - .6 * min(valley, 1.f);
    // Glitter flakes in the foil twinkle with the highs.
    float4 g = voronoi(p * 22, .9, 0);
    float2 gs = hash22(g.zw);
    float twinkle = pow(max(0.f, sin(t * (1.5 + gs.x * 2) + gs.y * TAU)), 16.f);
    color += paint(.85 + .1 * gs.x, f) * (1 - smoothstep(.03f, .09f, g.x)) * twinkle * (.08 + c.b.w * 2.2);
    // Attacks sweep a bright band across the foil, strongest on facets facing the light.
    float sweepAngle = c.m * 1.3 + .6;
    float2 axis = float2(cos(sweepAngle), sin(sweepAngle));
    float sweep = exp(-pow(dot(p, axis) - ((1 - c.hit) * 2.2 - 1.1) * reachAll, 2.f) * 9) * c.hit;
    color += filmColor(phase + .3, f) * sweep * (.6 + 1.4 * facing) * 1.4;
    return color * .9;
}
NATIVE_EFFECT(holoFoil)

// ---------------------------------------------------------------- 348 Opal Fire
// A black opal's play of colour: harlequin patches of spectral fire at two depths, each
// with a rolling flash that slides through it as the stone tilts, plus pinfire sparks.
// Each patch follows a band; attacks ignite a burst of fire that spreads through the patches.
float3 opalFire(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float2 ext = c.extent / c.size;
    float t = c.t;
    float2 tilt = float2(sin(t * .11), cos(t * .087)) * .9;
    float2 view = tilt + p * .4;
    float2 event = mat_eventPoint(c, 2.9, .6);
    float near = exp(-dot(p - event, p - event) * 3);
    // Black potch with a deep coloured glow from fire further inside the stone.
    float body = fbm2(p * 1.2 + float2(t * .01, 0), 3);
    float3 color = deep(.05, f) * .04 + filmColor(body * 2.2 + dot(view, float2(.4, .3)), f) * .07 * body;
    // Harlequin mosaic: patches, each a diffraction grating with its own angle.
    float2 q = rot(p * 4.4 + float2(c.travel * .2, 0), .35) * float2(1, 1.3);
    q += (float2(noise2(q * .45), noise2(q * .45 + 5.3)) - .5) * .5;
    float4 v = voronoi(q, .85, t * .03);
    float3 seed = hash33(float3(v.zw, 1.7));
    float level = c.b[int(seed.z * 3.99)];
    float2 grating = float2(cos(seed.x * TAU), sin(seed.x * TAU));
    float facing = dot(view, grating) + (seed.y - .5) * 1.2;
    float flash = pow(max(0.f, cos(facing * 2.2 + t * .02)), 4.f);
    float ignite = c.hit * (near * 2.4 + mat_pick(seed.x, c) * .35);
    // Each patch is a small diffraction grating: a spectrum runs across it and slides
    // through it as the viewing angle changes. That sliding spectrum is the play of colour.
    float2 local = q - v.zw - .5;
    float across = dot(local, grating);
    float spectrum = seed.y * 2 + across * .8 - facing * 1.1 + level * .35 + ignite * .25;
    float band = .4 + .6 * pow(.5 + .5 * cos(across * 3 - facing * 5 + seed.z * 6), 2.f);
    float grain = .7 + .3 * noise2(q * 9 + seed.xy * 40 + grating * t * .1);
    float seam = .08 + .92 * smoothstep(0.f, c.px / c.size * 10, v.y - v.x);
    float bright = (.04 + flash * (1.5 + level * 2.8) + ignite * 1.6) * band * grain * seam;
    color += mix(paint(spectrum, f), filmColor(spectrum * 1.1, f), .7) * bright;
    // Pinfire: tiny points of colour deeper in the stone.
    float4 pin = voronoi(p * 15 + 3.3, .9, 0);
    float2 ps = hash22(pin.zw);
    float twinkle = pow(.5 + .5 * sin(dot(view, float2(cos(ps.x * TAU), sin(ps.x * TAU))) * 6 + ps.y * TAU), 10.f);
    float dotMask = (1 - smoothstep(.03f, .09f, pin.x)) * step(.55f, ps.x);
    color += filmColor(ps.y + .3, f) * dotMask * twinkle * (.35 + c.b.w * 2.6);
    // Polished cabochon: a soft window reflection drifting over the stone.
    float2 g = p - float2(-.45, .4) * ext - .25 * float2(sin(t * .05), cos(t * .04));
    color += paint(.95, f) * exp(-dot(g * float2(1, 2.2), g * float2(1, 2.2)) * 2.5) * .12;
    return color;
}
NATIVE_EFFECT(opalFire)

// ---------------------------------------------------------------- 349 Raku Crackle
// Raku glaze straight from the kiln: smoky black glaze with pools of copper lustre whose
// iridescence flows like oil, split by a crackle network whose seams still glow with
// kiln heat. A broad gloss sweep rakes across the tiles; every tile is tilted a little,
// so the copper flash breaks at each crack. Bands grow new crazing in their own regions,
// bass heats the seams, low-mids shift the lustre colours, high-mids flash the copper,
// highs glint metal flecks; attacks shatter a local patch with a radiating star fracture.
float raku_edge(float4 v, float scale) { return (v.y - v.x) / scale; }
float3 rakuCrackle(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float2 ext = c.extent / c.size;
    float t = c.t;
    float px = c.px / c.size;
    float2 g = p + float2(c.travel * .04 + t * .004, t * .0015);
    // Crack paths wander a little instead of running dead straight.
    float2 gc = g + (float2(noise2(g * 1.3), noise2(g * 1.3 + 4.2)) - .5) * .3
                  + (float2(noise2(g * 6.1 + 2.3), noise2(g * 6.1 + 9.4)) - .5) * .05;
    float4 big = voronoi(gc * 1.45, .9, 0);
    float edgeBig = raku_edge(big, 1.45);
    float4 fine = voronoi(gc * 4.4 + 3.1, .9, 0);
    float edgeFine = raku_edge(fine, 4.4);
    float2 tileSeed = hash22(big.zw);
    // Crazed tiles lift slightly at their edges, so each one is a shallow dome with its own tilt.
    float2 dome = (gc * 1.45 - big.zw - .5 - .45 * sin(tileSeed * TAU)) / 1.45;
    float2 tilt = (tileSeed - .5) * .3 + (hash22(fine.zw) - .5) * .05 + dome * .9;
    // Copper lustre pools on smoky black glaze.
    float pool = fbm2(g * .85 + float2(2.3 - t * .006, t * .004), 3) + (tileSeed.x - .5) * .2;
    float lustre = smoothstep(.4f, .54f, pool);
    float thickness = fbm2(g * 1.5 + float2(t * .014, -t * .01), 3) * 2.4 + dot(tilt, float2(1.7, 1.2)) + c.b.y * .7;
    // A broad gloss sweep: each tile's tilt shifts it, so the flash breaks at every crack.
    float sweepAngle = .65 + .35 * sin(t * .019);
    float2 sweepAxis = float2(cos(sweepAngle), sin(sweepAngle));
    float sweepAt = sin(t * .047) * length(ext) * .75;
    float s = dot(p + tilt * 1.8, sweepAxis) - sweepAt;
    float sheen = exp(-s * s * 3.5);
    // The reflected window: a crisp stripe that steps sideways at every crack.
    float window = 1 - smoothstep(.12f, .16f, abs(s + .05 * sin(dot(p, sweepAxis.yx) * 2.3)));
    float flash = .6 + sheen * (.6 + c.b.z * 1.8) + window * (.7 + c.b.z);
    // Lustre bands run through the film; their hue follows their brightness like hot metal,
    // dim bands red, bright ones gold, so the glaze never turns brown.
    float band = flash * (.3 + .7 * smoothstep(-.35f, .75f, sin(thickness * 3.2)));
    float3 film = mix(paint(.03 + .42 * min(band * band, 1.5f), f), filmColor(thickness, f), .15) * band;
    float3 smoke = deep(.1 + .1 * tileSeed.y, f) * .05 + paint(0, f) * .05 * fbm2(g * 3 + 1.7, 2);
    float3 color = mix(smoke + paint(.15, f) * .14 * sheen + paint(.42, f) * .3 * window, film, lustre);
    color += paint(.8, f) * window * .1 * lustre;
    // Metal flecks in the lustre glint with the highs.
    float4 micro = voronoi(g * 13 + 7.7, .9, 0);
    float fleck = (1 - smoothstep(.03f, .08f, micro.x)) * step(.72f, hash21(micro.zw));
    color += paint(.9, f) * fleck * lustre * (.06 + .3 * sheen + c.b.w * 1.6);
    // Bands grow new crazing in their own regions; the network also spreads slowly on its own.
    float growth = 0;
    for (int k = 0; k < 4; ++k) {
        float angle = float(k) * 1.5708 + .4 + t * .02;
        float2 at = float2(cos(angle), sin(angle)) * ext * .55;
        growth += c.b[k] * exp(-dot(p - at, p - at) * 1.1);
    }
    float spread = .2 + .2 * sin(dot(g, float2(1.3, .9)) - t * .05) + growth * .9;
    float front = noise2(gc * 2.3 + 6.1) * .85 + noise2(gc * 7.3 + 1.9) * .3;
    float reveal = smoothstep(front - .06f, front + .06f, spread);
    // Smoke stains the glaze along every crack; the seams themselves still glow.
    float heat = .5 + .5 * noise2(gc * 2.2 + float2(0, t * .09)) + c.b.x * 1.2;
    float3 seamColor = paint(.4 + .38 * min(heat, 1.f), f);
    float3 haloColor = paint(.25 + .25 * min(heat, 1.f), f);
    float wBig = max(.0045f, px * 1.1), wFine = max(.0025f, px * .8);
    float crackBig = 1 - smoothstep(wBig * .4, wBig + px, edgeBig);
    float crackFine = 1 - smoothstep(wFine * .4, wFine + px, edgeFine);
    color *= 1 - .85 * exp(-edgeBig / .03) - .5 * exp(-edgeFine / .012) * (.3 + .7 * reveal);
    color += seamColor * crackBig * (.45 + heat);
    color += haloColor * exp(-edgeBig / (.01 + .018 * min(heat, 1.5f))) * .45 * heat;
    color += seamColor * crackFine * reveal * (.1 + growth * 1.2 + .12 * heat);
    // Attacks shatter a local patch: a star fracture and fine crazing radiate from the strike.
    float2 strike = mat_eventPoint(c, 4.1, .55);
    float2 d = p - strike;
    float r = length(d);
    float reach = .1 + (1 - c.hit) * .5;
    float zone = c.hit * smoothstep(reach + .06f, reach - .12f, r);
    float spokes = 9;
    float a = atan2(d.y, d.x) + .15 * sin(r * 14 + strike.x * 5);
    float spokeDistance = abs(fract(a / TAU * spokes + .5 * noise2(float2(r * 3, strike.y))) - .5) * TAU / spokes * r;
    float star = 1 - smoothstep(wBig * .4, wBig + px, spokeDistance);
    float crazing = 1 - smoothstep(.0015f, .0015f + px, raku_edge(micro, 13));
    color *= 1 - .5 * zone;
    color += paint(.9, f) * (star + crazing * .8) * zone * 1.6;
    color += paint(.8, f) * exp(-pow((r - reach) / .045, 2.f)) * c.hit * .9;
    return color;
}
NATIVE_EFFECT(rakuCrackle)
