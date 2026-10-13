import Foundation
import simd

struct OriginalVertex: Sendable {
    var position: SIMD3<Float>
    var color: SIMD4<Float>
    var uv: SIMD2<Float>
}

/// Original PulseCanvas designs. Pure functions let preview, seeking and export
/// produce the same geometry for the same soundtrack spectrum and timestamp.
enum OriginalGeometry {
    typealias Vertex = OriginalVertex
    enum Primitive: Sendable { case points, triangles }
    struct Mesh: Sendable {
        var vertices: [Vertex]
        var indices: [UInt32]
        var primitive: Primitive
        var pointSize: Float = 0.055
    }
    enum Scene: Int, CaseIterable, Sendable {
        case audioMandala = 15
        case orbitalRings = 16
        case ribbonWave = 17
        case spectralHelix = 18
        case particleFountain = 19
        case pulseGrid = 20
        case harmonicBloom = 21

        var title: String {
            switch self {
            case .audioMandala: return "Lotus Resonance"
            case .orbitalRings: return "Orbit Loom"
            case .ribbonWave: return "Silk Current"
            case .spectralHelix: return "Double Twist"
            case .particleFountain: return "Arc Spray"
            case .pulseGrid: return "Signal Tiles"
            case .harmonicBloom: return "Resonant Shell"
            }
        }
    }
    static var sceneNames: [String] { Scene.allCases.map(\.title) }

    static func make(scene: Int, time: Float, spectrum: [Float], intensity: Float = 1, palette: Int = 0) -> Mesh {
        let time = time.isFinite ? max(-100_000, min(100_000, time)) : 0
        let intensity = intensity.isFinite ? max(0, min(3, intensity)) : 1
        let audio = Audio(spectrum: spectrum, intensity: intensity)
        switch Scene(rawValue: scene) {
        case .audioMandala: return mandala(time: time, audio: audio, palette: palette)
        case .orbitalRings: return orbits(time: time, audio: audio, palette: palette)
        case .ribbonWave: return ribbons(time: time, audio: audio, palette: palette)
        case .spectralHelix: return helix(time: time, audio: audio, palette: palette)
        case .particleFountain: return fountain(time: time, audio: audio, palette: palette)
        case .pulseGrid: return grid(time: time, audio: audio, palette: palette)
        case .harmonicBloom: return bloom(time: time, audio: audio, palette: palette)
        case nil: return Mesh(vertices: [], indices: [], primitive: .triangles)
        }
    }

    private struct Audio {
        let bands: [Float]
        let intensity: Float
        init(spectrum: [Float], intensity: Float) {
            bands = spectrum.isEmpty ? [0] : spectrum.map { $0.isFinite ? min(1, max(0, $0)) : 0 }
            self.intensity = intensity
        }
        func at(_ position: Float) -> Float {
            let index = max(0, min(1, position)) * Float(bands.count - 1)
            let lower = Int(index), upper = min(lower + 1, bands.count - 1)
            return (bands[lower] + (bands[upper] - bands[lower]) * (index - Float(lower))) * intensity
        }
        var bass: Float {
            let count = max(1, bands.count / 5)
            return bands.prefix(count).reduce(0, +) / Float(count) * intensity
        }
    }

    private static let turn = Float.pi * 2
    private static func color(_ phase: Float, energy: Float, palette: Int, alpha: Float = 1) -> SIMD4<Float> {
        var result = VisualPalette.color(phase, palette: palette)
        let light = min(1, 0.4 + energy * 0.6)
        result.x *= light; result.y *= light; result.z *= light; result.w = alpha
        return result
    }
    private static func vertex(_ position: SIMD3<Float>, phase: Float, energy: Float, palette: Int, uv: SIMD2<Float> = .zero) -> Vertex {
        Vertex(position: position, color: color(phase, energy: energy, palette: palette), uv: uv)
    }
    private static func stripIndices(rows: Int, columns: Int) -> [UInt32] {
        var result: [UInt32] = []
        result.reserveCapacity(rows * columns * 6)
        for row in 0..<rows {
            for column in 0..<columns {
                let first = UInt32(row * (columns + 1) + column)
                let next = first + UInt32(columns + 1)
                result.append(contentsOf: [first, next, first + 1, first + 1, next, next + 1])
            }
        }
        return result
    }

    /// Concentric rosettes with twelve petal lobes, radial bass breathing and
    /// angle-local frequency displacement. The open center preserves its silhouette.
    private static func mandala(time: Float, audio: Audio, palette: Int) -> Mesh {
        let rings = 11, segments = 192
        var vertices: [Vertex] = [], indices: [UInt32] = []
        vertices.reserveCapacity(rings * (segments + 1) * 2)
        for ring in 0..<rings {
            let ringPosition = Float(ring) / Float(rings - 1)
            let baseRadius = 1.1 + ringPosition * 9.2
            for side in 0...1 {
                for segment in 0...segments {
                    let u = Float(segment) / Float(segments)
                    let angle = u * turn + time * (ring.isMultiple(of: 2) ? 0.07 : -0.05)
                    let band = audio.at((1 - cos(u * turn)) * 0.5)
                    let petal = cos(angle * 12 + time * 0.4 + ringPosition * .pi)
                    let radius = baseRadius + petal * (0.22 + band * 0.45) + audio.bass * 0.25 + Float(side) * (0.09 + band * 0.2)
                    let position = SIMD3(radius * cos(angle), radius * sin(angle), sin(angle * 6 + time * 0.6) * (0.15 + band * 0.4))
                    vertices.append(vertex(position, phase: ringPosition * 0.5 + u * 0.25 + time * 0.015, energy: band, palette: palette, uv: SIMD2(u * 8, Float(side))))
                }
            }
            let start = UInt32(ring * (segments + 1) * 2)
            for segment in 0..<segments {
                let a = start + UInt32(segment), b = a + UInt32(segments + 1)
                indices.append(contentsOf: [a, b, a + 1, a + 1, b, b + 1])
            }
        }
        return Mesh(vertices: vertices, indices: indices, primitive: .triangles)
    }

    /// Tilted tubular rings orbit along different axes, with each arc swelling
    /// from its own spectral band instead of a single global beat scalar.
    private static func orbits(time: Float, audio: Audio, palette: Int) -> Mesh {
        let rings = 7, segments = 144, tubeSegments = 8
        var vertices: [Vertex] = [], indices: [UInt32] = []
        for ring in 0..<rings {
            let f = Float(ring) / Float(rings - 1)
            let tilt = -1.1 + f * 2.2 + sin(time * 0.22 + f * turn) * 0.18
            let spin = time * (0.08 + f * 0.08) + f * .pi
            let baseRadius = 3.2 + f * 7
            for segment in 0...segments {
                let u = Float(segment) / Float(segments), angle = u * turn
                let energy = audio.at((1 - cos(u * turn)) * 0.325 + f * 0.35)
                let radius = baseRadius + energy * 0.65 + audio.bass * 0.25
                for edge in 0...tubeSegments {
                    let v = Float(edge) / Float(tubeSegments), tubeAngle = v * turn
                    let thickness = 0.07 + energy * 0.17
                    let x = cos(angle) * (radius + cos(tubeAngle) * thickness)
                    let y = sin(angle) * (radius + cos(tubeAngle) * thickness)
                    let z = sin(tubeAngle) * thickness
                    let tiltedY = y * cos(tilt) - z * sin(tilt)
                    let tiltedZ = y * sin(tilt) + z * cos(tilt)
                    let position = SIMD3(x * cos(spin) - tiltedY * sin(spin), x * sin(spin) + tiltedY * cos(spin), tiltedZ)
                    vertices.append(vertex(position, phase: f * 0.7 + u * 0.35 + time * 0.012, energy: energy, palette: palette, uv: SIMD2(u * 6, v)))
                }
            }
            let offset = UInt32(ring * (segments + 1) * (tubeSegments + 1))
            indices.append(contentsOf: stripIndices(rows: segments, columns: tubeSegments).map { $0 + offset })
        }
        return Mesh(vertices: vertices, indices: indices, primitive: .triangles)
    }

    /// Twisting silk sails flow in depth, with broad folds and frequency-driven crests.
    private static func ribbons(time: Float, audio: Audio, palette: Int) -> Mesh {
        let strips = 8, segments = 180, edges = 4
        var vertices: [Vertex] = [], indices: [UInt32] = []
        for strip in 0..<strips {
            let f = Float(strip) / Float(strips)
            for segment in 0...segments {
                let u = Float(segment) / Float(segments), energy = audio.at(u)
                let angle = f * turn + u * turn * 0.8 - time * 0.6
                let wave = sin(u * turn * 2.3 - time * 1.4 + f * 3) * (1.4 + energy * 2.2)
                let radius = 6.5 + wave + audio.bass * 0.7
                for edge in 0...edges {
                    let across = Float(edge) / Float(edges) - 0.5
                    let width = 1.2 + energy * 1.8
                    let fold = sin(across * .pi * 2 + u * 8 - time) * width * 0.65
                    let position = SIMD3(cos(angle) * radius - sin(angle) * across * width,
                                         sin(angle) * radius + cos(angle) * across * width,
                                         -18 + u * 36 + fold)
                    vertices.append(vertex(position, phase: u * 0.45 + f * 0.45 + time * 0.025,
                        energy: energy, palette: palette, uv: SIMD2(u * 6, Float(edge) / Float(edges))))
                }
            }
            let offset = UInt32(strip * (segments + 1) * (edges + 1))
            indices.append(contentsOf: stripIndices(rows: segments, columns: edges).map { $0 + offset })
        }
        return Mesh(vertices: vertices, indices: indices, primitive: .triangles)
    }

    /// Four substantial coils and discrete cross-rungs make a recognizable
    /// double-helix ball sculpture, even in a narrow portrait preview.
    private static func helix(time: Float, audio: Audio, palette: Int) -> Mesh {
        let strands = 4, segments = 256, lanes = 1
        var vertices: [Vertex] = []
        vertices.reserveCapacity(strands * segments * lanes + 1408)
        for strand in 0..<strands {
            for segment in 0..<segments {
                let u = Float(segment) / Float(segments - 1)
                let energy = audio.at(u)
                let angle = u * turn * 2.6 + Float(strand) * .pi / 2 + time * 0.95
                let radius = 3.15 + audio.bass * 0.75 + energy * 0.42
                let y = -10.3 + u * 20.6
                for lane in 0..<lanes {
                    let crossAngle = Float(lane) / Float(lanes) * turn
                    let thickness = 0.13 + energy * 0.045
                    let laneRadius = radius + cos(crossAngle) * thickness
                    let ripple = sin(u * turn * 18 + time * 2.8) * energy * 0.08
                    let position = SIMD3(cos(angle) * laneRadius + ripple, y + sin(crossAngle) * thickness, sin(angle) * laneRadius)
                    vertices.append(vertex(position, phase: u * 0.5 + Float(strand) * 0.17 + time * 0.018, energy: energy, palette: palette))
                }
            }
        }
        // Open rungs bridge opposite coils; spacing keeps clear negative space
        // between levels instead of turning the center into a solid cylinder.
        for level in 0..<32 {
            let u = (Float(level) + 0.5) / 32
            let energy = audio.at(u)
            let y = -10.3 + u * 20.6
            let radius = 3.15 + audio.bass * 0.75 + energy * 0.42
            for pair in 0..<2 {
                let angle = u * turn * 2.6 + Float(pair) * .pi / 2 + time * 0.95
                for sample in 0..<14 {
                    let across = -1 + Float(sample) / 13 * 2
                    let position = SIMD3(cos(angle) * radius * across, y + sin(across * .pi) * energy * 0.12, sin(angle) * radius * across)
                    vertices.append(vertex(position, phase: u * 0.5 + Float(pair) * 0.17 + time * 0.018, energy: energy * 0.7, palette: palette))
                }
            }
        }
        vertices.sort { $0.position.z < $1.position.z }
        return Mesh(vertices: vertices, indices: [], primitive: .points, pointSize: 0.8)
    }

    /// Eight connected swirling plumes rise through the full centered frame.
    /// Ordered flow lanes retain a strong vase-shaped silhouette, while depth
    /// separates foreground balls from the smaller background arms.
    private static func fountain(time: Float, audio: Audio, palette: Int) -> Mesh {
        let arms = 8, samples = 192, lanes = 1
        var vertices: [Vertex] = []
        vertices.reserveCapacity(arms * samples * lanes + 1024)
        for arm in 0..<arms {
            let armPhase = Float(arm) / Float(arms)
            let phaseOffset = random(UInt32(arm) &+ 43) * 0.12
            for sample in 0..<samples {
                let u = fraction(Float(sample) / Float(samples) + time * 0.055)
                let energy = audio.at(armPhase * 0.55 + u * 0.45)
                let belly = pow(max(0, sin(u * .pi)), 0.85)
                let radius = 1.15 + belly * (5.3 + energy * 0.6) + u * 0.8 + audio.bass * 0.25
                let angle = armPhase * turn + u * turn * 0.8 + time * 0.2 + phaseOffset
                let y = -10 + u * 20
                for lane in 0..<lanes {
                    let laneOffset = Float(lane) - Float(lanes - 1) * 0.5
                    let laneRadius = radius + laneOffset * (0.12 + energy * 0.025)
                    let laneAngle = angle + laneOffset * 0.016
                    let position = SIMD3(cos(laneAngle) * laneRadius, y + laneOffset * 0.025, sin(laneAngle) * laneRadius)
                    vertices.append(vertex(position, phase: armPhase * 0.8 + u * 0.25 + time * 0.018, energy: energy, palette: palette))
                }
            }
        }
        // The central rising braid connects the outer plumes into one object,
        // rather than leaving unrelated droplets scattered across the canvas.
        for strand in 0..<4 {
            for sample in 0..<192 {
                let u = fraction(Float(sample) / 192 + time * 0.075)
                let energy = audio.at(u)
                let angle = Float(strand) * .pi / 2 - u * turn * 1.6 - time * 0.28
                let radius = 0.6 + sin(u * .pi) * (0.8 + audio.bass * 0.2) + energy * 0.12
                let position = SIMD3(cos(angle) * radius, -9.8 + u * 19.6, sin(angle) * radius)
                vertices.append(vertex(position, phase: u * 0.45 + Float(strand) * 0.15 + time * 0.018, energy: energy, palette: palette))
            }
        }
        // Alpha-over sprites paint far layers before the near sphere surfaces.
        vertices.sort { $0.position.z < $1.position.z }
        return Mesh(vertices: vertices, indices: [], primitive: .points, pointSize: 1.0)
    }

    /// A square field of isolated luminous tiles. Each frequency raises a row,
    /// with travelling diagonal pulses driven by bass and local band energy.
    private static func grid(time: Float, audio: Audio, palette: Int) -> Mesh {
        let side = 32
        var vertices: [Vertex] = [], indices: [UInt32] = []
        vertices.reserveCapacity(side * side * 4)
        for row in 0..<side {
            let v = Float(row) / Float(side - 1)
            for column in 0..<side {
                let u = Float(column) / Float(side - 1)
                let energy = audio.at(u)
                let pulse = (sin((u + v) * turn * 2 - time * 1.5) + 1) * 0.5
                let z = energy * 2.8 + pulse * audio.bass * 1.2 - 1.4
                let x = -10.8 + u * 21.6, y = -10.8 + v * 21.6
                let size = 0.18 + 0.065 * energy + 0.05 * pulse
                let offset = UInt32(vertices.count)
                for corner in [SIMD2<Float>(-1, -1), SIMD2<Float>(1, -1), SIMD2<Float>(-1, 1), SIMD2<Float>(1, 1)] {
                    vertices.append(vertex(SIMD3(x + corner.x * size, y + corner.y * size, z), phase: u * 0.55 + v * 0.25 + time * 0.02, energy: energy + pulse * audio.bass * 0.2, palette: palette, uv: (corner + SIMD2(repeating: 1)) * 0.5))
                }
                indices.append(contentsOf: [offset, offset + 1, offset + 2, offset + 2, offset + 1, offset + 3])
            }
        }
        return Mesh(vertices: vertices, indices: indices, primitive: .triangles)
    }

    /// A closed three-dimensional flower with five major lobes, a twisting pole
    /// and frequency-resolved petal ridges across its longitude.
    private static func bloom(time: Float, audio: Audio, palette: Int) -> Mesh {
        let rings = 40, segments = 96
        var vertices: [Vertex] = []
        vertices.reserveCapacity((rings + 1) * (segments + 1))
        for ring in 0...rings {
            let v = Float(ring) / Float(rings), theta = v * .pi
            for segment in 0...segments {
                let u = Float(segment) / Float(segments), phi = u * turn
                let energy = audio.at((1 - cos(u * turn)) * 0.5)
                let petals = cos(phi * 5 + time * 0.3) * sin(theta) * sin(theta)
                let radius = 6.6 + petals * (1.25 + energy * 0.6) + sin(theta * 8 - time * 0.75) * energy * 0.45 + audio.bass * 0.4
                let twist = phi + cos(theta) * (0.22 + sin(time * 0.2) * 0.15)
                let position = SIMD3(sin(theta) * cos(twist) * radius, cos(theta) * radius * 1.2, sin(theta) * sin(twist) * radius)
                vertices.append(vertex(position, phase: u * 0.7 + v * 0.3 + time * 0.015, energy: energy, palette: palette, uv: SIMD2(u * 4, v * 3)))
            }
        }
        return Mesh(vertices: vertices, indices: stripIndices(rows: rings, columns: segments), primitive: .triangles)
    }

    private static func fraction(_ value: Float) -> Float { value - floor(value) }
    private static func random(_ seed: UInt32) -> Float {
        var value = seed &+ 0x9e3779b9
        value = (value ^ (value >> 16)) &* 0x85ebca6b
        value = (value ^ (value >> 13)) &* 0xc2b2ae35
        value ^= value >> 16
        return Float(value >> 8) / Float(1 << 24)
    }
}
