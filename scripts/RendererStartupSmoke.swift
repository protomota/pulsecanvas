import AppKit
import MetalKit
import Foundation

@main struct RendererStartupSmoke {
    @MainActor static func main() async throws {
        _ = NSApplication.shared
        var heartbeats = 0
        let heartbeat = Task { @MainActor in
            while !Task.isCancelled {
                heartbeats += 1
                try? await Task.sleep(for: .milliseconds(5))
            }
        }
        let start = ContinuousClock.now
        async let first: Void = VisualizerRenderer.prepareLiveAssets()
        async let second: Void = VisualizerRenderer.prepareLiveAssets()
        try await first
        try await second
        heartbeat.cancel()
        precondition(heartbeats > 1, "Shader preparation blocked the main actor")
        precondition(VisualizerRenderer.shaderResourceBuilds == 1, "Concurrent preparation compiled duplicate resources")

        let state = RenderState(), renderer = VisualizerRenderer(state: RenderState())
        renderer.state = state
        try renderer.prepareOffscreen(width: 160, height: 100)
        precondition(renderer.isReady)
        precondition(VisualizerRenderer.shaderResourceBuilds == 1, "Preview/export did not reuse prepared programs")
        let bands = (0..<32).map { Float($0 % 8) / 10 }
        for scene in [NativeEffects.activeIDs[0], NativeEffects.defaultScene, NativeEffects.activeIDs.last!] {
            state.scene = scene
            let texture = try renderer.renderOffscreen(time: 4.2, audioBands: bands)
            var pixels = [UInt8](repeating: 0, count: texture.width * texture.height * 4)
            pixels.withUnsafeMutableBytes {
                texture.getBytes($0.baseAddress!, bytesPerRow: texture.width * 4,
                    from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0)
            }
            precondition(pixels.enumerated().contains { $0.offset % 4 != 3 && $0.element > 30 }, "Prepared shaders produced an empty frame")
            precondition(state.errorMessage == nil)
        }
        print("PASS: one shared worker compilation, \(heartbeats) main-actor heartbeats; prepared GPU programs render and reuse correctly")
        print("Preparation and three render checks: \(start.duration(to: .now))")
    }
}
