// PulseCanvas native designs: tunnels (scenes 100–116). Original procedural code; see
// NativeCommon.metal. Every design is a pure function of its uniforms and every audio term
// is zero at zero Chaos.

// ---------------------------------------------------------------- shared tunnel helpers
// Wrap an angle into [-π, π].
float tnWrap(float a) { return a - TAU * floor(a / TAU + .5); }
// Smooth Lissajous drift for a vanishing point.
float2 tnDrift(float t, float2 amount) {
    return float2(sin(t * .23) + .45 * sin(t * .37 + 2.1), sin(t * .19 + 1.3) + .45 * sin(t * .31 + .4)) / 1.45 * amount;
}
// Bent tube: near walls stay centred while far depths converge on the drifting vanishing
// point. The map is smooth and one-to-one for |vanish| < .5.
float2 tnBend(float2 uv, float2 vanish) {
    float2 q = uv - vanish;
    return uv - vanish / (1 + 2.5 * dot(q, q));
}
// Depth fog with the Fog control.
float tnFog(float z, Ctx c, float base) { return exp(-z * (base + c.fog * .15)); }
// Normalized attack level: 0 when quiet, 1 on a strong attack.
float tnAttack(Ctx c) { return smoothstep(.04f, .7f, c.hit); }

// ---------------------------------------------------------------- 100 Plasma Bore
// A round bore of boiling plasma. Domain-warped noise on the cylinder forms hot filaments
// and colour bands that slide down the curving tube. Bass thickens the near filaments,
// highs crackle on the walls and attacks launch a plasma ring down the bore.
float3 plasmaBore(Ctx c, constant NativeFrame &f) {
    float2 vanish = tnDrift(c.t, float2(.36, .24));
    float2 d = tnBend(c.uv, vanish);
    float r = max(length(d), 1e-3f), a = atan2(d.y, d.x);
    // The bore wall bulges with the bass in rings that roll toward the camera.
    float bulge = 1 + c.b.x * .16 * sin((1 / r + c.travel * 2.4) * 1.3 + c.m * 2.5 + 2 * cos(a));
    float z = bulge / r, zw = z + c.travel * 2.4 + c.m * .7;
    float scale = 1 / c.size;
    float3 p = float3(cos(a) * 1.4, sin(a) * 1.4, zw * .42) * scale;
    float3 warp = float3(fbm3(p + float3(0, 0, c.t * .31 + c.m * .3), 3), fbm3(p + float3(4.1, 1.7, -c.t * .27), 3), 0);
    float n = fbm3(p * 1.5 + warp * (2.6 + c.b.y * 1.6) + float3(1.3, -.7, -c.t * .45 - c.m * .4), 4);
    float near = exp(-z * .6);
    float filaments = 1 - abs(sin(n * 11 + c.t * .5 + c.m * .4));
    float ridge = pow(filaments, 8 - 5 * c.b.x * near);
    float strands = pow(1 - abs(sin(warp.x * 14 - c.t * .3)), 14.f);
    float phase = n * 3.2 + zw * .05 - c.t * .1 + c.b.z * .5;
    float cloud = smoothstep(.38f, .72f, n);
    float bands = .55 + .45 * sin(zw * 1.3 - c.t * 1.4 + n * 5);
    float3 color = paint(phase + .5, f) * .04 + paint(phase, f) * cloud * .3 * bands;
    color += paint(phase + .15, f) * ridge * (1.1 + 2.4 * c.b.x * near) * (.6 + .4 * bands);
    color += paint(phase + .55, f) * strands * .45;
    color += paint(phase + .3, f) * pow(filaments, 30.f) * 1.1;
    // High-band crackle: tiny sparks that flicker on the near walls.
    float2 sparkCell = float2((a / TAU + .5) * 64, zw * 9);
    float sparkHash = hash21(floor(sparkCell) + 17);
    float twinkle = pow(.5 + .5 * sin(c.t * 23 * (.5 + sparkHash) + sparkHash * 40), 6.f);
    float spark = smoothstep(.32f, 0.f, length(fract(sparkCell) - .5)) * step(.82f, sparkHash);
    color += paint(phase + .5, f) * spark * twinkle * c.b.w * 5 * exp(-z * .3);
    // Attack: a ring-shaped surge that rides down the tube as the attack decays.
    float h = tnAttack(c);
    float ringDepth = 1.3 + (1 - h) * 6;
    float surge = exp(-pow((z - ringDepth) / (.12 + .1 * ringDepth), 2.f)) * c.hit;
    color += paint(.85 + n * .3, f) * surge * (1 + 2.6 * filaments);
    float3 core = paint(phase * .3 + .55, f) * .7 + paint(.9, f) * exp(-r * 9) * 1.4;
    return mix(core, color, tnFog(z, c, .03) * smoothstep(30.f, 10.f, z));
}

// ---------------------------------------------------------------- 101 LED Corridor
// A square corridor tiled with LED matrices. The walls run equalizer columns (left on the
// low band, right on high-mids) under marching chevrons, the ceiling scrolls a slow colour
// field and attacks run a pixel wave down the floor. Dark seams mark every panel.
float3 ledCorridor(Ctx c, constant NativeFrame &f) {
    float2 vanish = tnDrift(c.t * .8, float2(.18, .1));
    float2 d = tnBend(c.uv, vanish);
    float ax = abs(d.x), ay = abs(d.y);
    bool wall = ax > ay;
    float z = 1 / max(max(ax, ay), 1e-3f);
    // Forward drive: zoom travel plus the music clock, so energetic passages surge ahead.
    float drive = c.travel * 3.2 + c.m * .9;
    float zw = z + drive;
    float across = (wall ? d.y : d.x) * z;
    float pitch = .09 * c.size;
    float2 cell = float2(across, zw) / pitch;
    float2 id = floor(cell), local = fract(cell) - .5;
    float centreAcross = (id.x + .5) * pitch, centreDepth = (id.y + .5) * pitch;
    float relDepth = centreDepth - drive;
    float height01 = centreAcross * .5 + .5;
    // Every panel block listens to its own band.
    float2 block = floor(float2(id.x / 5, id.y / 6)) + (wall ? (d.x < 0 ? 0 : 40) : (d.y > 0 ? 80 : 120));
    float blockBand = c.b[int(hash21(block) * 3.99)];
    float3 led = 0;
    if (wall) {
        bool left = d.x < 0;
        if (height01 < .66) {
            float column = floor(id.y / 4);
            float gap = step(2.5f, id.y - column * 4);
            float band = left ? c.b.x : c.b.z;
            float level = .22 + .14 * sin(c.t * 2.3 + c.m * 1.5 + column * 1.37) + .09 * sin(c.t * 3.9 + column * .71)
                + band * (.45 + .4 * hash11(column * 1.71 + (left ? 0 : 50)));
            float h = height01 / .66;
            float on = (1 - gap) * step(h, level);
            float cap = (1 - gap) * step(level, h) * step(h, level + pitch * .75);
            led = paint(.04 + h * .8, f) * on * 1.1 + paint(.9, f) * cap * 1.3;
        } else {
            float row = (centreAcross - .66) / pitch;
            float march = fract((id.y + abs(row) * 1.2 - c.t * 7 - c.m * 5) / 9);
            led = paint(.72 + .1 * sin(id.y * .05) + c.b.w * .25, f) * step(march, .3f) * step(.7f, height01) * step(height01, .96f) * (1 + c.b.w * 1.8);
        }
    } else if (d.y > 0) {
        float n = noise2(float2(centreAcross * 1.2, centreDepth * .22 - c.t * .25 - c.m * .3));
        led = paint(n * 1.5 + c.t * .03 + centreDepth * .01 + c.b.y * .35, f) * (.25 + .4 * n) * (1 + blockBand * 2.4);
    } else {
        float lane = step(abs(abs(centreAcross) - .64), pitch * .6);
        float dash = step(fract(id.y / 8 - c.t * .9 - c.m * .6), .5);
        float arrow = step(fract((id.y + abs(id.x + .5) * 1.2 - c.t * 5 - c.m * 4) / 10), .22) * step(abs(centreAcross), .3f);
        led = paint(.55, f) * lane * dash * (.9 + c.b.y * 2.2) + paint(.3 + c.b.x * .3, f) * arrow * (.7 + c.b.x * 2);
        float h = tnAttack(c);
        float front = 1.7 + (1 - h) * 7;
        float wave = c.hit * exp(-pow((relDepth + abs(centreAcross) * .8 - front) / .7, 2.f));
        led += paint(.85 + .1 * centreAcross, f) * wave * 2.4;
    }
    float panel = 2.4;
    float seam = step(fract(centreDepth / panel), pitch / panel * 1.01);
    led *= 1 - seam;
    float2 fw = fwidth(cell);
    float blur = max(fw.x, fw.y);
    float dist = length(local);
    float aa = blur * .7 + .02;
    float resolve = smoothstep(.9f, .35f, blur);
    float dotMask = mix(.4f, 1 - smoothstep(.36f - aa, .36f + aa, dist), resolve);
    float halo = mix(.4f, exp(-dist * dist * 7), resolve);
    // Idle LEDs shimmer with their block's band in waves running down the corridor.
    float shimmer = pow(.5 + .5 * sin(relDepth * 1.3 - c.m * 3 + hash21(block) * 6), 2.f);
    float3 offLed = paint(.5 + blockBand * .4, f) * .03 * (1 - seam) * (1 + blockBand * 7 * shimmer);
    float3 color = deep(.3, f) * .025 * (1 - seam * .8) + (led + offLed) * (dotMask * 1.6 + halo * .3);
    float corner = exp(-abs(ax - ay) * z * 40);
    color *= 1 - corner * .6;
    float3 end = paint(.55, f) * .55 + paint(.85, f) * exp(-max(ax, ay) * 16) * 1.2;
    return mix(end, color, tnFog(z, c, .03));
}

// ---------------------------------------------------------------- 102 Prism Shaft
// A triangular glass shaft that turns as it flies past. Each face carries thin-film caustic
// lines; panels alternate tint along depth and the three corners burn as bright seams.
// Highs multiply and shimmer the caustics, bass widens the seams, attacks sweep a band of
// refracted light down the faces.
float3 prismShaft(Ctx c, constant NativeFrame &f) {
    float2 vanish = tnDrift(c.t * .9, float2(.22, .14));
    float2 d = tnBend(c.uv, vanish);
    float r = max(length(d), 1e-3f);
    float spin = c.travel * .14 + c.t * .05;
    float a = atan2(d.y, d.x) - spin;
    const float sector = TAU / 3;
    float k = floor(a / sector + .5);
    float phi = a - k * sector;
    float face = k - 3 * floor(k / 3);
    float z = 1 / (r * cos(phi));
    float lateral = tan(phi);
    float zw = z + c.travel * 2.6;
    float fs = 1 / c.size;
    float2 q = float2(lateral * .9, zw * .5) * fs + float2(face * 7.3, 0);
    float2 w = float2(fbm2(q * .7 + float2(0, c.t * .06), 3), fbm2(q * .7 + float2(5.2, -c.t * .05), 3));
    float n = fbm2(q * 1.3 + w * 2.2, 3);
    float freq = 20 + c.b.w * 14;
    float caustic = pow(1 - abs(sin(n * freq + c.t * .6 + c.m * 1.2)), 24.f);
    float n2 = fbm2(q * 2.3 - w * 1.5 + float2(c.t * .05, 0), 3);
    caustic += .7 * pow(1 - abs(sin(n2 * freq * 1.3 - c.t * .4 + 1.3)), 30.f) * (.35 + c.b.w * 1.2);
    float segment = floor(zw / 1.8);
    float parity = segment - 2 * floor(segment / 2);
    float3 glass = deep(.12 + parity * .3 + face * .13, f) * .2 + paint(.3 + parity * .25 + face * .1, f) * .05;
    glass *= .6 + .5 * lateral * lateral / 3;
    float sheen = exp(-pow(fract(zw * .12 + lateral * .18 - c.t * .08) - .5, 2.f) * 50);
    glass += paint(.75 + face * .08, f) * sheen * .12;
    float3 color = glass + filmColor(n * 1.6 + lateral * .12 + zw * .025, f) * caustic * 1.6;
    float segDist = abs(fract(zw / 1.8 + .5) - .5) * 1.8;
    color += paint(.6 + parity * .2, f) * (1 - smoothstep(0.f, fwidth(zw) * 1.5 + .004f, segDist)) * .6;
    float seamDist = r * sin(PI / 3 - abs(phi));
    float seamW = .005 + .012 * c.b.x;
    color += paint(.9, f) * (exp(-seamDist / seamW) * 1.5 + exp(-seamDist / (seamW * 8)) * .3);
    float h = tnAttack(c);
    float bandDepth = 1.4 + (1 - h) * 5;
    float band = exp(-pow((z - bandDepth) / (.15 + .08 * bandDepth), 2.f)) * c.hit;
    color += mix(paint(.97, f) * 1.4, filmColor(lateral * .25 + zw * .1, f) * 1.6, smoothstep(.2f, 1.6f, abs(lateral))) * band * 1.5;
    float3 core = deep(.55, f) * .6 + paint(.85, f) * exp(-r * 7) * 1.2;
    return mix(core, color, tnFog(z, c, .03) * smoothstep(40.f, 14.f, z));
}

// ---------------------------------------------------------------- 103 Hyperloop
// Riding a glass vacuum tube at speed: support rings flash past, a guide strip glows along
// the deck and a twilight city streaks by outside. Bass pulses the guide strip in segments,
// highs glint on the glass and attacks run a ring of light down the supports ahead.
float3 hyperloop(Ctx c, constant NativeFrame &f) {
    float2 vanish = tnDrift(c.t * .7, float2(.14, .06)) + float2(0, .05);
    float2 d = tnBend(c.uv, vanish);
    float r = max(length(d), 1e-3f), a = atan2(d.y, d.x);
    float z = 1 / r;
    // Forward drive: zoom travel plus the music clock, so energetic passages surge ahead.
    float drive = c.travel * 4.5 + c.m * 1.2;
    float zw = z + drive;
    // Outside the glass, seen through a shell that ripples with the bass.
    float2 view = c.uv + c.b.x * .045 * float2(sin(zw * 2.1 - c.m * 3 + a * 2), cos(zw * 1.7 - c.m * 2.5 + a)) * smoothstep(.3f, 1.2f, r);
    float horizon = vanish.y - .03;
    float y = view.y - horizon;
    float3 outside;
    if (y > 0) {
        outside = mix(paint(.62, f) * .5, deep(.08, f) * .18, smoothstep(0.f, 1.1f, y));
        outside += paint(.8 + c.b.y * .25, f) * exp(-y * 9) * (.5 + c.b.y * .9);
        float sx = view.x * 7 + c.travel * .08;
        float tower = hash11(floor(sx) + 3);
        float top = .03 + .2 * tower * tower;
        if (y < top) {
            float2 wc = float2(sx * 4, y * 70);
            float windowHash = hash21(floor(wc));
            float window = step(.7f, windowHash) * step(.3f, fract(wc.x)) * step(.35f, fract(wc.y));
            outside = deep(.15, f) * .12 + paint(.75 + tower * .2, f) * window * (.7 + c.b[int(windowHash * 13) & 3] * 2.5);
        }
        outside += paint(.9, f) * step(.996f, hash21(floor(view * 140))) * smoothstep(.25f, .8f, y) * .6;
    } else {
        float depth = .55 / max(-y, .004f);
        float X = (view.x - vanish.x) * depth;
        float Zg = depth + drive;
        float2 cellSize = float2(1.4, 3.2);
        float2 gid = floor(float2(X, Zg) / cellSize);
        float2 h2 = hash22(gid);
        float lx = (gid.x + .2 + .6 * h2.x) * cellSize.x;
        float lz = (gid.y + .4 * h2.y) * cellSize.y;
        float trail = .5 + 1.4 * f.camera.w;
        float along = Zg - lz;
        float inStreak = smoothstep(0.f, .15f, along) * smoothstep(trail, 0.f, along);
        float lateralScreen = abs(X - lx) / depth;
        float lamp = (exp(-lateralScreen * 260) + exp(-lateralScreen * 40) * .25) * inStreak * step(.35f, h2.y);
        outside = deep(.2, f) * .07 + paint(.6 + c.b.y * .25, f) * exp(y * 14) * (.35 + c.b.y * .6);
        outside += paint(h2.x * .8 + .1, f) * lamp * (2.2 + c.b[int(h2.x * 3.99)] * 4) * exp(-depth * .05);
    }
    float3 color = outside * .85 + paint(.5, f) * .03;
    color += paint(.55, f) * .1 * smoothstep(.6f, 2.f, r);
    float sheen = exp(-pow(tnWrap(a - 2.1) / .04, 2.f)) + exp(-pow(tnWrap(a - 1.05) / .03, 2.f)) * .6;
    color += paint(.8, f) * sheen * (.22 + c.b.z * .6) * (.6 + .4 * sin(zw * .3));
    // Glints on the glass.
    float2 gc = float2((a / TAU + .5) * 48, zw * 2);
    float gh = hash21(floor(gc) + 5);
    float glint = smoothstep(.3f, 0.f, length(fract(gc) - .5)) * step(.86f, gh) * pow(.5 + .5 * sin(c.t * 9 * (.5 + gh) + gh * 30), 8.f);
    color += paint(.9, f) * glint * c.b.w * 3.5 * exp(-z * .2);
    // Deck and guide strip along the floor.
    float floorAngle = tnWrap(a + PI * .5);
    float deck = smoothstep(.43f, .4f, abs(floorAngle));
    if (deck > 0) {
        float3 deckColor = deep(.3, f) * .08 * (.6 + .4 * step(.1f, fract(zw * .8)));
        deckColor += paint(.6, f) * exp(-(.42 - abs(floorAngle)) * r * 90) * .5;
        float strip = smoothstep(.05f, .035f, abs(floorAngle)) * step(fract(zw * 1.2), .6f);
        float pulse = 1 + c.b.x * 3.5 * pow(.5 + .5 * sin(zw * .7 - c.t * 5 - c.m * 4), 4.f);
        deckColor += paint(.7, f) * strip * 1.4 * pulse + paint(.7, f) * exp(-abs(floorAngle) * r * 30) * .25 * pulse;
        color = mix(color, deckColor, deck);
    }
    // Support rings.
    for (int k = 0; k < 6; ++k) {
        float ribAngle = (float(k) + .5) * TAU / 8 - PI * .5 + TAU / 8;
        float ribDist = r * abs(sin(a - ribAngle));
        color += paint(.62, f) * exp(-ribDist / (.002 + .003 * r)) * (.35 + c.b.z * 1.2) * step(0.f, cos(a - ribAngle));
    }
    float spacing = 1.5 * c.size;
    float ringIndex = floor(zw / spacing + .5);
    float dz = zw - ringIndex * spacing;
    float fwz = fwidth(zw);
    float thick = .11;
    float ringMask = 1 - smoothstep(thick * .5 - fwz, thick * .5 + fwz, abs(dz));
    ringMask = mix(ringMask, thick / spacing, smoothstep(.3f * spacing, spacing, fwz));
    float ringZ = ringIndex * spacing - drive;
    float ringBand = c.b[int(hash11(ringIndex * 3.3) * 3.99)];
    float h = tnAttack(c);
    float front = 2.2 + (1 - h) * 8;
    float flash = c.hit * exp(-pow((ringZ - front) / 1.2, 2.f));
    float leds = pow(.5 + .5 * cos(a * 16), 30.f);
    float3 ringColor = deep(.6, f) * .25 + paint(.65, f) * .35 * (.5 + .5 * abs(sin(a)));
    ringColor += paint(.85 + hash11(ringIndex) * .1, f) * (leds * (.9 + ringBand * 3) + flash * 2.5);
    color = mix(color, ringColor, ringMask);
    // Each ring's lights wash the glass around it with its own band.
    color += paint(.75, f) * exp(-abs(dz) * 8) * (.1 + flash * .5);
    color += paint(.6 + ringBand * .3, f) * exp(-abs(dz) * 2.2) * ringBand * .45;
    float3 end = paint(.7, f) * .45 + paint(.9, f) * exp(-r * 12) * 1.4;
    return mix(end, color, tnFog(z, c, .02));
}

// ---------------------------------------------------------------- 104 Barrel Wave
// Inside the curl of a breaking wave. Deep water climbs the face on the right, arcs
// overhead and falls as a thin backlit lip on the left; foam lines stream around the curl
// toward the bright opening ahead. Bass thickens the foam, highs sparkle spray on the water
// and attacks throw a burst of spray off the lip.
float3 barrelWave(Ctx c, constant NativeFrame &f) {
    float2 vanish = float2(.16 + .08 * sin(c.t * .13), .07 + .05 * sin(c.t * .19 + 1));
    float2 d = tnBend(c.uv, vanish);
    float r = max(length(d), 1e-3f), ang = atan2(d.y, d.x);
    // The water surface heaves with the bass in swells that roll down the barrel.
    float swell = c.b.x * .11 * sin((1 / r + c.travel * 2.2) * .9 - c.m * 2.5 + ang * 2);
    float radius = 1 + .18 * cos(2 * ang + .4) + swell;
    float z = radius / r, zw = z + c.travel * 2.2 + c.m * .6;
    // Angle around the barrel: rising face (about -1.5) to roof (0.8) to falling lip (π).
    // It is unwrapped so its only seam lies inside the trough, which covers it.
    float beta = tnWrap(ang - PI * .25);
    beta = beta < -2.4 ? beta + TAU : beta;
    float cs = 1 / c.size;
    // Water thins from the face (right) over the roof to the lip (left).
    float thin = smoothstep(-1.5f, 2.5f, beta);
    float3 water = mix(deep(.3, f) * .12, paint(.4, f) * .17, smoothstep(-1.5f, 1.2f, beta));
    water = mix(water, paint(.58, f) * .3, smoothstep(1.f, 2.5f, beta));
    water += paint(.75 + c.b.z * .2, f) * pow(thin, 4.f) * (.2 + c.b.z * .6);
    water += paint(.5, f) * swell * 1.6;
    // Foam streaks flowing around the curl, faster when the music drives.
    float s = beta * 1.5 + zw * .2;
    float2 fp = float2(s * .7 - c.t * 1.2 - c.m * 1.1, zw * 6) * cs;
    float n = fbm2(fp + float2(0, fbm2(fp * float2(.6, .2) + c.t * .15, 2) * 2), 4);
    float foam = smoothstep(.6f - .1f * c.b.x, .74f, n);
    float lace = exp(-abs(n - .52) * 40) * (.35 + c.b.w * 1.2);
    float3 color = water + paint(.85, f) * (foam * (.65 + c.b.y * 1.3) + lace) * (.35 + .45 * thin);
    // The flat trough along the bottom.
    float trough = max(smoothstep(PI + .1f, PI + .45f, beta), smoothstep(-1.5f, -1.9f, beta));
    float2 tp = float2(d.x * z * 2.5, (zw + c.t * .8) * 1.4) * cs;
    float troughFoam = smoothstep(.58f, .76f, fbm2(tp, 4));
    float3 troughColor = deep(.32, f) * .22 + paint(.7, f) * exp(-abs(d.x) * 5) * .2 + paint(.85, f) * troughFoam * .45;
    color = mix(color, troughColor, trough);
    // Where the falling lip lands in the trough: a band of churning whitewater.
    float landing = beta;
    float lipEnd = PI + .02 + .14 * sin(zw * .55 - c.t * 1.2) + .07 * sin(zw * 1.7 + c.t * .8);
    float churn = fbm2(float2(landing * 5 - c.t * .6, zw * 3 - c.t * 2.2 - c.m * 1.5) * cs, 4);
    float white = exp(-pow((landing - lipEnd) / (.3 + c.b.x * .15), 2.f)) * smoothstep(.3f, .6f, churn + .15);
    color = mix(color, paint(.82, f) * (.35 + .6 * churn) * (1 + c.b.x * .8), white);
    color += paint(.9, f) * exp(-abs(landing - lipEnd + .3) * 12) * .35;
    // Spray drifting off the lip.
    float2 sc = float2(beta * 9, zw * 4 - c.t * 1.5);
    float sh = hash21(floor(sc) + 3);
    float drop = smoothstep(.22f, 0.f, length(fract(sc) - .5 - (hash22(floor(sc)) - .5) * .4));
    color += paint(.95, f) * drop * step(.78f, sh) * smoothstep(1.7f, 2.6f, beta) * (1 - white) * (1 - trough) * .7;
    // Highs: sparkling glints across the water.
    float2 gl = float2(beta * 30, zw * 10);
    float glh = hash21(floor(gl));
    color += paint(.95, f) * smoothstep(.3f, 0.f, length(fract(gl) - .5)) * step(.93f, glh) * pow(.5 + .5 * sin(c.t * 11 * glh + glh * 50), 6.f) * c.b.w * 3 * exp(-z * .25);
    // Attack: a burst of spray thrown off the lip near the camera.
    float h = tnAttack(c);
    float burstZone = smoothstep(lipEnd - 1.1, lipEnd - .3, beta) * exp(-z * .4);
    float2 bc = float2(beta * 14 + (1 - h) * 3, zw * 7 + (1 - h) * 4);
    float bh = hash21(floor(bc) + 9);
    float burstDrop = smoothstep(.3f, 0.f, length(fract(bc) - .5)) * step(.55f, bh);
    color += (paint(.95, f) * burstDrop * 2.5 + paint(.8, f) * .2) * burstZone * c.hit;
    // The barrel's open end ahead: bright sky over the sea, framed by a ragged foamy rim.
    float rimDepth = 4.6 + .5 * sin(c.t * .27) + .35 * sin(ang * 3 + c.t * .5) + .2 * sin(ang * 5 - c.t * .8);
    float beyond = smoothstep(rimDepth - .2, rimDepth + .2, z);
    float2 view = c.uv - vanish;
    float horizonY = view.y + .03;
    float3 outside = mix(deep(.4, f) * .35 + paint(.6, f) * .25 * step(.6f, noise2(float2(view.x * 60, horizonY * 200 + c.t))), paint(.88, f) * .9, smoothstep(-.004f, .004f, horizonY));
    outside = mix(outside, paint(.55, f) * .5, smoothstep(.02f, .25f, horizonY));
    outside += paint(.95, f) * exp(-length(view - float2(.06, .05)) * 14) * .8;
    float3 mist = paint(.6, f) * .25;
    color = mix(mist, color, tnFog(z, c, .02));
    color = mix(color, outside, beyond);
    color += paint(.9, f) * exp(-abs(z - rimDepth) * 2.5) * .45 * (.6 + .4 * noise2(float2(ang * 4, c.t)));
    return color * .78;
}

// ---------------------------------------------------------------- 105 Magma Tube
// A lava tube: basalt plates split by incandescent cracks, a molten river churning toward
// the viewer along the floor, heat haze and drifting embers. Bass widens the near cracks,
// highs throw embers and attacks make the river spurt.
float3 magmaTube(Ctx c, constant NativeFrame &f) {
    float2 uv = c.uv;
    // Heat haze shimmers harder on the bass.
    float hazeAmount = (.012 + .02 * smoothstep(.3f, -1.f, uv.y)) * (1 + c.b.x * 2.5);
    uv += (float2(noise2(uv * 6 + float2(0, -c.t * 2.2 - c.m * 1.5)), noise2(uv * 6 + float2(7.1, -c.t * 1.9))) - .5) * hazeAmount;
    float2 vanish = tnDrift(c.t * .7, float2(.24, .12)) + float2(0, .06);
    float2 d = tnBend(uv, vanish);
    float r = max(length(d), 1e-3f);
    float theta = atan2(-d.x, d.y);
    float z = 1 / r;
    // Forward drive: zoom travel plus the music clock.
    float drive = c.travel * 1.8 + c.m * .5;
    float zw = z + drive;
    float cs = 1 / c.size;
    float near = exp(-z * .45);
    float floorDistance = PI - abs(theta);
    float2 pc = float2(theta * 1.45, zw * 1.45) * cs;
    float4 v = voronoi(pc, .85, 0);
    float edge = v.y - v.x;
    // Each plate's rim burns with its own band; bass widens the near cracks.
    float plateBand = c.b[int(hash21(v.zw) * 3.99)];
    float crackW = .035 + .1 * c.b.x * near + .03 * plateBand;
    float crack = 1 - smoothstep(crackW * .4f, crackW, edge);
    float heat = exp(-edge * (9 - 4 * c.b.x * near - 3.5 * plateBand));
    float flicker = .75 + .25 * noise2(v.zw * 3.1 + c.t * 1.3);
    float3 rock = deep(.06, f) * (.08 + .3 * fbm2(pc * 4, 3)) * (.5 + .5 * smoothstep(0.f, .3f, edge));
    float under = smoothstep(2.2f, .6f, floorDistance);
    rock += paint(.35, f) * under * .12;
    rock += paint(.3, f) * plateBand * .1 * smoothstep(.0f, .25f, edge) * (.5 + .5 * fbm2(pc * 4 + 7, 2));
    float3 color = rock + paint(.34 + .32 * heat + plateBand * .12, f) * (crack * 1.2 + heat * .5) * flicker * (1 + plateBand * 1.4);
    float riverHalf = .52 + .07 * sin(zw * .8 + c.t * .4) + .04 * sin(zw * 2.1 - c.t * .7);
    float riverMask = smoothstep(riverHalf + .04, riverHalf - .04, floorDistance);
    if (riverMask > 0) {
        float X = d.x * z;
        float2 rp = float2(X * 1.7, (zw + c.t * 1.6 + c.m * 1.2) * .7) * cs;
        float2 rw = float2(fbm2(rp * .8 + float2(0, c.t * .3), 3), fbm2(rp * .8 + float2(4.3, -c.t * .25), 3));
        float rn = fbm2(rp * 1.2 + rw * 2.4, 4);
        float crust = smoothstep(.45f, .55f, rn);
        float3 molten = paint(.3 + .36 * smoothstep(.5f, .2f, rn), f) * (.8 + .7 * smoothstep(.5f, .2f, rn));
        float3 river = mix(molten * (1 + c.b.x * .9), deep(.1, f) * .2 + paint(.35, f) * .15, crust * .9);
        color = mix(color, river, riverMask);
    }
    color += paint(.7, f) * exp(-abs(floorDistance - riverHalf) * 14) * (.6 + c.b.y * 1.2);
    // Embers drifting toward the camera.
    for (int i = 0; i < 2; ++i) {
        float rho = .5 + .3 * float(i);
        float ze = rho / r;
        if (ze < .3) continue;
        float count = 30 + 10 * float(i);
        float swirl = theta + c.t * (.12 + .05 * float(i)) + c.m * .1;
        float2 ec = float2(swirl / TAU * count, (ze + drive + c.t * .5) * 2.5);
        float2 eid = floor(ec);
        eid.x -= count * floor(eid.x / count);
        float eh = hash21(eid + float(i) * 37);
        float2 el = fract(ec) - .5 - (hash22(eid) - .5) * .5;
        float density = .05 + .3 * c.b.w;
        float ember = smoothstep(.16f, 0.f, length(el)) * smoothstep(density, density - .04f, eh);
        color += paint(.8, f) * ember * 2 * smoothstep(.3f, .8f, ze) * exp(-ze * .25);
    }
    // Attack: lava spurts from vents in the river.
    float h = tnAttack(c);
    const float ventSpacing = 6;
    float base = floor(drive / ventSpacing);
    for (int k = 1; k <= 3; ++k) {
        float ventDepth = (base + float(k)) * ventSpacing - drive;
        if (ventDepth < .6) continue;
        float vx = (hash11(base + float(k)) - .5) * .8;
        float2 foot = float2(vx, -.9) / ventDepth;
        float height = (.3 + .9 * h) / ventDepth;
        float2 q = d - foot;
        float column = exp(-abs(q.x) / (.06 / ventDepth)) * smoothstep(height, 0.f, q.y) * smoothstep(-.02f / ventDepth, 0.f, q.y);
        float splash = exp(-length(q - float2(0, height)) / (.1 / ventDepth));
        color += paint(.75, f) * (column * 2.5 + splash * 1.5) * c.hit;
    }
    float3 smoke = deep(.3, f) * .3 + paint(.55, f) * exp(-r * 5) * .8;
    return mix(smoke, color, tnFog(z, c, .04));
}

// ---------------------------------------------------------------- 106 Data Conduit
// A cylindrical circuit board: traces, vias and chips in deep tones, with data packets
// racing along the traces in both directions. Each trace layer's packet density follows
// its own band; attacks fire a broad packet burst out of the vanishing point.
float3 dataConduit(Ctx c, constant NativeFrame &f) {
    float2 vanish = tnDrift(c.t * .8, float2(.22, .14));
    float2 d = tnBend(c.uv, vanish);
    float r = max(length(d), 1e-3f), a = atan2(d.y, d.x) + c.t * .05;
    float z = 1 / r;
    const float speed = 3.4, N = 72;
    // Forward drive: zoom travel plus the music clock.
    float zw = z + c.travel * speed + c.m * .8;
    float2 g = float2(a / TAU * N, zw * N / TAU);
    float2 cell = floor(g), local = fract(g) - .5;
    float cx = cell.x - N * floor(cell.x / N);
    float2 fw = fwidth(g);
    float blur = smoothstep(.3f, .9f, max(fw.x, fw.y));
    float tw = .09 * c.size;
    // Board layout.
    float segRow = cell.y - 9 * floor(cell.y / 9);
    float laneOn = step(hash11(cx * 1.37 + 2), .58) * step(hash21(float2(cx, floor(cell.y / 9))), .85);
    float lane = laneOn * (1 - smoothstep(tw - fw.x, tw + fw.x, abs(local.x)));
    float crossRow = step(hash11(cell.y * .731 + 4), .3);
    float crossOn = crossRow * step(hash21(float2(floor(cx / 4), cell.y) + 5), .45);
    float crossLine = crossOn * (1 - smoothstep(tw - fw.y, tw + fw.y, abs(local.y)));
    float viaAt = max(laneOn * step(segRow, .5), laneOn * crossOn);
    float viaRing = abs(length(local) - .2);
    float via = viaAt * (1 - smoothstep(.07f - fw.x, .07f + fw.x, viaRing));
    float traces = max(max(lane, crossLine), via);
    float2 chipLocal = float2(cx - 14 * floor(cx / 14) - 4 + local.x + .5, cell.y - 15 * floor(cell.y / 15) - 5 + local.y + .5);
    float chipOn = step(hash21(float2(floor(cx / 14), floor(cell.y / 15)) + 11), .7);
    float chipBody = sdBox2(chipLocal - float2(3, 2.5), float2(2.6, 2.0));
    float pinRow = step(abs(abs(chipLocal.y - 2.5) - 2.35), .3) * step(abs(chipLocal.x - 3), 2.3f);
    float pins = pinRow * step(abs(fract(chipLocal.x * 2) - .5), .2);
    // Each trace layer glows with its own band; board sectors are backlit by theirs.
    float layer = floor(hash11(cx * 3.7 + 1) * 4);
    float band = c.b[int(layer)];
    float rowBand = c.b[int(hash11(cell.y * .61 + 2) * 3.99)];
    float sectorBand = c.b[int(hash21(float2(floor(cx / 6), floor(cell.y / 6)) + 21) * 3.99)];
    float3 board = deep(.3, f) * .15 * (.85 + .3 * hash21(float2(floor(cx / 2), floor(cell.y / 2)) + 3)) * (1 + sectorBand * 1.6);
    float3 copper = deep(.6, f) * .7;
    float traceGlow = max(lane * (1 + band * 2.2), max(crossLine * (1 + rowBand * 2.2), via * (1 + band * 1.5)));
    float3 color = board + copper * traceGlow * (1 - chipOn * step(chipBody, .4f));
    if (chipOn > 0) {
        float bodyMask = 1 - smoothstep(-fw.x, fw.x, chipBody);
        float chipBand = c.b[int(hash21(float2(floor(cx / 14), floor(cell.y / 15)) + 5) * 3.99)];
        float3 chip = deep(.12, f) * .12 + paint(.45 + chipBand * .2, f) * exp(-abs(chipBody) * (14 - 7 * chipBand)) * (.45 + chipBand * 1.2);
        chip += paint(.35, f) * .2 * step(abs(chipLocal.y - 2.5), .1f) * step(abs(chipLocal.x - 3), 1.4f);
        color = mix(color, chip, bodyMask);
        color += copper * 1.1 * pins * (1 - bodyMask);
    }
    // Packets racing along the depth lanes, one band per trace layer; the music clock
    // speeds them up.
    float dir = hash11(cx * 5.3 + 7) < .5 ? -1 : 1;
    float rate = 2 + 3 * hash11(cx * 9.1);
    float pos = (g.y - dir * (c.t * 1.5 + c.m * 1.2) * rate) / 6;
    float slot = floor(pos), fp = fract(pos);
    float density = .22 + .6 * band;
    float present = smoothstep(density, density - .1f, hash21(float2(cx, slot)));
    float dash = smoothstep(0.f, .03f, fp) * smoothstep(.3f, .22f, fp);
    float head = dir > 0 ? smoothstep(.12f, .3f, fp) : smoothstep(.15f, 0.f, fp);
    float3 packetColor = paint(.55 + layer * .12, f);
    float packet = present * dash * laneOn;
    color += packetColor * packet * (exp(-abs(local.x) / (tw * .8)) * (1.5 + head * 1.8) + exp(-abs(local.x) * 5) * .25);
    // Packets hopping around the ring traces.
    float around = (g.x + (hash11(cell.y) < .5 ? -1 : 1) * (c.t * 3 + c.m * 2.5)) / 4;
    float hopId = floor(around) - N / 4 * floor(floor(around) / (N / 4));
    float hop = crossOn * smoothstep(.25f, .15f, abs(fract(around) - .5)) * step(hash21(float2(hopId, cell.y)), .35f);
    color += paint(.75, f) * hop * exp(-abs(local.y) / (tw * .8)) * 1.3;
    // Attack: a packet burst spreading from the vanishing point.
    float h = tnAttack(c);
    float front = 1.2 + 5 * h;
    float zone = smoothstep(front - .8, front, z) * sqrt(h);
    float burst = smoothstep(.55f, 1.f, fract(g.y / 3 + c.t * 4));
    float3 average = board + copper * .3 + packetColor * density * .08;
    color = mix(color, average, blur);
    color += paint(.85, f) * zone * mix(max(lane, crossLine * .7) * (burst * 3 + .6), .5f, blur);
    float3 core = paint(.5, f) * .5 + paint(.85, f) * exp(-r * 9) * 1.2;
    return mix(core, color, tnFog(z, c, .03));
}

// ---------------------------------------------------------------- 107 Helix Stair
// Looking straight down a deep stairwell while descending the spiral. Each step's edge is a
// strip light, a handrail coils around the open well and the bottom fades into coloured
// mist. Bass rolls a swell of light down the steps, highs glint on the rail and attacks
// light a run of steps.
float3 helixStair(Ctx c, constant NativeFrame &f) {
    float2 vanish = tnDrift(c.t * .6, float2(.1, .08));
    float2 d = tnBend(c.uv, vanish);
    float r = max(length(d), 1e-4f), a = atan2(d.y, d.x);
    const float R = 1, Ri = .4, S = 18;
    float P = 1.7 * c.size;
    // Descent: zoom travel plus the music clock, so energetic passages hurry down.
    float descend = c.travel * .95 + c.m * .3;
    float spin = descend / P * TAU * .45 + c.t * .06;
    float theta = a + spin;
    float stepF = theta * S / TAU;
    float s0 = floor(stepF);
    float frac = stepF - s0;
    float z0 = s0 * P / S - descend;
    float zWall = R / r;
    float need = max(.18f, Ri / r);
    float n = ceil((need - z0) / P);
    float zs = z0 + n * P;
    float stepId = s0 + n * S;
    bool tread = zs * r <= R;
    float zSurface = tread ? zs : zWall;
    float h = tnAttack(c);
    float3 color;
    if (tread) {
        float rho = zs * r;
        float edgeScreen = (1 - frac) * TAU / S * r;
        float wave = pow(.5 + .5 * sin(stepId * .42 - c.t * 3.2 - c.m * 3), 4.f);
        float run = c.hit * smoothstep(P * (.6 + 2.6 * h), P * .4f, zs);
        float stepBand = c.b[int(hash11(stepId * .37) * 3.99)];
        float level = .9 + c.b.x * 1.8 * wave + stepBand * 2.2 + run * 3;
        float3 light = paint(stepId * .037 + .1 + stepBand * .2, f);
        float plank = smoothstep(.0f, .04f, abs(fract((rho - Ri) / (R - Ri) * 3) - .5));
        float3 treadColor = deep(.25 + stepId * .011, f) * .16 * (.55 + .45 * frac) * (.7 + .3 * plank);
        treadColor *= smoothstep(0.f, .25f, frac);
        treadColor += light * exp(-(1 - frac) * TAU / S * rho * (30 - 16 * stepBand)) * .25 * level;
        treadColor += light * (exp(-edgeScreen / .0035) * 2 + exp(-edgeScreen / .02) * .3) * level;
        treadColor += paint(.6, f) * exp(-(rho - Ri) / zs / .006) * .4;
        color = treadColor;
    } else {
        float above = floor((zWall - z0) / P);
        float below = z0 + (above + 1) * P - zWall;
        float groove = smoothstep(.06f, 0.f, abs(fract(theta * 12 / TAU) - .5) - .44);
        float course = smoothstep(.0f, .05f, abs(fract((zWall + descend) * 2.2) - .5) - .42);
        float belowId = s0 + (above + 1) * S;
        float belowBand = c.b[int(hash11(belowId * .37) * 3.99)];
        float3 wallColor = (deep(.3, f) * .3 + paint(.4, f) * .1) * (1 - groove * .6) * (1 - course * .4);
        wallColor += paint(.7 + c.b.z * .2, f) * groove * c.b.z * .5;
        wallColor += paint(belowId * .037 + .1 + belowBand * .2, f) * exp(-below * (4 - 2 * belowBand)) * (.5 + belowBand * 1.4);
        color = wallColor;
    }
    const float railHeight = .22;
    float ramp = theta * P / TAU - descend - railHeight;
    float nr = round((Ri / r - ramp) / P);
    float zr = ramp + nr * P;
    if (zr > .15 && zr < zSurface + .02) {
        float railScreen = abs(r - Ri / zr);
        float railW = .02 / zr;
        float glint = pow(hash21(float2(floor(theta * 64 / TAU + nr * 64), 3)), 12.f) * pow(.5 + .5 * sin(c.t * 7 + theta * 30), 4.f);
        color += paint(.85, f) * (exp(-railScreen / railW) * (1 + glint * c.b.w * 6 + c.b.w * .8) + exp(-railScreen / (railW * 5)) * (.2 + c.b.w * .4));
    }
    float mist = 1 - exp(-zSurface * (.05 + c.fog * .14));
    float3 mistColor = paint(.58 + c.b.y * .25, f) * .32 + paint(.85, f) * exp(-r * 7) * .9;
    return mix(color, mistColor, mist);
}

// ---------------------------------------------------------------- 108 Mirror Regress
// An infinity mirror: nested rounded frames in the canvas shape recede forever, each lined
// with an LED strip in its own colour and tilted against its neighbours. Bands drive running
// lights along individual strips; attacks send a ripple of light inward through the frames.


// ---------------------------------------------------------------- 109 Laser Bore
// A bore built only of laser light: six fans of beams radiate from the vanishing point and
// counter-rotate, laser rings flash past and haze glows between. Each fan's brightness
// follows a band; attacks splay the uppermost fan open.
float3 laserBore(Ctx c, constant NativeFrame &f) {
    float2 vanish = tnDrift(c.t * 1.1, float2(.25, .16));
    float2 d = tnBend(c.uv, vanish);
    float r = max(length(d), 1e-3f), a = atan2(d.y, d.x);
    float z = 1 / r;
    const float speed = 3;
    float zw = z + c.travel * speed;
    float fog = tnFog(z, c, .02);
    float haze = fbm3(float3(cos(a) * 1.5, sin(a) * 1.5, log(r) * 1.4 - c.t * .15), 3);
    float3 color = deep(.15, f) * .07 + deep(.6, f) * .3 * haze * haze;
    float3 scatter = 0;
    for (int i = 0; i < 6; ++i) {
        float fi = float(i);
        float dir = (i & 1) ? -1.f : 1.f;
        float centre = fi * TAU / 6 + dir * (c.t * (.18 + fi * .03) + c.travel * .03);
        float top = .5 + .5 * cos(centre - PI * .5);
        float spread = (.42 + .1 * sin(c.t * .4 + fi * 1.7)) * (1 + c.hit * 1.6 * pow(top, 4.f));
        const float M = 7;
        float local = tnWrap(a - centre);
        float spacing = spread / (M - 1);
        float j = clamp(round(local / spacing + (M - 1) * .5), 0.f, M - 1);
        float beamAngle = (j - (M - 1) * .5) * spacing;
        float dist = r * abs(sin(local - beamAngle));
        float width = .0035 * c.size * (.25 + r);
        float pulse = .6 + .4 * sin(zw * 1.7 - fi * 1.3 + j * 1.1);
        float bright = (.5 + c.b[i & 3] * 1.8) * (.3 + .7 * fog) * pulse;
        float3 beam = paint(fi * .17 + j * .02 + .05, f);
        color += beam * exp(-dist / width) * 1.4 * bright;
        scatter += beam * (exp(-dist / (width * 12 + .02)) + smoothstep(spread * .5f + .12f, spread * .5f - .04f, abs(local)) * .12) * bright;
    }
    color += scatter * (.07 + .2 * haze);
    const float ringSpacing = 2.4;
    float ringBase = floor(zw / ringSpacing + .5);
    for (int k = -1; k <= 2; ++k) {
        float id = ringBase + float(k);
        float ringZ = id * ringSpacing - c.travel * speed;
        if (ringZ < .2) continue;
        float ringR = 1 / ringZ;
        float dist = abs(r - ringR);
        float width = .005 * ringR + c.px;
        float3 ring = paint(hash11(id * 7.1) * .9 + .05, f);
        color += ring * (exp(-dist / width) * 1.3 + exp(-dist / (width * 10)) * .2) * smoothstep(16.f, 5.f, ringZ);
    }
    color += paint(.9, f) * exp(-r * 10) * 1.1 + paint(.6, f) * exp(-r * 3) * .25;
    return color;
}

// ---------------------------------------------------------------- 110 Twist Checker
// A round tube of raised glossy checker tiles whose rings twist with depth and time. Bevels
// catch a sweeping specular light. Bass lifts individual tiles off the wall; attacks flip a
// ring of tiles to bright.
float3 tnCheckerWall(float a, float z, float N, float speed, Ctx c, constant NativeFrame &f) {
    // Bass winds the twist tighter; the music clock speeds both twist and travel.
    float twist = z * (.3 + .14 * c.b.x) + c.t * .22 + c.m * .15;
    float drive = c.travel * speed + c.m * .6;
    float zw = z + drive;
    float2 uv = float2((a + twist) / TAU * N, zw * N / TAU);
    float2 id = floor(uv), l = fract(uv);
    float column = id.x - N * floor(id.x / N);
    float parity = id.x + id.y - 2 * floor((id.x + id.y) * .5);
    float ex = min(l.x, 1 - l.x), ey = min(l.y, 1 - l.y);
    float e = min(ex, ey);
    float top = smoothstep(0.f, .14f, e);
    float2 slope = ex < ey ? float2(l.x < .5 ? -1 : 1, 0) : float2(0, l.y < .5 ? -1 : 1);
    float2 lightDir = normalize(float2(cos(c.t * .4), .8));
    float facing = dot(slope, lightDir) * (1 - top);
    // The two tones drift along the palette with the low-mid and high-mid bands.
    float3 base = parity < .5 ? paint(.16 + c.b.y * .14, f) : paint(.64 + c.b.z * .14, f);
    float rowBand = c.b[int(hash11(id.y * .71) * 3.99)];
    float3 color = base * (.27 + .23 * top + .42 * facing) * (.2 + .8 * smoothstep(0.f, .03f, e)) * (1 + rowBand * .5 * top);
    float sweep = pow(max(cos(a - c.t * .7 - c.m * .8), 0.f), 18.f) * top;
    color += paint(.95, f) * sweep * (.5 + c.b.w * 1.2);
    float lift = c.b.x * smoothstep(.5f, .9f, hash21(float2(column, id.y))) * exp(-z * .2) * 1.2;
    float side = step(l.y, lift * .45);
    color = mix(color * (1 + lift * .9), base * .3, side);
    color += paint(.9, f) * exp(-abs(l.y - lift * .45) * 40) * lift * .8;
    float h = tnAttack(c);
    float rowZ = (id.y + .5) * TAU / N - drive;
    float front = 2.4 + 4 * (1 - h);
    float flip = c.hit * exp(-pow((rowZ - front) / .5, 2.f));
    color = mix(color, paint(.92 + .08 * parity, f) * 1.6 * (.6 + .4 * top), clamp(flip, 0.f, .85f));
    float blur = smoothstep(.3f, .9f, fwidth(uv.y));
    return mix(color, (paint(.16, f) + paint(.64, f)) * .22, blur);
}

float3 twistChecker(Ctx c, constant NativeFrame &f) {
    float2 vanish = tnDrift(c.t, float2(.3, .2));
    float2 d = tnBend(c.uv, vanish);
    float r = max(length(d), 1e-3f), a = atan2(d.y, d.x);
    float z = 1 / r;
    const float speed = 2.6;
    float count = 12 / c.size;
    float n0 = 2 * floor(count * .5);
    float blend = fract(count * .5);
    float3 color = tnCheckerWall(a, z, max(n0, 4.f), speed, c, f);
    if (blend > .001) color = mix(color, tnCheckerWall(a, z, max(n0 + 2, 4.f), speed, c, f), blend);
    color *= .47 + .38 * smoothstep(3.f, .6f, z);
    float3 core = paint(.5, f) * .4 + paint(.85, f) * exp(-r * 8) * 1.1;
    return mix(core, color, tnFog(z, c, .03));
}

// ---------------------------------------------------------------- 111 Foam Tube
// A tunnel of packed iridescent soap bubbles that drift and wobble: clear centres, swirling
// thin-film colour toward the rims and window highlights. Highs shimmer the small bubbles in
// the gaps, bass swells the near bubbles and attacks pop a ring of bubbles that then regrow.
float tnFoamCells(float2 p, float period, float phase, thread float2 &toSite, thread float2 &cellId, thread float &second) {
    float2 cell = floor(p), fr = fract(p);
    float first = 8;
    second = 8;
    for (int y = -1; y <= 1; ++y) for (int x = -1; x <= 1; ++x) {
        float2 g = float2(x, y), id = cell + g;
        float2 wrapped = float2(id.x - period * floor(id.x / period), id.y);
        float2 seed = hash22(wrapped);
        float2 site = g + .5 + .36 * sin(phase * (.6 + seed.yx * .8) + seed * TAU);
        float2 v = site - fr;
        float dd = dot(v, v);
        if (dd < first) { second = first; first = dd; toSite = v; cellId = wrapped; } else if (dd < second) second = dd;
    }
    second = sqrt(second);
    return sqrt(first);
}

float3 tnFoamWall(float a, float z, float N, float speed, Ctx c, constant NativeFrame &f) {
    float zw = z + c.travel * speed;
    float2 p = float2((a / TAU + .5) * N + c.t * .05, zw * N / TAU + c.t * .12);
    float2 toSite, cellId;
    float second;
    float first = tnFoamCells(p, N, c.t * .8, toSite, cellId, second);
    float q = 2 * first / (first + second);
    float cellZ = (cellId.y + .5 - c.t * .12) * TAU / N - c.travel * speed;
    float h = tnAttack(c);
    float front = 1.9 + 4 * (1 - h);
    float pop = c.hit * exp(-pow((cellZ - front) / .7, 2.f));
    float swell = c.b.x * exp(-z * .5);
    float radius = clamp(.93 + .06 * swell - pop * .8, .05f, 1.f);
    float qn = q / radius;
    float seed = hash21(cellId);
    float3 backdrop = deep(.35 + .15 * sin(zw * .2), f) * .07;
    float3 color = backdrop * .6;
    if (qn < 1) {
        float nz = sqrt(1 - qn * qn);
        float thickness = .2 + .7 * (1 - nz) + .35 * noise2(toSite * 3 + seed * 17 + c.t * .3) + c.t * .04 + seed * 2;
        float3 film = filmColor(thickness, f);
        float fresnel = pow(qn, 9.f);
        float swirl = pow(.5 + .5 * sin(thickness * 13 + c.t * .5), 6.f) * (1 - fresnel);
        color = backdrop + film * (.03 + 1.1 * fresnel + .14 * swirl);
        float2 rel = -toSite / radius;
        float2 w0 = rel - float2(-.17, .2);
        float window = exp(-dot(w0, w0) * 160) * 1.2 + exp(-dot(rel - float2(.2, -.22), rel - float2(.2, -.22)) * 400) * .4;
        color += paint(.95, f) * window * (1 - pop);
    }
    float rimLine = exp(-abs(qn - 1) * 45);
    color += filmColor(seed * 1.7 + c.t * .05 + .4, f) * rimLine * (.55 + pop * 4);
    float2 sp = p * 3 + float2(0, c.t * .2);
    float2 sid = floor(sp);
    sid.x -= 3 * N * floor(sid.x / (3 * N));
    float sh = hash21(sid + 13);
    float sr = length(fract(sp) - .5 - (hash22(sid) - .5) * .3) / (.12 + .1 * hash11(sh * 9));
    float small = exp(-abs(sr - 1) * 6) * step(.45f, sh) * smoothstep(.97f, 1.04f, qn);
    float shimmer = .35 + c.b.w * 2.5 * pow(.5 + .5 * sin(c.t * 9 + sh * 40), 3.f);
    color += filmColor(sh * 2 + c.t * .1, f) * small * shimmer * .8;
    float blur = smoothstep(.35f, .9f, fwidth(p.y));
    return mix(color, filmColor(.5, f) * .2, blur);
}

float3 foamTube(Ctx c, constant NativeFrame &f) {
    float2 vanish = tnDrift(c.t * .7, float2(.26, .18));
    float2 d = tnBend(c.uv, vanish);
    float r = max(length(d), 1e-3f), a = atan2(d.y, d.x);
    float z = 1 / r;
    const float speed = 1.5;
    float count = 13 / c.size;
    float n0 = floor(count);
    float blend = fract(count);
    float3 color = tnFoamWall(a, z, max(n0, 4.f), speed, c, f);
    if (blend > .001) color = mix(color, tnFoamWall(a, z, max(n0 + 1, 4.f), speed, c, f), blend);
    float3 core = filmColor(.3 + c.t * .02, f) * .35 + paint(.9, f) * exp(-r * 8);
    return mix(core, color, tnFog(z, c, .03)) * .78;
}

// ---------------------------------------------------------------- 112 Polygon Stack
// A receding stack of thick neon polygon outlines that morph between three and six sides,
// each turned a little further than the one before so the stack twists into a tunnel. Bass
// thickens the near outlines, highs add an echo outline and attacks kick one layer's spin.
// Regular polygon distance (unit circumradius) from polar coordinates.
float tnPolygon(float radius, float a, float sides) {
    float sector = TAU / sides;
    float local = a - sector * floor(a / sector + .5);
    return radius * cos(local) - cos(PI / sides);
}
float tnPolygonMorph(float radius, float a, float sides) {
    float n0 = floor(sides);
    return mix(tnPolygon(radius, a, n0), tnPolygon(radius, a, n0 + 1), smoothstep(0.f, 1.f, sides - n0));
}

float3 polygonStack(Ctx c, constant NativeFrame &f) {
    float2 vanish = tnDrift(c.t * .8, float2(.3, .2));
    float r = length(c.uv - vanish);
    float haze = fbm2(rot(c.uv - vanish, c.t * .05) * 1.5 + float2(0, -c.travel * .3), 3);
    float3 color = deep(.3, f) * (.06 + .06 * haze) + paint(.6, f) * exp(-r * 2.5) * .15;
    float3 hot = paint(.95, f) * .06;
    const int layers = 22;
    for (int k = 0; k < layers; ++k) {
        float2 slot = layerSlot(k, layers, c.travel * .19);
        float phase = slot.x, id = slot.y;
        float fade = layerFade(phase);
        if (fade <= 0) continue;
        float scale = layerScale(phase, 5);
        float2 centre = vanish * (1 - phase) * (1 - phase);
        float kick = c.hit * exp(-pow((phase - .72) / .07, 2.f)) * 1.4;
        float angle = id * .13 + c.t * .12 + kick;
        const float size = 3.2;
        float2 q = c.uv - centre;
        float sides = 4.5 + 1.5 * sin(id * .61 + c.t * .23);
        float dist = tnPolygonMorph(length(q) * scale / size, atan2(q.y, q.x) + angle, sides) * size / scale;
        float radius = size / scale;
        float width = radius * (.007 + .014 * c.b.x * phase * phase) * c.size + c.px * .5;
        if (abs(dist) > width * 26) continue;
        float core = 1 - smoothstep(width - c.px, width + c.px, abs(dist));
        float halo = exp(-abs(dist) / (width * 3));
        float echo = exp(-abs(dist + width * 4) / (width * .35 + c.px)) * c.b.w * 1.6;
        float3 tint = paint(id * .19 + .05 + phase * .1, f);
        color += (tint * (core * .6 + halo * .07 + echo) + hot * core) * fade;
    }
    return color;
}

// ---------------------------------------------------------------- 113 Gyroid Caverns
// A raymarched flight through a gyroid lattice with a corridor carved along the camera's
// path. Glowing contour bands wrap the surfaces under soft subsurface light and fog. Bass
// thickens the bands, highs sparkle on the surfaces, attacks send a glow wave outward from
// the camera.
float2 tnCavernPath(float z) { return float2(sin(z * .21) * 1.1 + sin(z * .09) * .7, cos(z * .17) * .9); }
float tnCavern(float3 p, float s, float wall, thread float &g) {
    float3 q = p / s;
    g = dot(sin(q), cos(q.yzx));
    float shell = (abs(g) - wall) * s * .5;
    float tunnel = 1.1 - length(p.xy - tnCavernPath(p.z));
    return max(shell, tunnel);
}

float3 gyroidCaverns(Ctx c, constant NativeFrame &f) {
    float s = .7 * c.size;
    // The lattice walls swell with the bass; the flight speeds up with the music clock.
    float wall = .22 + .09 * c.b.x;
    float zc = c.travel * 1.4 + c.m * .35;
    float3 ro = float3(tnCavernPath(zc), zc);
    float3 target = float3(tnCavernPath(zc + 2), zc + 2);
    float3 rd = cameraRay(c.uv, target - ro, float3(sin(c.t * .13) * .5, 1, 0), 1.1);
    float t = .05, glowSum = 0, g = 0;
    bool hit = false;
    for (int i = 0; i < 72; ++i) {
        float3 p = ro + rd * t;
        float dd = tnCavern(p, s, wall, g);
        glowSum += exp(-max(dd, 0.f) * 14) * .01;
        if (dd < .0015 * t) { hit = true; break; }
        t += dd * .85;
        if (t > 22) break;
    }
    float3 fogColor = deep(.5, f) * .06 + paint(.55, f) * .05;
    float3 color = fogColor;
    if (hit) {
        float3 p = ro + rd * t;
        const float2 e = float2(.004, -.004);
        float dummy;
        float3 nrm = normalize(e.xyy * tnCavern(p + e.xyy, s, wall, dummy) + e.yyx * tnCavern(p + e.yyx, s, wall, dummy)
            + e.yxy * tnCavern(p + e.yxy, s, wall, dummy) + e.xxx * tnCavern(p + e.xxx, s, wall, dummy));
        float3 q = p / s;
        float level = dot(cos(q * 1.3), sin(q.zxy * 1.3));
        float contour = abs(fract(level * 1.25 + c.t * .06 + c.m * .15) - .5);
        float width = .035 + .06 * c.b.x;
        float band = 1 - smoothstep(width * .5f, width, contour);
        float bandGlow = exp(-contour * 9);
        float diffuse = max(dot(nrm, -rd), 0.f);
        float rim = pow(1 - diffuse, 2.f);
        float occlusion = clamp(tnCavern(p + nrm * .35, s, wall, dummy) / .35, 0.f, 1.f);
        float3 base = deep(.2 + level * .1 + c.b.y * .25, f) * (.05 + .45 * diffuse) * (.3 + .7 * occlusion);
        base += paint(.4 + level * .1 + c.b.z * .25, f) * rim * (.3 + c.b.z * .6);
        base += paint(.75 + .1 * level, f) * (band * 1.5 + bandGlow * (.25 + .7 * c.b.x));
        float3 sparkCell = floor(p * 9);
        float3 sparkOffset = fract(p * 9) - .5 - (hash33(sparkCell) - .5) * .5;
        float sparkle = step(.93f, hash31(sparkCell)) * exp(-dot(sparkOffset, sparkOffset) * 60) * pow(.5 + .5 * sin(c.t * 8 + dot(sparkCell, float3(7, 11, 13))), 4.f);
        base += paint(.95, f) * sparkle * c.b.w * 4;
        float h = tnAttack(c);
        float waveDistance = 2.5 + 8 * (1 - h);
        base += paint(.9, f) * c.hit * exp(-pow((t - waveDistance) * 2.5, 2.f)) * 1.6;
        color = mix(fogColor, base, exp(-t * (.05 + c.fog * .12)));
    }
    return (color + paint(.6, f) * glowSum * (.5 + c.b.z * .9)) * .88;
}

// ---------------------------------------------------------------- 114 Spectrum Bore
// A tube built from equalizer bars: every column of the wall extrudes inward to a height set
// by the bands (lows on the floor, highs on the ceiling, mixes between), ring after ring
// receding with travel. Bar faces are segmented like LED meters with bright peak caps.
// With no music the bars still breathe on a slow wave.
float tnBarLevel(float column, float ring, float angle, Ctx c) {
    float x = (sin(angle) * .5 + .5) * 3;
    int i0 = int(min(floor(x), 2.f));
    float band = mix(c.b[i0], c.b[i0 + 1], x - float(i0));
    float h = hash21(float2(column, ring));
    float breathe = .5 + .5 * sin(c.t * 1.9 + column * .8 + ring * .55);
    return .08 + .12 * breathe * (.6 + .4 * h) + band * (.18 + .26 * h);
}
// Attack lift for one ring of bars that rides away from the camera as the attack decays.
float tnBarKick(float ring, float travel, float spacing, Ctx c) {
    float front = 1.6 + 5 * (1 - tnAttack(c));
    return c.hit * .22 * exp(-pow((ring * spacing - travel - front) / spacing, 2.f));
}

float3 spectrumBore(Ctx c, constant NativeFrame &f) {
    float2 vanish = tnDrift(c.t * .9, float2(.24, .15));
    float2 d = tnBend(c.uv, vanish);
    float r = max(length(d), 1e-3f), a = atan2(d.y, d.x);
    const float columns = 28, spacing = .9, barLength = .5, speed = 2.4, segment = .045;
    float travel = c.travel * speed;
    float colF = (a + PI) / TAU * columns;
    float column = floor(colF);
    float fa = colF - column - .5;
    float columnAngle = (column + .5) / columns * TAU - PI;
    float barHalf = min(.36 * c.size, .48f);
    float zWall = 1 / r;
    int hitType = 0;
    float zHit = zWall, level = 0, ringId = 0;
    if (abs(fa) < barHalf) {
        float zMin = .3 / r;
        float first = floor((zMin + travel) / spacing);
        for (int m = 0; m < 10; ++m) {
            float ring = first + float(m);
            float zs = ring * spacing - travel, ze = zs + barLength;
            if (zs > zWall) break;
            if (ze < .05) continue;
            float lv = tnBarLevel(column, ring, columnAngle, c) + tnBarKick(ring, travel, spacing, c);
            float zc = (1 - lv) / r;
            if (zc < zs) {
                if (zs * r <= 1 && zs > .05) { hitType = 2; zHit = zs; level = lv; ringId = ring; }
                break;
            }
            if (zc <= ze) { hitType = 1; zHit = zc; level = lv; ringId = ring; break; }
        }
    }
    float side = smoothstep(barHalf, barHalf * .6f, abs(fa));
    float3 color;
    if (hitType == 1) {
        float along = (zHit - (ringId * spacing - travel)) / barLength;
        float3 barTint = paint(.05 + level * 1.5, f);
        float outline = 1 - smoothstep(.0f, .12f, barHalf - abs(fa)) * 1;
        color = barTint * (.05 + .1 * (1 - along)) + barTint * outline * .5 * (1 - along * .6);
        color += paint(.95, f) * exp(-along * 30) * .7 + barTint * exp(-(1 - along) * 25) * .3;
    } else if (hitType == 2) {
        float height = 1 - zHit * r;
        float cells = height / segment;
        float blur = fwidth(cells);
        float lit = smoothstep(.12f, .12f + blur + .05f, fract(cells)) * smoothstep(.92f, .88f - blur, fract(cells));
        lit = mix(lit, .75f, smoothstep(.3f, 1.f, blur));
        float peak = exp(-(level - height) / (segment * .6));
        color = paint(.05 + height * 1.5, f) * (.12 + 1.2 * lit) * (.75 + .25 * side) + paint(.95, f) * peak * lit * .9;
    } else {
        float zw = zWall + travel;
        float ring = floor(zw / spacing);
        float u = zw - ring * spacing;
        float lvNext = tnBarLevel(column, ring + 1, columnAngle, c);
        float lvHere = tnBarLevel(column, ring, columnAngle, c);
        float columnLight = smoothstep(.55f, .1f, abs(fa));
        color = deep(.35, f) * .04 * (.6 + .4 * columnLight);
        color += paint(.05 + lvNext * 1.5, f) * exp(-(spacing - u) * 6) * .3 * columnLight;
        color += paint(.05 + lvHere * 1.5, f) * .06 * step(u, barLength) * columnLight;
        color += paint(.5, f) * .1 * exp(-abs(u - barLength) * 30 / max(fwidth(zw) * 8, 1.f));
    }
    float3 core = paint(.6, f) * .35 + paint(.85, f) * exp(-r * 8) * 1.1;
    return mix(core, color, tnFog(zHit, c, .03));
}

// ---------------------------------------------------------------- 115 Ribbon Vortex
// Broad translucent silk ribbons spiral together into a tube, each at its own radius and
// corkscrew rate, folding softly and overlapping in additive light. Bass widens the ribbons,
// highs sparkle along their edges and attacks ripple their edges outward.


// ---------------------------------------------------------------- 116 Gate Run
// Flying down an endless avenue of tall lacquered arch gates on a gently curving path over
// a mirror-dark floor, each gate hung with glowing lanterns against a horizon glow. Bass
// swings the lanterns, highs flicker their flames and attacks light a gate's beam trim.


// Gate facade at world position (X, Y) on its plane: rgb, opacity and additive lantern glow.


#define TUNNEL_EFFECTS(X) X(plasmaBore) X(ledCorridor) X(prismShaft) X(hyperloop) X(barrelWave) X(magmaTube) X(dataConduit) X(helixStair)  X(laserBore) X(twistChecker) X(foamTube) X(polygonStack) X(gyroidCaverns) X(spectrumBore)
TUNNEL_EFFECTS(NATIVE_EFFECT)

// Coaster versions: the same designs riding the roller-coaster course.
NATIVE_COASTER(plasmaBore, 100, false)
NATIVE_COASTER(ledCorridor, 101, true)
NATIVE_COASTER(magmaTube, 105, false)
NATIVE_COASTER(dataConduit, 106, false)
NATIVE_COASTER(helixStair, 107, false)
NATIVE_COASTER(laserBore, 109, false)
NATIVE_COASTER(twistChecker, 110, false)
NATIVE_COASTER(foamTube, 111, false)
NATIVE_COASTER(spectrumBore, 114, false)
