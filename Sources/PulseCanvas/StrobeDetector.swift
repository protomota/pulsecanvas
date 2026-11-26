import Foundation

/// High-frequency onset gate. No tempo guessing or low-frequency beat trigger.
/// Absolute timestamps keep seeking, preview, and offline rendering consistent.
struct StrobeDetector {
    private var previousEnergy: Float = 0
    private var noiseFloor: Float = 0
    private var lastTime = -Double.infinity
    private var lastAttack = -Double.infinity
    private var flashUntil = -Double.infinity

    mutating func reset() { self = StrobeDetector() }

    /// One white flash per source attack, including attacks between rendered frames.
    mutating func nextSourceFrame(time: Double, attackTime: Double?, strength: Float, sensitivity: Float = 1) -> Float {
        guard time.isFinite else { return 0 }
        if time < lastTime || time - lastTime > 0.25 { reset() }
        if time == lastTime { return time < flashUntil ? 1 : 0 }
        let interval = lastTime.isFinite ? max(0.025, min(0.1, time - lastTime)) : 0.025
        let gain = max(0.25, min(4, sensitivity))
        if let attackTime, attackTime <= time, time - attackTime <= interval,
           attackTime > lastAttack, strength >= 0.22 / gain {
            lastAttack = attackTime; flashUntil = time + 0.020
        }
        lastTime = time
        return time < flashUntil ? 1 : 0
    }

    mutating func nextFrame(time: Double, bands: [Float], sensitivity: Float = 1) -> Float {
        guard time.isFinite else { return 0 }
        if time < lastTime || time - lastTime > 0.25 { reset() }
        if time == lastTime { return time < flashUntil ? 1 : 0 }
        let dt = lastTime.isFinite ? max(0, time - lastTime) : 1.0 / 60
        let treble = bands.dropFirst(24).prefix(8).map { $0.isFinite ? max(0, min(1, $0)) : 0 }
        let energy = treble.isEmpty ? 0 : treble.reduce(0, +) / Float(treble.count)
        let flux = max(0, energy - previousEnergy)
        let gain = max(0.25, min(4, sensitivity))
        let threshold: Float = 0.055 / gain
        let onset = flux > threshold && energy > max(0.10 / gain, noiseFloor * 1.08)
        if onset && time - lastAttack >= 0.035 {
            lastAttack = time
            flashUntil = time + 0.025
        }
        let follow = Float(1 - exp(-dt / 0.4))
        noiseFloor += (energy - noiseFloor) * follow
        previousEnergy = energy
        lastTime = time
        return time < flashUntil ? 1 : 0
    }
}
