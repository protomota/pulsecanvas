import AppKit
@preconcurrency import AVFoundation
@preconcurrency import Metal

/// Verify audible attacks actually move geometry, independent of musical clock/brightness.
@main struct MusicResponseSmoke {
    static func require(_ value: Bool, _ message: String) throws {
        if !value { throw ExportError(message) }
    }
    static func pixels(_ texture: MTLTexture) -> [UInt8] {
        var result = [UInt8](repeating: 0, count: texture.width * texture.height * 4)
        result.withUnsafeMutableBytes { texture.getBytes($0.baseAddress!, bytesPerRow: texture.width * 4,
            from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0) }
        return result
    }
    static func difference(_ a: [UInt8], _ b: [UInt8]) -> Double {
        var sum = 0
        for p in stride(from: 0, to: a.count, by: 4) {
            for c in 0..<3 { sum += abs(Int(a[p+c]) - Int(b[p+c])) }
        }
        return Double(sum) / Double(a.count / 4 * 3)
    }
    /// Luma edges measure movement of shapes rather than a uniform brightness increase.
    static func edges(_ a: [UInt8], width: Int) -> [UInt8] {
        var output = a
        let height = a.count / (width * 4)
        for y in 0..<height-1 { for x in 0..<width-1 {
            let p = (y * width + x) * 4
            for c in 0..<3 {
                output[p+c] = UInt8(min(255, abs(Int(a[p+c]) - Int(a[p+4+c])) + abs(Int(a[p+c]) - Int(a[p+width*4+c]))))
            }
        }}
        return output
    }
    @MainActor static func main() async throws {
        _ = NSApplication.shared
        let root = URL(fileURLWithPath: ".build/music-response")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = URL(fileURLWithPath: "Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3")
        let state = RenderState(), renderer = VisualizerRenderer(state: state)
        try renderer.prepareOffscreen(width: 320, height: 180)
        let zero = [Float](repeating: 0, count: 32)
        func render(_ time: Double, _ audio: AudioFeatures) throws -> [UInt8] {
            pixels(try renderer.renderOffscreen(time: time, audioBands: audio.bands, audioPulse: audio.pulse,
                audioMomentum: audio.momentum, audioBeatMotionTime: audio.beatMotionTime,
                audioTreblePulse: audio.treblePulse, audioTrebleAttackTime: audio.trebleAttackTime,
                audioEnvelopes: audio.envelopes, audioSwell: audio.swell))
        }
        var minimumAttack = 255.0, minimumEdge = 255.0
        // Integrated designs share the expansion prelude's beat motion (Coaster versions of the
        // original tunnels 100–133 use the original prelude, like the designs they come from).
        let integrated = NativeEffects.activeIDs.filter { NativeEffects.all[$0].file?.hasPrefix("NativeExpansion") == true }
        for scene in integrated {
            state.scene = scene; VisualPreset.defaults(for: scene).apply(to: state)
            state.motionBlur = 0; state.strobeEnabled = false
            let idle = try render(99.2, .silence)
            let hit = try render(99.2, AudioFeatures(bands: zero, pulse: 1))
            let delta = difference(idle, hit), edgeDelta = difference(edges(idle, width: 320), edges(hit, width: 320))
            minimumAttack = min(minimumAttack, delta); minimumEdge = min(minimumEdge, edgeDelta)
            try require(delta > 2 && edgeDelta > 1, "Weak geometric attack: \(scene) \(NativeEffects.all[scene].name) rgb \(delta), edges \(edgeDelta)")
            let musicClock = try render(99.2, AudioFeatures(bands: zero, pulse: 0, beatMotionTime: 1))
            try require(difference(idle, musicClock) > 2, "Disconnected music clock: \(scene)")
            for band in 0..<4 {
                var levels = SIMD4<Float>(repeating: 0); levels[band] = 1
                let active = try render(99.2, AudioFeatures(bands: zero, pulse: 0, envelopes: levels))
                try require(difference(idle, active) > 0.75, "Disconnected band \(band): \(scene)")
            }
        }
        print(String(format: "PASS %d integrated native shaders: direct attacks move shapes (minimum RGB %.2f/255, edge movement %.2f/255); integrated percussion clock and all four bands connected", integrated.count, minimumAttack, minimumEdge))
        let analyzer = try SoundtrackAnalyzer(url: source)
        var features: [(Double, AudioFeatures)] = []
        for i in 0..<240 { let t = 99 + Double(i) / 60; features.append((t, try analyzer.frame(at: t, clipStart: 0, clipEnd: 10_000))) }
        for scene in [201, 205, 252, 273, 285, 290] {
            state.scene = scene; VisualPreset.defaults(for: scene).apply(to: state)
            state.motionBlur = 0; state.strobeEnabled = false
            var on: [Double] = [], between: [Double] = []
            for (time, audio) in features {
                let measured = try render(time, audio)
                var withoutAttack = audio; withoutAttack.pulse = 0
                let movement = difference(measured, try render(time, withoutAttack))
                if audio.pulse > 0.25 { on.append(movement) }
                if audio.pulse < 0.02 { between.append(movement) }
            }
            let strong = on.reduce(0,+) / Double(on.count), quiet = between.reduce(0,+) / Double(between.count)
            try require(on.count > 10 && between.count > 10 && strong > 2 && strong > quiet * 3,
                "Movement does not follow measured beats: \(scene) \(strong)/\(quiet)")
            print(String(format: "PASS source percussion %@: attack displacement %.2f, between attacks %.2f/255 (%d/%d frames)", NativeEffects.all[scene].name, strong, quiet, on.count, between.count))
        }
    }
}
