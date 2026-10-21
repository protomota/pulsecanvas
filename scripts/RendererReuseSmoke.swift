import AppKit
import MetalKit
import Foundation

@main struct RendererReuseSmoke {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        func pixels(_ texture: MTLTexture) -> [UInt8] {
            var result = [UInt8](repeating: 0, count: texture.width * texture.height * 4)
            result.withUnsafeMutableBytes {
                texture.getBytes($0.baseAddress!, bytesPerRow: texture.width * 4,
                    from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0)
            }
            return result
        }
        let state = RenderState(), first = VisualizerRenderer(state: RenderState())
        first.state = state
        let cold = Date()
        try first.prepareOffscreen(width: 160, height: 100)
        let coldTime = Date().timeIntervalSince(cold)
        let builds = VisualizerRenderer.shaderResourceBuilds
        precondition(builds == 1)
        let ids = NativeEffects.activeIDs
        let scenes = Array(ids.prefix(3)) + [ids[ids.count / 2]] + Array(ids.suffix(3))
        let bands = (0..<32).map { Float($0 % 8) / 10 }
        var reference: [[UInt8]] = []
        for scene in scenes {
            state.scene = scene; state.motionBlur = 0.4
            reference.append(pixels(try first.renderOffscreen(time: 4.2, audioBands: bands)))
        }
        var warmTimes: [Double] = []
        for _ in 0..<4 {
            let nextState = RenderState(), next = VisualizerRenderer(state: nextState)
            let warm = Date()
            try next.prepareOffscreen(width: 160, height: 100)
            warmTimes.append(Date().timeIntervalSince(warm))
            precondition(VisualizerRenderer.shaderResourceBuilds == builds, "Preview recreation recompiled shader resources")
            for (index, scene) in scenes.enumerated() {
                nextState.scene = scene; nextState.motionBlur = 0.4
                let result = pixels(try next.renderOffscreen(time: 4.2, audioBands: bands))
                precondition(result == reference[index], "Shared programs changed frame contents for scene \(scene)")
                precondition(nextState.errorMessage == nil)
            }
        }
        print("PASS: four preview recreations reuse compiled programs; 28 GPU frames match exactly with isolated render targets")
        print("Cold attach: \(coldTime) s; warm attach: \(warmTimes) s")
    }
}
