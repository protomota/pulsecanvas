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
// A poured acrylic skin: bold paint layers stream across the canvas, cells open in the
// cell-forming streams and white lacing webs the thin layers. Bass opens the cells, low-mids
// push the pour, high-mids thicken the lacing, highs freckle micro-cells; attacks open a
// bloom of fresh cells.
float acr_hue(float index) { return fract(index * .382 + .13); }
float3 acr_layer(float index, constant NativeFrame &f) {
    float kind = hash11(index * 2.71 + 8.3);
    if (kind < .28) return deep(acr_hue(index) + .5, f) * .1;
    return paint(acr_hue(index), f) * (.42 + .22 * kind);
}
float3 acrylicCells(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float t = c.t;
    float2 base = p * .85 + float2(t * .03 + c.travel * .06, -t * .012);
    float2 warp = float2(fbm2(base * .9 + float2(0, t * .02), 3), fbm2(base * .9 + float2(4.3, 1.7 - t * .018), 3));
    float2 q = base + (warp - .5) * (1.35 + c.b.y * 1.6);
    float3 white = mix(paint(.55, f), paint(.95, f), .5) * .7;
    // Stacked pour layers run along the flow.
    float s = q.y * 1.1 + q.x * .42 + .3 * sin(q.x * 1.2 + t * .04);
    float layer = s * 2.3;
    float index = floor(layer), fr = fract(layer);
    float aa = clamp(c.px / c.size * 9, .004f, .2f);
    float3 color = mix(acr_layer(index, f), acr_layer(index + 1, f), smoothstep(1 - aa, 1.f, fr));
    float boundary = min(fr, 1 - fr);
    color = mix(color, white, exp(-boundary / .018) * step(.5, hash11(index * 5.3 + 1)) * .75);
    // Cells: voronoi along the flow, open only in the cell-forming streams.
    float2 along = normalize(float2(1.1, -.42));
    float2 cq = float2(dot(q, along) * 2.6, dot(q, float2(-along.y, along.x)) * 4.4);
    float4 v = voronoi(cq, .9, t * .12);
    float2 seed = hash22(v.zw);
    float2 site = v.zw + .5 + .45 * sin(t * .12 + seed * TAU);
    float2 local = cq - site;
    float region = smoothstep(.36, .6, noise2(q * .8 + 11.3));
    float2 event = mat_eventPoint(c, .3, .6);
    float near = exp(-dot(p - event, p - event) * 2.2);
    float pick = mat_pick(seed.x, c);
    float radius = (.1 + .26 * seed.y) * region * (.7 + c.b.x * 1.5);
    radius += (.16 + .12 * seed.y) * c.hit * (pick + near * 1.6);
    radius = min(radius, .46f);
    float present = smoothstep(0.f, .03f, radius);
    float aac = c.px / c.size * 4.4 * 1.5;
    float inside = (1 - smoothstep(radius - aac, radius + aac, v.x)) * present;
    float3 cellColor = paint(acr_hue(index) + .5 + seed.x * .25, f) * .8;
    float inner = 1 - smoothstep(radius * .45 - aac, radius * .45 + aac, v.x);
    cellColor = mix(cellColor, seed.x > .5 ? deep(acr_hue(index), f) * .12 : paint(acr_hue(index) + .25, f) * .9, inner * step(.3, seed.x));
    float2 lit = local + float2(.3, -.3) * radius;
    float dome = exp(-dot(lit, lit) / max(radius * radius * .1, 1e-4f));
    cellColor += white * dome * .45;
    float rim = exp(-abs(v.x - radius) / (.018 + .02 * c.b.x)) * present;
    float halo = exp(-max(v.x - radius, 0.f) / .05) * (1 - inside) * present;
    color = mix(color * (1 - .75 * halo), cellColor, inside);
    color += white * rim * (.4 + c.hit * (pick + near) * 1.6);
    // Lacing and micro-cells on a finer web.
    float4 web = voronoi(cq * 2.3 + 5.1, .85, t * .1);
    float lace = 1 - smoothstep(.012, .045 + c.b.z * .07, web.y - web.x);
    float laceRegion = smoothstep(.42, .68, noise2(q * 1.1 + 4.7)) * (1 - inside);
    color = mix(color, white, lace * laceRegion * (.45 + c.b.z * 1.1));
    float freckle = 1 - smoothstep(.04 + .12 * c.b.w, .07 + .12 * c.b.w, web.x);
    color = mix(color, paint(hash21(web.zw), f) * .8, freckle * smoothstep(.02f, .1f, c.b.w) * (1 - inside) * region);
    // Wet gloss: a slow window reflection across the pour.
    float gloss = exp(-pow(dot(p, float2(.6, .8)) - 1.3 * sin(t * .045), 2.f) * 2.5);
    color += white * gloss * .08;
    return color;
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
        float heat = (.6 + .3 * sin(x * .8 - t * .1 + seed * 7) + .55 * level) * (1 - neck * .6) + kink * 2.4;
        // Glowing glass: emission peaks inside the cane, so there is no dark side.
        float emission = heat * (.3 + .7 * nz * nz);
        float twist = asin(uc) * 2 + x * (7 + 4 * seed) * side - t * (.35 + seed * .3);
        float strand = smoothstep(.35f, .75f, sin(twist)) * nz;
        float3 glass = paint(.12 + .72 * min(emission, 1.2f), f) * emission * 1.05;
        glass += paint(.88, f) * strand * (.08 + c.b.z * .9) * heat;
        float3 n = float3(0, uc, nz);
        float specular = pow(max(0.f, dot(n, normalize(float3(0, .58, .81)))), 220.f);
        glass += paint(.95, f) * specular * 1.3;
        glass += paint(.35, f) * pow(1 - nz, 8.f) * .35 * heat;
        // Trapped seeds (tiny bubbles) glint with the highs.
        float segment = floor(x * 2.5 + seed * 17);
        float2 bubbleSeed = hash22(float2(segment, fk));
        float2 bubble = float2((fract(x * 2.5 + seed * 17) - .2 - .6 * bubbleSeed.x) * .4 * stretch, (u - (bubbleSeed.y - .5) * 1.2) * width);
        glass += paint(.95, f) * glow(length(bubble) - .01, .005) * (.04 + c.b.w * 2.4) * nz;
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
        float separation = (c.hit * .5 + c.e * .1) * (.3 + pick);
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
    float3 color = deep(.1 + h * .1, f) * .35 + paint(.3 + haze * .3, f) * haze * haze * (.06 + .28 * h);
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
        color += tint * (strands * .32 + sheet * .25) * fade * (.45 + level * 1.9) * boost;
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
    float2 q = p + shimmer * (.08 + c.b.w * .28);
    const float span = .8;
    float xr = q.x / span + t * .01;
    float T = .42 - .42 * hc;
    // Counter-rotating convection rolls wrap warm streaks into spirals between the plumes.
    float roll = floor(xr * .5);
    float2 rl = float2((xr * .5 - roll - .5) * 2, q.y / ext.y * 1.1);
    float rr = length(rl);
    float turn = (int(roll) & 1) == 0 ? 1. : -1.;
    float spiral = sin(atan2(rl.y, rl.x) + rr * 9 * turn - t * .7 * turn);
    T += (.12 + c.b.y * .14) * spiral * smoothstep(1.05f, .25f, rr) * smoothstep(0.f, .2f, rr);
    T += .1 * cos(PI * xr) * sin(PI * hc);
    // Plumes rise where neighbouring rolls meet.
    float plume = floor(xr * .5 + .5);
    float dxr = (xr * .5 - plume) * 2 * span;
    float seed = hash11(plume * 1.7 + .3);
    float level = c.b[int(abs(plume)) % 4];
    float sway = .08 * hc * sin(q.y * 2.3 - t * .4 + seed * 6) + .05 * hc * sin(q.y * 5 - t * .7 + seed * 3);
    float dx = dxr - sway;
    float wide = .05 + .1 * hc;
    float strength = .28 + .18 * seed + c.b.x * .45 + level * .35;
    T += strength * exp(-dx * dx / (wide * wide)) * (1 - .45 * hc);
    for (int j = 0; j < 2; ++j) {
        float life = fract(t * .05 + seed + float(j) * .5);
        float y = mix(-1.3, 1.3, life) * ext.y;
        float2 head = float2(dx, q.y - y);
        float capWidth = .12 + .14 * life;
        float cap = exp(-head.x * head.x / (capWidth * capWidth) - head.y * head.y / .014);
        float curl = exp(-pow(abs(head.x) - capWidth * .95, 2.f) / .005 - pow(head.y + .06, 2.f) / .008);
        T += (cap * .42 + curl * .3) * strength;
    }
    float pick = mat_pick(seed, c);
    float bubbleY = -ext.y * .72 + (1 - c.hit) * .45;
    T += c.hit * (.55 + pick * 1.4) * exp(-(dx * dx + pow(q.y - bubbleY, 2.f)) / .03);
    T += .06 * (fbm2(q * 3 + float2(0, -t * .2), 3) - .5);
    float temp = clamp(T, 0.f, 1.3f);
    float3 color = paint(.02 + temp * .9, f) * (.025 + .95 * smoothstep(.08f, .7f, temp) + .35 * max(temp - .8f, 0.f));
    float iso = fract(T * 10);
    float isoLine = 1 - smoothstep(.02f, .1f, min(iso, 1 - iso));
    color *= 1 - .4 * isoLine;
    color += paint(.85, f) * isoLine * .1 * temp * temp;
    return color;
}
NATIVE_EFFECT(heatHaze)

// ---------------------------------------------------------------- 346 Gel Overlap
// Translucent colour gels lie on a light table; where they overlap their colours multiply.
// Each gel drifts and thickens with its band, the cut edges catch the light, and the music
// clock slides a long strip over the stack; attacks shove it and flash its edges.
float gel_sdf(float2 p, int k, float3 seed, float2 ext) {
    if (k == 1 || k == 4) return length(p) - (.42 + .22 * seed.x);
    if (k == 2) return sdBox2(p, float2(2.2 * max(ext.x, ext.y), .17 + .05 * seed.y)) - .02;
    return sdBox2(p, float2(.48 + .3 * seed.y, .34 + .2 * seed.z)) - .06;
}
float3 gelOverlap(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float2 ext = c.extent / c.size;
    float t = c.t;
    float px = c.px / c.size * 1.5;
    float glowField = .18 + 1.05 * exp(-dot(p / ext, p / ext) * 1.3);
    float3 table = (paint(0, f) + paint(.25, f) + paint(.5, f) + paint(.75, f)) * .25;
    float3 filter = float3(1);
    float cover = 0, shade = 1;
    float3 edges = 0;
    for (int k = 0; k < 7; ++k) {
        float fk = float(k);
        float3 seed = hash33(float3(fk, 2.7, 9.1));
        float level = k < 6 ? c.b[k % 4] : 0.;
        float2 center;
        float angle;
        int shape = k;
        if (k < 6) {
            float2 home = (seed.xy - .5) * ext * 1.3;
            float2 drift = float2(sin(t * (.04 + seed.z * .03) + fk * 1.7), cos(t * (.035 + seed.x * .03) + fk * 2.3)) * ext * .35;
            float2 push = float2(cos(fk * 2.4), sin(fk * 2.4)) * level * .55;
            center = home + drift + push;
            angle = t * .03 * (seed.z - .5) + fk;
        } else {
            // The slider: a long strip carried across by the music clock.
            center = float2((fract(c.m * .3 + .5) * 2 - 1) * (ext.x + 1.4) + c.hit * .35, 0);
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
        edges += (table * .35 + paint(.9, f) * .1) * (rim * (.3 + level * 1.2 + (k == 6 ? c.hit * 3 : 0.)) + sheen);
    }
    float covered = min(cover, 1.f);
    float3 color = mix(table * .42, filter * (.8 + .25 * min(cover - 1, 1.f)), covered) * glowField * shade;
    return color + edges;
}
NATIVE_EFFECT(gelOverlap)

// ---------------------------------------------------------------- 347 Holo Foil
// A sheet of crumpled holographic foil fills the frame: sharp creases split it into tilted
// facets whose diffraction rainbow slides as the sheet flexes. Bass deepens the creases,
// low-mids bend the sheet, high-mids widen the rainbow, highs sparkle glitter flakes;
// attacks sweep a highlight across the foil.
float holo_height(float2 p) {
    float h = 0, amplitude = .5;
    for (int i = 0; i < 3; ++i) {
        float n = noise2(p + float2(float(i) * 7.1, float(i) * 3.3));
        h += amplitude * (1 - abs(n * 2 - 1));
        p = rot(p, .7) * 2.2;
        amplitude *= .45;
    }
    return h;
}
float3 holoFoil(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float2 ext = c.extent / c.size;
    float t = c.t;
    float2 fp = rot(p, .45) * float2(.75, 1.5) + float2(c.travel * .05 + t * .006, 0);
    const float e = .01;
    float h0 = holo_height(fp), hx = holo_height(fp + float2(e, 0)), hy = holo_height(fp + float2(0, e));
    float flex = .75 + .25 * sin(t * .23 + p.x * .6) + c.b.x * 1.2;
    float2 grad = float2(hx - h0, hy - h0) / e * flex;
    float4 facet = voronoi(fp * 1.8, .9, 0);
    grad += (hash22(facet.zw) - .5) * (1.1 + c.b.x * 1.2);
    float bend = .45 + c.b.y * 1.1;
    grad += bend * float2(cos(p.x * 1.3 + t * .11) * sin(p.y * .9 - t * .07), .7 * sin(p.x * 1.3 + t * .11) * cos(p.y * .9 - t * .07));
    float3 n = normalize(float3(-grad * .4, 1));
    float3 light = normalize(float3(cos(t * .09) * .7, sin(t * .07) * .6, 1));
    float3 r = reflect(float3(0, 0, -1), n);
    float facing = max(dot(r, light), 0.f);
    float spread = 3 + c.b.z * 2.4;
    float phase = (n.x * .8 + n.y * .5) * spread + facing * .9 + dot(p, float2(.55, .85)) * .9 + t * .03;
    float3 color = filmColor(phase, f) * (.3 + .8 * pow(facing, 3.f));
    color += paint(.9, f) * pow(facing, 30.f) * .7;
    float4 g = voronoi(p * 20, .9, 0);
    float2 gs = hash22(g.zw);
    float twinkle = pow(max(0.f, sin(t * (1.5 + gs.x * 2) + gs.y * TAU)), 16.f);
    color += paint(.85 + .1 * gs.x, f) * (1 - smoothstep(.03f, .1f, g.x)) * twinkle * (.12 + c.b.w * 2.6);
    float sweepAngle = c.m * 1.3 + .6;
    float2 axis = float2(cos(sweepAngle), sin(sweepAngle));
    float reach = length(ext);
    float sweep = exp(-pow(dot(p, axis) - ((1 - c.hit) * 2.2 - 1.1) * reach, 2.f) * 9) * c.hit;
    color += paint(.88, f) * sweep * (.8 + 1.2 * facing * facing) * 1.6;
    return color;
}
NATIVE_EFFECT(holoFoil)

// ---------------------------------------------------------------- 348 Opal Fire
// A black opal's play of colour: harlequin patches of spectral fire at two depths, each
// with a rolling flash that slides through it as the stone tilts, plus pinfire sparks.
// Each patch follows a band; attacks ignite a burst of fire that spreads through the patches.
float3 opalFire(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float t = c.t;
    float2 tilt = float2(sin(t * .11), cos(t * .087)) * .9;
    float2 event = mat_eventPoint(c, 2.9, .6);
    float near = exp(-dot(p - event, p - event) * 3);
    // Black potch with a faint milky depth.
    float3 color = deep(.05, f) * .04 + deep(.35, f) * .05 * fbm2(p * 1.5 + t * .01, 2);
    // Harlequin patches of fire.
    float2 q = rot(p * 3.4 + float2(c.travel * .2, 0), .5) * float2(1, 1.4);
    q += (float2(noise2(q * .6), noise2(q * .6 + 5.3)) - .5) * .9;
    float4 v = voronoi(q, .95, t * .04);
    float3 seed = hash33(float3(v.zw, 1.7));
    float level = c.b[int(seed.z * 3.99)];
    float2 grating = float2(cos(seed.x * PI), sin(seed.x * PI));
    float2 across = float2(-grating.y, grating.x);
    float2 view = tilt + p * .35;
    // Rolling flash: a band of colour slides through each patch as the stone tilts.
    float roll = dot(view, grating) * 2.4 + dot(q, grating) * .8 + seed.y * 6 + t * .03;
    float flash = pow(.5 + .5 * cos(roll), 9.f);
    float ignite = c.hit * (near * 2.2 + mat_pick(seed.x, c) * .7);
    // Streaky flame texture runs along each patch's grating.
    float2 sq = float2(dot(q, grating) * 1.2, dot(q, across) * 5) + seed.xy * 20 + float2(t * .03, 0);
    float flame = .12 + .88 * pow(smoothstep(.25f, .8f, fbm2(sq, 3)), 1.5f);
    float edge = .75 + .25 * smoothstep(0.f, .05f, v.y - v.x);
    float bright = (.05 + flash * (2.2 + level * 3) + ignite * 1.6) * flame * edge;
    float hue = seed.y * 1.2 + dot(view, grating) * .35 + level * .3 + ignite * .2;
    color += mix(paint(hue, f), filmColor(hue * 1.3 + .2, f), .6) * bright;
    // Pinfire: tiny points of colour deeper in the stone.
    float4 pin = voronoi(p * 13 + 3.3, .9, 0);
    float2 ps = hash22(pin.zw);
    float twinkle = pow(.5 + .5 * sin(dot(view, float2(cos(ps.x * TAU), sin(ps.x * TAU))) * 5 + ps.y * TAU), 8.f);
    float dotMask = (1 - smoothstep(.03f, .1f, pin.x)) * step(.6f, ps.x);
    color += paint(ps.y + .3, f) * dotMask * twinkle * (.3 + c.b.w * 2.6);
    // Polished dome: a soft window reflection drifting over the stone.
    float2 g = p - float2(-.5, .45) - .25 * float2(sin(t * .05), cos(t * .04));
    color += paint(.95, f) * exp(-dot(g * float2(1, 2.5), g * float2(1, 2.5)) * 3) * .1;
    return color;
}
NATIVE_EFFECT(opalFire)

// ---------------------------------------------------------------- 349 Raku Crackle
// Raku glaze straight from the kiln: a crackle network splits the dark glossy glaze into
// tiles, its seams still glowing; copper lustre flashes across the tiles as their tilted
// gloss catches a moving light. Bands grow new cracks in their own regions, bass heats the
// seams, high-mids flash the copper; attacks shatter a local patch.
float3 rakuCrackle(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float2 ext = c.extent / c.size;
    float t = c.t;
    float px = c.px / c.size;
    float2 g = p + float2(c.travel * .04 + t * .004, 0);
    g += (float2(noise2(g * 1.7), noise2(g * 1.7 + 4.2)) - .5) * .18;
    float4 big = voronoi(g * 1.7, .85, 0);
    float edgeBig = (big.y - big.x) / 1.7;
    float4 fine = voronoi(g * 4.6 + 3.1, .9, 0);
    float edgeFine = (fine.y - fine.x) / 4.6;
    float2 tilt = (hash22(big.zw) - .5) * .6 + (hash22(fine.zw) - .5) * .14;
    float3 n = normalize(float3(tilt, 1));
    // A moving soft light reflected in the gloss; every tile tilts it differently.
    float2 mirror = p + n.xy * 2.4;
    float2 lamp = float2(sin(t * .05) * ext.x * .8, cos(t * .037) * ext.y * .6);
    float2 box = abs(mirror - lamp) - float2(.65, .3);
    float softbox = 1 - smoothstep(-.1f, .3f, max(box.x, box.y));
    float lustre = smoothstep(.44f, .62f, fbm2(g * 1.1 + float2(t * .01, 0), 3));
    float thickness = fbm2(g * 2.2 - t * .02, 2) * 1.8 + dot(n.xy, float2(3, 2));
    float flash = .5 + c.b.z * 1.5;
    float3 glaze = mix(deep(.2, f) * .07 + paint(.05, f) * .03, filmColor(thickness, f) * .5 * flash, lustre);
    glaze += mix(paint(.85, f) * .3, filmColor(thickness + .3, f) * 1.1, lustre) * softbox;
    // Band regions decide where new cracks grow.
    float growth = 0;
    for (int k = 0; k < 4; ++k) {
        float angle = float(k) * 1.5708 + .4 + t * .02;
        float2 at = float2(cos(angle), sin(angle)) * ext * .55;
        growth += c.b[k] * exp(-dot(p - at, p - at) * .9);
    }
    float crackBig = 1 - smoothstep(.007f, .007f + px * 1.5, edgeBig);
    float grow = smoothstep(-.06f, .06f, .3 + growth * 1.3 - noise2(g * 2.6));
    float crackFine = (1 - smoothstep(.0035f, .0035f + px * 1.5, edgeFine)) * grow;
    float2 event = mat_eventPoint(c, 4.1, .6);
    float shatter = c.hit * exp(-dot(p - event, p - event) * 4.5);
    float4 micro = voronoi(g * 12 + 7.7, .9, 0);
    float edgeMicro = (micro.y - micro.x) / 12;
    float crackMicro = (1 - smoothstep(.002f, .002f + px * 1.5, edgeMicro)) * smoothstep(.04f, .25f, shatter);
    float heat = .4 + .6 * noise2(g * 2 + float2(0, t * .08)) + c.b.x * 1.1;
    float3 color = glaze * (1 - .9 * max(crackBig, max(crackFine, crackMicro)));
    float seam = exp(-edgeBig * 140) * .8 + exp(-edgeFine * 220) * .5 * grow + exp(-edgeMicro * 300) * shatter * 2.5;
    color += paint(.55 + .35 * min(heat, 1.f), f) * seam * heat * (.55 + shatter * 2);
    return color;
}
NATIVE_EFFECT(rakuCrackle)
