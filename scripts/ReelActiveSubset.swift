import Foundation
@preconcurrency import AVFoundation

/// Remove retired gallery sections without re-encoding their neighbors.
@main struct ReelActiveSubset {
    static func main() async throws {
        let input = URL(fileURLWithPath: CommandLine.arguments[1])
        let output = URL(fileURLWithPath: CommandLine.arguments[2])
        let retired = Set(CommandLine.arguments.dropFirst(3).compactMap(Int.init))
        var metadata = try JSONSerialization.jsonObject(with: Data(contentsOf: input.deletingPathExtension().appendingPathExtension("json"))) as! [String: Any]
        let segments = metadata["segments"] as! [[String: Any]]
        let asset = AVURLAsset(url: input)
        let composition = AVMutableComposition()
        var cursor = CMTime.zero
        var kept: [[String: Any]] = []
        var ordered = segments.filter { !retired.contains(($0["scene"] as! NSNumber).intValue) }
        if CommandLine.arguments.contains("--varied") {
            var remaining = ordered
            ordered.removeAll()
            while !remaining.isEmpty {
                let previous = ordered.last?["palette"] as? String
                let index = remaining.firstIndex { ($0["palette"] as? String) != previous } ?? 0
                ordered.append(remaining.remove(at: index))
            }
            precondition(zip(ordered, ordered.dropFirst()).allSatisfy { ($0.0["palette"] as? String) != ($0.1["palette"] as? String) })
        }
        for var segment in ordered {
            let start = (segment["start"] as! NSNumber).doubleValue
            let end = (segment["end"] as! NSNumber).doubleValue
            let duration = CMTime(seconds: end - start, preferredTimescale: 600)
            try await composition.insertTimeRange(CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 600), duration: duration), of: asset, at: cursor)
            segment["start"] = cursor.seconds
            cursor = cursor + duration; segment["end"] = cursor.seconds
            kept.append(segment)
        }
        guard kept.count == segments.count - retired.count else { fatalError("Unexpected retired section mapping") }
        try? FileManager.default.removeItem(at: output)
        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
        try await exporter.export(to: output, as: .mp4)
        metadata["segments"] = kept
        metadata["duration"] = cursor.seconds
        if metadata["effects"] != nil { metadata["effects"] = kept.count }
        try JSONSerialization.data(withJSONObject: metadata, options: [.prettyPrinted, .sortedKeys]).write(to: output.deletingPathExtension().appendingPathExtension("json"))
        print("PASS preserved video/audio tracks; retained \(kept.count) sections, \(cursor.seconds) seconds")
    }
}
