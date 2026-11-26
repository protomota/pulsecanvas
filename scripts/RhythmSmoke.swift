import AVFoundation
import Foundation
@main struct RhythmSmoke {
    static func require(_ condition: Bool, _ message: String) throws { if !condition { throw AudioAnalysisError(message) } }
    static func fixture(_ url: URL, duration: Double, sample: (Double) -> Float) throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(duration * 44_100))!
        buffer.frameLength = buffer.frameCapacity
        for i in 0..<Int(buffer.frameLength) {
            let value = sample(Double(i) / 44_100)
            buffer.floatChannelData![0][i] = value; buffer.floatChannelData![1][i] = -value
        }
        var settings = format.settings; settings[AVLinearPCMIsNonInterleaved] = false
        try AVAudioFile(forWriting: url, settings: settings).write(from: buffer)
    }
    static func main() throws {
        let root = URL(fileURLWithPath: ".build/rhythm-validation")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let url = root.appendingPathComponent("drum-density.wav")
        let sparse = [3.05, 3.55, 4.05], dense = (0..<8).map { 5.05 + Double($0) * 0.25 }
        try fixture(url, duration: 9) { time in
            let swell = min(1, max(0, (time - 0.3) / 0.7))
            var sample = swell * (0.035 * sin(time * 2 * .pi * 55) + 0.025 * sin(time * 2 * .pi * 440))
            for attack in sparse + dense {
                let age = time - attack
                if age >= 0 && age < 0.13 { sample += 0.65 * exp(-age * 30) * sin(age * 2 * .pi * 65) }
            }
            return Float(sample)
        }
        let reader = try SoundtrackAnalyzer(url: url)
        let calm = try (120..<270).map { try reader.frame(at: Double($0)/100, clipStart: 0, clipEnd: 9) }
        try require(calm.map(\.pulse).max()! < 0.12, "Melody without drums must not invent beats")
        let sparseDrive = try (330..<445).map { try reader.frame(at: Double($0)/100, clipStart: 0, clipEnd: 9).momentum }.reduce(0,+) / 115
        let denseDrive = try (570..<690).map { try reader.frame(at: Double($0)/100, clipStart: 0, clipEnd: 9).momentum }.reduce(0,+) / 120
        let released = try reader.frame(at: 8.5, clipStart: 0, clipEnd: 9)
        try require(denseDrive > sparseDrive * 1.5 && released.momentum < denseDrive * 0.2, "Drum density must build momentum, then release")
        for attack in sparse + dense {
            let peaks = try (0...7).map { try reader.frame(at: attack + Double($0)/100, clipStart: 0, clipEnd: 9).pulse }
            try require(peaks.max()! > 0.5, "Every kick must trigger close to its source attack")
        }
        print("PASS: no fabricated rhythm over sustained melody; sparse drive \(sparseDrive), dense drive \(denseDrive), quiet release \(released.momentum); every kick within 70 ms")
        let hats = (0..<7).map { 0.113 + Double($0) * 0.07 }
        let hatURL = root.appendingPathComponent("off-grid-hats.wav")
        try fixture(hatURL, duration: 0.8) { time in
            var sample = 0.0
            for attack in hats {
                let age = time - attack
                if age >= 0 && age < 0.02 { sample += 0.7 * exp(-age * 180) * sin(age * 2 * .pi * 8000) }
            }
            return Float(sample)
        }
        let hatReader = try SoundtrackAnalyzer(url: hatURL)
        for fps in [24,30,60] {
            var detector = StrobeDetector(), emitted = Set<Double>()
            for index in 0..<Int(0.8 * Double(fps)) {
                let time = Double(index)/Double(fps), feature = try hatReader.frame(at: time, clipStart: 0, clipEnd: 0.8)
                let flash = detector.nextSourceFrame(time: time, attackTime: feature.trebleAttackTime, strength: feature.treblePulse)
                if flash > 0, let attack = feature.trebleAttackTime { emitted.insert(attack) }
            }
            try require(emitted.count == hats.count, "All seven off-grid hats must flash at \(fps)fps; found \(emitted.count)")
            print("PASS: all seven off-grid treble attacks flash at \(fps) fps")
        }
        var bassDetector = StrobeDetector(), bassFlashes = 0
        for index in 200..<450 {
            let t = Double(index)/60, feature = try reader.frame(at: t, clipStart: 0, clipEnd: 9)
            if bassDetector.nextSourceFrame(time: t, attackTime: feature.trebleAttackTime, strength: feature.treblePulse) > 0 { bassFlashes += 1 }
        }
        try require(bassFlashes == 0, "Bass-only kicks must not trigger hi-hat strobe")
        print("PASS: bass-only PCM triggers no white flashes")
        let beatURL = root.appendingPathComponent("120bpm.wav")
        try fixture(beatURL, duration: 25) { time in
            let age = (time - 0.1).truncatingRemainder(dividingBy: 0.5)
            return age >= 0 && age < 0.13 ? Float(0.65 * exp(-age * 30) * sin(age * 2 * .pi * 65)) : 0
        }
        let beatReader = try SoundtrackAnalyzer(url: beatURL), plan = beatReader.segmentPlan()
        try require(abs((plan.bpm ?? 0) - 120) < 3, "Detect a real 120 BPM fixture: \(plan.bpm ?? 0)")
        try require(plan.boundaries.first == 0 && plan.boundaries.last == 25 && plan.boundaries.count == 5, "Four-bar sections must span source duration: \(plan.boundaries)")
        for cue in plan.boundaries.dropFirst().dropLast() {
            let nearest = 0.1 + ((cue - 0.1) / 0.5).rounded() * 0.5
            try require(abs(cue - nearest) < 0.04, "Section must align to a detected source beat")
        }
        try require(plan.boundaries == beatReader.segmentPlan().boundaries, "Segment detection must be deterministic")
        print("PASS: 120 BPM detected, four-bar sections aligned to source beats, deterministic boundaries \(plan.boundaries)")
        for bars in [1, 2, 3, 4, 5, 6, 7, 8, 12] {
            let cadence = beatReader.segmentPlan(beatsPerSection: bars * 4)
            try require(cadence.boundaries.first == 0 && cadence.boundaries.last == 25, "Cadence must cover the full song")
            if cadence.boundaries.count > 3 {
                try require(abs(cadence.boundaries[2] - cadence.boundaries[1] - Double(bars) * 2) < 0.05, "Cadence must use requested bars")
            }
        }
        let sustained = root.appendingPathComponent("sustained.wav")
        try fixture(sustained, duration: 20) { time in Float(0.1 * sin(time * 2 * .pi * 440)) }
        let fallback = try SoundtrackAnalyzer(url: sustained).segmentPlan(beatsPerSection: 12)
        try require(fallback.bpm == nil && fallback.boundaries == [0, 6, 12, 18, 20], "No-grid audio uses requested bars at a 120 BPM fallback")
        print("PASS: 1–8 and 12 bar cadence preserves full-song coverage and requested beat-aligned spacing")

        if CommandLine.arguments.count > 1 {
            let started = Date(), music = try SoundtrackAnalyzer(url: URL(fileURLWithPath: CommandLine.arguments[1]))
            var csv = "seconds,pulse,momentum,treble\n"
            for index in 0..<3600 {
                let t = Double(index)/30, f = try music.frame(at: t, clipStart: 0, clipEnd: 120)
                csv += "\(t),\(f.pulse),\(f.momentum),\(f.treblePulse)\n"
            }
            try csv.write(to: root.appendingPathComponent("soundtrack-reaction.csv"), atomically: true, encoding: .utf8)
            print("Soundtrack Studio plan: \(music.segmentPlan().boundaries), BPM \(music.segmentPlan().bpm ?? 0)")
            print("Soundtrack 120s timeline and 3600 feature lookups: \(Date().timeIntervalSince(started))s")
        }
    }
}
