import AppKit
import AVFoundation
import Foundation
import MetalKit

@main struct AudioSyncSmoke {
    static func require(_ condition: Bool, _ message: String) throws {
        if !condition { throw AudioAnalysisError(message) }
    }
    @MainActor static func main() async throws {
        _ = NSApplication.shared
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".build/audio-sync-validation")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
        let attacks = [0.3, 0.8, 1.3, 1.8]
        func fixture(_ name: String, beats: Bool, gain: Float = 1, rightOnly: Bool = false) throws -> URL {
            let url = root.appendingPathComponent(name + ".wav")
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 110_250)!
            buffer.frameLength = buffer.frameCapacity
            for i in 0..<Int(buffer.frameLength) {
                let t = Double(i) / 44_100
                var sample = 0.035 * sin(2 * Double.pi * 55 * t) + 0.025 * sin(2 * Double.pi * 440 * t)
                if beats {
                    for attack in attacks {
                        let age = t - attack
                        if age >= 0 && age < 0.12 { sample += 0.65 * exp(-age * 30) * sin(2 * Double.pi * 65 * age) }
                    }
                }
                buffer.floatChannelData![0][i] = rightOnly ? 0 : Float(sample) * gain
                buffer.floatChannelData![1][i] = -Float(sample) * gain
            }
            var settings = format.settings; settings[AVLinearPCMIsNonInterleaved] = false
            let file = try AVAudioFile(forWriting: url, settings: settings)
            try file.write(from: buffer)
            return url
        }
        let track = try fixture("beat-fixture", beats: true)
        let reader = try SoundtrackAnalyzer(url: track)
        for gain in [Float(1), 0.2] {
            let url = try fixture("right-only-\(gain)", beats: true, gain: gain, rightOnly: true)
            let analysis = try SoundtrackAnalyzer(url: url)
            for attack in attacks {
                let frames = try (0...6).map { try analysis.frame(at: attack + Double($0) / 100, clipStart: 0, clipEnd: 2.5) }
                let peak = frames.map(\.pulse).max() ?? 0
                let released = try analysis.frame(at: attack + 0.25, clipStart: 0, clipEnd: 2.5).pulse
                print("beat \(attack), gain \(gain): peak \(peak), released \(released)")
                try require(peak > 0.4 && released < peak * 0.2, "Beat must give a sharp pulse followed by release, including right-only and quiet audio")
            }
        }
        let sustained = try SoundtrackAnalyzer(url: fixture("sustained", beats: false))
        let steadyPulses = try (30..<140).map { try sustained.frame(at: Double($0) / 60, clipStart: 0, clipEnd: 2.5).pulse }
        print("sustained max \(steadyPulses.max() ?? 0)")
        try require((steadyPulses.max() ?? 1) < 0.12, "Sustained bass must not fabricate rhythmic attacks")
        let frame = try reader.frame(at: 1.33, clipStart: 0, clipEnd: 2.5)
        _ = try reader.frame(at: 2.2, clipStart: 0, clipEnd: 2.5)
        let seek = try reader.frame(at: 1.33, clipStart: 1.2, clipEnd: 2)
        try require(frame.pulse == seek.pulse && frame.bands == seek.bands, "Seeking and clip trims must retain exact PCM response")
        print("PASS: real PCM attacks, quiet/right-only stereo, sustained-bass rejection, deterministic seeking and clip boundaries")

        let audio = AudioController()
        audio.volume = 0
        try require(audio.load(url: track), "Preview soundtrack must load")
        audio.seek(fraction: 1.33 / 2.5)
        try require(abs(audio.beatPulse - frame.pulse) < 0.01, "Muted preview must match export analysis at the same playhead")
        audio.playPause()
        var livePeak: Float = 0
        for _ in 0..<45 {
            try await Task.sleep(for: .milliseconds(15))
            livePeak = max(livePeak, audio.beatPulse)
        }
        audio.pause()
        try require(livePeak > 0.4 && audio.playbackSeconds > 1.8, "Live playback must publish actual beat pulses while muted")
        audio.clear()
        print("PASS: live preview publishes PCM pulse and matches export independently of monitor volume")

        if CommandLine.arguments.count > 1 {
            let url = URL(fileURLWithPath: CommandLine.arguments[1])
            let realTrack = try SoundtrackAnalyzer(url: url)
            let source = try AVAudioFile(forReading: url)
            let duration = Double(source.length) / source.processingFormat.sampleRate
            let started = Date()
            var peaks = 0, previous: Float = 0, maximum: Float = 0
            var csv = "seconds,pulse\n"
            for index in 0..<Int(min(120, duration) * 30) {
                let time = Double(index) / 30
                let features = try realTrack.frame(at: time, clipStart: 0, clipEnd: duration)
                if features.pulse > 0.45 && features.pulse > previous + 0.15 { peaks += 1 }
                maximum = max(maximum, features.pulse); previous = features.pulse
                csv += "\(time),\(features.pulse)\n"
            }
            try csv.write(to: root.appendingPathComponent("soundtrack-pulses.csv"), atomically: true, encoding: .utf8)
            print("Soundtrack check: \(peaks) strong attacks, max pulse \(maximum), \(Date().timeIntervalSince(started)) seconds to analyze \(min(120, duration)) seconds")
        }

        func pixels(_ texture: MTLTexture) -> [UInt8] {
            var bytes = [UInt8](repeating: 0, count: texture.width * texture.height * 4)
            bytes.withUnsafeMutableBytes { texture.getBytes($0.baseAddress!, bytesPerRow: texture.width * 4,
                from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0) }
            return bytes
        }
        let state = RenderState(), renderer = VisualizerRenderer(state: state)
        try renderer.prepareOffscreen(width: 180, height: 320)
        var paletteChecks = 0
        for scene in NativeEffects.activeIDs {
            state.scene = scene; state.zoom = 1; state.brightness = 1; state.strobeEnabled = false
            let idle = pixels(try renderer.renderOffscreen(time: 1.33, audioBands: frame.bands, audioPulse: 0))
            // Real analysis always pairs an attack with its smoothed swell.
            let beat = pixels(try renderer.renderOffscreen(time: 1.33, audioBands: frame.bands, audioPulse: 1, audioSwell: 1))
            let changed = zip(idle, beat).filter { abs(Int($0) - Int($1)) > 8 }.count
            try require(changed > 100, "Beat pulse must visibly change scene \(scene), with white strobe off")
            var results = Set<Data>()
            for palette in VisualPalette.allCases {
                state.palette = palette.rawValue
                let image = pixels(try renderer.renderOffscreen(time: 1.33, audioBands: frame.bands))
                results.insert(Data(image))
                // Palettes now include contrasting accents. A frame can emphasize an
                // accent, so whole-frame channel ratios no longer define correctness.
                paletteChecks += 1
                if scene == 19 {
                    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 180, pixelsHigh: 320,
                        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                        colorSpaceName: .deviceRGB, bytesPerRow: 180 * 4, bitsPerPixel: 32)!
                    for i in stride(from: 0, to: image.count, by: 4) {
                        bitmap.bitmapData![i] = image[i+2]; bitmap.bitmapData![i+1] = image[i+1]
                        bitmap.bitmapData![i+2] = image[i]; bitmap.bitmapData![i+3] = 255
                    }
                    try bitmap.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("palette-\(palette.rawValue).png"))
                }
            }
            try require(results.count == VisualPalette.allCases.count, "Every palette must differ in scene \(scene)")
        }
        print("PASS: \(NativeEffects.activeIDs.count) scenes visibly pulse without strobe; \(paletteChecks) distinct GPU palette outputs")
    }
}
