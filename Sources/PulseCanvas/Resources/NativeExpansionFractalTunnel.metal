// Original PulseCanvas designs 365–369. Flights through fractal tunnels: fractal sets wrapped onto tube walls, intertwined fractal tubes, a raymarched quaternion Julia and a loxodromic double spiral. The owner asked for "fractals twisting into each other ... through a fractal tunnel". Vivid and glowing; avoid the look of the withdrawn 126 Fractal Throat (grey folded-box blades) and the kept 61 Menger Nave / 60 Mandel Bloom.
// Escape-time sets, distance estimates and the Koenigs linearisation are implemented from their definitions.

// ---------------------------------------------------------------- complex helpers (ft_)
float2 ft_mul(float2 a, float2 b) { return float2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x); }
float2 ft_sq(float2 a) { return float2(a.x * a.x - a.y * a.y, 2 * a.x * a.y); }
float2 ft_div(float2 a, float2 b) { return float2(a.x * b.x + a.y * b.y, a.y * b.x - a.x * b.y) / max(dot(b, b), 1e-20f); }
float2 ft_exp(float2 a) { return exp(a.x) * float2(cos(a.y), sin(a.y)); }
float2 ft_log(float2 a) { return float2(.5f * log(max(dot(a, a), 1e-30f)), atan2(a.y, a.x)); }
float2 ft_sqrt(float2 a) {
    float m = length(a);
    return float2(sqrt(max(.5f * (m + a.x), 0.f)), (a.y < 0 ? -1.f : 1.f) * sqrt(max(.5f * (m - a.x), 0.f)));
}
// Triangle wave: 1 at integers, 0 at half-integers; a continuous mirror fold.
float ft_tri(float x) { return abs(fract(x) * 2 - 1); }
// Band level for a continuous family index with period 4; neighbouring families blend.
float ft_band(float x, float4 b) {
    float ph = x - 4 * floor(x * .25f), sum = 0;
    for (int i = 0; i < 4; ++i) { float d = abs(ph - float(i)); d = min(d, 4 - d); sum += max(0.f, 1 - d) * b[i]; }
    return sum;
}

// ---------------------------------------------------------------- 365 Mandelbrot Wormhole
// The tube wall is parameterised by the multiplier mu of the main cardioid (c = mu/2 - mu^2/4):
// the tunnel angle is the internal angle, so every crown carries the ring of bulbs that sits on
// the cardioid; |mu| swings in and out of the boundary along depth, so crowns of bulbs, their
// filaments and the cardioid interior stream past and twist into the vanishing point.
float3 mandelbrotWormhole(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size + float2(sin(c.t * .11f), cos(c.t * .09f)) * .05f;
    float r = max(length(p), 1e-3f), ang = atan2(p.y, p.x);
    float near = -log(r) + 1.2f;                       // log-polar distance from the viewer
    float depth = near + c.travel * .55f;
    float s = .15f + .07f * sin(depth * 1.3f + c.t * .1f) + .28f * sin(depth * 6.f);
    float theta = 3 * ang + depth * .9f + c.t * .05f;  // three crowns around, twisting with depth
    float2 mu = exp(s) * float2(cos(theta), sin(theta));
    float2 cc = .5f * mu - .25f * ft_sq(mu);
    float cpu = max(length(fwidth(cc)), 1e-7f) / c.px;

    // Analytic components: main cardioid (multiplier mu or 2 - mu) and the period-2 disc.
    float2 mirror = float2(2, 0) - mu;
    float mainR = min(length(mu), length(mirror));
    float twoR = 4 * length(cc + float2(1, 0));
    float2 z = 0, dz = 0; float m2 = 0, atom = 1e9; int per = 1; bool escaped = false; int n = 0;
    if (mainR >= 1 && twoR >= 1) {
        for (n = 0; n < 64; ++n) {
            dz = 2 * ft_mul(z, dz) + float2(1, 0);
            z = ft_sq(z) + cc;
            m2 = dot(z, z);
            if (m2 < atom) { atom = m2; per = n + 1; }
            if (m2 > 1e4) { escaped = true; break; }
        }
    } else per = mainR < 1 ? 1 : 2;

    float front = 1.2f + (1 - c.hit) * 4.5f;
    float wave = c.hit * exp(-(near - front) * (near - front) * 5);
    float3 col;
    if (escaped) {
        float nu = float(n) + 1 - log2(.5f * log(m2));
        float de = .25f * sqrt(m2 / max(dot(dz, dz), 1e-20f)) * log(m2) / cpu;
        // High-mid lights the halo and equipotential threads, treble the neon filaments.
        float halo = exp(-de * 40);
        float neon = glow(de, .0035f + .003f * c.detail + .004f * c.b.w);
        float equip = pow(ft_tri(nu * .5f), 12.f) * exp(-de * 6);
        col = deep(.9f + nu * .03f, f) * .06f;
        col += paint(.75f + nu * .035f, f) * (.2f * halo + .16f * equip) * (1 + 3 * c.b.z);
        col += paint(.05f + .08f * sin(nu * .4f), f) * neon * (1 + 2 * c.b.w + 2.5f * wave);
        col += paint(.95f, f) * halo * wave * .7f;
    } else {
        // Components light by period: cardioid with the bass, period 2 low-mid, 3 high-mid, 4+ treble.
        float fam = float(min(per, 4) - 1);
        float lit = 1 + 3 * c.b[int(fam)];
        float edge = per == 1 ? mainR : twoR;
        float rim = per <= 2 ? pow(edge, 24.f) : smoothstep(.0f, .5f, sqrt(atom));
        float body = per <= 2 ? pow(edge, 4.f) : rim;
        float2 m = per == 1 ? (length(mu) < 1 ? mu : mirror) : cc + float2(1, 0);
        float spokes = line(sin(atan2(m.y, m.x) * (per == 1 ? 7 : 4) + c.t * .2f), .08f, .03f) * body;
        float level = line(sin(log(1.0001f - edge) * 5 - c.t * .6f), .12f, .06f) * (1 - rim) * smoothstep(.3f, .9f, edge);
        col = per == 1 ? deep(.15f, f) * .1f + paint(.02f, f) * (.18f * spokes + .7f * rim) * lit + paint(.85f, f) * (body * .06f + level * .18f) * lit
                       : paint(.3f + .22f * fam, f) * (.08f + .3f * body + .5f * rim + .15f * spokes + .2f * level) * lit;
        col += paint(.9f, f) * rim * wave * 1.5f;
    }
    float fade = smoothstep(.01f, .2f, r) * exp(-near * .12f * (.4f + c.fog)) * .72f;
    return col * fade + paint(.88f, f) * glow(r, .05f) * .5f + deep(.4f, f) * .03f;
}
NATIVE_EFFECT(mandelbrotWormhole)

// ---------------------------------------------------------------- 366 Burning Ship Abyss
// A twisting square shaft. Each wall shows the Burning Ship's armada (hulls, masts and
// rigging) mirrored at the waterline and at the mast tips, so spires hang from both sides of
// every hull as you descend; the walls fold at their centres and corners.
float3 burningShipAbyss(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float r0 = max(length(p), 1e-3f);
    p = rot(p, -.3f * log(r0) + c.t * .035f);
    float2 a = abs(p);
    float d = max(max(a.x, a.y), 1e-3f);
    float u = min(a.x, a.y) / d;
    float near = 1.2f - log(d);
    float depth = near + c.travel * .5f;
    float v = depth * 1.5f;
    // Side walls and floor/ceiling show different stretches of the armada; they meet at the corners.
    float x0 = a.x > a.y ? -1.97f : -1.84f;
    float2 cc = float2(mix(x0, -1.55f, u), -.004f - .15f * (1 - ft_tri(v)));
    float cpu = max(length(fwidth(cc)), 1e-8f) / c.px;

    float2 z = 0; float md = 0, m2 = 0, trap = 1e9; bool escaped = false; int n = 0;
    for (n = 0; n < 56; ++n) {
        md = 2 * sqrt(m2) * md + 1;
        z = abs(z);
        z = float2(z.x * z.x - z.y * z.y, 2 * z.x * z.y) + cc;
        m2 = dot(z, z);
        trap = min(trap, abs(z.y));
        if (m2 > 1e4) { escaped = true; break; }
    }
    float mast = (cc.x + 1.93f) / .08f;
    float lit = 1 + 3.2f * ft_band(mast, c.b);
    float front = .8f + (1 - c.hit) * 5;
    float ring = c.hit * exp(-(near - front) * (near - front) * 7);
    float3 col;
    if (escaped) {
        float nu = float(n) + 1 - log2(.5f * log(m2));
        float de = .25f * sqrt(m2) * log(m2) / md / cpu;
        float heat = saturate(nu / 40.f);
        float halo = exp(-de * 200), neon = glow(de, .0015f);
        float flame = pow(ft_tri(nu * .5f), 8.f);
        col = deep(.2f + heat * .3f, f) * (.05f + .25f * heat * heat);
        col += paint(.55f + .1f * sin(nu * .7f), f) * flame * heat * .18f;
        col += paint(.15f + heat * .6f, f) * (pow(heat, 2.2f) * 1.1f + .1f * heat) * (.7f + .3f * flame) * lit;
        col += paint(.6f, f) * neon * lit * .3f + paint(1.f, f) * (neon + flame * halo + .4f * flame * heat) * ring * 1.6f;
    } else {
        col = (paint(.62f, f) * .3f + paint(.95f, f) * .35f * glow(trap, .02f)) * lit + paint(.9f, f) * ring * .5f;
    }
    col += paint(.3f, f) * glow(1 - u, .012f) * .3f;    // the shaft's corner seams
    float fade = smoothstep(.01f, .25f, d) * exp(-near * .05f * (.4f + c.fog));
    return col * fade + deep(.3f, f) * glow(d, .12f) * .5f;
}
NATIVE_EFFECT(burningShipAbyss)

// ---------------------------------------------------------------- 367 Fractal Double Helix
// Two raymarched helical tubes braid around the flight axis, weaving in and out; each wall
// carries a tiled, living Julia set (its own parameter orbiting), shaded with rim light and a
// neon halo in the gaps.
float3 fractalDoubleHelix(Ctx c, constant NativeFrame &f) {
    float2 uv = c.uv / c.size;
    // Every z frequency below divides a 16-unit period, so the camera wraps without a seam.
    float camZ = c.travel * 1.25f;
    camZ -= 16 * floor(camZ / 16);
    float2 sway = float2(.1f * sin(c.t * .13f), .08f * cos(c.t * .11f));
    float3 ro = float3(sway, camZ);
    float3 rd = cameraRay(uv, float3(.1f * sin(c.t * .07f), .08f * cos(c.t * .09f), 1), float3(0, 1, 0), 1.2f);
    const float K = PI / 2, R = .8f;
    float spin = c.t * .12f;
    float rhoA = .25f + .12f * c.b.x, rhoB = .25f + .12f * c.b.y;
    float tt = .05f, gA = 0, gB = 0, dA = 1, dB = 1; bool hit = false;
    float3 q = ro;
    for (int i = 0; i < 48; ++i) {
        q = ro + rd * tt;
        float ph = q.z * K + spin, weave = .3f * sin(q.z * (PI / 8) + c.t * .2f);
        float2 h = float2(cos(ph), sin(ph));
        dA = length(q.xy - h * R * (1 + weave)) - rhoA; dB = length(q.xy + h * R * (1 - weave)) - rhoB;
        float dd = min(dA, dB);
        gA += exp(-max(dA, 0.f) * 5); gB += exp(-max(dB, 0.f) * 5);
        if (dd < .0015f * tt) { hit = true; break; }
        tt += dd * .7f;
        if (tt > 22) break;
    }
    bool strandA = dA < dB;
    float ph = q.z * K + spin, weave = .3f * sin(q.z * (PI / 8) + c.t * .2f);
    float sgn = strandA ? 1 : -1;
    float2 h = float2(cos(ph), sin(ph)) * R * (1 + sgn * weave) * sgn;
    float2 a2 = q.xy - h;
    float2 local = rot(a2, -ph);
    float psi = atan2(local.y, local.x);
    // Rays that slip between the strands meet the enclosing fractal tunnel wall.
    const float wallR = 2.6f;
    float ra = dot(rd.xy, rd.xy), rb = dot(ro.xy, rd.xy), rc = dot(ro.xy, ro.xy) - wallR * wallR;
    float tw = (-rb + sqrt(max(rb * rb - ra * rc, 0.f))) / max(ra, 1e-6f);
    float3 qw = ro + rd * tw;
    float thw = atan2(qw.y, qw.x) + qw.z * (PI / 24);
    float2 zj = hit ? (2 * float2(ft_tri(q.z * 1.125f + (strandA ? 0 : .5f)), ft_tri(psi / PI)) - 1) * 1.45f
                    : (2 * float2(ft_tri(qw.z * .375f), ft_tri(thw * 3 / PI)) - 1) * 1.45f;
    float zpx = max(length(fwidth(zj)), 1e-6f) / c.px;
    // Living Julia sets: parameters glide just inside the main cardioid's rim.
    float ca = c.t * .05f + (hit ? (strandA ? 0 : 2.2f) : 4.1f);
    float2 em = .97f * float2(cos(ca), sin(ca));
    float2 cj = .5f * em - .25f * ft_sq(em);
    float m2 = dot(zj, zj), md = 1, trap = 1e9; bool escaped = false; int n = 0;
    for (n = 0; n < 32; ++n) {
        md *= 2 * sqrt(m2);
        zj = ft_sq(zj) + cj;
        m2 = dot(zj, zj);
        trap = min(trap, abs(sqrt(m2) - .4f));
        if (m2 > 64) { escaped = true; break; }
    }
    float hueBase = hit ? (strandA ? .05f : .6f) : .3f;
    float bandFill = strandA ? c.b.x : c.b.y, bandLine = strandA ? c.b.z : c.b.w;
    if (!hit) { bandFill = 0; bandLine = .5f * (c.b.z + c.b.w); }
    float3 tex;
    if (escaped) {
        float nu = float(n) + 1 - log2(.5f * log(m2));
        float de = .25f * sqrt(m2) * log(m2) / max(md, 1e-6f) / zpx;
        float bands = pow(ft_tri(nu * .5f), 4.f);
        tex = deep(hueBase + .1f, f) * .07f + paint(hueBase + nu * .03f, f) * (.03f + .2f * bands) * exp(-de * 4)
            + paint(hueBase + .45f, f) * glow(de, .005f + .004f * bandLine) * (1 + 2.5f * bandLine);
    } else {
        // Koenigs coordinate of the attracting fixed point em/2: a rose of spokes and rings.
        float2 kz = ft_div(zj - .5f * em, ft_exp(float(n) * float2(log(.97f), ca)));
        float rose = pow(.5f + .5f * cos(atan2(kz.y, kz.x) * 5 + log(max(length(kz), 1e-6f)) * 3 - c.t * .5f), 3.f);
        tex = paint(hueBase + .3f + .2f * rose, f) * (.06f + .5f * rose) * (.7f + 1.8f * bandFill);
    }
    float pulseZ = camZ + 1.5f + (1 - c.hit) * 14;
    float3 col;
    if (hit) {
        float2 nxy = normalize(a2);
        float3 nrm = normalize(float3(nxy, dot(nxy, R * K * float2(sin(ph), -cos(ph)) * sgn)));
        float facing = abs(dot(nrm, rd));
        float rim = pow(1 - facing, 3.f);
        float pulse = c.hit * exp(-(q.z - pulseZ) * (q.z - pulseZ) * 2);
        col = tex * (.5f + .7f * facing) + paint(hueBase + .1f, f) * rim * .8f + paint(.95f, f) * pulse * 1.5f;
        col *= exp(-tt * .07f * (.4f + c.fog));
    } else {
        float pulse = c.hit * exp(-(qw.z - pulseZ) * (qw.z - pulseZ) * .5f);
        col = (tex * .4f + paint(.9f, f) * pulse * .5f) * exp(-(qw.z - camZ) * .09f * (.4f + c.fog));
    }
    if (!hit) col += paint(.25f, f) * gA * .006f + paint(.75f, f) * gB * .006f;
    col += paint(.9f, f) * glow(length(uv - sway * 1.2f), .08f) * .35f;
    return col;
}
NATIVE_EFFECT(fractalDoubleHelix)

// ---------------------------------------------------------------- 368 Quaternion Bloom
// Distance estimate of a quaternion Julia set, q <- q^2 + c, sliced into 3D by a rotating
// 4D plane. |dq| is tracked as a scalar because the quaternion norm is multiplicative.
float ft_qjulia(float3 p, float4 cq, float2 slice, thread float4 &trap) {
    float4 q = float4(p.x, p.y * slice.x, p.z, p.y * slice.y);
    float m2 = dot(q, q), md2 = 1;
    trap = float4(1e3);
    for (int i = 0; i < 8; ++i) {
        md2 *= 4 * m2;
        q = float4(q.x * q.x - dot(q.yzw, q.yzw), 2 * q.x * q.yzw) + cq;
        m2 = dot(q, q);
        if (i < 3) trap = min(trap, float4(abs(q.x), abs(q.y), abs(length(q.yzw) - .5f), abs(sqrt(m2) - .8f)));
        if (m2 > 256) break;
    }
    return .25f * sqrt(m2 / md2) * log(m2);
}
float3 quaternionBloom(Ctx c, constant NativeFrame &f) {
    float2 uv = c.uv / c.size;
    float az = c.travel * .21f + c.t * .02f, el = .35f * sin(c.travel * .07f + 1);
    float dist = 1.85f - .25f * sin(c.travel * .11f);
    float3 ro = dist * float3(cos(el) * sin(az), sin(el), cos(el) * cos(az));
    float3 rd = cameraRay(uv, -ro, float3(0, 1, 0), 1.35f);
    float sa = c.t * .06f;
    float2 slice = float2(cos(sa), sin(sa));
    float ca = c.t * .045f;
    float4 cq = float4(-.2f + .07f * sin(ca), .4f + .1f * sin(ca * .8f + 1), -.4f + .1f * cos(ca * .6f), -.4f + .08f * sin(ca * 1.1f + 2));
    float bR = 1.5f, bb = dot(ro, rd), cc0 = dot(ro, ro) - bR * bR, disc = bb * bb - cc0;
    float haloAcc = 0; bool hit = false; float tt = 0; float4 trap = 1e3; float steps = 0;
    if (disc > 0) {
        float t0 = max(-bb - sqrt(disc), 0.f), t1 = -bb + sqrt(disc);
        tt = t0;
        float dd = 1;
        for (int i = 0; i < 32; ++i) {
            dd = ft_qjulia(ro + rd * tt, cq, slice, trap);
            haloAcc += exp(-max(dd, 0.f) * 20);
            if (dd < .003f * tt) break;
            tt += max(dd, .002f);
            steps += 1;
            if (tt > t1) { dd = 1; break; }
        }
        hit = dd < .03f;
    }
    float r = length(uv), ang = atan2(uv.y, uv.x);
    // A corona of soft petals unfolding behind the bloom.
    float lr = log(max(r, 1e-3f));
    float petals = pow(.5f + .5f * cos(ang * 7 + sin(lr * 2.5f - c.t * .3f) * 1.2f - c.t * .08f), 4.f);
    float veil = pow(.5f + .5f * cos(ang * 4 - lr * 3 + c.t * .15f), 6.f);
    float3 col = deep(.55f, f) * .07f + paint(.45f + .25f * petals, f) * (petals * .2f + veil * .08f) * smoothstep(.25f, 1.2f, r) * exp(-r * .4f);
    col += paint(.45f, f) * haloAcc * .025f;
    if (hit) {
        float3 pos = ro + rd * tt;
        float4 tmp;
        const float e = .003f;
        float d0 = ft_qjulia(pos, cq, slice, trap);
        float3 nrm = normalize(float3(ft_qjulia(pos + float3(e, 0, 0), cq, slice, tmp) - d0,
                                      ft_qjulia(pos + float3(0, e, 0), cq, slice, tmp) - d0,
                                      ft_qjulia(pos + float3(0, 0, e), cq, slice, tmp) - d0));
        float facing = max(0.f, -dot(nrm, rd));
        float rim = pow(1 - facing, 2.5f);
        float diff = max(0.f, dot(nrm, normalize(float3(.5f, .8f, .3f))));
        float shell = .2f + (1 - c.hit) * 1.4f;
        float flare = c.hit * exp(-(length(pos) - shell) * (length(pos) - shell) * 30);
        float3 vc = 0;
        for (int k = 0; k < 4; ++k) vc += paint(.6f + .1f * float(k), f) * glow(trap[k], .01f + .012f * c.b[k]) * (.35f + 3 * c.b[k] + 3 * flare);
        float ao = 1 - steps / 48;
        float3 base = paint(.3f + .6f * saturate(trap.w * 1.5f), f) * (.12f + .6f * diff) * ao;
        col = base + vc * .5f + paint(.95f, f) * rim * 1.1f;
    }
    return col;
}
NATIVE_EFFECT(quaternionBloom)

// ---------------------------------------------------------------- 369 Loxodrome Fractal
// Bipolar coordinates W = log((p - source) / (p - sink)) feed a loxodromic flow through the
// exponential picture of a Julia set at its repelling fixed point alpha. The Koenigs relation
// G(f(z)) = 2 G(z) makes that picture exactly periodic under w -> w + log(lambda), so the
// detail streams out of one spiral pole and into the other without ever resetting.
float3 loxodromeFractal(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float2 axis = rot(c.extent.x >= c.extent.y ? float2(1, 0) : float2(0, 1), .3f * sin(c.t * .05f));
    float sep = .55f * max(c.extent.x, c.extent.y) / c.size;
    float2 side = float2(-axis.y, axis.x) * .12f;
    float2 p1 = -axis * sep + side, p2 = axis * sep - side;
    float2 W = ft_log(ft_div(p - p1, p - p2));
    float dW = length(p2 - p1) / max(length(p - p1) * length(p - p2), 1e-6f);

    float ca = c.t * .03f;
    float2 cj = float2(-.05f, .84f) + .025f * float2(cos(ca), sin(ca * 1.3f));
    float2 alpha = .5f * (float2(1, 0) - ft_sqrt(float2(1, 0) - 4 * cj));
    float2 lam = 2 * alpha;
    float2 L = ft_log(lam);
    // w = A W with A (2 pi i) = 2 pi i + L: one turn around a pole is one level deeper.
    float2 A = float2(1, 0) + ft_div(L, float2(0, TAU));
    float2 w = ft_mul(A, W) - L.x * c.travel * .9f * float2(1, .6f) + float2(0, c.t * .06f);
    float k = floor(w.x / L.x);
    float2 wr = w - k * L;
    const float sigma = .05f;
    const int pre = 8;
    float2 delta = sigma * ft_exp(wr - float(pre) * L);
    float2 ddelta = delta;                          // d delta / d w'
    for (int i = 0; i < pre; ++i) {
        ddelta = ft_mul(ddelta, lam + 2 * delta);
        delta = ft_mul(delta, lam + delta);
    }
    float2 z = alpha + delta, dz = ddelta;
    float m2 = dot(z, z), trap = 1e9; bool escaped = false; int n = 0;
    for (n = 0; n < 40; ++n) {
        dz = 2 * ft_mul(z, dz);
        z = ft_sq(z) + cj;
        m2 = dot(z, z);
        trap = min(trap, length(z - alpha));
        if (m2 > 1e4) { escaped = true; break; }
    }
    float wpx = length(A) * dW;
    float front = mix(-3.5f, 3.5f, 1 - c.hit);
    float wave = c.hit * exp(-(W.x - front) * (W.x - front) * 1.2f);
    float3 col;
    if (escaped) {
        float nu = float(n) + 1 - log2(.5f * log(m2)) - k;
        float de = .25f * sqrt(m2 / max(dot(dz, dz), 1e-30f)) * log(m2) / max(wpx, 1e-6f);
        float lit = 1 + 3 * ft_band(nu * .5f, c.b);
        float halo = exp(-de * 18), neon = glow(de, .004f);
        float flow = pow(ft_tri(nu * .5f), 8.f) * exp(-de * 3);
        col = deep(.3f + nu * .02f, f) * .12f + paint(.45f + .25f * sin(nu * .3f), f) * (.3f * halo + .16f * flow) * lit;
        col += paint(.92f, f) * neon * (1 + 3 * wave) + paint(1.f, f) * halo * wave * .6f;
    } else {
        col = deep(.2f, f) * .25f + paint(.7f, f) * glow(trap, .05f) * .4f;
    }
    float pole = min(length(p - p1), length(p - p2));
    col *= smoothstep(.0f, .12f, pole) * (.3f + .55f * pow(abs(W.y) / PI, 1.5f));
    col += paint(.92f, f) * glow(length(p - p1), .07f) * .7f + paint(.55f, f) * glow(length(p - p2), .07f) * .5f;
    return col;
}
NATIVE_EFFECT(loxodromeFractal)

// Coaster versions: the same designs riding the roller-coaster course.
NATIVE_COASTER(mandelbrotWormhole, 365, false)
NATIVE_COASTER(burningShipAbyss, 366, false)
NATIVE_COASTER(fractalDoubleHelix, 367, false)
