import Foundation
import Metal
struct PackPreset: Codable { let path: String; let title: String }
@main struct PackSmoke {
    static func main() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {fatalError("Metal unavailable")}
        let root = URL(fileURLWithPath:"Sources/PulseCanvas/Resources/ProjectM")
        let presets = try JSONDecoder().decode([PackPreset].self, from: Data(contentsOf:root.appendingPathComponent("catalog.json")))
        let report = try JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("compatibility-report.json"))) as! [String:Any]
        precondition(presets.count == report["retained"] as! Int)
        let engine = try ProjectMEngine()
        var failures: [String] = [], clock: Double = 0
        let pcm = (0..<2048).map {Float(sin(Double($0 / 2) * 0.13) * 0.8)}
        let started = Date()
        for (index, preset) in presets.enumerated() {
            do {
                _ = try engine.frame(preset: root.appendingPathComponent("Presets/"+preset.path), texturePaths:[root.appendingPathComponent("Presets/"+preset.path).deletingLastPathComponent(),root.appendingPathComponent("Textures")],device:device,width:128,height:72,time:clock,sourceTime:clock,pcm:pcm,chaos:1)
            } catch {failures.append(preset.path+": "+error.localizedDescription)}
            clock += 1.0 / 60
            if index % 100 == 0 {print("Checked \(index+1)/\(presets.count), failures \(failures.count), elapsed \(Int(Date().timeIntervalSince(started)))s"); fflush(stdout)}
        }
        let receipt: [String:Any] = ["presets":presets.count,"loadedAndRendered":presets.count-failures.count,"failures":failures,"elapsedSeconds":Date().timeIntervalSince(started)]
        try JSONSerialization.data(withJSONObject:receipt,options:[.prettyPrinted,.sortedKeys]).write(to: URL(fileURLWithPath:".build/validation/projectm-pack-receipt.json"))
        print("Finished",presets.count,"effects; load failures",failures.count)
    }
}
