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

struct CanvasPointUniforms { float4x4 mvp; float pointSize; float viewportScale; float2 padding; };
struct CanvasPoint { float4 position [[position]]; float4 color; float size [[point_size]]; };
vertex CanvasPoint canvasPointVertex(CanvasInput input [[stage_in]], constant CanvasPointUniforms &u [[buffer(1)]]) {
    CanvasPoint output;
    output.position = u.mvp * float4(input.position, 1);
    // A world-space bead diameter projected at this depth.
    output.size = clamp(u.pointSize * u.viewportScale / max(output.position.w, 0.1), 1.0, 160.0);
    output.color = input.color;
    return output;
}
/// A lit bead computed inside each sprite; no texture is sampled.
fragment float4 canvasPointFragment(CanvasPoint input [[stage_in]], float2 coord [[point_coord]]) {
    float2 p = coord * 2 - 1;
    float radius2 = dot(p, p);
    if (radius2 >= 1) discard_fragment();
    float3 normal = float3(p.x, -p.y, sqrt(1 - radius2));
    float diffuse = max(0.0, dot(normal, normalize(float3(-0.4, 0.45, 0.8))));
    float shine = pow(max(0.0, dot(normal, normalize(float3(-0.25, 0.3, 0.92)))), 24);
    float rim = pow(1 - normal.z, 2);
    float3 color = input.color.rgb * (0.2 + 0.75 * diffuse + 0.35 * rim) + shine * 0.45;
    return float4(color, 0.82 * smoothstep(1.0, 0.82, sqrt(radius2)));
}
