import Accelerate
import AVFoundation
import Foundation
import simd

struct SongSegmentation {
    let boundaries: [Double]
    let bpm: Double?
}

struct AudioFeatures {
    var bands: [Float]
    var pulse: Float
    var momentum: Float = 0
    var beatMotionTime: Double = 0
    var treblePulse: Float = 0
    var trebleAttackTime: Double? = nil
    /// Smoothed low, low-mid, high-mid and high levels, normalized per song (0...1).
    var envelopes = SIMD4<Float>(repeating: 0)
    /// Attack envelope with a short rise and ~0.25 s fall, for fluid element motion.
    var swell: Float = 0
    static let silence = AudioFeatures(bands: [Float](repeating: 0, count: 32), pulse: 0)
}

/// Source PCM is sampled at the playhead, before preview volume. Both preview
/// and export use this bounded, stateless window, including on backwards seeks.
final class SoundtrackAnalyzer {
    private let file: AVAudioFile
    private let length = 2048
    private let setup: FFTSetup
    private let window: [Float]
    private let rhythm: RhythmTimeline
    private var segmentationPlans: [Int: SongSegmentation] = [:]
    var sampleRate: Double { file.processingFormat.sampleRate }

    init(url: URL) throws {
        file = try AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false)
        guard file.length > 0, file.processingFormat.sampleRate > 80,
              let setup = vDSP_create_fftsetup(11, FFTRadix(kFFTRadix2)) else {
            throw AudioAnalysisError("Soundtrack contains no readable PCM samples")
        }
        self.setup = setup
        var values = [Float](repeating: 0, count: length)
        vDSP_hann_window(&values, vDSP_Length(length), Int32(vDSP_HANN_NORM))
        window = values
        rhythm = try RhythmTimeline(file: file)
    }
    deinit { vDSP_destroy_fftsetup(setup) }

    /// Stereo PCM at 44.1 kHz, the sample rate expected by Milkdrop presets.
    /// It is read before preview volume and used by preview and offline export.
    func pcm(at time: Double, count: Int = 1024) throws -> [Float] {
        guard time.isFinite, time >= 0 else { return [] }
        let windowStart = (time - Double(count) / 44100) * sampleRate
        let first = max(0, Int(floor(windowStart)))
        let required = Int(ceil(Double(count) * sampleRate / 44100)) + 2
        let available = min(required, Int(file.length) - first)
        guard available > 0, let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(available)) else { return [] }
        file.framePosition = AVAudioFramePosition(first); try file.read(into: buffer)
        guard let channels = buffer.floatChannelData else { return [] }
        var result = [Float](repeating: 0, count: count * 2)
        for index in 0..<count {
            let position = windowStart + Double(index) * sampleRate / 44100 - Double(first)
            guard position >= 0 else {continue}
            let lower = Int(position), upper = lower + 1, fraction = Float(position - Double(lower))
            guard lower >= 0, upper < Int(buffer.frameLength) else {continue}
            for channel in 0..<2 {
                let samples = channels[min(channel, Int(buffer.format.channelCount) - 1)]
                result[index * 2 + channel] = samples[lower] * (1 - fraction) + samples[upper] * fraction
            }
        }
        return result
    }

    func segmentPlan(beatsPerSection: Int = 16) -> SongSegmentation {
        let beats = max(1, beatsPerSection)
        if let cached = segmentationPlans[beats] { return cached }
        let plan = rhythm.segmentPlan(duration: Double(file.length) / sampleRate, beatsPerSection: beats)
        segmentationPlans[beats] = plan
        return plan
    }

    func frame(at time: Double, clipStart: Double, clipEnd: Double, frameInterval: Double = 1.0 / 60) throws -> AudioFeatures {
        guard time.isFinite, clipStart.isFinite, clipEnd.isFinite, time >= 0 else { return .silence }
        let center = Int((time * sampleRate).rounded())
        let fftStart = center - length / 2
        let first = max(0, fftStart)
        let last = min(Int(file.length), center + length / 2)
        guard last > first,
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(last - first)) else { return .silence }
        file.framePosition = AVAudioFramePosition(first)
        try file.read(into: buffer)
        guard let channels = buffer.floatChannelData else { throw AudioAnalysisError("Cannot read soundtrack PCM") }
        let channelCount = Int(buffer.format.channelCount)
        let frameCount = Int(buffer.frameLength)
        var power = [Float](repeating: 0, count: length / 2)
        for channel in 0..<channelCount {
            var samples = [Float](repeating: 0, count: length)
            for i in 0..<length {
                let source = fftStart + i, offset = source - first
                if offset >= 0 && offset < frameCount && source >= Int(clipStart * sampleRate) && source < Int(clipEnd * sampleRate) {
                    samples[i] = channels[channel][offset] * window[i]
                }
            }
            var real = [Float](repeating: 0, count: length / 2)
            var imaginary = real, channelPower = real
            real.withUnsafeMutableBufferPointer { re in
                imaginary.withUnsafeMutableBufferPointer { im in
                    var split = DSPSplitComplex(realp: re.baseAddress!, imagp: im.baseAddress!)
                    samples.withUnsafeBufferPointer { input in
                        input.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: length / 2) {
                            vDSP_ctoz($0, 2, &split, 1, vDSP_Length(length / 2))
                        }
                    }
                    vDSP_fft_zrip(setup, &split, 1, 11, FFTDirection(FFT_FORWARD))
                    split.imagp[0] = 0
                    vDSP_zvmags(&split, 1, &channelPower, 1, vDSP_Length(length / 2))
                }
            }
            for bin in power.indices { power[bin] += channelPower[bin] / Float(channelCount) }
        }
        let maximum = min(16_000, sampleRate / 2)
        var bands = [Float](repeating: 0, count: 32)
        for band in bands.indices {
            let lower = 40 * pow(maximum / 40, Double(band) / 32)
            let upper = 40 * pow(maximum / 40, Double(band + 1) / 32)
            let firstBin = min(length / 2 - 1, max(1, Int(lower * Double(length) / sampleRate)))
            let lastBin = min(length / 2 - 1, max(firstBin, Int(upper * Double(length) / sampleRate)))
            let amplitude = sqrt(power[firstBin...lastBin].max() ?? 0) / Float(length)
            // Keep musical dynamics; the old -70...0 dB mapping flattened loud music.
            bands[band] = min(1, pow(max(0, amplitude - 0.0005) * 5, 0.6))
        }
        let reaction = rhythm.at(time, frameInterval: frameInterval)
        let (envelopes, swell) = rhythm.envelopes(at: time)
        return AudioFeatures(bands: bands, pulse: reaction.pulse, momentum: reaction.momentum, beatMotionTime: reaction.beatMotionTime, treblePulse: reaction.treblePulse, trebleAttackTime: reaction.trebleAttackTime, envelopes: envelopes, swell: swell)
    }

}

struct AudioAnalysisError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

/// Detect actual attacks once from continuous PCM, then read them on the source timeline.
/// No running tempo, frame-history dependency, or resetting filter at each preview frame.
private struct RhythmTimeline {
    struct Attack { let time: Double; let strength: Float }
    let attacks: [Attack]
    let trebleAttacks: [Attack]
    let hopSeconds: Double
    let momentum: [Float]
    let motionTimes: [Double]
    /// Per-hop smoothed band levels and attack swell, computed once so every frame is a
    /// pure function of soundtrack time (identical in preview, Studio and export).
    let bandEnvelopes: [SIMD4<Float>]
    let swells: [Float]

    init(file: AVAudioFile) throws {
        let rate = file.processingFormat.sampleRate
        let hop = max(1, Int((rate * 0.01).rounded()))
        hopSeconds = Double(hop) / rate
        let channelCount = Int(file.processingFormat.channelCount)
        let capacity = AVAudioFrameCount(hop * 100)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: capacity) else {
            throw AudioAnalysisError("Cannot allocate rhythm analysis buffer")
        }
        var bass = [Float](), body = [Float](), treble = [Float]()
        var bandEnergy = [SIMD4<Float>]()
        // Crossovers match the renderer's 32-band groups: 123, 552 and 2960 Hz.
        let crossovers = SIMD3<Float>(Float(1 - exp(-2 * Double.pi * 123 / rate)), Float(1 - exp(-2 * Double.pi * 552 / rate)), Float(1 - exp(-2 * Double.pi * 2960 / rate)))
        var splitA = [SIMD3<Float>](repeating: .zero, count: channelCount), splitB = splitA
        var lower = [Float](repeating: 0, count: channelCount), lower2 = lower, upper = lower
        var high2 = lower, high3 = lower, high4 = lower
        let lowCoefficient = Float(1 - exp(-2 * Double.pi * 180 / rate))
        let highCoefficient = Float(1 - exp(-2 * Double.pi * 1800 / rate))
        file.framePosition = 0
        while file.framePosition < file.length {
            try file.read(into: buffer, frameCount: capacity)
            guard let samples = buffer.floatChannelData, buffer.frameLength > 0 else { break }
            let count = Int(buffer.frameLength)
            for first in stride(from: 0, to: count, by: hop) {
                let last = min(count, first + hop)
                var lo: Float = 0, mid: Float = 0, hi: Float = 0
                var split = SIMD4<Float>(repeating: 0)
                for channel in 0..<channelCount {
                    for index in first..<last {
                        let sample = samples[channel][index]
                        splitA[channel] += crossovers * (SIMD3(repeating: sample) - splitA[channel])
                        splitB[channel] += crossovers * (splitA[channel] - splitB[channel])
                        let lows = splitB[channel]
                        let parts = SIMD4(lows.x, lows.y - lows.x, lows.z - lows.y, sample - lows.z)
                        split += parts * parts
                        lower[channel] += lowCoefficient * (sample - lower[channel])
                        lower2[channel] += lowCoefficient * (lower[channel] - lower2[channel])
                        upper[channel] += highCoefficient * (sample - upper[channel])
                        let middle = upper[channel] - lower[channel]
                        // Four high-pass stages reject low-frequency leakage at a bass onset.
                        let high1 = sample - upper[channel]
                        high2[channel] += highCoefficient * (high1 - high2[channel])
                        let highSecond = high1 - high2[channel]
                        high3[channel] += highCoefficient * (highSecond - high3[channel])
                        let highThird = highSecond - high3[channel]
                        high4[channel] += highCoefficient * (highThird - high4[channel])
                        let high = highThird - high4[channel]
                        lo += lower2[channel] * lower2[channel]; mid += middle * middle; hi += high * high
                    }
                }
                let divisor = Float((last - first) * channelCount)
                bass.append(lo / divisor); body.append(mid / divisor); treble.append(hi / divisor)
                bandEnergy.append(split / divisor)
            }
        }
        var events = [Attack](), hats = [Attack](), drive = [Float](repeating: 0, count: bass.count)
        var lastKick = -Double.infinity, lastSnare = lastKick, lastHat = lastKick
        var baseline = SIMD3<Float>(repeating: 0), previous = baseline
        var currentMomentum: Float = 0
        for tick in bass.indices {
            let start = max(0, tick - 2), divisor = Float(tick - start + 1)
            let envelope = SIMD3(sqrt(bass[start...tick].reduce(0,+) / divisor),
                                 sqrt(body[start...tick].reduce(0,+) / divisor),
                                 sqrt(treble[max(0,tick-1)...tick].reduce(0,+) / Float(min(tick+1,2))))
            let rise = Self.simdMaxZero(envelope - previous)
            let timestamp = max(0, Double(tick + 1) * hopSeconds - 0.008)
            let kick = rise.x > max(0.0012, baseline.x * 0.20) && envelope.x > baseline.x * 1.3 && timestamp - lastKick > 0.085
            let snare = rise.y > max(0.0025, baseline.y * 0.32) && envelope.y > baseline.y * 1.5 &&
                envelope.z > max(0.001, envelope.y * 0.08) && timestamp - lastSnare > 0.075
            let hat = rise.z > max(0.001, baseline.z * 0.4) && envelope.z > baseline.z * 1.5 && rise.z > rise.x * 0.10 && timestamp - lastHat > 0.035
            var strength: Float = 0
            if kick { strength = min(1, rise.x / max(0.003, baseline.x * 0.65)); lastKick = timestamp }
            if snare { strength = max(strength, min(1, rise.y / max(0.005, baseline.y * 0.8))); lastSnare = timestamp }
            if hat {
                let hatStrength = min(1, rise.z / max(0.0015, baseline.z * 0.8))
                hats.append(Attack(time: timestamp, strength: hatStrength))
                strength = max(strength, hatStrength * 0.42); lastHat = timestamp
            }
            // A short silent lead-in has no synthetic pulse; only measured rises add drive.
            if strength > 0.08 { events.append(Attack(time: timestamp, strength: strength)) }
            currentMomentum = min(1, currentMomentum * Float(exp(-hopSeconds / 0.7)) + strength * 0.24)
            drive[tick] = currentMomentum
            baseline += (envelope - baseline) * Float(1 - exp(-hopSeconds / 0.22))
            previous = envelope
        }
        attacks = events; trebleAttacks = hats; momentum = drive
        (bandEnvelopes, swells) = Self.smoothedLevels(energy: bandEnergy, attacks: events, hop: hopSeconds)
        var accumulated = [0.0]
        accumulated.reserveCapacity(drive.count + 1)
        for value in drive { accumulated.append(accumulated.last! + Double(value) * hopSeconds) }
        motionTimes = accumulated
    }

    /// Normalizes each band against its own loud passages (95th percentile of non-silent
    /// hops), so dynamics within a song are kept, then applies a rise/fall follower.
    private static func smoothedLevels(energy: [SIMD4<Float>], attacks: [Attack], hop: Double) -> ([SIMD4<Float>], [Float]) {
        guard !energy.isEmpty else { return ([], []) }
        let amplitudes = energy.map { $0.replacing(with: 0, where: $0 .< 0).squareRoot() }
        var reference = SIMD4<Float>(repeating: 1)
        for band in 0..<4 {
            let audible = amplitudes.map { $0[band] }.filter { $0 > 1e-4 }.sorted()
            reference[band] = audible.isEmpty ? 1 : max(1e-4, audible[min(audible.count - 1, Int(Double(audible.count) * 0.95))])
        }
        // Resolve short subdivisions without holding most of a beat.
        let rise = Float(1 - exp(-hop / 0.018)), fall = Float(1 - exp(-hop / 0.095))
        var envelopes = [SIMD4<Float>](), level = SIMD4<Float>(repeating: 0)
        envelopes.reserveCapacity(amplitudes.count)
        for amplitude in amplitudes {
            let target = simd_min(amplitude / reference, SIMD4<Float>(repeating: 1.15)) * 0.87
            for band in 0..<4 { level[band] += (target[band] - level[band]) * (target[band] > level[band] ? rise : fall) }
            envelopes.append(level)
        }
        var raw = [Float](repeating: 0, count: energy.count)
        for attack in attacks {
            let first = max(0, Int(attack.time / hop))
            for tick in first..<min(raw.count, first + Int(0.35 / hop)) {
                let age = max(0, Double(tick) * hop - attack.time)
                raw[tick] = max(raw[tick], attack.strength * Float(exp(-age / 0.065)))
            }
        }
        let attackRise = Float(1 - exp(-hop / 0.02)), attackFall = Float(1 - exp(-hop / 0.25))
        var swells = [Float](), swell: Float = 0
        swells.reserveCapacity(raw.count)
        for value in raw {
            swell += (value - swell) * (value > swell ? attackRise : attackFall)
            swells.append(swell)
        }
        return (envelopes, swells)
    }

    func envelopes(at time: Double) -> (SIMD4<Float>, Float) {
        guard !bandEnvelopes.isEmpty, time.isFinite, time >= 0 else { return (SIMD4<Float>(repeating: 0), 0) }
        let position = min(Double(bandEnvelopes.count - 1), time / hopSeconds)
        let tick = Int(position), next = min(bandEnvelopes.count - 1, tick + 1)
        let fraction = Float(position - Double(tick))
        let envelope = bandEnvelopes[tick] + (bandEnvelopes[next] - bandEnvelopes[tick]) * fraction
        return (envelope, swells[tick] + (swells[next] - swells[tick]) * fraction)
    }

    func at(_ time: Double, frameInterval: Double) -> (pulse: Float, momentum: Float, beatMotionTime: Double, treblePulse: Float, trebleAttackTime: Double?) {
        // Binary search keeps lookup cheap even for long soundtracks.
        var low = 0, high = attacks.count
        while low < high { let mid = (low + high) / 2; if attacks[mid].time <= time { low = mid + 1 } else { high = mid } }
        var pulse: Float = 0, index = low - 1
        while index >= 0 {
            let attack = attacks[index], age = time - attack.time
            if age > 0.32 { break }
            pulse = max(pulse, attack.strength * Float(exp(-age / 0.065)))
            index -= 1
        }
        let tick = max(0, min(momentum.count - 1, Int(time / hopSeconds)))
        var hatLow = 0, hatHigh = trebleAttacks.count
        while hatLow < hatHigh { let mid = (hatLow + hatHigh) / 2; if trebleAttacks[mid].time <= time { hatLow = mid + 1 } else { hatHigh = mid } }
        var treble: Float = 0, hatIndex = hatLow - 1
        let duration = max(0.025, min(0.1, frameInterval.isFinite ? frameInterval : 1.0 / 60))
        while hatIndex >= 0 && time - trebleAttacks[hatIndex].time < duration {
            treble = max(treble, trebleAttacks[hatIndex].strength); hatIndex -= 1
        }
        let lastHat = hatLow - 1
        let attackTime = lastHat >= 0 ? trebleAttacks[lastHat].time : nil
        if let attackTime, time - attackTime < 0.1 { treble = trebleAttacks[lastHat].strength }
        let position = min(Double(momentum.count), max(0, time / hopSeconds))
        let motion = momentum.isEmpty ? 0 : motionTimes[tick] + Double(momentum[tick]) * hopSeconds * (position - Double(tick))
        return (pulse, momentum.isEmpty ? 0 : momentum[tick], motion, treble, attackTime)
    }
    func segmentPlan(duration: Double, beatsPerSection: Int) -> SongSegmentation {
        let strong = attacks.filter { $0.strength >= 0.55 }
        var period = 0.5, detectedBPM: Double? = nil, phase = 0.0
        if strong.count >= 4 && duration >= 2 {
            var impulses = [Float](repeating: 0, count: momentum.count)
            for attack in strong {
                let index = min(impulses.count - 1, Int(attack.time / hopSeconds))
                if index >= 0 { impulses[index] = max(impulses[index], attack.strength) }
            }
            var bestScore: Float = 0
            for lag in Int(0.3 / hopSeconds)...Int(1.0 / hopSeconds) where lag < impulses.count {
                var score: Float = 0
                for i in lag..<impulses.count where impulses[i] > 0 {
                    let lo = max(0, i - lag - 2), hi = min(impulses.count - 1, i - lag + 2)
                    score += impulses[i] * (impulses[lo...hi].max() ?? 0)
                }
                let candidate = Double(lag) * hopSeconds
                score *= Float(exp(-pow(log(candidate / 0.5), 2) / 0.5))
                if score > bestScore { bestScore = score; period = candidate }
            }
            if bestScore > 1 {
                detectedBPM = 60 / period
                var phases = [Float](repeating: 0, count: 64)
                for attack in strong {
                    let fraction = attack.time / period - floor(attack.time / period)
                    let bin = Int(fraction * 64) % 64
                    for offset in -2...2 { phases[(bin + offset + 64) % 64] += attack.strength * Float(3 - abs(offset)) }
                }
                phase = Double(phases.indices.max(by: { phases[$0] < phases[$1] }) ?? 0) / 64 * period
            }
        }
        let spacing = period * Double(max(1, beatsPerSection))
        var points = [0.0], target = phase + spacing
        while target < duration - 0.5 {
            let nearby = strong.filter { abs($0.time - target) < period * 0.18 }
            let cue = nearby.min(by: { abs($0.time-target) < abs($1.time-target) })?.time ?? target
            if cue > points.last! + 0.5 { points.append(cue) }
            target += spacing
        }
        points.append(duration)
        return SongSegmentation(boundaries: points, bpm: detectedBPM)
    }
    private static func simdMaxZero(_ value: SIMD3<Float>) -> SIMD3<Float> {
        SIMD3(max(0,value.x),max(0,value.y),max(0,value.z))
    }
}
