import Foundation
@main struct FamilyGeometrySmoke {
    static func main() {
        struct Fixture: Decodable { var kernel: String; var ring: Int; var segment: Int; var position: [Double] }
        let fixtureURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("scripts/fixtures/family-native.json")
        let fixtures = try! JSONDecoder().decode([Fixture].self, from: Data(contentsOf: fixtureURL))
        for f in fixtures {
            let result: [Double]
            switch f.kernel {
            case "tunnel": let p = MeshGeometry.tunnel(ring: f.ring, segment: f.segment, parameters: .init()); result = [Double(p.x), Double(p.y), Double(p.z)]
            case "morph": let p = MeshGeometry.crystalMorph(ring: f.ring, segment: f.segment, parameters: .init()); result = [Double(p.x), Double(p.y), Double(p.z)]
            case "crystal": let p = MeshGeometry.crystalTunnel(ring: f.ring, segment: f.segment, parameters: .init()); result = [Double(p.x), Double(p.y), Double(p.z)]
            default: let p = MeshGeometry.galaxySpiral()[f.ring]; result = [p.x, p.y, 0]
            }
            for (native, swift) in zip(f.position, result) { assert(abs(native - swift) <= max(abs(native), abs(swift), 1) * 1e-6, "Kernel mismatch: \(f.kernel), \(f.ring), \(f.segment)") }
        }
        print("PASS: \(fixtures.count) native instruction fixtures match Swift kernels")
        struct CyborgFixture:Decodable{var profile:Int;var ring:Int;var segment:Int;var position:[Float]}
        let cyborg=try! JSONDecoder().decode([CyborgFixture].self,from:Data(contentsOf:URL(fileURLWithPath:"scripts/fixtures/cyborg-native.json")))
        for f in cyborg{
            let p=MeshGeometry.cyborg(ring:f.ring,segment:f.segment,profile:f.profile)
            for(a,b)in zip(f.position,[p.x,p.y,p.z]){assert(abs(a-b)<=max(abs(a),abs(b),1)*1e-6,"Cyborg mismatch \(f.profile) \(f.ring): \(a) vs \(b)")}
        }
        print("PASS: \(cyborg.count) Cyborg native kernel/collector fixtures")
        let stars=MeshGeometry.galaxyStars(depthSpan:10000,specialized:true)
        assert(stars.count==1050 && stars.allSatisfy{$0.z >= -5000 && $0.z<=15000})
        let samples = [(0, 0), (1, 1), (24, 3), (99, 19), (100, 7), (123, 12), (599, 17)]
        for (ring, segment) in samples {
            for (name, p) in [
                ("tunnel", MeshGeometry.tunnel(ring: ring, segment: segment, parameters: .init())),
                ("morph", MeshGeometry.crystalMorph(ring: ring, segment: segment, parameters: .init())),
                ("crystal", MeshGeometry.crystalTunnel(ring: ring, segment: segment, parameters: .init()))
            ] { print("\(name)\t\(ring)\t\(segment)\t\(p.x)\t\(p.y)\t\(p.z)") }
        }
        let spiral = MeshGeometry.galaxySpiral()
        for index in [0, 1, 150, 599, 1049] { print("spiral\t\(index)\t0\t\(spiral[index].x)\t\(spiral[index].y)\t0") }
        assert(spiral.count == 1050)
    }
}
