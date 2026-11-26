// Liquid, molten and wave designs. Original PulseCanvas procedural code.
// Every effect receives Ctx from NativeCommon.metal; audio terms are zero at zero Chaos.

// ------------------------------------------------------------------ 31 Silk Cascade
// Layered satin drapes hang at different depths and drift toward the viewer. Pleats run
// down each drape; bass deepens them, attacks send a gust across the cloth, and highs
// tighten the satin highlight.
float silkHeight(float2 p, float id, Ctx c) {
    float drift = c.t * .3 + c.m * .5 + id * 1.7;
    float gust = c.b.x * .6 + c.hit * .5;
    float sway = sin(p.y * .9 + drift) * (.9 + gust * .8) + sin(p.y * 2.3 - drift * 1.3 + id) * .25;
    float pleats = sin(p.x * 5.5 + sway * 1.6 + id * 3.1);
    pleats = sign(pleats) * pow(abs(pleats), .7f);
    float secondary = sin(p.x * 13 + sway * 3 - p.y * .6) * .18;
    float cascade = sin(p.y * 3.4 - drift * 2.2 + p.x * .8) * (.08 + gust * .14);
    return pleats * .5 + secondary + cascade;
}
float3 silkCascade(Ctx c, constant NativeFrame &f) {
    float3 color = deep(.15 + c.uv.y * .06, f) * .05;
    const int count = 5;
    for (int k = 0; k < count; ++k) {
        float2 slot = layerSlot(k, count, c.travel * 0.1);
        float phase = slot.x, id = slot.y, fade = layerFade(phase);
        float scale = layerScale(phase, 2.2) * .7 / c.size;
        float2 p = rot(c.uv, .12 * sin(id * 1.9)) * scale + float2(hash11(id) * 17, id * 5.3);
        float coordinate = p.x * .23 + .12 * sin(p.y * .6 + c.t * .15 + id);
        float gap = abs(fract(coordinate) - .5) * 2;
        float width = .8 + .1 * sin(id * 2.3);
        float edge = c.px * scale * 3;
        float mask = (1 - smoothstep(width - edge, width + edge, gap)) * fade;
        float shadow = (1 - smoothstep(width, width + .25, gap)) * fade;
        float h = silkHeight(p, id, c), e = .006;
        float2 slope = float2(silkHeight(p + float2(e, 0), id, c) - h, silkHeight(p + float2(0, e), id, c) - h) / e;
        float3 n = normalize(float3(-slope * .16, 1));
        float3 light = normalize(float3(-.65, .35, .65));
        float diffuse = max(dot(n, light), 0.f);
        float3 halfway = normalize(light + float3(0, 0, 1));
        float sheen = pow(max(dot(n, halfway), 0.f), 40 + c.b.w * 80 + c.detail * 40);
        float rim = pow(1 - n.z, 2.f);
        float3 cloth = paint(.2 + hash11(id + 3) * .45 + h * .08, f);
        float3 shaded = cloth * (.04 + diffuse * diffuse * .9 + rim * .2) + paint(.92, f) * sheen * (1.1 + c.detail);
        shaded *= .75 + .25 * smoothstep(width, width * .6, gap);
        float depthTone = mix(.3, 1., phase) * (1 - c.fog * .4 * (1 - phase));
        color *= 1 - shadow * .7;
        color = mix(color, shaded * depthTone, mask);
    }
    return color;
}

// ------------------------------------------------------------------ 33 Ribbon Foundry
// Broad forged ribbons twist through depth. Each shows a chrome face and a hot face; the
// twist reveals one, then the glowing edge, then the other. Music speeds individual
// twists, bass curls the ribbons and highs heat their edges.
float3 ribbonFoundry(Ctx c, constant NativeFrame &f) {
    float3 color = deep(.08 + c.screen.y * .1, f) * .05;
    color += paint(.9, f) * pow(noise2(c.uv * 3 + c.t * .1), 6.f) * .05;
    const int count = 9;
    for (int k = 0; k < count; ++k) {
        float2 slot = layerSlot(k, count, c.travel * 0.09);
        float phase = slot.x, id = slot.y, fade = layerFade(phase);
        float scale = layerScale(phase, 2.6) * .6;
        float angle = (hash11(id * 7.1) - .5) * 1.2;
        float2 p = rot(c.uv, angle) * scale + float2(id * 2.3, (hash11(id) - .5) * 1.4);
        float band = hash11(id * 3.3);
        float curl = .38 + c.b.x * .3 * (band < .5 ? 1. : .6);
        float center = curl * sin(p.x * 1.1 + c.t * .4 + id) + .18 * sin(p.x * 2.6 - c.t * .3 + id * 2);
        center += c.hit * .12 * sin(p.x * 5 - c.m * 6 + id);
        float twist = p.x * (1.4 + band) + c.t * (.6 + band * .5) + c.m * (.8 + band) + id;
        float facing = cos(twist);
        float halfWidth = .2 * c.size * max(abs(facing), .045);
        float across = (p.y - center) / halfWidth;
        float pixel = c.px * scale / halfWidth;
        float body = (1 - smoothstep(1 - pixel, 1 + pixel, abs(across))) * fade;
        float bevel = sqrt(max(0.f, 1 - across * across));
        float3 n = normalize(float3(0, sin(twist) + across * .45 * facing, abs(facing) * (.5 + .5 * bevel)));
        float3 light = normalize(float3(.3, .6, .75));
        float specular = pow(max(dot(reflect(-light, n), float3(0, 0, 1)), 0.f), 24.f);
        float3 chrome = paint(.3 + band * .4 + n.y * .2, f) * (.15 + .5 * max(dot(n, light), 0.f)) + paint(.95, f) * specular * 1.4;
        float3 molten = paint(.75 + n.y * .15, f) * (.65 + .35 * bevel) * 1.4;
        float3 face = facing > 0 ? chrome : molten;
        float edge = pow(abs(across), 8.f) * (1 - abs(facing)) * (1.2 + c.b.w * 2);
        face += paint(.9, f) * edge;
        float depthTone = mix(.3, 1., phase);
        color = mix(color * (1 - .4 * fade * exp(-abs(across) * .5) * step(1.f, abs(across))), face * depthTone, body);
        color += paint(.85, f) * exp(-max(abs(across) - 1, 0.f) * 6) * .04 * fade * (1 - body);
    }
    return color;
}

// ------------------------------------------------------------------ 40 Lava Estuary
// An oblique flight over a molten delta: cooled crust plates drift on glowing rivers.
// Bass opens the cracks where surges pass, attacks flare the seams, highs lift embers.


// ------------------------------------------------------------------ 78 Ferrofluid Crown
// One continuous liquid height field: smooth magnetic crowns and travelling capillary
// waves. Analytic slopes keep reflections joined across the triangular lattice.


// ------------------------------------------------------------------ 79 Windowpane Drizzle
// Rain running down a window in front of soft city lights. Every drop is a lens that
// shows a sharp, inverted view of the lights. Bands brighten individual lights; the
// music clock speeds the running drops.
float3 bokehLights(float2 p, float blur, Ctx c, constant NativeFrame &f) {
    float3 color = deep(.12 + p.y * .05, f) * .22 + paint(.3, f) * .05 * (1 + p.y);
    for (int layer = 0; layer < 3; ++layer) {
        float fl = float(layer);
        float2 q = p * (1.4 + fl * .9) + float2(fl * 7.3, c.t * .025 * (fl + 1));
        float2 base = floor(q);
        for (int y = -1; y <= 1; ++y) for (int x = -1; x <= 1; ++x) {
            float2 cell = base + float2(x, y);
            float seed = hash21(cell + fl * 31);
            if (seed < .3) continue;
            float2 center = cell + .5 + (hash22(cell + fl * 17) - .5) * .8;
            float band = c.b[int(fract(seed * 7.3) * 3.99)];
            float radius = (.32 + fract(seed * 13.1) * .3) * (1 + band * .3);
            float d = length(q - center);
            float soft = blur * (1.4 + fl);
            float disc = 1 - smoothstep(radius - soft, radius + soft, d);
            float ring = exp(-pow((d - radius) / (soft + .03), 2.f)) * .3;
            float shimmer = .65 + .35 * sin(c.t * (.4 + seed) + seed * 40) + c.hit * step(.6, fract(seed * 3.7)) * 1.2;
            color += paint(seed * 1.6 + fl * .25, f) * (disc * .35 + ring * .5) * shimmer * (1 + band * 1.6) / (1 + fl * .6);
        }
    }
    return color;
}
float3 windowpaneDrizzle(Ctx c, constant NativeFrame &f) {
    float2 view = c.uv * (1 - .08 * sin(c.travel * .2)) + float2(0, c.travel * .05);
    float2 refraction = 0.f;
    float drop = 0;
    // Static beads.
    float2 grid = c.uv * 9 / c.size;
    float2 cell = floor(grid), local = fract(grid) - .5;
    float2 seed = hash22(cell);
    float2 bead = local - (seed - .5) * .6;
    float beadRadius = .08 + seed.x * .14;
    float beadMask = 1 - smoothstep(beadRadius * .85, beadRadius, length(bead));
    beadMask *= step(.35, seed.y);
    refraction += bead / beadRadius * beadMask;
    drop = max(drop, beadMask);
    // Running drops with trails.
    float columns = 5 / c.size;
    float x = c.uv.x * columns;
    float column = floor(x);
    float lane = hash11(column * 3.7);
    float speed = .25 + lane * .35;
    float fall = c.t * speed + c.m * .4 * (lane + .3) + lane * 9;
    float y = c.uv.y * columns * .6 + fall;
    float segment = floor(y);
    float local1 = fract(y);
    float wiggle = sin(c.uv.y * 9 + lane * 20) * .08;
    float2 runner = float2(fract(x) - .5 - wiggle - (hash11(segment + column) - .5) * .4, (local1 - .25) * 1.6);
    float runnerRadius = .2 + hash11(column + segment * 1.7) * .1;
    float runnerMask = (1 - smoothstep(runnerRadius * .8, runnerRadius, length(runner * float2(1, .7)))) * step(.3, hash11(segment * 2.1 + column));
    float trail = (1 - smoothstep(.03f, .07f, abs(runner.x))) * smoothstep(.0f, .8f, local1 - .3) * .6 * step(.3, hash11(segment * 2.1 + column));
    refraction += runner / runnerRadius * runnerMask * 1.4;
    drop = max(drop, runnerMask);
    float3 behind = bokehLights(view, .08, c, f);
    float3 through = bokehLights(view * float2(-1, -1) * .6 + refraction * .3 + 2, .015, c, f);
    float3 color = mix(behind * (1 - trail * .3), through * 1.3, drop);
    float3 n = normalize(float3(refraction, 1));
    color += paint(.95, f) * pow(max(dot(n, normalize(float3(-.5, .7, .6))), 0.f), 30.f) * drop * (1 + c.b.w);
    color += paint(.9, f) * trail * .05;
    return color;
}

// ------------------------------------------------------------------ 80 Ink Bloom
// Palette inks billow downward through clear water over a pale ground. Bass makes the
// plumes billow, attacks release fresh puffs, highs add fine filaments.
float3 inkBloom(Ctx c, constant NativeFrame &f) {
    float3 paper = mix(paint(.8, f), paint(1, f), .5) * 1.6;
    float3 color = paper * (.9 + .1 * fbm2(c.uv * 3, 3));
    for (int ink = 0; ink < 3; ++ink) {
        float fi = float(ink);
        float2 p = c.uv * (.9 + fi * .25) / c.size + float2(fi * 3.7, 0);
        p.y += c.t * (.12 + fi * .03) + c.travel * .12;
        float billow = .8 + c.b.x * .5 + c.e * .3;
        float2 warp = float2(fbm2(p * 1.3 + float2(0, c.t * .1) + fi, 4), fbm2(p * 1.3 + float2(5.2, -c.t * .08) + fi, 4));
        float2 q = p + (warp - .5) * 1.6 * billow;
        q += curl2(q * 1.4 + c.m * .3) * (.08 + c.b.x * .08 + c.hit * .1);
        float plume = fbm2(q * 1.6, 5);
        float columns = .5 + .5 * sin(q.x * 2.3 + fi * 2);
        float density = smoothstep(.45, .75, plume * (.75 + .45 * columns));
        float filaments = pow(max(0.f, 1 - abs(fbm2(q * 6 + fi, 3) - .5) * 6), 3.f) * (.25 + c.detail * .4 + c.b.w * .8);
        density = clamp(density + filaments * smoothstep(.3, .6, plume), 0.f, 1.f);
        float3 inkColor = paint(.1 + fi * .32, f);
        color = mix(color, color * inkColor * 1.1, density * .85);
    }
    return color;
}

// ------------------------------------------------------------------ 81 Oil Marble
// Combed marbling with thin-film colors. Slow vortices fold the bands; the music clock
// spins them, bass pulls the comb, attacks drop new rings of ink.
float2 marbleWarp(float2 p, Ctx c) {
    for (int i = 0; i < 4; ++i) {
        float fi = float(i);
        float2 center = float2(sin(c.t * .07 + fi * 2.3), cos(c.t * .06 + fi * 1.7)) * 1.6;
        float2 d = p - center;
        float r = length(d);
        float spin = (.9 + c.b.y * .8) * exp(-r * r * .6) * sin(c.t * .11 + c.m * .4 + fi * 2.1);
        p = center + rot(d, spin);
    }
    p.x += sin(p.y * 3.1 + c.t * .2) * (.12 + c.b.x * .18);
    p.y += sin(p.x * 1.7 - c.t * .15) * .18;
    return p;
}
float3 oilMarblePattern(float2 p, Ctx c, constant NativeFrame &f) {
    float2 q = marbleWarp(p, c);
    float drop = 0;
    for (int i = 0; i < 3; ++i) {
        float beat = floor(c.m * .5 + float(i) / 3);
        float age = fract(c.m * .5 + float(i) / 3);
        float2 center = (hash22(float2(beat, float(i))) - .5) * 3;
        drop += sin(length(q - center) * 14 - age * 6) * exp(-length(q - center) * 1.5) * (1 - age) * smoothstep(0.f, .1f, age);
    }
    float bands = q.y * 2.2 + fbm2(q * 1.5, 4) * 1.4 + drop * (.35 + c.hit * .5);
    float thickness = fract(bands);
    float3 film = filmColor(bands * .35 + c.t * .01, f);
    float vein = exp(-abs(thickness - .5) * 16) * .6;
    return film * (.55 + .45 * smoothstep(.1f, .5f, thickness)) + paint(.95, f) * vein * (.5 + c.hit * .8);
}
float3 oilMarble(Ctx c, constant NativeFrame &f) {
    float3 color = 0.f;
    for (int octave = 0; octave < 2; ++octave) {
        float2 z = octaveZoom(c.travel * .12, octave);
        color += oilMarblePattern(c.uv * z.x * .9 / c.size + float2(0, float(octave) * 0), c, f) * z.y;
    }
    float2 n = curl2(c.uv * 3 + c.t * .05) * .1;
    color += paint(.9, f) * pow(max(0.f, n.x + n.y), 2.f) * .3 * (1 + c.b.w);
    return color;
}

// ------------------------------------------------------------------ 82 Chladni Sand
// Sand piles into the nodal lines of a vibrating brass plate. The mode drifts slowly;
// bass shakes grains off the lines and attacks scatter them, so loud passages blur the
// figure and quiet ones let bold ridges form again.


// ------------------------------------------------------------------ 83 Ripple Tank
// An oblique view across a wide ripple tank. Drifting sources interfere; the curvature of
// the surface focuses light into caustic lines on the floor. Each source follows its own
// band; attacks drop a ring at a new point.
float tankHeight(float2 p, Ctx c) {
    float h = 0;
    float2 cell = floor(p / 2.5);
    for (int y = -1; y <= 1; ++y) for (int x = -1; x <= 1; ++x) {
        float2 id = cell + float2(x, y);
        float2 seed = hash22(id);
        float2 source = (id + .5 + (seed - .5) * .5) * 2.5 + float2(sin(c.t * .2 + seed.x * 6), cos(c.t * .17 + seed.y * 6)) * .35;
        float r = length(p - source);
        float band = c.b[int(seed.x * 3.99)];
        float amplitude = (.35 + band * .8 + c.hit * .5 * step(.5, seed.y)) / (1 + r * .6) * smoothstep(2.5f, 1.2f, r);
        h += amplitude * sin(r * (8 + seed.y * 3) - c.t * 2.2 - c.m * 2 + seed.x * 6);
    }
    float drop = floor(c.m * .7), age = fract(c.m * .7);
    float2 at = (hash22(float2(drop, 3)) - .5) * 6 + float2(0, c.travel * 1.2 + 6);
    float r = length(p - at);
    h += exp(-abs(r - age * 6) * 3) * sin(r * 9 - age * 20) * (1 - age) * smoothstep(0.f, .08f, age) * (.8 + c.hit * 1.6);
    return h * .12;
}
float3 rippleTank(Ctx c, constant NativeFrame &f) {
    // Seen from directly above, drifting across an endless tank.
    float3 g = float3(c.uv, 0);
    float2 p = rot(c.uv, .3) * 3.2 / c.size + float2(c.t * .05, c.travel * 1.2);
    float e = .025;
    float h = tankHeight(p, c);
    float hx = tankHeight(p + float2(e, 0), c), hy = tankHeight(p + float2(0, e), c);
    float hx2 = tankHeight(p - float2(e, 0), c), hy2 = tankHeight(p - float2(0, e), c);
    float laplacian = (hx + hx2 + hy + hy2 - 4 * h) / (e * e);
    float2 slope = float2(hx - hx2, hy - hy2) / (2 * e);
    float2 floorUV = p + slope * .6;
    float2 tile = abs(fract(floorUV * .5) - .5);
    float grout = 1 - smoothstep(.0f, .04f, min(tile.x, tile.y));
    float caustic = clamp(1 - laplacian * .35, 0.f, 5.f);
    caustic = pow(caustic, 3.f) * .6;
    float3 floorColor = deep(.3 + floorUV.x * .02, f) * (.25 - grout * .15);
    float3 color = floorColor * (.4 + caustic * .9) + paint(.85 + h, f) * pow(max(caustic - 1, 0.f), 1.5f) * .5;
    float3 n = normalize(float3(-slope * .5, 1));
    color += paint(.95, f) * pow(max(dot(reflect(float3(0, 0, -1), n), normalize(float3(.3, .4, .85))), 0.f), 60.f) * .6;
    float vignette = 1 - .35 * dot(g.xy, g.xy) / dot(c.extent, c.extent);
    return color * vignette;
}

// ------------------------------------------------------------------ 84 Chrome Metaballs
// A drifting field of liquid-chrome droplets that merge and part as the camera glides
// through them. Each droplet swells with its own band; attacks ripple their skins.
float metaField(float3 p, Ctx c) {
    float3 cell = floor(p / 3), base = cell * 3;
    float3 local = p - base - 1.5;
    float3 octant = sign(local);
    float d = 9;
    for (int i = 0; i < 8; ++i) {
        float3 o = float3(i & 1, (i >> 1) & 1, (i >> 2) & 1) * octant;
        float3 id = cell + o;
        float3 seed = hash33(id);
        float band = c.b[int(seed.x * 3.99)];
        float3 center = (id + .5) * 3 + sin(c.t * (.3 + seed * .4) + seed * TAU) * .9;
        float radius = (.75 + seed.y * .45) * c.size * .9 * (1 + band * .35);
        d = smin(d, length(p - center) - radius, .9);
    }
    d += c.hit * .03 * sin(p.x * 9 + c.m * 5) * sin(p.y * 9) * sin(p.z * 9 - c.m * 4);
    float2 path = float2(sin(c.t * .11) * .8, cos(c.t * .09) * .6);
    return max(d, .9 - length(p.xy - path));
}
float3 chromeMetaballs(Ctx c, constant NativeFrame &f) {
    float3 ro = float3(sin(c.t * .11) * .8, cos(c.t * .09) * .6, c.travel * 1.6);
    float3 rd = normalize(float3(c.uv, 1.4));
    rd.xy = rot(rd.xy, c.t * .04);
    float travel = 0, glow = 0;
    bool hit = false;
    for (int i = 0; i < 44; ++i) {
        float d = metaField(ro + rd * travel, c);
        glow += exp(-max(d, 0.f) * 4) * .012;
        if (d < .002 * (1 + travel * .4)) { hit = true; break; }
        travel += d;
        if (travel > 26) break;
    }
    float3 background = deep(.2 + rd.y * .2, f) * .12 + paint(.6, f) * glow * .4;
    if (!hit) return background;
    float3 p = ro + rd * travel;
    float2 e = float2(.004, 0);
    float3 n = normalize(float3(metaField(p + e.xyy, c) - metaField(p - e.xyy, c), metaField(p + e.yxy, c) - metaField(p - e.yxy, c), metaField(p + e.yyx, c) - metaField(p - e.yyx, c)));
    float3 r = reflect(rd, n);
    float3 environment = mix(deep(.1, f) * .25, paint(.3 + r.y * .3, f) * .8, smoothstep(-.02f, .02f, r.y));
    float2 box = abs(float2(atan2(r.x, r.z) - c.t * .05, r.y - .55));
    box.x = abs(fract(box.x / 1.6 + .5) - .5) * 1.6;
    environment += paint(.95, f) * (1 - smoothstep(.0f, .03f, max(box.x - .3, box.y - .12))) * 2.2;
    environment += paint(.75, f) * exp(-abs(r.y) * 30) * .8;
    environment += deep(.4, f) * .2 * step(r.y, 0.f) * smoothstep(.9f, 1.f, abs(sin(r.x / max(-r.y, .05f) * 3)));
    float fresnel = .4 + .6 * pow(1 - max(dot(-rd, n), 0.f), 3.f);
    float3 color = environment * fresnel;
    float fog = exp(-travel * (.035 + c.fog * .05));
    return mix(background, color, fog);
}

// ------------------------------------------------------------------ 85 Ocean Swell
// Rolling open-ocean swells under a palette dusk. Bass lifts wave groups as they pass,
// highs add chop and glitter, and the camera skims forward with Zoom speed.
float swellHeight(float2 p, Ctx c, int octaves) {
    float h = 0, amplitude = .55 * (1 + c.b.x * .5), frequency = .32;
    float2 direction = normalize(float2(.3, 1));
    for (int i = 0; i < octaves; ++i) {
        float fi = float(i);
        float2 d = rot(direction, fi * 1.37 - .6);
        float phase = dot(p, d) * frequency + c.t * (.7 + fi * .21) + c.m * .25 * fi;
        float wave = 1 - abs(sin(phase));
        h += (wave * wave - .4) * amplitude;
        amplitude *= .52 + c.b.w * .05; frequency *= 1.85;
    }
    return h;
}
float3 oceanSwell(Ctx c, constant NativeFrame &f) {
    // The glide over the swell speeds up with the music clock.
    float3 ro = float3(0, 1.6, c.travel * 2.5 + c.m * .8);
    float3 rd = cameraRay(c.uv, float3(0, -.12, 1), float3(0, 1, 0), 1.5);
    float3 sunDirection = normalize(float3(.25, .18, 1));
    float3 sky = mix(paint(.85, f) * .9, deep(.25, f) * .35, smoothstep(-.05f, .5f, rd.y));
    sky += paint(.98, f) * pow(max(dot(rd, sunDirection), 0.f), 400.f) * 4 + paint(.9, f) * pow(max(dot(rd, sunDirection), 0.f), 8.f) * .4;
    float clouds = fbm2(rd.xz / max(rd.y, .05f) * .6 + c.t * .02, 4);
    sky = mix(sky, paint(.6, f) * .6, smoothstep(.5f, .8f, clouds) * smoothstep(0.f, .2f, rd.y) * .6);
    if (rd.y > 0) return sky;
    float travel = (ro.y + .3) / -rd.y * .5, lastGap = 1;
    for (int i = 0; i < 60; ++i) {
        float3 p = ro + rd * travel;
        float gap = p.y - swellHeight(p.xz, c, 4);
        if (gap < .01) break;
        travel += gap * .7;
        lastGap = gap;
        if (travel > 60) break;
    }
    float3 p = ro + rd * travel;
    float e = .03;
    float h = swellHeight(p.xz, c, 7);
    float3 n = normalize(float3(h - swellHeight(p.xz + float2(e, 0), c, 7), e, h - swellHeight(p.xz + float2(0, e), c, 7)));
    float3 r = reflect(rd, n);
    r.y = abs(r.y);
    float fresnel = .04 + .96 * pow(1 - max(dot(-rd, n), 0.f), 5.f);
    float3 reflected = mix(paint(.85, f) * .9, deep(.25, f) * .35, smoothstep(-.05f, .5f, r.y)) + paint(.98, f) * pow(max(dot(r, sunDirection), 0.f), 120.f) * (3 + c.b.w * 4 + c.hit * 5);
    // Crests glow from within on the low-mids, in bands that roll toward the viewer on the clock.
    float roll = .5 + .5 * sin(p.z * .35 - c.m * 1.8 + p.x * .1);
    float3 water = deep(.3, f) * .12 * (.6 + .4 * max(n.y, 0.f)) + paint(.45 + c.b.z * .15, f) * (.08 + c.b.y * .35 * roll) * smoothstep(-.2f, .6f, h);
    float foam = smoothstep(.45f - c.hit * .12, .75f, h + .1 * fbm2(p.xz * 3, 3)) * (.6 + c.b.x * .5);
    float3 color = mix(water, reflected, fresnel) + paint(.95, f) * foam * .5;
    float distanceFog = 1 - exp(-travel * (.02 + c.fog * .03));
    return mix(color, sky, distanceFog);
}

#define FLOW_EFFECTS(X) X(silkCascade) X(ribbonFoundry)   X(windowpaneDrizzle) X(inkBloom) X(oilMarble)  X(rippleTank) X(chromeMetaballs) X(oceanSwell)
FLOW_EFFECTS(NATIVE_EFFECT)
