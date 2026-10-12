import Foundation
@main struct PointSmoke {
    static func main() throws {
        struct Fixture: Decodable { var kernel: String; var pattern: Int; var position: [Double];var index:Int;var length:Int;var spread:Int;var amplitude:Double;var phaseA:Int;var phaseB:Int }
        let fixtures = try JSONDecoder().decode([Fixture].self, from: Data(contentsOf: URL(fileURLWithPath: "scripts/fixtures/point-native.json")))
        for f in fixtures {
            var phaseA = f.phaseA, phaseB = f.phaseB
            let p: SIMD3<Double>
            switch f.kernel {
            case "point": p = PointReferenceGeometry.pointPattern(pattern: f.pattern, index: f.index, length: f.length, amplitude: f.amplitude, spread: f.spread, phaseA: &phaseA, phaseB: &phaseB)
            case "stars": p = PointReferenceGeometry.starPattern(pattern: f.pattern, index: f.index, length: f.length, amplitude: f.amplitude, spread: f.spread, phaseA: &phaseA, phaseB: &phaseB)
            default: p = PointReferenceGeometry.cloudPattern(pattern: f.pattern, index: f.index, length: f.length, amplitude: f.amplitude, spread: f.spread, phaseA: &phaseA, phaseB: &phaseB)
            }
            for (a, b) in zip(f.position, [p.x, p.y, p.z]) { assert(abs(a-b) <= max(abs(a),abs(b),1) * 1e-13, "Mismatch \(f.kernel) \(f.pattern): \(a) vs \(b)") }
        }
        print("PASS: \(fixtures.count) recovered point-pattern native instruction fixtures")
    }
}
