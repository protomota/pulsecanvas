import AppKit
import MetalKit
import Foundation
@main struct OfflineSmoke {
    @MainActor static func main() throws {
        func pixels(_ t: MTLTexture) -> [UInt8] {
            var p = [UInt8](repeating: 0, count: t.width * t.height * 4)
            p.withUnsafeMutableBytes { t.getBytes($0.baseAddress!, bytesPerRow: t.width * 4, from: MTLRegionMake2D(0, 0, t.width, t.height), mipmapLevel: 0) }
            return p
        }
        func mean(_ p: [UInt8]) -> Double {
            var sum: Double = 0
            for i in stride(from: 0, to: p.count, by: 4) { sum += Double(p[i]) + Double(p[i+1]) + Double(p[i+2]) }
            return sum / Double(p.count / 4 * 3)
        }
        _ = NSApplication.shared
        let state = RenderState(), renderer = VisualizerRenderer(state: RenderState())
        renderer.state = state
        let zero = [Float](repeating: 0, count: 32)
        let spectrum = (0..<32).map { Float($0 % 7) / 10 }
        var hats = zero; for i in 24..<32 { hats[i] = 0.9 }
        var bass = zero; for i in 0..<6 { bass[i] = 1 }
        var checks = 0
        for (width, height) in [(320, 180), (90, 160)] {
            try renderer.prepareOffscreen(width: width, height: height)
            for scene in NativeEffects.activeIDs {
                state.scene = scene; state.motionBlur = 0.55; state.strobeEnabled = false
                let a = pixels(try renderer.renderOffscreen(time: 4.2, audioBands: spectrum))
                let b = pixels(try renderer.renderOffscreen(time: 4.2, audioBands: spectrum))
                assert(a == b, "Repeated timestamp mismatch scene \(scene)")
                assert(a.count == width * height * 4 && mean(a) > 0.5)
                state.strobeEnabled = true
                _ = try renderer.renderOffscreen(time: 0, audioBands: zero)
                let white = pixels(try renderer.renderOffscreen(time: 0.01, audioBands: hats))
                assert(mean(white) > 254.5, "Flash not full-frame white scene \(scene)")
                _ = try renderer.renderOffscreen(time: 0, audioBands: zero)
                let low = pixels(try renderer.renderOffscreen(time: 0.01, audioBands: bass))
                assert(mean(low) < 250, "Bass incorrectly triggered flash scene \(scene)")
                checks += 3
            }
        }
        print("PASS: \(checks) offline checks: all modes, landscape/portrait exact pixels, deterministic timestamps, post-blur white flash and bass rejection")
    }
}
