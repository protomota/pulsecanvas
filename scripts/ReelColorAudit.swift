import AppKit
@preconcurrency import AVFoundation
import Foundation

/// Inspect a decoded midpoint from every section of the actual exported movie.
@main struct ReelColorAudit {
    static func main() async throws {
        _ = NSApplication.shared
        let video = URL(fileURLWithPath: CommandLine.arguments[1])
        let folder = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let metadata = try JSONSerialization.jsonObject(with: Data(contentsOf: video.deletingPathExtension().appendingPathExtension("json"))) as! [String: Any]
        let segments = metadata["segments"] as! [[String: Any]]
        let names = metadata["names"] as! [String]
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: video))
        generator.maximumSize = CGSize(width: 320, height: 180)
        generator.requestedTimeToleranceBefore = .zero; generator.requestedTimeToleranceAfter = .zero
        var receipt: [[String: Any]] = []
        for (index, segment) in segments.enumerated() {
            let scene = (segment["scene"] as! NSNumber).intValue
            let start = (segment["start"] as! NSNumber).doubleValue, end = (segment["end"] as! NSNumber).doubleValue
            let time = (start + end) / 2
            let result = try await generator.image(at: CMTime(seconds: time, preferredTimescale: 600))
            let bitmap = NSBitmapImageRep(cgImage: result.image)
            try bitmap.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent(String(format: "%03d.png", index)))
            receipt.append(["index": index, "scene": scene, "name": names[scene], "palette": segment["palette"]!, "time": time, "actualTime": result.actualTime.seconds])
            if index % 40 == 0 { print("Decoded color sample \(index + 1)/\(segments.count)"); fflush(stdout) }
        }
        try JSONSerialization.data(withJSONObject: receipt, options: [.prettyPrinted, .sortedKeys]).write(to: folder.appendingPathComponent("samples.json"))
        print("PASS decoded actual video samples: \(receipt.count) sections")
    }
}
