import Foundation

/// One inexpensive, edge-aware pass, confined to headset presentation.
/// Mac exports and the visualizers' source shaders are not modified.
enum VisionPresentation {
    static let width = 1920
    static let height = 1080
    static let smoothingShader = """
    #include <metal_stdlib>
    using namespace metal;
    kernel void smoothPresentation(texture2d<float, access::sample> source [[texture(0)]],
                                   texture2d<float, access::write> target [[texture(1)]],
                                   constant uint &enabled [[buffer(0)]], uint2 p [[thread_position_in_grid]]) {
        if (p.x >= target.get_width() || p.y >= target.get_height()) return;
        float4 c = source.read(p);
        if (!enabled) { target.write(c, p); return; }
        float4 n = source.read(uint2(p.x, p.y == 0 ? 0 : p.y - 1));
        float4 s = source.read(uint2(p.x, min(p.y + 1, target.get_height() - 1)));
        float4 w = source.read(uint2(p.x == 0 ? 0 : p.x - 1, p.y));
        float4 e = source.read(uint2(min(p.x + 1, target.get_width() - 1), p.y));
        float3 weights = float3(0.2126, 0.7152, 0.0722);
        float lc = dot(c.rgb, weights), ln = dot(n.rgb, weights), ls = dot(s.rgb, weights);
        float lw = dot(w.rgb, weights), le = dot(e.rgb, weights);
        float low = min(lc, min(min(ln, ls), min(lw, le)));
        float high = max(lc, max(max(ln, ls), max(lw, le)));
        float amount = smoothstep(max(0.04, high * 0.08), max(0.08, high * 0.3), high - low) * 0.65;
        float4 result = mix(c, (c * 4.0 + n + s + w + e) / 8.0, amount);
        target.write(float4(result.rgb, c.a), p);
    }
    """
}
