import Foundation
import simd

/// Scalar kernels lifted from native ARM64. Host camera, colors, UVs and mesh
/// connectivity are separate reconstruction choices; these methods return raw positions.
enum MeshGeometry {
    struct TunnelParameters {
        var segments = 20
        var adjust: Float = 3
        var radiusBase: Double = 2.5
        var radiusModulation: Float = 0.5
        var rideRadius: Double = 12
        var pathLength = 80
        var wavelength: Double = 14
        var zAdjust: Float = 4
        var swapXY = false
        var innerRadius: Double = 3
    }
    // Native 0x1003abf44, shared by several textured tunnel builders.
    static func tunnel(ring: Int, segment: Int, parameters p: TunnelParameters) -> SIMD3<Float> {
        let phase = (2 * Double.pi * fmod(Double(ring), p.wavelength)) / p.wavelength
        let growth = ring == 0 ? 0 : (ring < 100 ? Double(Float(ring) * Float(0.01)) : 1)
        let scale = growth * (p.radiusBase + sin(phase) * Double(p.radiusModulation)) * Double(p.adjust)
        let pathAngle = Double(ring % p.pathLength) / Double(p.pathLength)
        let angle = Double(segment) * (2 * Double.pi) / Double(p.segments)
        let x = scale * (sin(pathAngle) * p.rideRadius + p.innerRadius * sin(angle))
        let y = scale * (cos(pathAngle) * p.rideRadius + p.innerRadius * cos(angle))
        let z = Float(Double(ring) * Double(p.adjust) * Double(p.zAdjust))
        return p.swapXY ? SIMD3(Float(x), Float(y), z) : SIMD3(Float(y), Float(x), z)
    }
    struct MorphParameters {
        var segments = 40
        var radiusBase: Double = 2.5
        var adjust: Float = 3
        var modulation: Float = 0.5
        var frequency: Double = 0.0125
        var modulationFactor: Float = 14
        var xScale: Float = 1
        var yScale: Float = 1
    }
    // Native 0x1003bc300: tangent/sine radius with double clamps and squared-adjust depth.
    static func crystalMorph(ring: Int, segment: Int, parameters p: MorphParameters) -> SIMD3<Float> {
        let phase = p.frequency * (fmod(Double(ring), 1 / p.frequency) * (2 * Double.pi))
        let radius = max(2, p.radiusBase + (tan(phase) * 0.3 + sin(phase) * 0.7) * Double(p.modulation * p.modulationFactor))
        let angle = Double(segment) * (2 * Double.pi) / Double(p.segments)
        let limit = Double(p.adjust * 8)
        let adjust = Double(p.adjust)
        let x = min(limit, max(-limit, sin(angle) * radius * adjust * Double(p.xScale))) * adjust
        let y = min(limit, max(-limit, cos(angle) * radius * adjust * Double(p.yScale))) * adjust
        return SIMD3(Float(x), Float(y), -Float(Double(ring) * adjust * adjust))
    }
    struct CrystalTunnelParameters {
        var segments = 20
        var xScale: Float = 1
        var yScale: Float = 1
        var adjust: Float = 3
        var radiusFactor: Float = 1
        var zAdjust: Float = 4
    }
    // Native 0x1003c3a50: all arithmetic before sincosf is single precision.
    static func crystalTunnel(ring: Int, segment: Int, parameters p: CrystalTunnelParameters) -> SIMD3<Float> {
        let radius = ((p.adjust * 0.3) * Float(max(ring, 1))) * p.radiusFactor
        let theta = (Float(segment) * Float(bitPattern: 0x40c90fda)) / Float(p.segments)
        return SIMD3((p.yScale * radius) * sin(theta), (p.xScale * radius) * cos(theta), (p.adjust * Float(ring)) * p.zAdjust)
    }
    // Native 0x1003db6e8: 1050 samples, angle+=2°, radial accumulator+=.00015225.
    static func galaxySpiral() -> [SIMD2<Double>] {
        var angle: Double = 0, radial: Double = 0
        var result: [SIMD2<Double>] = []; result.reserveCapacity(1050)
        for _ in 0..<1050 {
            let theta = (angle * Double.pi) / 180
            let radius = radial * 1090
            result.append(SIMD2(radius * cos(theta), radius * sin(theta)))
            angle += 2; radial += 0.00015225
        }
        return result
    }
    /// Host deterministic stream substitutes OS randomness while retaining 24-bit
    /// closed-unit uniform values used by the native scattering wrapper.
    struct RandomStream {
        var state: UInt64
        mutating func word() -> UInt32 {
            state &+= 0x9e3779b97f4a7c15
            var z = state; z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
            z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
            return UInt32(truncatingIfNeeded: z ^ (z >> 31))
        }
        mutating func unit() -> Float {
            while true {
                let product = UInt64(word()) * 0x1000001
                if UInt32(truncatingIfNeeded: product) >= 0xffff01 {
                    return Float(product >> 32) / 16777216
                }
            }
        }
    }
    // Native 0x1003db818, excluding Metal buffer allocation. First151 samples
    // scatter ±250 in XY, all planar coordinates scale15, optional tail outliers
    // add10000 depth with .25/.5/.75 probabilities in the final10% of samples.
    static func galaxyStars(depthSpan: Float, specialized: Bool, seed: UInt64 = 0x50434e56) -> [SIMD3<Float>] {
        var rng = RandomStream(state: seed)
        return galaxySpiral().enumerated().map { index, spiral in
            var z = rng.unit() * depthSpan - depthSpan * 0.5
            let fraction = Float(index) / 1050
            if specialized && fraction > 0.9 {
                let chance: Float = fraction <= 0.93 ? 0.25 : (fraction <= 0.965 ? 0.5 : 0.75)
                if rng.unit() < chance { z += 10000 }
            }
            var x = Float(spiral.x) * 15, y = Float(spiral.y) * 15
            if index < 151 { x += rng.unit() * 500 - 250; y += rng.unit() * 500 - 250 }
            return SIMD3(x, y, z)
        }
    }

    // Native Cyborg profile table0x100a94920 and position kernel0x1003a25a8.
    // All8 profiles use native mode5 or11 (different tangent weight/depth).
    static func cyborg(ring: Int, segment: Int, profile: Int, segments: Int = 20) -> SIMD3<Float> {
        let index = max(0, min(7, profile))
        let scale: [Float] = [2.7, 2.75, 2.68, 2.68, 2.57, 2.7, 2.75, 2.57]
        let waves = [14, 18, 26, 10, 16, 14, 18, 16]
        let mode11 = index == 4 || index == 7
        let adjust = Double(scale[index] * Float(0.1252))
        let wavelength = Double(waves[index]) * 5 + 5
        let phase = (fmod(Double(ring), wavelength) * (2 * Double.pi)) / wavelength
        let radiusValue = 4.5 + (sin(phase) * 0.7 + tan(phase) * (mode11 ? 0.24 : 0.3)) * 6
        let radius = radiusValue < 2 ? 4 : min(radiusValue, 5) * 2
        let theta = Double(segment) * (2 * Double.pi) / Double(segments)
        let x = sin(theta) * radius * adjust
        let y = cos(theta) * radius * adjust
        let z = mode11 ? Double(ring) * adjust : (adjust * 0.9) * Double(ring)
        // Nativecollector0x1003a1f58 swapAxes=true: x*=adjust*1.2,
        // y=depth*adjust,z=radialY*adjust; wrapper0x1003ca7cc negatesz.
        let a = Float(adjust)
        return SIMD3((a * Float(x)) * 1.2, a * Float(z), -(a * Float(y)))
    }
}
