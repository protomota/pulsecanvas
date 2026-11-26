import AppKit
import MetalKit

/// Actual soundtrack inputs must survive seeks and renderer history unchanged.
@main struct NativeSourceTimeSmoke {
    static func require(_ condition: Bool, _ message: String) throws {
        if !condition { throw NSError(domain: message, code: 1) }
    }
    static func pixels(_ texture: MTLTexture) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: texture.width * texture.height * 4)
        bytes.withUnsafeMutableBytes { texture.getBytes($0.baseAddress!, bytesPerRow: texture.width * 4,
            from: MTLRegionMake2D(0,0,texture.width,texture.height), mipmapLevel: 0) }
        return bytes
    }
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let analyzer = try SoundtrackAnalyzer(url: URL(fileURLWithPath: "Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3"))
        let feature = try analyzer.frame(at: 12.3, clipStart: 0, clipEnd: 20)
        let trimmed = try analyzer.frame(at: 12.3, clipStart: 12, clipEnd: 13, frameInterval: 1.0/24)
        try require(feature.envelopes == trimmed.envelopes && feature.swell == trimmed.swell,
                    "Source envelopes changed with clip range or frame rate")
        let state = RenderState(), renderer = VisualizerRenderer(state: state)
        func render(_ time: Double, _ audio: AudioFeatures) throws -> [UInt8] {
            pixels(try renderer.renderOffscreen(time: time, audioBands: audio.bands, audioPulse: audio.pulse,
                audioMomentum: audio.momentum, audioBeatMotionTime: audio.beatMotionTime,
                audioTreblePulse: audio.treblePulse, audioTrebleAttackTime: audio.trebleAttackTime,
                audioEnvelopes: audio.envelopes, audioSwell: audio.swell))
        }
        var checked = 0
        for (width,height) in [(320,180),(180,320)] {
            try renderer.prepareOffscreen(width: width, height: height)
            for scene in NativeEffects.activeScenes {
                state.scene = scene; VisualPreset.defaults(for: scene).apply(to: state)
                state.chaos = 0.8; state.strobeEnabled = false
                let direct = try render(12.3, feature)
                _ = try render(12.29, .silence)
                let afterQuiet = try render(12.3, feature)
                _ = try render(0, .silence)
                let afterSeek = try render(12.3, trimmed)
                try require(direct == afterQuiet && direct == afterSeek,
                            "Native source frame retained render history: \(scene), \(width)x\(height)")
                state.chaos = 0
                let silent = try render(12.3, .silence), music = try render(12.3, feature)
                try require(silent == music, "Source envelopes leaked at zero Chaos: \(scene)")
                checked += 1
            }
        }
        print("PASS \(checked) actual-soundtrack scene/orientation checks: source envelopes, seeks, trim/fps invariance, audio-history independence and zero Chaos")
    }
}
