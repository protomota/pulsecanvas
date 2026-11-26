import Foundation
import Metal
import AVFoundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// One preset per process: crashes and timeouts cannot poison the next candidate.
@main struct ProjectMCandidateAudit {
    struct Candidate: Decodable { let id: String; let path: String; let title: String }
    static func main() throws {
        let args = CommandLine.arguments
        guard args.count == 9, let index = Int(args[3]), let width = Int(args[5]),
              let height = Int(args[6]), let frames = Int(args[7]), frames >= 90 else {
            fatalError("Usage: audit UPSTREAM CANDIDATES INDEX OUTPUT WIDTH HEIGHT FRAMES SOUNDTRACK")
        }
        let upstream = URL(fileURLWithPath: args[1]), output = URL(fileURLWithPath: args[4])
        let candidates = try JSONDecoder().decode([Candidate].self, from: Data(contentsOf: URL(fileURLWithPath: args[2])))
        let preset = candidates[index]
        let audio = try AVAudioFile(forReading: URL(fileURLWithPath: args[8]))
        let rate = audio.processingFormat.sampleRate
        audio.framePosition = min(AVAudioFramePosition(42 * rate), max(0, audio.length - AVAudioFramePosition(12 * rate)))
        let buffer = AVAudioPCMBuffer(pcmFormat: audio.processingFormat, frameCapacity: AVAudioFrameCount(12 * rate))!
        try audio.read(into: buffer)
        let channels = buffer.floatChannelData!, channelCount = Int(buffer.format.channelCount)
        let sampleCount = Int(buffer.frameLength)
        let device = MTLCreateSystemDefaultDevice()!, engine = try ProjectMEngine()
        let url = upstream.appendingPathComponent(preset.path)
        let textures = URL(fileURLWithPath: "Sources/PulseCanvas/Resources/ProjectM/Textures")
        var timing: [Double] = [], motion: [Double] = [], coverage: [Double] = [], whites: [Double] = []
        var previous: [UInt8]?, pixels = [UInt8](repeating: 0, count: width * height * 4)
        var error: String?
        do {
            for frame in 0..<frames {
                let end = Int(Double(frame + 1) * rate / 30) % max(1, sampleCount)
                let pcm: [Float] = (0..<1024).flatMap { offset in
                    let sample = (end - 1024 + offset + sampleCount) % sampleCount
                    return [channels[0][sample], channels[min(1, channelCount - 1)][sample]]
                }
                let began = Date()
                let texture = try engine.frame(preset: url, texturePaths: [url.deletingLastPathComponent(), textures],
                    device: device, width: width, height: height, time: Double(frame) / 30,
                    sourceTime: Double(frame) / 30, pcm: pcm, chaos: 1, fps: 30)
                if frame >= 10 { timing.append(Date().timeIntervalSince(began) * 1000) }
                // Do not spend minutes in a known high-instance family.
                if timing.count >= 8, timing.sorted()[timing.count / 2] > 33 { error = "Playback exceeds 33 ms/frame"; break }
                if frame >= 60 && frame % 15 == 0 {
                    texture.getBytes(&pixels, bytesPerRow: width * 4,
                        from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
                    var lit = 0, white = 0, difference = 0
                    for y in stride(from: 0, to: height, by: 4) {
                        for x in stride(from: 0, to: width, by: 4) {
                            let p = (y * width + x) * 4
                            if max(pixels[p], pixels[p + 1], pixels[p + 2]) > 24 { lit += 1 }
                            if min(pixels[p], pixels[p + 1], pixels[p + 2]) > 245 { white += 1 }
                            if let previous {
                                difference += (0..<3).reduce(0) { $0 + abs(Int(pixels[p + $1]) - Int(previous[p + $1])) }
                            }
                        }
                    }
                    let samples = Double(((width + 3) / 4) * ((height + 3) / 4))
                    coverage.append(Double(lit) / samples); whites.append(Double(white) / samples)
                    if previous != nil { motion.append(Double(difference) / (samples * 3 * 255)) }
                    previous = pixels
                    if frame == frames - 15 {
                        let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue).union(.byteOrder32Little),
                            provider: CGDataProvider(data: Data(pixels) as CFData)!, decode: nil,
                            shouldInterpolate: false, intent: .defaultIntent)!
                        let destination = CGImageDestinationCreateWithURL(output.deletingPathExtension().appendingPathExtension("png") as CFURL,
                            UTType.png.identifier as CFString, 1, nil)!
                        CGImageDestinationAddImage(destination, image, nil)
                        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
                    }
                }
            }
        } catch let failure { error = failure.localizedDescription }
        timing.sort()
        let median = timing.isEmpty ? 0 : timing[timing.count / 2]
        let p95 = timing.isEmpty ? 0 : timing[Int(Double(timing.count - 1) * 0.95)]
        let visible = coverage.max() ?? 0, movement = motion.max() ?? 0, white = whites.min() ?? 0
        let visibleFraction = Double(coverage.filter { $0 >= 0.01 }.count) / Double(max(1, coverage.count))
        let passed = error == nil && visibleFraction >= 0.8 && movement >= 0.00005 && white <= 0.98 && median <= 33 && p95 <= 40
        let result: [String: Any] = ["id": preset.id, "path": preset.path, "title": preset.title,
            "width": width, "height": height, "frames": frames, "medianMS": median, "p95MS": p95,
            "coverage": visible, "motion": movement, "whiteCoverage": white,
            "visibleSampleFraction": visibleFraction, "soundtrackPCM": true,
            "error": error as Any? ?? NSNull(), "passed": passed]
        try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]).write(to: output)
    }
}
