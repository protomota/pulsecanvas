import AppKit
@preconcurrency import AVFoundation
import Foundation
@preconcurrency import Metal

/// Native catalog: coverage in every canvas shape, distinct designs, Chaos-isolated music
/// response, timing, Studio switching and decoded exports with the real soundtrack.
@main struct NativeExpansionSmoke {
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
    static func excerpt(_ source: URL, start: Double, duration: Double, to target: URL) throws {
        let input = try AVAudioFile(forReading: source)
        let rate = input.processingFormat.sampleRate
        var settings = input.processingFormat.settings
        settings[AVLinearPCMIsNonInterleaved] = false
        let writer = try AVAudioFile(forWriting: target, settings: settings)
        var remaining = AVAudioFramePosition((duration * rate).rounded())
        var position = AVAudioFramePosition((start * rate).rounded()) % input.length
        while remaining > 0 {
            input.framePosition = position
            let count = AVAudioFrameCount(min(remaining, input.length - position))
            let buffer = AVAudioPCMBuffer(pcmFormat: input.processingFormat, frameCapacity: count)!
            try input.read(into: buffer, frameCount: count)
            try writer.write(from: buffer)
            remaining -= AVAudioFramePosition(buffer.frameLength); position = 0
        }
    }
    static func verifyVideo(_ url: URL, width: Int, height: Int, fps: Int, duration: Double) async throws {
        let asset = AVURLAsset(url: url)
        let track = try await asset.loadTracks(withMediaType: .video).first!
        let size = try await track.load(.naturalSize)
        let rate = try await track.load(.nominalFrameRate)
        let seconds = try await asset.load(.duration).seconds
        try require(size.width == Double(width) && size.height == Double(height), "Wrong video dimensions \(size)")
        try require(abs(rate-Float(fps)) < 0.01 && abs(seconds-duration) < 0.04, "Wrong video timing \(rate) fps \(seconds) s")
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        try require(!audioTracks.isEmpty, "Real soundtrack must be included")
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        reader.add(output); try require(reader.startReading(), "Decoder did not start")
        var count = 0, minimumMean = 255.0
        while let sample = output.copyNextSampleBuffer() {
            guard let buffer = CMSampleBufferGetImageBuffer(sample) else { throw ExportError("Decoded frame missing") }
            CVPixelBufferLockBaseAddress(buffer, .readOnly)
            let data = CVPixelBufferGetBaseAddress(buffer)!.assumingMemoryBound(to: UInt8.self)
            let stride = CVPixelBufferGetBytesPerRow(buffer)
            var sum = 0.0, samples = 0
            for y in Swift.stride(from: 0, to: height, by: 16) {
                for x in Swift.stride(from: 0, to: width, by: 16) {
                    let index = y * stride + x * 4
                    sum += Double(data[index]) + Double(data[index+1]) + Double(data[index+2]); samples += 3
                }
            }
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
            minimumMean = min(minimumMean, sum / Double(samples)); count += 1
        }
        try require(reader.status == .completed && count == Int((duration * Double(fps)).rounded()), "Missing decoded video frames: \(count)")
        try require(minimumMean > 1, "Black frame in exported video, minimum RGB \(minimumMean)")
        print("PASS decoded \(url.lastPathComponent): \(count) frames, \(width)x\(height), \(fps) fps, soundtrack present, minimum RGB \(String(format: "%.1f", minimumMean))")
    }
    @MainActor static func main() async {
        NSApplication.shared.setActivationPolicy(.accessory)
        do { try await run() } catch { print("FAIL: \(error.localizedDescription)"); exit(1) }
    }
    @MainActor static func render(_ renderer: VisualizerRenderer, _ analyzer: SoundtrackAnalyzer, at time: Double) throws -> [UInt8] {
        let features = try analyzer.frame(at: time, clipStart: 0, clipEnd: 10_000)
        return pixels(try renderer.renderOffscreen(time: time, audioBands: features.bands, audioPulse: features.pulse,
            audioMomentum: features.momentum, audioBeatMotionTime: features.beatMotionTime,
            audioEnvelopes: features.envelopes, audioSwell: features.swell))
    }
    @MainActor static func run() async throws {
        let root = URL(fileURLWithPath: ".build/native-expansion", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = URL(fileURLWithPath: "Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3")
        let analyzer = try SoundtrackAnalyzer(url: source)
        let state = RenderState(), renderer = VisualizerRenderer(state: state)
        let names = RenderState.nativeSceneNames
        let active = NativeEffects.activeIDs
        try require(Set(active.map { names[$0] }).count == active.count, "Expected uniquely named native designs")
        try require(active.allSatisfy { NativeEffects.effect(NativeEffects.resolved($0)) != nil } && NativeEffects.all.indices.allSatisfy { !NativeEffects.isRetired(NativeEffects.resolved($0)) },
                    "Every retired design must resolve to an active design")
        let scenes = active.filter { $0 >= NativeEffects.legacyCount }
        try require(scenes.allSatisfy { NativeEffects.all[$0].shader != nil && NativeEffects.shaderFiles.contains(NativeEffects.all[$0].file ?? "") }, "Every new design must use a registered native Metal pass")
        try require(Set(scenes.compactMap { NativeEffects.all[$0].shader }).count == scenes.count, "Every new design needs its own shader")
        try require(NativeEffects.timelineOrder.count == active.count && Set(NativeEffects.timelineOrder) == Set(active), "Studio's automatic order must use every active design once")
        print("PASS catalog: \(active.count) active designs, \(names.count - active.count) retired IDs reserved for migration")

        let paletteCounts = Dictionary(grouping: active, by: { VisualPreset.defaults(for: $0).palette }).mapValues(\.count)
        try require(paletteCounts.count == VisualPalette.allCases.count && (paletteCounts[0] ?? 0) < active.count / 3,
                    "Default looks must cover every palette without a violet majority")
        try require(active.allSatisfy { VisualPreset.defaults(for: $0).palette == NativeEffects.all[$0].look.palette },
                    "Editor, reset and Studio must use the registered palette defaults")
        print("PASS default palettes: \(paletteCounts.sorted { $0.key < $1.key })")

        // Coverage in every canvas shape with the real soundtrack, at each design's defaults.
        let shapes: [(Int, Int, String)] = [(640,360,"wide"),(480,360,"landscape"),(360,480,"portrait"),(360,640,"phone"),(480,480,"square")]
        for (width, height, tag) in shapes {
            try renderer.prepareOffscreen(width: width, height: height)
            var weakest = (scene: 0, lit: 1.0)
            for scene in active {
                state.scene = scene
                VisualPreset.defaults(for: scene).apply(to: state)
                state.motionBlur = 0; state.strobeEnabled = false
                for time in [12.3, 47.1, 96.4] {
                    let bytes = try render(renderer, analyzer, at: time)
                    var cells = Set<Int>(), lit = 0
                    for i in Swift.stride(from: 0, to: bytes.count, by: 4) where max(bytes[i], max(bytes[i+1], bytes[i+2])) > 20 {
                        lit += 1
                        cells.insert(((i/4) / width * 4 / height) * 4 + (i/4) % width * 4 / width)
                    }
                    let fraction = Double(lit) / Double(width * height)
                    try require(cells.count >= 14 && fraction > 0.05, "Sparse canvas: \(names[scene]) \(tag) at \(time)s, \(cells.count) cells, \(Int(fraction * 100))% lit")
                    if fraction < weakest.lit { weakest = (scene, fraction) }
                    if time == 12.3 && scene >= NativeEffects.legacyCount { try png(bytes, width: width, height: height, to: root.appendingPathComponent(String(format: "%03d-%@.png", scene, tag))) }
                }
            }
            print("PASS \(tag) \(width)x\(height): all \(active.count) designs fill ≥14/16 canvas cells at three song positions; least lit \(names[weakest.scene]) \(Int(weakest.lit * 100))%")
        }

        // Distinct designs: same palette and controls, compared at low resolution.
        try renderer.prepareOffscreen(width: 160, height: 90)
        var frames: [[UInt8]] = []
        for scene in active {
            state.scene = scene
            VisualPreset().apply(to: state)
            state.zoomSpeed = 1; state.chaos = 0.6
            frames.append(try render(renderer, analyzer, at: 40))
        }
        var closest = (a: 0, b: 0, difference: 255.0)
        for a in frames.indices {
            for b in frames.indices where b > a {
                var total = 0
                for i in Swift.stride(from: 0, to: frames[a].count, by: 4) {
                    total += abs(Int(frames[a][i]) - Int(frames[b][i])) + abs(Int(frames[a][i+1]) - Int(frames[b][i+1])) + abs(Int(frames[a][i+2]) - Int(frames[b][i+2]))
                }
                let difference = Double(total) / Double(frames[a].count / 4 * 3)
                if difference < closest.difference { closest = (active[a], active[b], difference) }
            }
        }
        try require(closest.difference > 4, "Indistinguishable designs: \(names[closest.a]) and \(names[closest.b]) (\(closest.difference))")
        print(String(format: "PASS distinct outputs for all %d pairs with one palette; closest pair %@ / %@ differs by %.1f/255", active.count * (active.count - 1) / 2, names[closest.a], names[closest.b], closest.difference))

        // Timing: sequential completed GPU frames.
        for (width, height) in [(1920,1080),(3840,2160)] {
            try renderer.prepareOffscreen(width: width, height: height)
            var slowest = (scene: 0, ms: 0.0), total = 0.0
            for scene in active {
                state.scene = scene
                VisualPreset.defaults(for: scene).apply(to: state)
                _ = try render(renderer, analyzer, at: 12)
                let start = ProcessInfo.processInfo.systemUptime
                for frame in 0..<6 { _ = try render(renderer, analyzer, at: 12 + Double(frame) / 60) }
                let ms = (ProcessInfo.processInfo.systemUptime - start) * 1000 / 6
                total += ms
                if ms > slowest.ms { slowest = (scene, ms) }
                print(String(format: "TIMING %3d %-22@ %dx%d %7.2f ms", scene, names[scene] as NSString, width, height, ms))
            }
            print(String(format: "SUMMARY %dx%d: mean %.2f ms, slowest %@ %.2f ms", width, height, total / Double(active.count), names[slowest.scene], slowest.ms))
        }

        // Studio switching through every new design, exported and decoded in two shapes.
        let duration = Double(scenes.count)
        let excerptURL = root.appendingPathComponent("soundtrack-excerpt.wav")
        try excerpt(source, start: 0, duration: duration, to: excerptURL)
        let segments = scenes.enumerated().map { StudioSegment(start: Double($0.offset), end: Double($0.offset + 1), scene: $0.element) }
        let preferencesKey = "PulseCanvas.videoFormat.v1"
        let savedFormat = UserDefaults.standard.data(forKey: preferencesKey)
        defer {
            if let savedFormat { UserDefaults.standard.set(savedFormat, forKey: preferencesKey) }
            else { UserDefaults.standard.removeObject(forKey: preferencesKey) }
        }
        let exporter = SocialExportController()
        exporter.fps = 30; exporter.resolution = 720
        for aspect in [SocialAspect.wide, .phone, .square] {
            exporter.aspect = aspect
            let video = root.appendingPathComponent("native-expansion-\(aspect == .wide ? "wide" : aspect == .phone ? "phone" : "square").mp4")
            await exporter.export(audioURL: excerptURL, render: state, to: video, segments: segments)
            try require(exporter.exportedURL == video, exporter.status)
            let size = aspect.dimensions(resolution: 720)
            try await verifyVideo(video, width: size.width, height: size.height, fps: 30, duration: duration)
        }
        let shortURL = root.appendingPathComponent("soundtrack-2s.wav")
        try excerpt(source, start: 40, duration: 2, to: shortURL)
        exporter.aspect = .wide; exporter.resolution = 2160; exporter.fps = 60
        let fourK = root.appendingPathComponent("native-expansion-4k60.mp4")
        await exporter.export(audioURL: shortURL, render: state, to: fourK,
            segments: [StudioSegment(start: 0, end: 0.7, scene: 91), StudioSegment(start: 0.7, end: 1.4, scene: 33), StudioSegment(start: 1.4, end: 2, scene: 84)])
        try require(exporter.exportedURL == fourK, exporter.status)
        try await verifyVideo(fourK, width: 3840, height: 2160, fps: 60, duration: 2)
        print("PASS \(scenes.count) new designs (\(active.count) active) through real soundtrack analysis, every canvas shape, Studio switching, GPU timing and decoded exports.")
    }
}
