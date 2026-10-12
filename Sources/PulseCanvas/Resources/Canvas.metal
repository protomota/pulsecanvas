#include <metal_stdlib>
using namespace metal;
struct CanvasInput {
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
    float2 uv [[attribute(2)]];
};
struct CanvasOutput { float4 position [[position]]; float4 color; float3 surface; };
vertex CanvasOutput canvasVertex(CanvasInput input [[stage_in]], constant float4x4 &mvp [[buffer(1)]], constant uint &scene [[buffer(2)]]) {
    CanvasOutput output;
    output.position = mvp * float4(input.position, 1);
    output.surface = input.position;
    output.color = input.color;
    return output;
}
fragment float4 canvasFragment(CanvasOutput input [[stage_in]]) {
    float3 normal = normalize(cross(dfdx(input.surface), dfdy(input.surface)) + float3(0,0,0.00001));
    float diffuse = abs(dot(normal, normalize(float3(-0.35,0.45,0.82))));
    float specular = pow(abs(dot(normal, normalize(float3(-0.15,0.25,0.96)))), 18);
    float depth = clamp(1.2 - length(input.surface) / 100, 0.4, 1.0);
    float shade = (0.30 + 0.70 * diffuse + 0.20 * specular) * depth;
    return float4(input.color.rgb * shade, input.color.a);
}
