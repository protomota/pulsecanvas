import AppKit
@preconcurrency import AVFoundation
import Foundation
import CryptoKit

/// Exercise the actual exporter, then decode every frame rather than trusting metadata.
@main struct HighFrameRateSmoke {
    static func require(_ value: Bool, _ message: String) throws {
        if !value { throw ExportError(message) }
    }

    static func verify(_ url: URL, width: Int, height: Int, fps: Int, duration: Double, allowPresetStartup: Bool) async throws -> (frames: Int, startupDarkFrames: Int, laterDarkFrames: Int) {
        let asset = AVURLAsset(url: url)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let track = tracks.first else { throw ExportError("Video track missing") }
        let size = try await track.load(.naturalSize)
        let rate = try await track.load(.nominalFrameRate)
        let seconds = try await asset.load(.duration).seconds
        try require(size.width == Double(width) && size.height == Double(height), "Incorrect dimensions")
        try require(abs(rate - Float(fps)) < 0.01 && abs(seconds - duration) < 0.02, "Incorrect frame rate/duration")
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        try require(!audioTracks.isEmpty, "Soundtrack missing")
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        reader.add(output)
        try require(reader.startReading(), "Decoder did not start")
        var count = 0, startupDarkFrames = 0, laterDarkFrames = 0, hashes = Set<String>()
        while let sample = output.copyNextSampleBuffer() {
            let time = CMSampleBufferGetPresentationTimeStamp(sample).seconds
            try require(abs(time - Double(count) / Double(fps)) < 0.0001, "Frame timestamp gap at \(count)")
            guard let buffer = CMSampleBufferGetImageBuffer(sample) else { throw ExportError("Missing image") }
            CVPixelBufferLockBaseAddress(buffer, .readOnly)
            let data = CVPixelBufferGetBaseAddress(buffer)!.assumingMemoryBound(to: UInt8.self)
            let row = CVPixelBufferGetBytesPerRow(buffer)
            var pixels = Data(), sum = 0
            for y in stride(from: 0, to: height, by: 32) {
                for x in stride(from: 0, to: width, by: 32) {
                    for channel in 0..<3 {
                        let byte = data[y * row + x * 4 + channel]
                        pixels.append(byte); sum += Int(byte)
                    }
                }
            }
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
            if Double(sum) / Double(pixels.count) <= 1 {
                // Record brightness separately so timing/decoding evidence survives
                // a preset that becomes too dark at the experimental frame rate.
                if allowPresetStartup && time < 0.5 { startupDarkFrames += 1 }
                else { laterDarkFrames += 1 }
            }
            hashes.insert(SHA256.hash(data: pixels).description)
            count += 1
        }
        try require(reader.status == .completed && count == Int(duration * Double(fps)), "Missing decoded frames")
        try require(hashes.count > count / 2, "Animation is largely duplicated")
        // Decode audio too, to catch a broken mux rather than merely an empty track.
        let audioReader = try AVAssetReader(asset: asset)
        let audioOutput = AVAssetReaderTrackOutput(track: audioTracks[0], outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM])
        audioReader.add(audioOutput)
        try require(audioReader.startReading(), "Audio decoder did not start")
        var audioSamples = 0
        while let sample = audioOutput.copyNextSampleBuffer() { audioSamples += CMSampleBufferGetNumSamples(sample) }
        try require(audioReader.status == .completed && audioSamples > 0, "Audio decoding failed")
        return (count, startupDarkFrames, laterDarkFrames)
    }

    @MainActor static func main() async {
        NSApplication.shared.setActivationPolicy(.accessory)
        do { try await run() } catch { fputs("FAIL: \(error.localizedDescription)\n", stderr); exit(1) }
    }

    @MainActor static func run() async throws {
        let args = CommandLine.arguments
        guard args.count == 2 else { throw ExportError("Usage: HighFrameRateSmoke OUTPUT_DIRECTORY_ON_MUSIC") }
        let root = URL(fileURLWithPath: args[1], isDirectory: true).standardizedFileURL
        try require(root.path.hasPrefix("/Volumes/Music/"), "Benchmarks must use the Music drive")
        let volume = try URL(fileURLWithPath: "/Volumes/Music").resourceValues(forKeys: [.isVolumeKey])
        try require(volume.isVolume == true, "Music drive is not mounted")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let key = "PulseCanvas.videoFormat.v1", saved = UserDefaults.standard.data(forKey: "PulseCanvas.videoFormat.v1")
        defer {
            if let saved { UserDefaults.standard.set(saved, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        let duration = 3.0
        let audio = root.appendingPathComponent("soundtrack-excerpt.wav")
        let source = try AVAudioFile(forReading: URL(fileURLWithPath: "Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3"))
        source.framePosition = AVAudioFramePosition(42 * source.processingFormat.sampleRate)
        let count = AVAudioFrameCount(duration * source.processingFormat.sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: source.processingFormat, frameCapacity: count)!
        try source.read(into: buffer, frameCount: count)
        var settings = source.processingFormat.settings
        settings[AVLinearPCMIsNonInterleaved] = false
        try AVAudioFile(forWriting: audio, settings: settings).write(from: buffer)
        guard let scene = RenderState.nativeSceneNames.firstIndex(of: "Octagon Vault") else { throw ExportError("Benchmark scene missing") }
        let exporter = SocialExportController(scratchDirectory: root)
        exporter.aspect = .wide; exporter.resolution = 1080; exporter.fps = 120
        try require(SocialExportController().fps == 120, "120 fps preference does not restore")
        let appearance = VisualPreset.defaults(for: scene)
        let project = CreatorProject(scene: scene, appearance: appearance, aspect: SocialAspect.wide.rawValue, resolution: 1080, fps: 120)
        let decoded = try JSONDecoder().decode(CreatorProject.self, from: JSONEncoder().encode(project))
        try require(decoded.fps == 120 && SocialExportController.supportedFrameRates.contains(decoded.fps), "120 fps project round trip failed")
        var cases: [(String, SocialAspect, Int, Int, Int, Bool)] = [
            ("native-1080p-60", .wide, 1080, 60, scene, false),
            ("native-1080p-120", .wide, 1080, 120, scene, false),
            ("native-4K-60", .wide, 2160, 60, scene, false),
            ("native-4K-120", .wide, 2160, 120, scene, false),
            ("phone-120", .phone, 720, 120, scene, false),
            ("studio-120", .square, 720, 120, scene, true)
        ]
        #if !STORE_BUILD
        let presets = try JSONDecoder().decode([ProjectMPreset].self, from: Data(contentsOf: URL(fileURLWithPath: "Sources/PulseCanvas/Resources/ProjectM/catalog.json")))
        guard let external = presets.first, let externalScene = ProjectMPresets.shared.scene(for: external.id) else { throw ExportError("OpenGL benchmark preset missing") }
        cases.append(("opengl-60", .wide, 720, 60, externalScene, false))
        cases.append(("opengl-120", .wide, 720, 120, externalScene, false))
        if let glass = presets.first(where: { $0.title == "Glass Chamber" }), let glassScene = ProjectMPresets.shared.scene(for: glass.id) {
            cases.append(("opengl-glass-chamber-120", .wide, 720, 120, glassScene, false))
        }
        #endif
        var results: [[String: Any]] = []
        var brightnessFailures = 0
        for (name, aspect, resolution, fps, selectedScene, studio) in cases {
            let state = RenderState()
            state.scene = selectedScene
            VisualPreset.defaults(for: selectedScene).apply(to: state)
            state.chaos = 1
            exporter.aspect = aspect; exporter.resolution = resolution; exporter.fps = fps
            let secondScene = RenderState.nativeSceneNames.firstIndex(of: "Double Twist")!
            let segments = studio ? [StudioSegment(start: 0, end: 1.5, scene: selectedScene), StudioSegment(start: 1.5, end: duration, scene: secondScene)] : []
            let destination = root.appendingPathComponent(name + ".mp4")
            let start = ProcessInfo.processInfo.systemUptime
            await exporter.export(audioURL: audio, render: state, to: destination, segments: segments)
            let elapsed = ProcessInfo.processInfo.systemUptime - start
            try require(exporter.exportedURL == destination, exporter.status)
            try require(exporter.totalFrames == Int(duration * Double(fps)) && exporter.renderedFrames == exporter.totalFrames, "Incorrect rendered frame count")
            let size = aspect.dimensions(resolution: resolution)
            let decoded = try await verify(destination, width: size.width, height: size.height, fps: fps, duration: duration, allowPresetStartup: selectedScene >= RenderState.nativeSceneNames.count)
            let frames = decoded.frames
            let visible = decoded.laterDarkFrames == 0
            if !visible { brightnessFailures += 1 }
            let result: [String: Any] = ["case": name, "visualizer": RenderState.sceneNames[selectedScene], "width": size.width, "height": size.height, "fps": fps, "duration": duration, "decodedFrames": frames, "startupDarkFrames": decoded.startupDarkFrames, "laterDarkFrames": decoded.laterDarkFrames, "timingAudioMotion": "passed", "brightnessCheck": visible ? "passed" : "failed", "exportSeconds": elapsed, "endToEndFramesPerSecond": Double(frames) / elapsed, "lastProgressFramesPerSecond": exporter.framesPerSecond, "path": destination.path]
            results.append(result)
            print("PASS \(name): \(frames) decoded frames, exact cadence, audio and motion; \(decoded.startupDarkFrames) startup dark frames; export \(String(format: "%.2f", elapsed)) s (\(String(format: "%.1f", Double(frames) / elapsed)) frames/s)")
            if !visible { print("FAIL \(name) brightness check: \(decoded.laterDarkFrames) frames have sampled mean RGB <= 1 after startup") }
        }
        let receipt: [String: Any] = ["date": ISO8601DateFormatter().string(from: Date()), "results": results, "preferencesAndProjectRoundTrip": "passed", "decoder": "AVAssetReader, every video frame and all audio samples", "encoder": "H.264, hardware acceleration requested; backend use not instrumented"]
        try JSONSerialization.data(withJSONObject: receipt, options: [.prettyPrinted, .sortedKeys]).write(to: root.appendingPathComponent("receipt.json"))
        try require(brightnessFailures == 0, "\(brightnessFailures) visual brightness checks failed; complete timing and benchmark results are in receipt.json")
    }
}
