import Foundation
import simd

@main struct OriginalGeometrySmoke {
    static func matches(_ first: OriginalGeometry.Mesh, _ second: OriginalGeometry.Mesh) -> Bool {
        first.indices == second.indices && first.vertices.count == second.vertices.count && zip(first.vertices, second.vertices).allSatisfy {
            $0.position == $1.position && $0.color == $1.color && $0.uv == $1.uv
        }
    }
    static func main() {
        precondition(OriginalGeometry.Scene.allCases.count == 7)
        precondition(OriginalGeometry.sceneNames.count == 7)
        let silence = [Float](repeating: 0, count: 32)
        let loud = [Float](repeating: 0.85, count: 32)
        let bass = (0..<32).map { $0 < 5 ? Float(0.9) : Float(0) }
        let treble = (0..<32).map { $0 >= 27 ? Float(0.9) : Float(0) }
        var counts: Set<Int> = []
        for scene in OriginalGeometry.Scene.allCases {
            let quiet = OriginalGeometry.make(scene: scene.rawValue, time: 1.25, spectrum: silence)
            let active = OriginalGeometry.make(scene: scene.rawValue, time: 1.25, spectrum: loud)
            let repeatFrame = OriginalGeometry.make(scene: scene.rawValue, time: 1.25, spectrum: loud)
            let later = OriginalGeometry.make(scene: scene.rawValue, time: 2.75, spectrum: loud)
            let low = OriginalGeometry.make(scene: scene.rawValue, time: 1.25, spectrum: bass)
            let high = OriginalGeometry.make(scene: scene.rawValue, time: 1.25, spectrum: treble)
            precondition(active.vertices.count > 1000 && active.vertices.count < 20000)
            precondition(matches(active, repeatFrame), "Timestamp generation must be deterministic")
            precondition(!matches(active, later), "Animation must advance")
            precondition(zip(quiet.vertices, active.vertices).contains { $0.position != $1.position }, "Audio must move geometry")
            precondition(zip(quiet.vertices, active.vertices).contains { $0.color != $1.color }, "Audio must affect color")
            precondition(zip(low.vertices, high.vertices).contains { $0.position != $1.position }, "Band distribution must affect geometry")
            for vertex in active.vertices {
                precondition((0..<3).allSatisfy { vertex.position[$0].isFinite && abs(vertex.position[$0]) < 30 })
                precondition((0..<4).allSatisfy { vertex.color[$0].isFinite && vertex.color[$0] >= 0 && vertex.color[$0] <= 1 })
            }
            precondition(active.indices.allSatisfy { Int($0) < active.vertices.count })
            switch active.primitive {
            case .points: precondition(active.indices.isEmpty)
            case .triangles: precondition(!active.indices.isEmpty && active.indices.count.isMultiple(of: 3))
            }
            let invalid = OriginalGeometry.make(scene: scene.rawValue, time: .infinity, spectrum: [.nan, -.infinity, .infinity], intensity: .nan)
            precondition(invalid.vertices.allSatisfy { $0.position.x.isFinite && $0.position.y.isFinite && $0.position.z.isFinite })
            // Tubular and rosette seams must remain closed under uneven spectra.
            if scene == .orbitalRings {
                for ring in 0..<7 {
                    let start = ring * 145 * 9
                    for edge in 0...8 { precondition(simd_length(low.vertices[start + edge].position - low.vertices[start + 144 * 9 + edge].position) < 0.0001) }
                }
            }
            if scene == .audioMandala {
                for ring in 0..<11 {
                    for side in 0...1 {
                        let start = ring * 193 * 2 + side * 193
                        precondition(simd_length(low.vertices[start].position - low.vertices[start + 192].position) < 0.0001)
                    }
                }
            }
            counts.insert(active.vertices.count)
            print("PASS: \(scene.title), \(active.vertices.count) vertices, \(active.indices.count / 3) triangles")
        }
        precondition(counts.count >= 6)
        precondition(OriginalGeometry.make(scene: -1, time: 0, spectrum: []).vertices.isEmpty)
        print("PASS: seven deterministic designs, finite geometry, valid topology, audio position/color response, frequency distribution and timeline animation")
    }
}
