import AppKit
import MetalKit

@main struct CanvasCoverageSmoke {
    static func require(_ condition: Bool, _ message: String) throws {
        if !condition { throw NSError(domain: message, code: 1) }
    }
    struct Coverage { let lit: Double; let width: Double; let height: Double; let occupied: Int }
    static func pixels(_ texture: MTLTexture) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: texture.width * texture.height * 4)
        bytes.withUnsafeMutableBytes { texture.getBytes($0.baseAddress!, bytesPerRow: texture.width * 4,
            from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0) }
        return bytes
    }
    static func coverage(_ p: [UInt8], width: Int, height: Int) -> Coverage {
        var count = 0, minX = width, maxX = 0, minY = height, maxY = 0
        var cells = Set<Int>()
        for i in stride(from: 0, to: p.count, by: 4) where max(p[i], max(p[i+1], p[i+2])) > 16 {
            let x = (i/4) % width, y = (i/4) / width
            count += 1; minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
            cells.insert((y * 4 / height) * 4 + x * 4 / width)
        }
        return Coverage(lit: Double(count) / Double(width * height), width: Double(maxX-minX) / Double(width),
                        height: Double(maxY-minY) / Double(height), occupied: cells.count)
    }
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let state = RenderState(), renderer = VisualizerRenderer(state: state)
        var checks = 0, leastWidth = 1.0, leastHeight = 1.0, leastLit = 1.0, leastCells = 16
        let settings: [(Double, Float, Float)] = [(2.3, 1, 0), (0, 0.6, 2.7), (8, 1.55, -2.7), (24, 1, 1.1)]
        for (tag, w, h) in [("wide", 256, 144), ("phone", 144, 256)] {
            try renderer.prepareOffscreen(width: w, height: h)
            for scene in 0..<RenderState.nativeSceneNames.count {
                state.scene = scene; state.speed = 1; state.brightness = 1; state.particleSize = 1; state.palette = 0
                state.zoom = 1; state.rotation = 0
                let first = pixels(try renderer.renderOffscreen(time: 2.3, audioBands: Array(repeating: 0.2, count: 32)))
                let later = pixels(try renderer.renderOffscreen(time: 3.3, audioBands: Array(repeating: 0.2, count: 32)))
                let repeated = pixels(try renderer.renderOffscreen(time: 2.3, audioBands: Array(repeating: 0.2, count: 32)))
                try require(first == repeated, "Revisiting a frame must be deterministic: \(scene)")
                let changed = zip(first, later).filter { abs(Int($0)-Int($1)) > 8 }.count
                try require(Double(changed) / Double(w*h*3) > 0.01, "Visible movement required: \(scene) \(tag)")
                for (time, zoom, rotation) in settings {
                    // Check the established fullscreen modes at defaults; the revised fields also cover varied framing.
                    if [0, 1, 2, 5, 7].contains(scene) && time != 2.3 { continue }
                    state.zoom = zoom; state.rotation = rotation
                    let p = pixels(try renderer.renderOffscreen(time: time, audioBands: Array(repeating: 0.2, count: 32)))
                    let c = coverage(p, width: w, height: h)
                    try require(c.width > 0.95 && c.height > 0.95, "Canvas span failed \(scene) \(tag) t=\(time) zoom=\(zoom): \(c.width),\(c.height)")
                    try require(c.lit > 0.05 && c.occupied >= 14, "Too sparse or confined: \(scene) \(tag) t=\(time) lit=\(c.lit) cells=\(c.occupied)")
                    leastWidth = min(leastWidth,c.width); leastHeight = min(leastHeight,c.height)
                    leastLit = min(leastLit,c.lit); leastCells = min(leastCells,c.occupied); checks += 1
                    if time == 2.3 { print("\(tag) \(RenderState.sceneNames[scene]): lit \(String(format: "%.1f", c.lit * 100))%, span \(String(format: "%.1f × %.1f", c.width * 100, c.height * 100))%, occupied \(c.occupied)/16") }
                }
            }
        }
        print("PASS: \(checks) GPU canvas coverage checks; \(RenderState.nativeSceneNames.count * 2) motion/determinism checks; minimum spans \(leastWidth), \(leastHeight), lit \(leastLit), cells \(leastCells)/16")
    }
}
