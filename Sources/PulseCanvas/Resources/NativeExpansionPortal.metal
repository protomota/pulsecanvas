// Original PulseCanvas designs 310–319: portal tunnels. Each is a perspective tube or portal
// stack whose walls carry one strong surface material (chainmail, feathers, tartan,
// herringbone, quilting, lace, zippers, cable knit, basketry, louvres). Cross-sections and
// cameras vary: a billowing bent bore, a pointed vault, a twisting rounded square, a
// rectangular hall, an off-axis pipe, a lace stack, a helical seam, a padded bent tube,
// an elliptic burrow seen from low down and an octagon. Original procedural code; every
// audio term is zero at zero Chaos.

// ---------------------------------------------------------------- shared portal helpers
// Smooth wandering offset for a vanishing point.
float2 ptlDrift(float t, float2 amount) {
    return float2(sin(t * .21 + .6) + .5 * sin(t * .34 + 2.3), cos(t * .17 + 1.1) + .5 * sin(t * .29 + .2)) / 1.5 * amount;
}
// Bent view: far depths converge on the drifting vanishing point while the near walls stay
// put. One-to-one for |vanish| < .9.
float2 ptlBend(float2 uv, float2 vanish) { return uv - vanish * exp(-dot(uv, uv) * 1.6); }
float ptlFog(float depth, Ctx c, float base) { return exp(-depth * (base + c.fog * .12)); }
float ptlAttack(Ctx c) { return smoothstep(.03f, .65f, c.hit); }
// Attack front: a band of depth that starts near the camera and runs away as the attack
// decays, so every hit sends a local event down the tunnel.
float ptlFront(Ctx c, float depth, float near, float far, float width) {
    float x = (depth - near - (1 - ptlAttack(c)) * far) / width;
    return c.hit * exp(-x * x);
}
float ptlWrap(float x, float period) { return x - period * floor(x / period); }
float ptlBand(Ctx c, float id) { return c.b[min(3, int(ptlWrap(id, 4.f)))]; }

// ---------------------------------------------------------------- 310 Chainmail Bore
// A bent bore lined with interlocking 4-in-1 chainmail. Two staggered ring families tilt
// opposite ways, so every crossing alternates over and under. Bass billows the mesh in
// rolling folds and lights their crests, low-mids roll light behind the mesh, high-mids
// tint the staggered ring family, highs spin bright glints around the rings and attacks run
// a bright ripple through whole linked rings.
struct PtlRing { float cover; float height; float across; float2 dir; float2 centre; float family; };

PtlRing ptlNoRing() {
    PtlRing ring;
    ring.cover = 0; ring.height = -9; ring.across = 0; ring.dir = float2(0, 1); ring.centre = 0; ring.family = 0;
    return ring;
}
PtlRing ptlMailRing(float2 p, float2 centre, float family, float aa) {
    const float radius = .4, wire = .088;
    PtlRing ring;
    float2 l = p - centre;
    float dist = length(l);
    ring.dir = l / max(dist, 1e-4f);
    ring.across = clamp((dist - radius) / wire, -1.f, 1.f);
    ring.cover = 1 - smoothstep(wire - aa, wire + aa, abs(dist - radius));
    // Opposite tilts for the two families make every crossing alternate over and under.
    ring.height = (family > .5 ? -l.y : l.y) / radius;
    ring.centre = centre;
    ring.family = family;
    return ring;
}
float3 ptlMailShade(PtlRing ring, Ctx c, constant NativeFrame &f, float unit, float travel, float crest) {
    float seed = hash21(float2(ptlWrap(ring.centre.x, 20.f), ring.centre.y) + ring.family * 41);
    float s = ring.across;
    float3 n = normalize(float3(ring.dir * s, sqrt(max(0.f, 1 - s * s)) + .2));
    // Each ring has its own light that circles it: the glint spins around the wire.
    float spin = seed * TAU + c.t * (.5 + seed) * (seed > .5 ? 1 : -1);
    float3 light = normalize(float3(cos(spin), sin(spin), 1.1));
    float diffuse = max(0.f, dot(n, light));
    float spec = pow(max(0.f, dot(n, normalize(light + float3(0, 0, 1)))), 28.f);
    float ripple = ptlFront(c, ring.centre.y * unit - travel, .5, 6, .45);
    float twinkle = step(.5f, seed) * pow(.5 + .5 * sin(c.t * 4.3 + seed * 60), 6.f);
    float3 base = paint(.04 + seed * .24 + ring.family * (.3 + c.b.z * .2), f);
    float3 color = base * (.04 + .5 * diffuse) * (1 + ring.family * c.b.z * 2.6 + crest * 2.6);
    color += paint(.95, f) * spec * (.5 + c.b.w * 6 * (.25 + twinkle));
    color += paint(.85 + seed * .1, f) * ripple * (1 + 2.5 * spec + diffuse);
    return color;
}

float3 chainmailBore(Ctx c, constant NativeFrame &f) {
    const float N = 20, unit = TAU / N;
    float2 vanish = ptlDrift(c.t * .6, float2(.3, .2));
    float2 q = ptlBend(c.uv / c.size, vanish);
    float r = max(length(q), 1e-3f), a = atan2(q.y, q.x);
    float travel = c.travel * 2.2, d0 = 1 / r;
    // The mesh hangs in soft folds that roll toward the camera; bass deepens them.
    float fold = .6 * sin(a * 3 + (d0 + travel) * .8 - c.t * .7) + .4 * sin(a * 2 - (d0 + travel) * .5 + c.t * .45);
    float depth = d0 * (1 + (.05 + .22 * c.b.x) * fold);
    float zw = depth + travel;
    float2 p = float2(a, zw) / unit;
    float fw = c.px / c.size * max(1.f, depth) / r / unit;
    float aa = clamp(fw * .75f, .004f, .3f);
    PtlRing best = ptlNoRing(), under = ptlNoRing();
    float2 baseA = floor(p), baseB = floor(p - .5) + .5;
    for (int k = 0; k < 8; ++k) {
        float2 o = float2(float(k & 1), float((k >> 1) & 1));
        PtlRing ring = ptlMailRing(p, (k < 4 ? baseA : baseB) + o, k < 4 ? 0.f : 1.f, aa);
        if (ring.cover > .001) {
            if (ring.height > best.height) { under = best; best = ring; }
            else if (ring.height > under.height) under = ring;
        }
    }
    float crest = max(0.f, fold) * c.b.x;
    float behind = .5 + .5 * sin(zw * .7 - c.t * .8 + sin(a * 2 + c.t * .1) * 1.2);
    float3 back = deep(.5, f) * .03 + paint(.45 + .15 * sin(a + zw * .05), f) * behind * behind * (.02 + .6 * c.b.y);
    back += paint(.85, f) * ptlFront(c, depth, .5, 6, .6) * .4;
    float3 color = back;
    if (under.cover > 0) color = mix(color, ptlMailShade(under, c, f, unit, travel, crest) * .45, under.cover);
    if (best.cover > 0) color = mix(color, ptlMailShade(best, c, f, unit, travel, crest), best.cover);
    float3 average = back * .6 + paint(.2, f) * (.09 + crest * .2);
    color = mix(average, color, smoothstep(.24f, .07f, fw));
    float3 core = paint(.55, f) * .12 + paint(.9, f) * exp(-r * 7) * .8;
    return mix(core, color, ptlFog(depth, c, .045));
}
NATIVE_EFFECT(chainmailBore)

// ---------------------------------------------------------------- 311 Feather Vault
// A pointed vault lined with long overlapping iridescent feathers whose tips flow toward the
// viewer. Farther rows lie on top, like scales, and the feathers lean so the rows spiral.
// Bass lifts waves of feathers (they reach out, catch light and throw shadows), low-mids
// light the shafts, high-mids the vane rims, highs shimmer the barbs and attacks ruffle a
// wave of feathers down the vault.
float ptlVaultRadius(float a) {
    float s = sin(a), co = cos(a);
    // Pointed arch above (two circular arcs meeting at the apex), a flatter oval below.
    if (s > 0) return sqrt(1.55f * 1.55f - .3025f * s * s) - .55f * abs(co);
    return rsqrt(co * co + s * s / .8f);
}
struct PtlFeather { float alpha; float shadow; float3 color; };

PtlFeather ptlFeather(float2 p, float row, float column, Ctx c, constant NativeFrame &f, float aa, float resolve, float rowDepth, float N) {
    PtlFeather fe;
    float seed = hash21(float2(ptlWrap(column, N), row));
    float sway = .5 + .5 * sin(row * .7 + column * 1.3 - c.t * 1.2);
    float ruffle = ptlFront(c, rowDepth, .45, 6, .6);
    float lift = c.b.x * (.2 + .8 * sway * sway) * 1.5 + ruffle * 1.4;
    float y = p.y - row + lift * .2;
    float t = (y + 1.6) / 2.1;                 // 0 at the tip, 1 at the base
    // Feathers lean and their tips curl, so the rows read as a flowing helix.
    float x = p.x - column + t * .95 - .12 * (1 - t) * (1 - t) - .04 * sin(c.t * .7 + seed * 6);
    float halfWidth = .5 * pow(saturate(t * 2.2), .6f) * (1 + lift * .08);
    float edge = abs(x) - halfWidth;
    float body = smoothstep(-.01f, .03f, t) * (1 - smoothstep(.9f, 1.f, t));
    // Barbs sweep from the shaft back toward the base; some vanes split apart.
    float barbCoord = y + abs(x) * 1.6;
    float split = smoothstep(.04f, .015f, abs(fract(barbCoord * .8 + seed * 3) - .5)) * step(.08f, abs(x)) * step(.35f, seed);
    fe.alpha = (1 - smoothstep(-aa, aa, edge)) * body * (1 - split * resolve * .9);
    float st = (y + 1.8 + .2 * lift) / 2.1;
    fe.shadow = (1 - smoothstep(-.1f, .12f, abs(x) - .55f * pow(saturate(st * 2.2), .6f))) * smoothstep(0.f, .1f, st) * (.45 + .55 * saturate(lift));
    float across = saturate(abs(x) / max(halfWidth, 1e-3f));
    float barbs = pow(.5 + .5 * cos(barbCoord * 14 * TAU), 2.f);
    float shimmer = c.b.w * sin(barbCoord * 7 + c.t * 3 + seed * 9);
    float3 film = filmColor(seed * .5 + across * .45 + t * .4 + shimmer * .3 + c.t * .02, f);
    float tuck = mix(1.f, .12f, smoothstep(.22f, .55f, t));
    float barbLight = mix(.55f, .3f + .8f * barbs * (1 + 2.5 * c.b.w), resolve);
    float3 color = film * (.07 + .3 * (1 - across * .6)) * barbLight * tuck;
    color += film * lift * .45 * pow(1 - across * .7, 2.f) * tuck;
    float shaft = line(x, .028 * (1.3 - t * .6), aa) * smoothstep(.02f, .08f, t);
    color += paint(.9, f) * shaft * (.12 + 2.6 * c.b.y) * tuck;
    float rim = smoothstep(-.1f, -.01f, edge);
    color += paint(.72 + seed * .12, f) * rim * (.06 + 2.2 * c.b.z) * tuck;
    color += paint(.92, f) * ruffle * (.4 + barbs) * tuck;
    fe.color = color;
    return fe;
}

float3 featherVault(Ctx c, constant NativeFrame &f) {
    const float N = 22, rowLength = .34;
    float2 vanish = ptlDrift(c.t * .5, float2(.16, .1)) + float2(0, .14);
    float2 q = ptlBend(c.uv / c.size, vanish);
    float r = max(length(q), 1e-3f), a = atan2(q.y, q.x);
    float depth = ptlVaultRadius(a) / r;
    float travel = c.travel * 2.1, zw = depth + travel;
    float2 p = float2(a * N / TAU, zw / rowLength);
    float fw = c.px / c.size / r * max(N / TAU, depth / rowLength);
    float aa = clamp(fw, .004f, .3f);
    float resolve = smoothstep(.1f, .035f, fw);
    float3 color = 0;
    float transmit = 1, shade = 1;
    float baseRow = floor(p.y);
    for (int k = 2; k >= 0; --k) {
        float row = baseRow + float(k);
        float offset = ptlWrap(row, 2.f) * .5;
        float lean = saturate((p.y - row + 1.6) / 2.1) * .95;
        float column = floor(p.x + lean - offset + .5) + offset;
        float other = column + (p.x + lean > column ? 1 : -1);
        float rowDepth = row * rowLength - travel;
        for (int j = 0; j < 2; ++j) {
            PtlFeather fe = ptlFeather(p, row, j == 0 ? column : other, c, f, aa, resolve, rowDepth, N);
            color += transmit * shade * fe.alpha * fe.color;
            transmit *= 1 - fe.alpha;
            shade *= 1 - .65 * fe.shadow;
        }
    }
    color += transmit * shade * deep(.35, f) * .05;
    // The apex rib of the pointed vault.
    float rib = exp(-abs(a - PI * .5) * r * 60) * step(0.f, q.y);
    color += paint(.8, f) * rib * (.12 + .5 * c.b.z);
    float3 core = paint(.65, f) * .25 + paint(.92, f) * exp(-r * 6) * 1.1;
    return mix(core, color, ptlFog(depth, c, .05));
}
NATIVE_EFFECT(featherVault)

// ---------------------------------------------------------------- 312 Tartan Tube
// A twisting rounded-square tube wrapped in tartan: a symmetric sett of crossing thread
// stripes woven as a 2/2 twill, so the diagonal weave shows in every check. Each of the four
// thread colours belongs to one band and brightens with it; attacks send a bright stripe
// along the weft, lighting only the weft floats so the twill flashes.
float ptlSett(float s) {
    float x = abs(fract(s) - .5) * 2;
    return x < .07 ? 3 : x < .36 ? 0 : x < .44 ? 2 : x < .64 ? 1 : x < .7 ? 3 : x < .84 ? 2 : 0;
}
float3 ptlThread(float slot, Ctx c, constant NativeFrame &f) {
    float3 hue = slot < .5 ? paint(.97, f) : slot < 1.5 ? paint(.04, f) : slot < 2.5 ? paint(.74, f) : paint(.5, f);
    float gain = slot < .5 ? .14 : slot < 2.5 ? .22 : .4;
    return hue * (gain + 1.4 * c.b[min(3, int(slot))]);
}

float3 tartanTube(Ctx c, constant NativeFrame &f) {
    const float T = 36, setts = 10, settLength = .75;
    float2 vanish = ptlDrift(c.t * .5, float2(.22, .15));
    float2 q = ptlBend(c.uv / c.size, vanish);
    float r = max(length(q), 1e-3f);
    float travel = c.travel * 2.1;
    // The section twists along the tube, so flying forward slowly rolls the view.
    float twist = (1 / r + travel) * .07 + c.t * .04;
    float a = atan2(q.y, q.x) - twist;
    float ca = cos(a) * cos(a), sa = sin(a) * sin(a);
    float depth = rsqrt(sqrt(ca * ca + sa * sa)) / r;
    float zw = depth + travel;
    float2 yarnPos = float2(a / TAU * setts, zw / settLength) * T;
    float2 cell = floor(yarnPos), local = fract(yarnPos);
    float warpSlot = ptlSett((cell.x + .5) / T), weftSlot = ptlSett((cell.y + .5) / T);
    float twill = ptlWrap(cell.x + cell.y, 4.f);
    bool warpUp = twill < 2;
    float3 warpColor = ptlThread(warpSlot, c, f), weftColor = ptlThread(weftSlot, c, f);
    // Each float is a rounded thread that dips at the ends where it passes under.
    float along = warpUp ? (twill + local.y) * .5 : (twill - 2 + local.x) * .5;
    float dip = .65 + .35 * sin(PI * along);
    float3 woven = (warpUp ? warpColor * (.35 + .65 * sin(PI * local.x)) : weftColor * (.35 + .65 * sin(PI * local.y))) * dip;
    float fw = c.px / c.size / r * max(T * setts / TAU, depth * T / settLength);
    float3 cloth = mix((warpColor + weftColor) * .33, woven, smoothstep(.55f, .2f, fw));
    // Soft drapes in the cloth.
    float drape = .7 + .3 * sin(a * 8 + zw * .6 + sin(zw * .3 + c.t * .2) * 2);
    cloth *= drape;
    float stripe = ptlFront(c, depth, .4, 5, .35);
    float head = pow(.5 + .5 * cos(a - (1 - ptlAttack(c)) * 9), 6.f);
    cloth += paint(.9, f) * stripe * (warpUp ? .25 : 1.3) * (1 + 2 * head);
    float3 core = deep(.25, f) * .12 + paint(.9, f) * exp(-r * 9) * .6;
    return mix(core, cloth, ptlFog(depth, c, .05));
}
NATIVE_EFFECT(tartanTube)

// ---------------------------------------------------------------- 313 Herringbone Hall
// A rectangular hall paved on every surface with 2:1 herringbone tiles and glowing grout;
// the pattern folds continuously around the corners. Bass tilts and lights tiles in chevron
// waves that roll down the hall, low-mids glow the vertical tiles, high-mids sheen the
// horizontal ones, highs light the grout and attacks flash a whole herringbone row.
struct PtlBrick { float2 local; float2 id; float2 centre; float vertical; float edge; };

// Herringbone of 2x1 bricks in brick units: a staircase of horizontal/vertical pairs
// repeating along (1,1) and (0,4).
PtlBrick ptlHerringbone(float2 p) {
    PtlBrick b;
    float m = floor(p.x), lx = p.x - m;
    float yp = p.y - m + 3, n = floor(yp / 4), yl = yp - 4 * n;
    if (yl < 2) {
        b.local = float2(yl, lx); b.id = float2(m - 2, n); b.vertical = 1;
        b.centre = float2(m + .5, m - 2 + 4 * n);
    } else if (yl < 3) {
        b.local = float2(lx + 1, yl - 2); b.id = float2(m - 1, n); b.vertical = 0;
        b.centre = float2(m, m - .5 + 4 * n);
    } else {
        b.local = float2(lx, yl - 3); b.id = float2(m, n); b.vertical = 0;
        b.centre = float2(m + 1, m + .5 + 4 * n);
    }
    b.edge = min(min(b.local.x, 2 - b.local.x), min(b.local.y, 1 - b.local.y));
    return b;
}

float3 herringboneHall(Ctx c, constant NativeFrame &f) {
    const float W = 1.3, H = .82, unit = .15;
    float2 vanish = ptlDrift(c.t * .5, float2(.16, .1));
    float2 q = ptlBend(c.uv / c.size, vanish);
    float ax = abs(q.x) / W, ay = abs(q.y) / H;
    bool wall = ax > ay;
    float depth = 1 / max(max(ax, ay), 1e-3f);
    float travel = c.travel * 2.4, zw = depth + travel;
    float2 hit = q * depth;
    // Perimeter coordinate, continuous around the corners; mid = centre of this surface.
    float across, mid;
    if (wall) {
        if (q.x > 0) { across = 2 * W + H + hit.y; mid = 2 * W + H; }
        else { across = 4 * W + 3 * H - hit.y; mid = 4 * W + 3 * H; }
    } else {
        if (q.y < 0) { across = W + hit.x; mid = W; }
        else { across = 3 * W + 2 * H - hit.x; mid = 3 * W + 2 * H; }
    }
    float2 p = rot(float2(across, zw), PI * .25) / unit;
    PtlBrick b = ptlHerringbone(p);
    float2 cs = rot(b.centre * unit, -PI * .25);
    float rel = cs.y - travel;
    float seed = hash21(b.id + b.vertical * 19);
    float fw = c.px / c.size * depth * max(1.f, depth / (wall ? W : H)) / unit;
    float aa = clamp(fw, .01f, .5f);
    // Chevron waves roll down the hall; bass tilts and lights the tiles they cross.
    float wave = pow(.5 + .5 * sin(rel * 1.6 - abs(cs.x - mid) * 1.4 - c.t * 1.2), 4.f);
    float lit = wave * (.12 + c.b.x);  // a small baseline keeps the corridor moving at zero zoom
    float tilt = (b.local.x - 1) * (.22 + 1.2 * lit) * (seed > .5 ? 1 : -1);
    float3 tile = paint(.02 + seed * .2 + b.vertical * .3, f) * (.05 + .08 * seed);
    float twinkle = .5 + .5 * sin(seed * 23 + c.t * .8);
    tile *= (1 + (b.vertical > .5 ? c.b.y : c.b.z) * 2.6 * twinkle) * (.85 + tilt);
    float bevel = smoothstep(.03f, .16f, b.edge);
    tile *= .55 + .45 * bevel;
    tile += paint(.7 + seed * .12, f) * lit * 1.3 * bevel;
    tile += paint(.92, f) * ptlFront(c, rel, .5, 6, .55) * 1.6;
    float grout = line(b.edge, .045, aa);
    float3 groutColor = paint(.72, f) * (.22 + 2.4 * c.b.w);
    float3 color = mix(tile, groutColor, grout) + groutColor * glow(b.edge, .1) * .1;
    float3 average = paint(.2, f) * .1 + groutColor * .1;
    color = mix(average, color, smoothstep(.35f, .1f, fw));
    // Dark creases where the surfaces meet.
    color *= 1 - .7 * exp(-abs(ax - ay) * depth * 26);
    float3 core = paint(.8, f) * .3 + paint(.95, f) * exp(-max(ax, ay) * 12) * 1.1;
    return mix(core, color, ptlFog(depth, c, .045));
}
NATIVE_EFFECT(herringboneHall)


// ---------------------------------------------------------------- 315 Lace Funnel
// A funnel of layered lace rings drifting toward the viewer against a hot core of light.
// The lace is laid out on conformal log-polar tiles, so every motif keeps its shape at
// every radius: rows of rimmed eyelets in cloth stitch, five-petal flowers over net and
// spotted net, with a picot inner edge and a scalloped border. Alternate layers turn against
// each other. Each layer's eyelets glow with its own band, highs light the cords and attacks
// bloom light through the openwork of one layer as it passes.
float4 ptlLace(float2 g, float yIn, float yOut, float aa) {
    float y = g.y - yIn, row = floor(y);
    float shift = ptlWrap(row, 2.f) * .5;
    float2 l = float2(fract(g.x + shift) - .5, y - row - .5);
    float type = ptlWrap(row, 3.f);
    float e = length(l);
    float cord = 0, cloth = 0, net = 0, hole = 0;
    if (type < .5) {
        // Eyelet band: cloth stitch pierced by a rimmed eyelet, small holes at the corners.
        float corner = length(abs(l) - .5);
        hole = max(fill(e - .13, aa), fill(corner - .08, aa));
        cord = max(line(e - .17, .045, aa), line(corner - .11, .03, aa));
        cloth = 1;
    } else if (type < 1.5) {
        // Five-petal flower in cloth stitch over net, with a pierced centre.
        float ang = atan2(l.y, l.x);
        float petal = e - (.14 + .28 * pow(abs(cos(ang * 2.5)), .7f));
        cloth = fill(petal, aa);
        cord = max(line(petal, .03, aa), line(e - .075, .025, aa));
        hole = fill(e - .055, aa);
        net = 1;
    } else {
        // Spotted net with a ring motif.
        cloth = fill(e - .08, aa);
        cord = line(e - .24, .03, aa);
        net = 1;
    }
    float4 h = hexCell(g * 5);
    float hexEdge = .5 - max(abs(h.x), max(abs(.5 * h.x + .866 * h.y), abs(.5 * h.x - .866 * h.y)));
    float netThread = mix(.3f, line(hexEdge, .09, aa * 5), smoothstep(.12f, .05f, aa));
    float clothTex = mix(.6f, .5f + .5f * sin((l.x + l.y) * 50) * sin((l.x - l.y) * 50), smoothstep(.05f, .02f, aa));
    // Picot inner edge and scalloped outer border.
    float sx = fract(g.x) - .5;
    float border = yOut - .35 + .35 * sqrt(max(0.f, 1 - 4 * sx * sx));
    float inside = fill(g.y - border, aa) * fill(yIn - g.y, aa);
    float edges = line(g.y - border, .05, aa) + line(g.y - yIn, .05, aa);
    edges += line(length(float2(sx, g.y - yIn + .13)) - .1, .028, aa) * step(g.y, yIn);
    float lace = max(cloth * .85, net * netThread * .7);
    float opacity = max(inside * max(lace, cord), edges) * (1 - hole * inside);
    float glowLight = inside * ((1 - hole) * (cloth * .32 * clothTex + net * (1 - cloth) * netThread * .55));
    return float4(saturate(opacity), glowLight, inside * hole, saturate(inside * cord + edges));
}

float3 laceFunnel(Ctx c, constant NativeFrame &f) {
    const float M = 16;
    float2 uv = c.uv / c.size;
    float ru = length(uv), au = atan2(uv.y, uv.x);
    float rays = .6 + .4 * sin(au * 7 + c.t * .2) * sin(au * 4 - c.t * .13);
    float3 color = deep(.3, f) * .1 + paint(.4, f) * glow(ru, .9) * .25 * rays + paint(.9, f) * glow(ru, .2) * 1.4;
    const float yIn = -2.4, yOut = 2.6;
    const int layers = 6;
    for (int k = 0; k < layers; ++k) {
        float2 s = layerSlot(k, layers, c.travel * .14);
        float id = s.y;
        float sc = layerScale(s.x, 3.6);
        float turn = ptlWrap(id, 2.f) < 1 ? 1 : -1;
        float2 off = float2(sin(id * .9 + c.t * .21), cos(id * .7 + c.t * .17)) * .1 * (1 - s.x);
        float2 p = rot(uv * sc - off, turn * c.t * .1 + id * .6);
        float rr = max(length(p), 1e-3f);
        float2 g = float2(atan2(p.y, p.x), log(rr)) * M / TAU;
        float aa = c.px / c.size * sc / rr * M / TAU;
        float4 lace = ptlLace(g, yIn, yOut, aa);
        float fade = layerFade(s.x);
        float dim = .4 + .6 * s.x;
        float band = ptlBand(c, id);
        float bloom = ptlFront(c, 1 - s.x, .15, .65, .13);
        float3 threadColor = paint(.55 + .15 * sin(id * 1.3), f);
        float3 emit = threadColor * lace.y * .4 * dim + paint(.9, f) * lace.w * (.22 + 1.4 * c.b.w) * dim;
        float3 eyelets = paint(.95, f) * lace.z * (.03 + 2.8 * band + 3 * bloom);
        color = color * (1 - lace.x * fade * .88) + (emit + eyelets + paint(.95, f) * bloom * lace.y * 2) * fade;
    }
    return color;
}
NATIVE_EFFECT(laceFunnel)

// ---------------------------------------------------------------- 316 Zipper Run
// A tube sewn from one continuous helical zipper: the seam spirals down the walls and its
// sliders run along it, opening lens-shaped sections that reveal hot light behind the teeth
// and closing them again. Bass widens the openings, low-mids light the tape stitching,
// high-mids the piping between turns, highs glint the metal teeth and attacks unzip a
// section that runs away down the tube.
float3 zipperRun(Ctx c, constant NativeFrame &f) {
    const float pitch = .85, P = .13, tw = .05;
    float2 vanish = ptlDrift(c.t * .55, float2(.24, .16));
    float2 q = ptlBend(c.uv / c.size, vanish);
    float r = max(length(q), 1e-3f);
    float a = atan2(q.y, q.x) + c.t * .04;
    float depth = 1 / r;
    float travel = c.travel * 2.3, zw = depth + travel;
    // One continuous helical seam: `across` runs along the tube, `along` follows the helix.
    float turns = a / TAU;
    float w = zw - turns * pitch;
    float k = floor(w / pitch + .5);
    float across = w - k * pitch;
    float along = (turns + k) * TAU;
    float aa = clamp(c.px / c.size / r * max(1.f, depth), .002f, .2f);
    // Sliders run along the helix, opening lens-shaped sections and closing them again.
    float lens = .6 * sin(along * .32 - c.t * .9) + .4 * sin(along * .11 + c.t * .35);
    float open = max(0.f, lens - .2) * (.2 + .6 * c.b.x);
    float unzip = ptlFront(c, depth, .4, 5, .6);
    open += unzip * .3 * (.6 + .4 * sin(along * .5));
    float sl = across + open * .5, sr = across - open * .5;
    float nl = floor(along / P + .5), nr = floor(along / P) + .5;
    float2 tl = float2(sl + .8 * tw, along - nl * P), tr = float2(sr - .8 * tw, along - nr * P);
    float2 toothSize = float2(tw * 1.1, P * .24);
    float toothL = sdBox2(tl, toothSize) - P * .05, toothR = sdBox2(tr, toothSize) - P * .05;
    float teeth = fill(min(toothL, toothR), aa);
    bool leftTooth = toothL < toothR;
    float2 tooth = leftTooth ? tl : tr;
    float toothId = leftTooth ? nl : nr + 5000;
    float tape = max(fill(sl + 1.45 * tw, aa), fill(1.45 * tw - sr, aa));
    // Hot light behind the chain.
    float3 lightColor = paint(.04 + .08 * sin(along * .07 + c.t * .2), f) * (1.3 + 3 * unzip);
    float3 color = lightColor;
    // Fabric tapes: fine ribbing, colour drifting along the helix, two stitch lines each.
    float edgeDist = abs(across) - open * .5 - 1.45 * tw;
    float rib = .8 + .2 * sin(abs(across) * 150);
    float fold = smoothstep(pitch * .5f, 0.f, abs(across));
    float3 fabric = paint(.62 + .14 * sin(along * .05 + k), f) * (.05 + .17 * fold) * rib;
    float seams = (line(edgeDist - .03, .006, aa) + line(edgeDist - .06, .006, aa)) * smoothstep(.3f, .55f, fract(along * 16));
    fabric += paint(.35, f) * seams * (.12 + 2.6 * c.b.y);
    color = mix(color, fabric, tape);
    // Metal teeth: rounded crowns with glints on highs.
    float seed = hash21(float2(toothId, k));
    float crown = saturate(1 - abs(tooth.y) / (P * .29));
    float3 metal = paint(.45, f) * (.1 + .7 * crown * crown) + paint(.9, f) * pow(crown, 8.f) * .4;
    metal += paint(.95, f) * pow(seed, 5.f) * c.b.w * 5 * crown;
    color = mix(color, metal, teeth);
    // Light spills over the open edges.
    color += lightColor * glow(abs(across) - open * .5, .02 + open * .3) * .35 * saturate(open * 6);
    // Piping cord where neighbouring turns of the helix are sewn together.
    float pipe = pitch * .5 - abs(across);
    float cord = fill(pipe - .035, aa);
    float3 piping = paint(.8, f) * (.06 + .25 * smoothstep(0.f, .035f, pipe)) * (1 + 3.5 * c.b.z);
    color = mix(color, piping, cord) + paint(.78, f) * glow(pipe, .03) * c.b.z * .5;
    float3 core = paint(.1, f) * .3 + paint(.95, f) * exp(-r * 8) * 1.1;
    return mix(core, color, ptlFog(depth, c, .05));
}
NATIVE_EFFECT(zipperRun)

// ---------------------------------------------------------------- 317 Cable Knit Tube
// A strongly bending tube of chunky cable knit. Seven padded cables run down the walls, each
// two braided strands of plied V stitches crossing over and under, with purl ridges between
// and a soft fibre fuzz, lit by two coloured lights. Bass twists the cables further, each
// cable's stitches brighten with its own band and attacks pull a ripple through the knit.
float3 cableKnitTube(Ctx c, constant NativeFrame &f) {
    const float N = 7, rowsPerColumn = 9, sw = .14;
    float2 vanish = ptlDrift(c.t * .75, float2(.42, .3));
    float2 q = ptlBend(c.uv / c.size, vanish);
    float r = max(length(q), 1e-3f), a = atan2(q.y, q.x) + c.t * .025;
    float u = a * N / TAU;
    float column = floor(u + .5), x = u - column;
    float depth = (1 - .07 * cos(x * TAU)) / r;
    float travel = c.travel * 1.9, zw = depth + travel;
    float colId = ptlWrap(column, N);
    float band = ptlBand(c, colId);
    float pull = ptlFront(c, depth, .4, 5, .55);
    float v = zw * N / TAU + pull * .3;
    float fw = c.px / c.size / r * max(1.f, depth) * N / TAU;
    float resolve = smoothstep(.06f, .02f, fw);
    // Two strands braid around each other; bass twists them further.
    float twist = c.b.x * 2.8 * (.55 + .45 * sin(colId * 1.9 + c.t * .5));
    float phase = v * 2.2 + twist + colId * 1.3;
    float A = sw * (1 + .25 * c.b.x);
    float x1 = A * cos(phase);
    bool firstOver = ptlWrap(floor(phase / PI), 2.f) < 1;
    float d1 = abs(x - x1), d2 = abs(x + x1);
    float aaX = clamp(fw, .002f, .1f);
    float c1 = fill(d1 - sw, aaX), c2 = fill(d2 - sw, aaX);
    bool useFirst = (c1 > .5 && c2 > .5) ? firstOver : d1 < d2;
    float strand = useFirst ? c1 : c2;
    float centre = useFirst ? x1 : -x1;
    // Plied V stitches: two stitch columns per strand, each stitch two leaning yarn legs.
    float vc = (x - centre) / sw + 1;
    float2 sp = float2(fract(vc) - .5, v * rowsPerColumn);
    float rowBase = floor(sp.y);
    float best = 9, along = 0, legSide = 1;
    float2 away = float2(0, 1);
    for (int i = 0; i < 2; ++i) {
        float ry = rowBase + (i == 0 ? 0.f : (fract(sp.y) < .5 ? -1.f : 1.f));
        for (int j = 0; j < 2; ++j) {
            float side = j == 0 ? -1 : 1;
            float2 a0 = float2(side * .4, ry + .95), a1 = float2(side * .06, ry);
            float2 pa = sp - a0, ba = a1 - a0;
            float h = saturate(dot(pa, ba) / dot(ba, ba));
            float2 dv = pa - ba * h;
            float d = length(dv);
            if (d < best) { best = d; along = h; away = dv / max(d, 1e-4f); legSide = side; }
        }
    }
    const float yarn = .21;
    float across = saturate(best / yarn);
    float bump = sqrt(saturate(1 - across * across));
    float legMask = 1 - smoothstep(.85f, 1.05f, best / yarn);
    float ply = .75 + .25 * sin(along * 18 + legSide * across * 3);
    float3 n = normalize(float3(away * across, bump + .05));
    float3 lightA = normalize(float3(-.7, .5, .55)), lightB = normalize(float3(.75, -.35, .55));
    float hue = colId * .09 + (useFirst ? 0 : .12);
    float3 knit = paint(.05 + hue, f) * (.02 + .1 * bump);
    knit += (paint(.12 + hue * .5, f) * max(0.f, dot(n, lightA)) + paint(.7, f) * max(0.f, dot(n, lightB))) * .28 * ply;
    knit *= legMask;
    knit = mix(paint(.3 + hue, f) * .1, knit, resolve);
    // Strands are rounded: their edges fall into shadow, and the strand on top shades the other.
    float strandEdge = sw - abs(x - centre);
    float otherEdge = abs(x - (useFirst ? -x1 : x1)) - sw;
    knit *= smoothstep(-.01f, .05f, strandEdge) * .6 + .4;
    knit *= 1 - .7 * ((useFirst != firstOver) ? smoothstep(.07f, 0.f, otherEdge) : 0.f);
    knit *= 1 + band * 2.8;
    // Purl ridges between the cables.
    float2 pp = float2(x * 18 + .5 * floor(v * rowsPerColumn), v * rowsPerColumn);
    float2 pl = fract(pp) - .5;
    float purlBump = saturate(1 - length(pl * float2(1.1, 1.9)) * 1.5);
    float3 purl = paint(.55 + colId * .05, f) * (.015 + .1 * mix(.4f, purlBump, resolve)) * (1 + band);
    float3 color = mix(purl, knit, strand);
    // Fibre fuzz: a soft halo of stray fibres along the strand edges.
    float fuzz = noise2(float2(u * 50, v * 50)) * glow(min(d1, d2) - sw, .03) * resolve;
    color += paint(.75, f) * fuzz * (.08 + band * .5);
    color += paint(.92, f) * pull * (.3 + bump) * strand * 1.3;
    float3 core = paint(.6, f) * .15 + paint(.9, f) * exp(-r * 8) * .8;
    return mix(core, color, ptlFog(depth, c, .05));
}
NATIVE_EFFECT(cableKnitTube)

// ---------------------------------------------------------------- 318 Basket Weave Burrow
// An elliptic burrow seen from low down, woven from two families of wide helical strips that
// pass over and under each other, with light leaking through the gaps. Bass lifts and shifts
// the strips (opening the gaps), low-mids and high-mids each light one strip family, highs
// brighten the gap light and attacks tighten a weave ring that squeezes down the burrow.
float3 basketWeaveBurrow(Ctx c, constant NativeFrame &f) {
    const float ea = 1.3, eb = .85, h = .3, N = 14;
    float2 vanish = ptlDrift(c.t * .5, float2(.15, .08));
    float2 q = ptlBend(c.uv / c.size, vanish);
    float r = max(length(q), 1e-3f);
    float2 dir = q / r;
    float A = dir.x * dir.x / (ea * ea) + dir.y * dir.y / (eb * eb);
    float B = dir.y * h / (eb * eb), C = h * h / (eb * eb) - 1;
    float R = (B + sqrt(max(0.f, B * B - A * C))) / A;
    float2 P = dir * R;
    float travel = c.travel * 2.0;
    float squeeze = ptlFront(c, R / r, .4, 5, .5);
    float depth = R / r * (1 + .12 * squeeze);
    float zw = depth + travel;
    float phi = atan2((P.y - h) / eb, P.x / ea);
    float2 g = float2(phi * N / TAU, zw * N / 6.8);
    float lift = c.b.x * (.5 + .5 * sin(g.y * .5 - c.t * .9 + phi * 2));
    float2 s = float2(g.x + g.y, g.x - g.y) + lift * .25 * float2(1, -1);
    float2 cell = floor(s), l = fract(s) - .5;
    float fw = c.px / c.size / r * max(N / TAU, depth * N / 6.8) * 1.5;
    float aa = clamp(fw, .01f, .5f);
    float halfWidth = .41 - .12 * lift + .06 * squeeze;
    float coverA = fill(abs(l.x) - halfWidth, aa), coverB = fill(abs(l.y) - halfWidth, aa);
    float hA = cos(PI * (s.y - .5 + cell.x)), hB = -cos(PI * (s.x - .5 + cell.y));
    float topA = smoothstep(-.15f, .15f, hA - hB);
    float3 stripA = paint(.06 + .08 * sin(cell.x * 1.7), f) * (.03 + .22 * (.5 + .5 * hA)) * (1 + 3 * c.b.y);
    float3 stripB = paint(.42 + .08 * sin(cell.y * 1.3), f) * (.03 + .2 * (.5 + .5 * hB)) * (1 + 3 * c.b.z);
    stripA *= 1 - .45 * (l.x / halfWidth) * (l.x / halfWidth);
    stripB *= 1 - .45 * (l.y / halfWidth) * (l.y / halfWidth);
    // A soft sheen on each strip where it crests over its neighbour.
    stripA += paint(.75, f) * pow(saturate(hA), 6.f) * .14 * saturate(1 - abs(l.x) / halfWidth);
    stripB += paint(.75, f) * pow(saturate(hB), 6.f) * .14 * saturate(1 - abs(l.y) / halfWidth);
    // Grain lines along each strip.
    float grain = smoothstep(.4f, .15f, fw);
    stripA *= 1 - grain * .2 * (.5 + .5 * sin(s.y * 40 + cell.x * 3));
    stripB *= 1 - grain * .2 * (.5 + .5 * sin(s.x * 40 + cell.y * 3));
    float3 gap = paint(.8 + .08 * sin(zw * .3), f) * (.5 + 3.5 * c.b.w);
    float3 color = gap;
    color = mix(color, stripB, coverB * (1 - coverA * topA));
    color = mix(color, stripA, coverA * (coverB > 0 ? topA : 1));
    color += gap * glow(min(abs(l.x), abs(l.y)) - halfWidth, .04) * (1 - coverA * coverB) * .2;
    color += paint(.92, f) * squeeze * (.6 + .5 * max(hA, hB));
    float3 average = paint(.3, f) * .12 + gap * .05;
    color = mix(average, color, smoothstep(.45f, .15f, fw));
    float3 core = paint(.8, f) * .3 + paint(.95, f) * exp(-r * 8) * 1.1;
    return mix(core, color, ptlFog(depth, c, .05));
}
NATIVE_EFFECT(basketWeaveBurrow)

// ---------------------------------------------------------------- 319 Louvre Tunnel
// A slowly rolling octagonal tunnel whose faces are banks of angled louvre slats with
// coloured light behind them. Slats open and close in waves; bass opens groups of slat rows,
// low-mids and high-mids brighten the light behind alternate faces, highs glint the
// mullions and attacks snap a ring of slats open so light floods through locally.
float3 louvreTunnel(Ctx c, constant NativeFrame &f) {
    const float rin = .9, P = .14;
    float2 vanish = ptlDrift(c.t * .5, float2(.2, .14));
    float2 q = ptlBend(c.uv / c.size, vanish);
    float r = max(length(q), 1e-3f);
    float a = atan2(q.y, q.x) - c.t * .03;
    float sector = floor(a / (TAU / 8) + .5);
    float local = a - sector * TAU / 8;
    float face = ptlWrap(sector, 8.f);
    float depth = rin / (r * cos(local));
    float across = rin * tan(local);
    float travel = c.travel * 2.2, zw = depth + travel;
    float row = floor(zw / P), zl = zw / P - row;
    float rowDepth = (row + .5) * P - travel;
    float fz = clamp(fwidth(zw) / P, .002f, .5f);
    float wave = .5 + .5 * sin(row * .3 - c.t * 1.3 + face * .7);
    float bassRows = pow(.5 + .5 * sin(row * .8 + face * 1.1 - c.t * .2), 3.f);
    float snap = ptlFront(c, rowDepth, .4, 5, .45);
    float open = clamp(.06 + .36 * wave * wave + 1.4 * c.b.x * bassRows + 1.6 * snap, 0.f, .85f);
    float cover = 1 - open;
    float slat = fill(zl - cover, fz);
    float t01 = saturate(zl / max(cover, .05f));
    bool even = ptlWrap(face, 2.f) < 1;
    float lamp = .45 + .55 * cos(across / (rin * .41421356) * 1.3);
    float3 light = paint(even ? .05 + .05 * sin(row * .13) : .78 + .05 * sin(row * .11), f) * (.35 + .6 * open) * lamp * (1 + 2.4 * (even ? c.b.y : c.b.z));
    light += paint(.95, f) * snap * 1.5;
    // Slat face: tilted, so it shades from its hinge to the lip that catches the light.
    float sideShade = 1 - .5 * pow(abs(across) / (rin * .41421356), 4.f);
    float3 slatColor = paint(.98, f) * (.025 + .14 * t01 * t01) * sideShade;
    slatColor += light * pow(t01, 10.f) * (.15 + .5 * open);
    float3 color = mix(light, slatColor, slat);
    // Light floods over the slats around open gaps.
    color += light * glow(zl - cover, .04 + open * .3) * open * .25 * slat;
    // Mullions between faces.
    float edge = rin * .41421356 - abs(across);
    float mullion = fill(edge - .04, max(fz * P, .003f));
    float glint = pow(.5 + .5 * sin(zw * 9 - c.t * 2 + face * 2), 12.f);
    float3 frame = deep(.2, f) * .03 + paint(.5, f) * glint * smoothstep(.01f, .04f, edge) * c.b.w * 3;
    color = mix(color, frame, mullion);
    float3 average = mix(light, slatColor, .6);
    color = mix(average, color, smoothstep(.45f, .15f, fz));
    float3 core = paint(.8, f) * .35 + paint(.95, f) * exp(-r * 8) * 1.0;
    return mix(core, color, ptlFog(depth, c, .05));
}
NATIVE_EFFECT(louvreTunnel)

// Coaster versions: the same designs riding the roller-coaster course.
NATIVE_COASTER(chainmailBore, 310, false)
NATIVE_COASTER(featherVault, 311, false)
NATIVE_COASTER(tartanTube, 312, false)
NATIVE_COASTER(herringboneHall, 313, false)
NATIVE_COASTER(laceFunnel, 315, false)
NATIVE_COASTER(zipperRun, 316, false)
NATIVE_COASTER(cableKnitTube, 317, false)
NATIVE_COASTER(basketWeaveBurrow, 318, false)
NATIVE_COASTER(louvreTunnel, 319, false)
