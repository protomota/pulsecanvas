import AppKit
import Foundation
@preconcurrency import Metal

// The harness runs outside the checkout and loads only the built app's resources.
extension Bundle {
    static var module: Bundle {
        Bundle(path: ProcessInfo.processInfo.environment["PULSECANVAS_TEST_APP"]!)!
    }
}
@main struct OriginalBundleSmoke {
    static func require(_ value: Bool, _ message: String) throws {
        if !value { throw NSError(domain: message, code: 1) }
    }
    static func pixels(_ texture: MTLTexture) -> [UInt8] {
        var data = [UInt8](repeating: 0, count: texture.width * texture.height * 4)
        data.withUnsafeMutableBytes { texture.getBytes($0.baseAddress!, bytesPerRow: texture.width * 4,
            from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0) }
        return data
    }
    @MainActor static func main() throws {
        NSApplication.shared.setActivationPolicy(.accessory)
        let audio = Bundle.module.url(forResource: "PulseCanvas", withExtension: "mp3", subdirectory: "Resources/Audio")!
        let analyzer = try SoundtrackAnalyzer(url: audio)
        let state = RenderState(), renderer = VisualizerRenderer(state: state)
        var comparisons = 0
        for (width,height) in [(320,180),(180,320)] {
            try renderer.prepareOffscreen(width: width, height: height)
            for scene in NativeEffects.activeScenes {
                state.scene = scene; VisualPreset.defaults(for: scene).apply(to: state)
                state.chaos = 0; state.strobeEnabled = true; state.motionBlur = 0.4
                for zoom: Float in [0,1.5,3] {
                    state.zoomSpeed = zoom
                    for time in [0.301,2.3,12.3] {
                        let feature = try analyzer.frame(at: time, clipStart: 0, clipEnd: 20)
                        let quiet = pixels(try renderer.renderOffscreen(time: time, audioBands: Array(repeating: 0, count: 32)))
                        let loud = pixels(try renderer.renderOffscreen(time: time, audioBands: feature.bands,
                            audioPulse: feature.pulse, audioMomentum: feature.momentum,
                            audioBeatMotionTime: feature.beatMotionTime, audioTreblePulse: 1, audioTrebleAttackTime: time,
                            audioEnvelopes: feature.envelopes, audioSwell: feature.swell))
                        try require(quiet == loud, "Bundled zero-Chaos output differs: \(scene), \(time), \(zoom)")
                        let rgb = stride(from: 0, to: quiet.count, by: 4).reduce(0.0) { $0 + Double(quiet[$1]) + Double(quiet[$1+1]) + Double(quiet[$1+2]) }
                        try require(rgb / Double(width*height*3) > 1, "Bundled frame is black: \(scene)")
                        comparisons += 1
                    }
                }
            }
        }
        print("PASS actual app resources: \(NativeEffects.activeCount) effects, \(comparisons) music/silence GPU comparisons, two orientations, three zoom speeds and three song positions; no checkout-resource fallback")
    }
}
