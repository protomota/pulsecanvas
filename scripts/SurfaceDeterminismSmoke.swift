import AppKit
import MetalKit
import Foundation

/// Repeated identical frames catch rare surface-lighting instability that a
/// single music/silence comparison can miss. Every render completes on the GPU.
@main struct SurfaceDeterminismSmoke {
    static func pixels(_ texture: MTLTexture) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: texture.width * texture.height * 4)
        bytes.withUnsafeMutableBytes {
            texture.getBytes($0.baseAddress!, bytesPerRow: texture.width * 4,
                from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0)
        }
        return bytes
    }

    static func difference(_ a: [UInt8], _ b: [UInt8]) -> String {
        let changes = zip(a,b).map { abs(Int($0.0)-Int($0.1)) }.filter { $0 > 0 }
        return "channels=\(changes.count) max=\(changes.max() ?? 0) sum=\(changes.reduce(0,+))"
    }

    @MainActor static func main() throws {
        _ = NSApplication.shared
        let state = RenderState(), renderer = VisualizerRenderer(state: state)
        let silence = [Float](repeating: 0, count: 32)
        for (width,height) in [(320,180),(180,320)] {
            try renderer.prepareOffscreen(width: width, height: height)
            for scene in [15,16] {
                for zoom in [Float(0),1.5,3] {
                    state.scene = scene
                    state.chaos = 0
                    state.zoomSpeed = zoom
                    state.motionBlur = 0.4
                    state.strobeEnabled = true
                    state.particleSize = 1.6
                    for index in 0..<200 {
                        let clean = pixels(try renderer.renderOffscreen(time: 0.801, audioBands: silence))
                        let loud = pixels(try renderer.renderOffscreen(time: 0.801,
                            audioBands: (0..<32).map { Float(($0+index)%3)/2 },
                            audioPulse: 1, audioMomentum: 1, audioBeatMotionTime: 4,
                            audioTreblePulse: 1, audioTrebleAttackTime: 0.801))
                        let repeated = pixels(try renderer.renderOffscreen(time: 0.801, audioBands: silence))
                        if clean != loud || clean != repeated {
                            let message = "Surface \(scene), \(width)x\(height), zoom \(zoom), pair \(index): music \(difference(clean,loud)); repeated silence \(difference(clean,repeated))"
                            throw NSError(domain: "SurfaceDeterminism", code: 1,
                                          userInfo: [NSLocalizedDescriptionKey: message])
                        }
                    }
                    print("PASS surface \(scene), \(width)x\(height), zoom \(zoom): 200 exact music/silence/repeated-silence pairs")
                }
            }
        }
        print("PASS 7,200 completed GPU frames retain exact surface pixels at zero Chaos")
    }
}
