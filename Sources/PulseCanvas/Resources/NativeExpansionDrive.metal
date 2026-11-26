// Newly authored PulseCanvas driving studies. No preset formulas, third-party
// textures, shader translations or external implementations are used.

struct DriveWall { float angle; float radius; float depth; float distance; float aa; };
DriveWall driveWall(float2 p, Ctx c, float pitch) {
    DriveWall w;
    p /= c.size;
    w.radius = max(length(p), .035f);
    w.angle = atan2(p.y, p.x);
    w.distance = 1 / w.radius;
    w.depth = pitch * w.distance + c.travel;
    w.aa = min(.3f, c.px * (1 + w.distance * w.distance));
    return w;
}
float driveStripe(float phase, float thickness, float aa) {
    return 1 - smoothstep(thickness, thickness + max(.02f, aa), abs(sin(phase)));
}

// A continuous curved motorway below a billowing sky. Four staggered lane
// markings, luminous shoulders and road ripples have independent audio inputs.


// Three braided track ribbons wind around an illuminated tube. The gaps reveal
// a second, counter-rotating wall of oblique seams, rather than a flat ring stack.
float3 iridescentRaceway(Ctx c, constant NativeFrame &f) {
    float2 p = rot(c.uv, .12 * sin(c.t * .3));
    DriveWall w = driveWall(p, c, 2.4);
    float helix = w.angle * 3 + w.depth * .8 - c.t * .35;
    float ribbon = pow(.5 + .5 * cos(helix + c.b.y * sin(w.depth) * 2), 3.f);
    float seam = driveStripe(w.angle * 12 - w.depth * 1.1 + c.t * .4, .06, w.aa);
    float curb = driveStripe(helix, .1 + c.b.w * .09, w.aa);
    float grain = .65 + .35 * sin(w.depth * 4 + sin(w.angle * 7));
    float3 color = paint((.5 + .3 * sin(w.angle)) + w.depth * .022, f) * (ribbon * (.65 + grain) + seam * .3);
    color += paint(w.depth * .05 + .6, f) * curb * (1 + c.hit * .6);
    return color * smoothstep(.025f, .18f, w.radius) + paint(.5, f) * .08;
}

// Four beveled planes converge into a bending diamond gallery. Wall reflections
// move in opposite directions and diagonal braces open with the low-mid band.
float3 cobaltCatapult(Ctx c, constant NativeFrame &f) {
    float2 p = rot(c.uv / c.size + float2(sin(c.t * .19), cos(c.t * .16)) * .09, PI * .25);
    float radius = max(max(abs(p.x), abs(p.y)), .045f);
    float depth = 2.6 / radius + c.travel * 1.8;
    float face = abs(p.x) > abs(p.y) ? p.y / radius : p.x / radius;
    float seam = driveStripe(depth * 1.7 + face * 2.5, .075, c.px / radius);
    float diagonal = driveStripe(face * 8 + sin(depth * .3) * 2, .08 + c.b.y * .18, c.px / radius);
    float bevel = pow(min(abs(p.x), abs(p.y)) / radius, 16.f);
    float3 color = paint(face * .13 + depth * .02, f) * (.25 + .22 * sin(depth + face * 5));
    color += paint(.75 + depth * .03, f) * (seam * 1.3 + diagonal * .7 + bevel * .8);
    return color * smoothstep(.02f, .12f, radius) + deep(.7, f) * .12;
}

// A rocket corridor of long comet plumes. Each plume curves through its own
// arc; faded stable depth slots prevent spawning flashes during forward travel.
float3 tangerineRocket(Ctx c, constant NativeFrame &f) {
    float3 color = paint(.4, f) * .08;
    for (int k = 0; k < 6; ++k) {
        float2 slot = layerSlot(k, 6, c.travel * .12);
        float scale = layerScale(slot.x, 2.6) / c.size;
        float2 p = rot(c.uv * scale, slot.y * .21 + c.t * .15);
        float a = atan2(p.y, p.x), r = length(p);
        float plume = driveStripe(a * 9 + r * 1.7 + sin(r + c.t * .3) + slot.y, .08 + c.b.z * .1, c.px * scale / max(.15f, r));
        float tail = pow(.5 + .5 * cos(r * 2 - c.t * .8 + slot.y), 3.f);
        float arc = glow(r - (1.2 + .15 * sin(a * 6 + c.t + slot.y) + c.b[int(slot.y - 4 * floor(slot.y / 4))] * .16), .035 * c.size);
        color += paint(slot.y * .12 + (.5 + .3 * sin(a)), f) * (plume * tail * .8 + arc * 1.4) * layerFade(slot.x);
    }
    return color;
}

// A pentagonal acceleration chamber with alternating inset facets. Surface
// pressure deforms each angular panel; forward zoom and twist stay procedural.
float3 prismaticOverdrive(Ctx c, constant NativeFrame &f) {
    DriveWall w = driveWall(c.uv, c, 1.7);
    float twist = w.angle + w.depth * .22 + c.t * .12;
    float panel = cos(twist * 5);
    float facet = .7 + .3 * panel;
    float pressure = sin(twist * 10 + w.depth * .8) * c.b.x * .55;
    float ribs = driveStripe(w.depth * 2.3 + facet * 2 + pressure, .13, w.aa);
    float bolts = pow(.5 + .5 * cos(twist * 20), 10.f) * pow(.5 + .5 * cos(w.depth * 4.6), 10.f);
    float3 color = paint((.5 + .3 * sin(twist)) + w.depth * .015, f) * (.18 + facet * .5 + ribs * 1.3);
    color += paint(.75, f) * bolts * (1 + c.b.w);
    return color * smoothstep(.025f, .12f, w.radius) + deep(.8, f) * .12;
}

// Five long ruled sails twist around a dark core. The fabric has distinct
// crosswise folds; percussion shakes individual folds rather than the camera.
float3 scarletSlipstream(Ctx c, constant NativeFrame &f) {
    DriveWall w = driveWall(c.uv, c, 2.2);
    float3 color = deep(.2, f) * .2;
    for (int k = 0; k < 5; ++k) {
        float phase = w.angle - float(k) * TAU / 5 + w.depth * (.19 + float(k) * .025) + c.t * .16;
        float fold = sin(w.depth * 3 + float(k) * 1.7) * (.15 + c.b[k % 4] * .4);
        float sail = glow(sin(phase) + fold, .14 * c.size) * (.5 + .5 * cos(phase));
        float weave = .7 + .3 * sin(w.depth * 9 + phase * 7);
        color += paint(float(k) * .17 + w.depth * .017, f) * sail * weave;
    }
    return color * smoothstep(.025f, .12f, w.radius) + paint(.3, f) * .07;
}

// Suspended twin carriageways cross a reflective valley. Rail separation is
// fixed; their banks and luminous cross ties dance to different frequency bands.
float3 laserAutobahn(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float horizon = .28;
    float z = 1.8 / max(abs(p.y - horizon), .04f) + c.travel * 2;
    float x = p.x / max(abs(p.y - horizon), .04f);
    float roadCenter = sin(z * .14 + c.t * .19) * 1.2;
    float banks = .5 + .5 * cos(z * .6 + c.b.x * sin(x) * 2);
    float rails = glow(abs(x - roadCenter) - 2.4, .14 * c.size);
    float ties = driveStripe(z * 3, .075 + c.b.z * .1, c.px * z) * exp(-abs(x - roadCenter) * .35);
    float mountains = .5 + .5 * sin(p.x * 3 + sin(p.x * 2 + c.t * .1));
    float3 color = paint(.8 + mountains * .15, f) * (.1 + mountains * .2);
    float3 road = paint(x * .035 + z * .012, f) * (.12 + banks * .2 + rails * 1.7 + ties * .8);
    return mix(color, road, smoothstep(-.05f, .05f, horizon - p.y));
}

// A flowing canyon seen from within. Narrow liquid strata curl around wide
// concave walls, with separate bass swells and high-frequency surface ripples.
float3 rainbowRiptide(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv + float2(sin(c.t * .23), cos(c.t * .17)) * .13;
    DriveWall w = driveWall(p, c, 1.9);
    float stream = w.depth * .55 + sin(w.angle * 3 + w.depth * .18) * 2;
    stream += c.b.x * sin(w.angle * 5 + w.depth) * .6;
    float ripple = sin(stream * 6 + c.b.w * sin(w.angle * 24) * 2);
    float liquid = .5 + .5 * sin(stream);
    float sheen = pow(max(0.f, ripple), 14.f);
    float bank = .3 + .7 * pow(.5 + .5 * cos(w.angle * 2), 2.f);
    float3 color = paint(stream * .035 + (.5 + .3 * sin(w.angle)), f) * (bank * .65 + liquid * .45);
    color += paint(.85, f) * sheen * (.8 + c.detail);
    return color * smoothstep(.025f, .14f, w.radius) + paint(.2, f) * .08;
}

// A winding road through luminous rectangular archways. Perspective slats
// bend continuously left/right; walls carry traveling, independently pulsing bars.
float3 electricSwitchback(Ctx c, constant NativeFrame &f) {
    float2 p = c.uv / c.size;
    float r = max(max(abs(p.x), abs(p.y * .8)), .04f);
    float z = 2 / r + c.travel * 2.4;
    float curve = sin(z * .13 + c.t * .3) * .35 + sin(z * .31) * .13;
    float side = p.x / r - curve;
    float arch = driveStripe(z * 1.8 + sin(side * 3) * c.b.y * .25, .1, c.px / r);
    float vertical = driveStripe(side * 3.5, .08, c.px / r);
    float bottom = smoothstep(.1f, -.25f, p.y);
    float groove = .5 + .5 * sin(z * 5 + side * 2 + c.t * .5);
    float3 color = paint(side * .2 + z * .02, f) * (.18 + arch * 1.4 + vertical * .35 + bottom * groove * .25);
    return color * smoothstep(.02f, .12f, r) + deep(.65, f) * .15;
}

// A drum-machine tunnel tiled with dancing oval lamps. Each lamp has a smooth
// spatial phase and band assignment; there is no hash-based frame flicker.
float3 discoTransit(Ctx c, constant NativeFrame &f) {
    DriveWall w = driveWall(rot(c.uv, c.t * .07), c, 2.3);
    float column = w.angle * 8 / PI;
    float row = w.depth * .7;
    float2 tile = float2(column, row);
    float2 id = floor(tile), local = fract(tile) - .5;
    float phase = sin(id.x * TAU / 16) * 2 + id.y * 1.3;
    float band = c.b[int(id.x + id.y - 4 * floor((id.x + id.y) / 4))];
    float dance = sin(c.t * 1.6 + phase) * .09;
    float2 shape = (local - float2(dance, sin(c.t + phase) * .07)) / float2(.32 + band * .1, .36);
    float lamp = 1 - smoothstep(.85f, 1.f, dot(shape, shape));
    float center = glow(length(shape), .25);
    float joints = driveStripe(column * PI, .08, w.aa) + driveStripe(row * PI, .08, w.aa);
    float3 color = paint(phase * .08 + .3, f) * (lamp * (.5 + band) + center * .7 + joints * .2 + .1);
    return color * smoothstep(.02f, .13f, w.radius) + paint(.5, f) * .06;
}


NATIVE_EFFECT(iridescentRaceway)
NATIVE_EFFECT(cobaltCatapult)
NATIVE_EFFECT(tangerineRocket)
NATIVE_EFFECT(prismaticOverdrive)
NATIVE_EFFECT(scarletSlipstream)
NATIVE_EFFECT(laserAutobahn)
NATIVE_EFFECT(rainbowRiptide)
NATIVE_EFFECT(electricSwitchback)
NATIVE_EFFECT(discoTransit)
