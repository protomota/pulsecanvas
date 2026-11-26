import Foundation
@preconcurrency import AVFoundation
import CoreVideo

/// Read every encoded video frame and verify dimensions, cadence, coverage and soundtrack.
@main struct ReelDecodeSmoke {
    static func main() async throws {
        for path in CommandLine.arguments.dropFirst() {
            let url = URL(fileURLWithPath: path), asset = AVURLAsset(url: URL(fileURLWithPath: path))
            let metadata = try JSONSerialization.jsonObject(with: Data(contentsOf: url.deletingPathExtension().appendingPathExtension("json"))) as! [String: Any]
            let sections = metadata["segments"] as! [[String: Any]]
            let expectedSeconds = sections.last!["end"] as! Double
            let video = try await asset.loadTracks(withMediaType: .video).first!
            let audio = try await asset.loadTracks(withMediaType: .audio)
            precondition(!audio.isEmpty, "Missing soundtrack")
            let size = try await video.load(.naturalSize), rate = try await video.load(.nominalFrameRate)
            let duration = try await asset.load(.duration).seconds
            precondition(abs(duration - expectedSeconds) < 0.06, "Incorrect duration")
            let reader = try AVAssetReader(asset: asset)
            let output = AVAssetReaderTrackOutput(track: video, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
            output.alwaysCopiesSampleData = false; reader.add(output)
            precondition(reader.startReading())
            var count = 0, minimumMean = 255.0, maximumCadenceError = 0.0
            while let sample = output.copyNextSampleBuffer() {
                let time = CMSampleBufferGetPresentationTimeStamp(sample).seconds
                maximumCadenceError = max(maximumCadenceError, abs(time - Double(count) / Double(rate)))
                let buffer = CMSampleBufferGetImageBuffer(sample)!
                let w = CVPixelBufferGetWidth(buffer), h = CVPixelBufferGetHeight(buffer)
                precondition(w == Int(size.width) && h == Int(size.height))
                CVPixelBufferLockBaseAddress(buffer, .readOnly)
                let data = CVPixelBufferGetBaseAddress(buffer)!.assumingMemoryBound(to: UInt8.self)
                let row = CVPixelBufferGetBytesPerRow(buffer)
                var sum = 0, n = 0
                // Sample the scene interior; labels at the bottom cannot mask a black image.
                for y in stride(from: h / 20, to: h * 4 / 5, by: max(1, h / 18)) {
                    for x in stride(from: w / 30, to: w * 29 / 30, by: max(1, w / 24)) {
                        let i = y * row + x * 4
                        sum += Int(data[i]) + Int(data[i+1]) + Int(data[i+2]); n += 3
                    }
                }
                CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
                minimumMean = min(minimumMean, Double(sum) / Double(n)); count += 1
            }
            precondition(reader.status == .completed && count == Int((expectedSeconds * Double(rate)).rounded()), "Missing or undecodable frames")
            precondition(minimumMean > 1 && maximumCadenceError < 0.0001, "Black interior or incorrect cadence")
            let receipt: [String: Any] = ["file": url.path, "width": size.width, "height": size.height,
                "fps": rate, "duration": duration, "decodedFrames": count, "soundtrackPresent": true,
                "minimumInteriorRGB": minimumMean, "maximumCadenceErrorSeconds": maximumCadenceError]
            try JSONSerialization.data(withJSONObject: receipt, options: [.prettyPrinted, .sortedKeys]).write(to: url.deletingPathExtension().appendingPathExtension("decoded.json"))
            print("PASS every decoded frame: \(url.lastPathComponent), \(count) frames, \(Int(size.width))×\(Int(size.height)), \(rate) fps, soundtrack present, minimum interior RGB \(minimumMean)")
        }
    }
}
