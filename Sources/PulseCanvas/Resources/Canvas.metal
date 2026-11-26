#include <metal_stdlib>
using namespace metal;
struct CanvasMeshInput {
    float3 position;
    float4 color;
    float2 uv;
    float3 normal;
};
struct CanvasOutput { float4 position [[position]]; float4 color; float3 surface; float3 normal; float3 faceNormal [[flat]]; };
vertex CanvasOutput canvasVertex(uint id [[vertex_id]], device const CanvasMeshInput *vertices [[buffer(0)]],
                                 constant float4x4 &mvp [[buffer(1)]], device const uint *indices [[buffer(3)]]) {
    CanvasMeshInput input=vertices[indices[id]];
    uint triangle=id/3*3;
    float3 a=vertices[indices[triangle]].position;
    float3 b=vertices[indices[triangle+1]].position;
    float3 c=vertices[indices[triangle+2]].position;
    float3 face=cross(b-a,c-a);
    CanvasOutput output;
    output.position = mvp * float4(input.position, 1);
    output.surface = input.position;
    output.color = input.color;
    // Derivatives at narrow triangle edges can depend on helper-lane values.
    // Derive the face normal from its vertices so lighting has stable inputs.
    output.normal = input.normal;
    output.faceNormal=dot(face,face)>1e-12 ? normalize(face) : float3(0,0,1);
    return output;
}
fragment float4 canvasFragment(CanvasOutput input [[stage_in]]) {
    float3 normal = length_squared(input.normal) > 0.25 ? normalize(input.normal) : input.faceNormal;
    float diffuse = abs(dot(normal, normalize(float3(-0.35,0.45,0.82))));
    float specular = pow(abs(dot(normal, normalize(float3(-0.15,0.25,0.96)))), 18);
    float depth = clamp(1.2 - length(input.surface) / 100, 0.4, 1.0);
    float shade = (0.30 + 0.70 * diffuse + 0.20 * specular) * depth;
    return float4(input.color.rgb * shade, input.color.a);
}

struct CanvasInput { float3 position [[attribute(0)]]; float4 color [[attribute(1)]]; float2 uv [[attribute(2)]]; };
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
