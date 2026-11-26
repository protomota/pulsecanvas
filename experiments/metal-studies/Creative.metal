#include <metal_stdlib>
using namespace metal;
// PulseCanvas visual experiments. No preset equations, engine code, or external images.
struct Frame { float time; uint frame; uint style; float pulse; };
float ribbon(float distance, float width) {
    return exp(-abs(distance) / width);
}
float3 violetUndertow(float2 p, constant Frame &f) {
    float t = f.time;
    float2 center = .24f * float2(sin(t * .37f), cos(t * .29f));
    float2 q = p - center;
    float radius = length(q), angle = atan2(q.y, q.x);
    // Local travelling ripples deform each spiral arm separately on the beat.
    float ripple = f.pulse * .12f * sin(radius * 15.f - t * 8.f + angle * 3.f);
    float spiral = radius * 13.f + angle * 7.f - t * 1.8f + ripple * 7.f;
    float strand = abs(sin(spiral));
    float secondary = abs(sin(radius * 19.f - angle * 5.f + t * .9f));
    float light = ribbon(strand, .08f) * (.24f + .2f * sin(radius * 4.f - t) * sin(radius * 4.f - t));
    light += ribbon(secondary, .035f) * .18f;
    float mixAmount = .5f + .5f * sin(radius * 2.5f + angle + t * .3f);
    float3 color = mix(float3(.18f,.04f,.65f),float3(.95f,.27f,.61f),mixAmount);
    float sparks = pow(max(0.f, cos(angle * 11.f + radius * 8.f - t * 3.f)), 24.f);
    return color * light + float3(.55f,.7f,1.f) * sparks * ribbon(strand,.035f) * (.08f + f.pulse * .32f);
}
float3 auroraWeave(float2 p, constant Frame &f) {
    float t = f.time;
    float3 color = float3(0);
    // Distinct depths and lateral phases create overlapping sheets across the frame.
    for (int layer = 0; layer < 9; ++layer) {
        float depth = float(layer) / 8.f;
        float x = p.x * (1.1f + depth * .65f) + sin(t * .22f + depth * 5.f) * .35f;
        float travel = x * 3.f - t * (.55f + depth * .2f);
        float beatBend = f.pulse * .17f * sin(x * 8.f - t * 7.f + depth * 9.f);
        float y = sin(travel + depth * 4.f) * .45f + sin(x * 5.f + t * .7f) * .1f;
        y += (depth - .5f) * 1.4f + beatBend;
        float edge = ribbon(p.y - y, .008f + depth * .007f);
        float glow = ribbon(p.y - y, .04f) * .12f;
        float3 tint = mix(float3(.04f,.5f,.75f), float3(.6f,1.f,.35f), depth);
        color += tint * (edge * .48f + glow) * (.7f + .3f * sin(travel * .5f + depth * 6.f));
    }
    return color;
}
kernel void creativeFrame(texture2d<float,access::sample> previous [[texture(0)]],
                          texture2d<float,access::write> output [[texture(1)]],
                          constant Frame &f [[buffer(0)]], uint2 id [[thread_position_in_grid]]) {
    if(id.x >= output.get_width() || id.y >= output.get_height()) return;
    float2 size = float2(output.get_width(),output.get_height());
    float2 uv = (float2(id) + .5f) / size;
    float2 p = (uv - .5f) * float2(size.x / size.y,1.f) * 2.f;
    float3 fresh = f.style == 0 ? violetUndertow(p,f) : auroraWeave(p,f);
    constexpr sampler history(coord::normalized,address::clamp_to_edge,filter::linear);
    // Short, controlled trails. No global camera pulse or full-screen scale jump.
    float3 trail = previous.sample(history,uv + float2(.0008f,-.0004f)).rgb * .32f;
    float3 color = 1.f - exp(-(fresh + trail) * 1.7f);
    output.write(float4(color,1),id);
}
