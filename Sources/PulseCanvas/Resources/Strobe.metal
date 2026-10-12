#include <metal_stdlib>
using namespace metal;
// Original fullscreen overlay, composed after all scene effects.
vertex float4 whiteFlashVertex(uint id [[vertex_id]]) {
    const float2 p[3] = { float2(-1, -1), float2(3, -1), float2(-1, 3) };
    return float4(p[id], 0, 1);
}
fragment float4 whiteFlashFragment(constant float &strength [[buffer(0)]]) {
    return float4(1, 1, 1, clamp(strength, 0.0f, 1.0f));
}

// Uniform Gaussian softness: sample distance is independent of screen position.
// Clamp at the canvas border so opposite edges never bleed into each other.
fragment float4 contentBlurFragment(float4 position [[position]],
                                    texture2d<float> source [[texture(0)]],
                                    constant float2 &step [[buffer(0)]]) {
    constexpr sampler sampling(coord::normalized, address::clamp_to_edge, filter::linear);
    float2 uv = position.xy / float2(source.get_width(), source.get_height());
    const float weights[5] = {70.f, 56.f, 28.f, 8.f, 1.f};
    float3 color = source.sample(sampling, uv).rgb * weights[0];
    for (int i = 1; i <= 4; ++i) {
        color += (source.sample(sampling, uv + step * float(i)).rgb
                + source.sample(sampling, uv - step * float(i)).rgb) * weights[i];
    }
    return float4(color / 256.f, 1);
}

// Two expanding views trade places only when their weight reaches zero.
// This keeps forward zoom continuous without a visible reset at each cycle.
fragment float4 forwardZoomFragment(float4 position [[position]],
                                    texture2d<float> source [[texture(0)]],
                                    constant float &travel [[buffer(0)]]) {
    constexpr sampler sampling(coord::normalized, address::clamp_to_edge, filter::linear);
    float2 uv=position.xy/float2(source.get_width(),source.get_height());
    float phase=fract(travel), next=fract(phase+.5);
    float weight=pow(sin(phase*3.14159265),2.f);
    float3 first=source.sample(sampling,(uv-.5)/exp2(phase*2)+.5).rgb;
    float3 second=source.sample(sampling,(uv-.5)/exp2(next*2)+.5).rgb;
    // Retain a wider depth layer so narrow ribbons cannot leave the canvas empty.
    float3 wide=source.sample(sampling,uv).rgb;
    return float4(mix(wide,mix(second,first,weight),.65),1);
}

// Flip OpenGL's bottom-up pixels while preserving the preset's own colors.
fragment float4 projectMFragment(float4 position [[position]],
                                texture2d<float> source [[texture(0)]],
                                constant float4 &style [[buffer(0)]],
                                constant float2 &outputSize [[buffer(1)]]) {
    constexpr sampler sampling(coord::normalized, address::clamp_to_edge, filter::linear);
    // Fragment positions belong to the destination drawable, which may be larger
    // than the capped OpenGL surface. Map the full drawable to normalized UVs.
    float2 uv = position.xy / outputSize;
    float2 p = (uv - .5) / max(.3f, style.y);
    float c = cos(style.z), s = sin(style.z);
    uv = float2(c*p.x-s*p.y, s*p.x+c*p.y) + .5;
    uv.y = 1 - uv.y;
    return float4(source.sample(sampling, uv).rgb * style.x, 1);
}
