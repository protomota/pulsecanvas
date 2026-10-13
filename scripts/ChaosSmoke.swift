import AppKit
import AVFoundation
import MetalKit
import Foundation
@main struct ChaosSmoke {
    static func require(_ condition: Bool, _ message: String) throws { if !condition { throw AudioAnalysisError(message) } }
    static func pixels(_ texture: MTLTexture) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: texture.width * texture.height * 4)
        bytes.withUnsafeMutableBytes { texture.getBytes($0.baseAddress!, bytesPerRow: texture.width*4, from: MTLRegionMake2D(0,0,texture.width,texture.height), mipmapLevel: 0) }
        return bytes
    }
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let root = URL(fileURLWithPath: ".build/chaos-validation")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        let pcm = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 176_400)!
        pcm.frameLength = pcm.frameCapacity
        for i in 0..<Int(pcm.frameLength) {
            let time = Double(i)/44_100
            var value = 0.0
            for attack in [0.3,0.8] {
                let age = time - attack
                if age >= 0 && age < 0.12 { value += 0.65 * exp(-age * 30) * sin(age * 2 * .pi * 65) }
            }
            pcm.floatChannelData![0][i] = Float(value)
        }
        let url = root.appendingPathComponent("two-beats.wav")
        var settings = format.settings; settings[AVLinearPCMIsNonInterleaved] = false
        try AVAudioFile(forWriting: url, settings: settings).write(from: pcm)
        let analyzer = try SoundtrackAnalyzer(url: url)
        var previous = 0.0
        for i in 0..<400 {
            let feature = try analyzer.frame(at: Double(i)/100, clipStart: 0, clipEnd: 4)
            try require(feature.beatMotionTime >= previous, "Beat acceleration clock cannot rewind")
            if i < 29 { try require(feature.beatMotionTime == 0, "No beat acceleration before percussion") }
            previous = feature.beatMotionTime
        }
        let quiet = try analyzer.frame(at: 3.8, clipStart: 0, clipEnd: 4)
        let later = try analyzer.frame(at: 3.9, clipStart: 0, clipEnd: 4)
        try require((later.beatMotionTime-quiet.beatMotionTime)/0.1 < 0.01, "Acceleration must settle in quiet passages")
        let hit = try analyzer.frame(at: 0.83, clipStart: 0, clipEnd: 4)
        let repeated = try analyzer.frame(at: 0.83, clipStart: 0.8, clipEnd: 1.1, frameInterval: 1.0/24)
        try require(hit.beatMotionTime > 0.05 && hit.beatMotionTime == repeated.beatMotionTime, "Beat clock must remain source-locked when seeking, trimming, and changing fps")
        print("PASS: percussion-only acceleration, monotonic source clock, quiet release, deterministic seeks/trims/frame rates")
        let state = RenderState(), renderer = VisualizerRenderer(state: state)
        try renderer.prepareOffscreen(width: 320, height: 180)
        let bands = [Float](repeating: 0.3, count: 32)
        let silence = [Float](repeating: 0, count: 32)
        for scene in NativeEffects.activeIDs {
            state.scene = scene; state.particleSize = 1.6
            state.chaos = 0
            let calm = pixels(try renderer.renderOffscreen(time: 2.3, audioBands: silence))
            state.chaos = 1
            let noBeats = pixels(try renderer.renderOffscreen(time: 2.3, audioBands: silence))
            try require(calm == noBeats, "Chaos must add no activity without beats, scene \(scene)")
            state.chaos = 0
            let restrained = pixels(try renderer.renderOffscreen(time: 2.3, audioBands: bands, audioPulse: 0.8, audioMomentum: 0.9, audioBeatMotionTime: hit.beatMotionTime, audioEnvelopes: SIMD4(repeating: 0.6), audioSwell: 0.8))
            try require(calm == restrained, "Zero Chaos must ignore all music inputs, scene \(scene)")
            state.chaos = 1
            let active = pixels(try renderer.renderOffscreen(time: 2.3, audioBands: bands, audioPulse: 0.8, audioMomentum: 0.9, audioBeatMotionTime: hit.beatMotionTime, audioEnvelopes: SIMD4(repeating: 0.6), audioSwell: 0.8))
            let difference = zip(restrained,active).reduce(0.0) { $0 + Double(abs(Int($1.0)-Int($1.1))) } / Double(active.count)
            try require(difference > 0.05, "Chaos must visibly change beat activity in scene \(scene): \(difference)")
            _ = try renderer.renderOffscreen(time: 0.1, audioBands: bands)
            let revisit = pixels(try renderer.renderOffscreen(time: 2.3, audioBands: bands, audioPulse: 0.8, audioMomentum: 0.9, audioBeatMotionTime: hit.beatMotionTime, audioEnvelopes: SIMD4(repeating: 0.6), audioSwell: 0.8))
            try require(active == revisit, "Chaotic visuals must remain deterministic after backwards seeks")
        }
        print("PASS: all \(NativeEffects.activeIDs.count) GPU visualizers respond to Chaos on beats, remain unchanged without beats, and reproduce exact pixels after seeking")
        // Exercise the shared path with zoom/blur/strobe and sharply changing
        // audio features. Zero Chaos must be identical to a silent soundtrack
        // at every source timestamp, without stopping procedural animation.
        for (width, height) in [(320,180),(180,320)] {
            try renderer.prepareOffscreen(width: width, height: height)
            for scene in NativeEffects.activeIDs {
                state.scene = scene; state.chaos = 0; state.strobeEnabled = true
                state.motionBlur = 0.4
                for zoom in [Float(0),1.5,3] {
                    state.zoomSpeed = zoom
                    var first: [UInt8]?
                    var last: [UInt8] = []
                    for (index, time) in [0.299,0.301,0.799,0.801,2.3].enumerated() {
                        let clean = pixels(try renderer.renderOffscreen(time: time, audioBands: silence))
                        let loud = pixels(try renderer.renderOffscreen(time: time,
                            audioBands: (0..<32).map { Float(($0+index)%3)/2 }, audioPulse: 1,
                            audioMomentum: 1, audioBeatMotionTime: Double(index+1),
                            audioTreblePulse: 1, audioTrebleAttackTime: time,
                            audioEnvelopes: SIMD4(Float(index % 2), 1, 0.5, 1), audioSwell: 1))
                        try require(clean == loud, "Zero Chaos leaked music at \(time): \(RenderState.sceneNames[scene]), zoom \(zoom), \(width)x\(height)")
                        if first == nil { first = clean }; last = clean
                    }
                    try require(first != last, "Zero Chaos must retain visualization motion: \(RenderState.sceneNames[scene]), zoom \(zoom)")
                }
            }
        }
        print("PASS: every style at zero Chaos ignores pulse, spectrum, momentum, beat clock and strobe in wide/portrait at three zoom speeds, while visualization motion continues")
    }
}
