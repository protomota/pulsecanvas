// Final version of 314 Quilted Pipe (its v2 review clip was red-tagged).
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
// Travelling pulse used to spread a band's response down the tunnel as moving bands of
// light rather than a uniform brightness change.
float ptlSurge(float x) { float s = .5 + .5 * sin(x); return s * s * s; }

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
    float ripple = ptlFront(c, ring.centre.y * unit - travel, 1.1, 6, .3);
    float twinkle = step(.5f, seed) * pow(.5 + .5 * sin(c.t * 4.3 + seed * 60), 6.f);
    float3 base = paint(.04 + seed * .24 + ring.family * (.3 + c.b.z * .2), f);
    float surge = ptlSurge(ring.centre.y * .7 - c.t * 2.2 + 2 * sin(ring.centre.x * TAU / 10));
    float3 color = base * (.04 + .5 * diffuse) * (1 + ring.family * c.b.z * 7 * surge + crest * 2.6);
    color += paint(.95, f) * spec * (.5 + c.b.w * 6 * (.25 + twinkle));
    color += paint(.85 + seed * .1, f) * ripple * (1 + 2.5 * spec + diffuse);
    return color;
}


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
    float ruffle = ptlFront(c, rowDepth, 1.1, 6, .35);
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
    float surge = ptlSurge(row * .8 - c.t * 3 + 2 * sin(column * TAU / N * 3));
    float barbLight = mix(.55f, .3f + .8f * barbs * (1 + 6 * c.b.w * surge), resolve);
    float3 color = film * (.09 + .34 * (1 - across * .6)) * barbLight * tuck;
    color += film * lift * .45 * pow(1 - across * .7, 2.f) * tuck;
    float shaft = line(x, .028 * (1.3 - t * .6), aa) * smoothstep(.02f, .08f, t);
    color += paint(.9, f) * shaft * (.12 + 2.6 * c.b.y) * tuck;
    float rim = smoothstep(-.1f, -.01f, edge);
    color += paint(.72 + seed * .12, f) * rim * (.06 + 2.2 * c.b.z) * tuck;
    color += paint(.92, f) * ruffle * (.4 + barbs) * tuck;
    fe.color = color;
    return fe;
}


// ---------------------------------------------------------------- 312 Tartan Tube
// A twisting rounded-square tube wrapped in tartan: a symmetric sett of crossing thread
// stripes woven as a 2/2 twill, so the diagonal weave shows in every check. Each of the four
// thread colours belongs to one band and brightens with it; attacks send a bright stripe
// along the weft, lighting only the weft floats so the twill flashes.
float ptlSett(float s) {
    float x = abs(fract(s) - .5) * 2;
    return x < .07 ? 3 : x < .36 ? 0 : x < .44 ? 2 : x < .64 ? 1 : x < .7 ? 3 : x < .84 ? 2 : 0;
}
float3 ptlThread(float slot, float phase, Ctx c, constant NativeFrame &f) {
    float3 hue = slot < .5 ? paint(.97, f) : slot < 1.5 ? paint(.04, f) : slot < 2.5 ? paint(.74, f) : paint(.5, f);
    float gain = slot < .5 ? .26 : slot < 2.5 ? .36 : .55;
    return hue * (gain + 3 * c.b[min(3, int(slot))] * ptlSurge(phase + slot * 1.9));
}


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


// ---------------------------------------------------------------- 314 Quilted Pipe
// An off-axis view down a round pipe upholstered in puffy quilted diamonds: the camera rides
// close to one wall and slowly orbits the axis, so near diamonds loom large on one side.
// Bass inflates diamonds in rolling groups, low-mids brighten alternate diamonds, high-mids
// light the tufted buttons, highs glow the running stitches and attacks press a dimple
// wave through the quilt.
float3 quiltedPipe(Ctx c, constant NativeFrame &f) {
    const float N = 11;
    float orbit = c.t * .05;
    float2 eye = float2(cos(orbit), sin(orbit)) * .5;
    float3 forward = normalize(float3(-eye * .3, 1));
    float3 ray = cameraRay(c.uv / c.size, forward, float3(0, 1, 0), 1.15);
    float2 dxy = ray.xy;
    float bq = dot(eye, dxy), aq = max(dot(dxy, dxy), 1e-7f);
    float tq = (-bq + sqrt(max(0.f, bq * bq - aq * (dot(eye, eye) - 1)))) / aq;
    float2 hit = eye + dxy * tq;
    float depth = min(tq * ray.z, 200.f);
    float a = atan2(hit.y, hit.x);
    float travel = c.travel * 1.2, zw = depth + travel;
    float2 grid = float2(a, zw) * N / TAU;
    float2 dia = float2(grid.x + grid.y, grid.x - grid.y);
    float2 cell = floor(dia), l = fract(dia) - .5;
    float fw = max(length(fwidth(hit)), fwidth(zw)) * N / TAU * 1.4;
    float aa = clamp(fw, .01f, .5f);
    float parity = ptlWrap(cell.x + cell.y, 2.f);
    float seed = hash21(float2(cell.x - cell.y, ptlWrap(cell.x + cell.y, 2 * N)));
    float cellDepth = (cell.x - cell.y) * .5 * TAU / N - travel;
    float group = .5 + .5 * sin(cellDepth * .9 - c.t * 1.1 + parity * 2.2 + a);
    float press = ptlFront(c, cellDepth, 1.1, 5, .35);
    float inflate = .6 + .2 * sin(seed * 6 + c.t * .6) + 1.7 * c.b.x * group * group - 2.4 * press;
    float2 cl = cos(PI * l), sl = sin(PI * l);
    float2 grad = -PI * float2(sl.x * cl.y, cl.x * sl.y) * inflate;
    float3 n = normalize(float3(-grad * .45, 1));
    float spin = c.t * .15;
    float3 light = normalize(float3(cos(spin) * .8, sin(spin) * .8 + .3, .8));
    float diffuse = .55 * n.z * n.z + .45 * max(0.f, dot(n, light));
    float spec = pow(max(0.f, dot(n, normalize(light + float3(0, 0, 1)))), 22.f);
    float edge = .5 - max(abs(l.x), abs(l.y));
    float crease = smoothstep(0.f, .2f, edge);
    float3 satin = paint(.06 + parity * .36 + seed * .12, f) * (.02 + .42 * pow(diffuse, 3.f)) * (.25 + .75 * crease);
    satin *= 1 + parity * 7 * c.b.y * ptlSurge(cellDepth * 1.3 - c.t * 2.2 + sin(a * 2));
    satin += paint(.88, f) * spec * (.25 + .4 * saturate(inflate)) * crease;
    // Running stitches just inside every seam.
    float seamAlong = abs(l.x) > abs(l.y) ? dia.y : dia.x;
    float dash = smoothstep(.12f, .2f, abs(fract(seamAlong * 5) - .5));
    float stitch = line(edge - .075, .018, aa) * dash;
    float3 stitchColor = paint(.95, f) * (.25 + 3 * c.b.w);
    float3 color = mix(satin, stitchColor, stitch * smoothstep(.3f, .1f, fw));
    // Tufted buttons where the seams cross.
    float button = length(.5 - abs(l));
    color = mix(color, paint(.75, f) * (.25 + 3 * c.b.z), fill(button - .075, aa));
    color += paint(.75, f) * glow(button, .06) * c.b.z * .6;
    color += paint(.92, f) * press * (crease * .6 + glow(edge, .06) * 1.5);
    float3 average = paint(.2, f) * .14;
    color = mix(average, color, smoothstep(.4f, .12f, fw));
    float3 core = deep(.6, f) * .1 + paint(.85, f) * exp(-length(dxy) * 9) * 1.0;
    return mix(core, color, ptlFog(depth, c, .045));
}
NATIVE_EFFECT(quiltedPipe)

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
    // A ring cord runs along every row boundary.
    float cord = line(abs(l.y) - .5, .05, aa), cloth = 0, hole = 0, rim = 0;
    if (type < .5) {
        // Eyelet row: a band of cloth stitch pierced by rimmed eyelets.
        float e = length(l * float2(1, 1.15));
        hole = fill(e - .16, aa);
        rim = line(e - .2, .04, aa);
        cloth = fill(abs(l.y) - .3, aa);
    } else if (type < 1.5) {
        // Scallop row: cloth arches, each pierced by an eyelet, open net between them.
        float2 m = float2(l.x, l.y + .5);
        float arch = length(m) - .46;
        float eye = length(m - float2(0, .22)) - .08;
        cloth = fill(arch, aa);
        hole = fill(eye, aa);
        rim = max(line(arch, .045, aa), line(eye - .035, .028, aa));
    } else {
        // Bar row: open net crossed by slanted twisted bars joining the cords.
        rim = line(abs(l.x - l.y * .6) - .02, .035, aa) * (.75 + .25 * sin(l.y * 40));
    }
    cord = max(cord, rim);
    float4 h = hexCell(g * 5);
    float hexEdge = .5 - max(abs(h.x), max(abs(.5 * h.x + .866 * h.y), abs(.5 * h.x - .866 * h.y)));
    float netThread = mix(.3f, line(hexEdge, .09, aa * 5), smoothstep(.12f, .05f, aa));
    float clothTex = mix(.6f, .5f + .5f * sin((l.x + l.y) * 50) * sin((l.x - l.y) * 50), smoothstep(.05f, .02f, aa));
    // Picot inner edge and scalloped outer border.
    float sx = fract(g.x) - .5;
    float border = yOut - .35 + .35 * sqrt(max(0.f, 1 - 4 * sx * sx));
    float inside = fill(g.y - border, aa) * fill(yIn - g.y, aa);
    float edges = line(g.y - border, .08, aa) + line(g.y - yIn, .07, aa);
    edges += line(length(float2(sx, g.y - yIn + .13)) - .1, .028, aa) * step(g.y, yIn);
    float lace = max(cloth * .85, (1 - cloth) * netThread * .22);
    float opacity = max(inside * max(lace, cord), edges) * (1 - hole * inside);
    float glowLight = inside * (1 - hole) * (cloth * .5 * clothTex + (1 - cloth) * netThread * .12);
    float holeGlow = inside * hole * (1 - smoothstep(0.f, .16f, length(l)) * .6);
    return float4(saturate(opacity), glowLight, holeGlow, saturate(inside * cord + edges));
}





