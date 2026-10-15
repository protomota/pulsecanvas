import AppKit
@preconcurrency import AVFoundation
import Foundation
@preconcurrency import Metal

@main struct NativeExportAgreementSmoke {
    static func require(_ condition: Bool, _ message: String) throws {
        if !condition { throw ExportError(message) }
    }
    static func pixels(_ texture: MTLTexture) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: texture.width * texture.height * 4)
        bytes.withUnsafeMutableBytes {
            texture.getBytes($0.baseAddress!, bytesPerRow: texture.width * 4,
                             from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0)
        }
        return bytes
    }
    static func png(_ bytes: [UInt8], width: Int, height: Int, to url: URL) throws {
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: width * 4, bitsPerPixel: 32)!
        for pixel in stride(from: 0, to: bytes.count, by: 4) {
            bitmap.bitmapData![pixel] = bytes[pixel + 2]
            bitmap.bitmapData![pixel + 1] = bytes[pixel + 1]
            bitmap.bitmapData![pixel + 2] = bytes[pixel]
            bitmap.bitmapData![pixel + 3] = 255
        }
        try bitmap.representation(using: .png, properties: [:])!.write(to: url)
    }
    static func excerpt(_ source: URL, duration: Double, to target: URL) throws {
        let input = try AVAudioFile(forReading: source)
        let count = AVAudioFrameCount(duration * input.processingFormat.sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: input.processingFormat, frameCapacity: count)!
        try input.read(into: buffer, frameCount: count)
        var settings = input.processingFormat.settings
        settings[AVLinearPCMIsNonInterleaved] = false
        try AVAudioFile(forWriting: target, settings: settings).write(from: buffer)
    }
    static func verifyVideo(_ url: URL, width: Int, height: Int, fps: Int, duration: Double,
                            expectedFrames: [Int: [UInt8]] = [:]) async throws {
        let asset = AVURLAsset(url: url)
        let track = try await asset.loadTracks(withMediaType: .video).first!
        let size = try await track.load(.naturalSize)
        let rate = try await track.load(.nominalFrameRate)
        let seconds = try await asset.load(.duration).seconds
        try require(size.width == Double(width) && size.height == Double(height), "Wrong video dimensions")
        try require(abs(rate-Float(fps)) < 0.01 && abs(seconds-duration) < 0.04, "Wrong video timing")
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        try require(!audioTracks.isEmpty, "Real soundtrack must be included in the preview")
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        reader.add(output); try require(reader.startReading(), "Decoder did not start")
        var count = 0, minimumMean = 255.0, compared = 0, largestError = 0.0
        while let sample = output.copyNextSampleBuffer() {
            guard let buffer = CMSampleBufferGetImageBuffer(sample) else { throw ExportError("Decoded frame missing") }
            CVPixelBufferLockBaseAddress(buffer, .readOnly)
            let data = CVPixelBufferGetBaseAddress(buffer)!.assumingMemoryBound(to: UInt8.self)
            let stride = CVPixelBufferGetBytesPerRow(buffer)
            var sum = 0.0, samples = 0, sampled: [UInt8] = []
            for y in Swift.stride(from: 0, to: height, by: 16) {
                for x in Swift.stride(from: 0, to: width, by: 16) {
                    let index = y * stride + x * 4
                    sum += Double(data[index]) + Double(data[index+1]) + Double(data[index+2]); samples += 3
                    if expectedFrames[count] != nil { sampled += [data[index], data[index+1], data[index+2]] }
                }
            }
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
            if let expected = expectedFrames[count] {
                try require(sampled.count == expected.count, "Decoded/reference sample sizes differ")
                let error = zip(sampled,expected).reduce(0.0) { $0 + Double(abs(Int($1.0)-Int($1.1))) } / Double(expected.count)
                try require(error < 12, "Decoded/reference RGB error at frame \(count), \(width)x\(height): \(error)")
                compared += 1; largestError = max(largestError,error)
            }
            minimumMean = min(minimumMean, sum / Double(samples)); count += 1
        }
        try require(reader.status == .completed && count == Int((duration * Double(fps)).rounded()), "Missing decoded video frames")
        try require(minimumMean > 1, "Black frame in exported video, minimum RGB \(minimumMean)")
        try require(compared == expectedFrames.count, "Missing per-section reference comparisons")
        print("PASS decoded \(url.lastPathComponent): \(count) frames, \(width)x\(height), \(fps) fps, soundtrack present, minimum RGB \(minimumMean)")
        if compared > 0 { print("PASS \(compared) Studio sections match default-profile native preview samples after compression; largest mean RGB error \(largestError)") }
    }
    @MainActor static func referenceFrames(scenes: [Int], width: Int, height: Int, fps: Int,
                                           analyzer: SoundtrackAnalyzer, duration: Double) throws -> [Int: [UInt8]] {
        let state = RenderState(), renderer = VisualizerRenderer(state: state)
        try renderer.prepareOffscreen(width: width, height: height)
        var result: [Int: [UInt8]] = [:]
        for (index,scene) in scenes.enumerated() {
            state.scene = scene; VisualPreset.defaults(for: scene).apply(to: state)
            let time = Double(index) + 0.5
            let features = try analyzer.frame(at: time, clipStart: 0, clipEnd: duration)
            let frame = pixels(try renderer.renderOffscreen(time: time, audioBands: features.bands,
                audioPulse: features.pulse, audioMomentum: features.momentum, audioBeatMotionTime: features.beatMotionTime,
                audioTreblePulse: features.treblePulse, audioTrebleAttackTime: features.trebleAttackTime, audioEnvelopes: features.envelopes, audioSwell: features.swell))
            var samples: [UInt8] = []
            for y in Swift.stride(from: 0, to: height, by: 16) {
                for x in Swift.stride(from: 0, to: width, by: 16) {
                    let offset = (y*width+x)*4
                    samples += [frame[offset],frame[offset+1],frame[offset+2]]
                }
            }
            result[Int((Double(index) + 0.5)*Double(fps))] = samples
        }
        return result
    }
    @MainActor static func main() async {
        NSApplication.shared.setActivationPolicy(.accessory)
        do { try await run() } catch { print("FAIL: \(error.localizedDescription)"); exit(1) }
    }
    @MainActor static func run() async throws {
        let root = URL(fileURLWithPath: ".build/native-expansion")
        let analyzer = try SoundtrackAnalyzer(url: root.appendingPathComponent("soundtrack-excerpt.wav"))
        let scenes = NativeEffects.activeIDs.filter { $0 >= 31 }
        let duration = Double(scenes.count)
        for aspect in [SocialAspect.wide, .phone, .square] {
            let size = aspect.dimensions(resolution:720)
            let tag = aspect == .wide ? "wide" : (aspect == .phone ? "phone" : "square")
            let expected = try referenceFrames(scenes:scenes,width:size.width,height:size.height,fps:30,analyzer:analyzer,duration:duration)
            try await verifyVideo(root.appendingPathComponent("native-expansion-\(tag).mp4"),width:size.width,height:size.height,fps:30,duration:duration,expectedFrames:expected)
        }
    }
}
