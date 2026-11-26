@preconcurrency import AVFoundation
import Combine
import CoreVideo
import Foundation
import CoreGraphics
@preconcurrency import Metal
import VideoToolbox

enum SocialAspect: String, CaseIterable, Identifiable {
    case wide = "16:9 · Wide"
    case landscape = "4:3 · Landscape"
    case portrait = "3:4 · Portrait"
    case phone = "9:16 · Phone"
    case square = "1:1 · Square"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .wide: String(localized: "16:9 · Wide")
        case .landscape: String(localized: "4:3 · Landscape")
        case .portrait: String(localized: "3:4 · Portrait")
        case .phone: String(localized: "9:16 · Phone")
        case .square: String(localized: "1:1 · Square")
        }
    }
    var aspectRatio: Double {
        switch self {
        case .wide: return 16.0 / 9
        case .landscape: return 4.0 / 3
        case .portrait: return 3.0 / 4
        case .phone: return 9.0 / 16
        case .square: return 1
        }
    }
    /// Resolution is the shorter edge; every H.264 dimension is even.
    func dimensions(resolution: Int) -> (width: Int, height: Int) {
        let edge = [720, 1080, 2160].contains(resolution) ? resolution : 1080
        if aspectRatio >= 1 { return (Int((Double(edge) * aspectRatio / 2).rounded()) * 2, edge) }
        return (edge, Int((Double(edge) / aspectRatio / 2).rounded()) * 2)
    }
}

@MainActor
final class SocialExportController: ObservableObject {
    #if os(visionOS) || os(iOS)
    static let supportedFrameRates = [24, 30, 60]
    static let supportedResolutions = [720, 1080, 2160]
    #else
    static let supportedFrameRates = [24, 30, 60, 120]
    static let supportedResolutions = [720, 1080, 2160]
    #endif
    @Published var aspect: SocialAspect = .wide { didSet { persistSettings() } }
    @Published var resolution = 1080 { didSet { persistSettings() } }
    @Published var fps = 30 { didSet { persistSettings() } }
    @Published private(set) var isExporting = false
    @Published private(set) var progress = 0.0
    enum Phase: String { case preparing, rendering, muxing, validating }
    private(set) var phase = Phase.preparing
    private(set) var error: Error?
    private(set) var didFail = false
    // Constructed on a worker and transferred once to the export actor.
    private struct PreparedSpectrum: @unchecked Sendable {
        let analyzer: SoundtrackAnalyzer
    }

    struct OfflineOptions {
        let aspect: SocialAspect
        let resolution: Int
        let fps: Int
        let scratchDirectory: URL
        let previewSeconds: Double?
    }
    @Published private(set) var status = String(localized: "Ready to export")
    @Published private(set) var exportedURL: URL?
    @Published private(set) var successfulSaveID: UUID?
    @Published private(set) var renderedFrames = 0
    @Published private(set) var totalFrames = 0
    @Published private(set) var framePreview: CGImage?
    @Published private(set) var framesPerSecond = 0.0
    @Published private(set) var estimatedSecondsRemaining: Double?
    private(set) var cancellationRequested = false

    private struct FormatSettings: Codable { var aspect: String; var resolution: Int; var fps: Int }
    private let preferencesKey = "PulseCanvas.videoFormat.v1"
    private let scratchDirectory: URL
    /// Offline test tools can keep intermediate video files on their render drive.
    /// The app defaults to its sandbox temporary area, as required by NSSavePanel access.
    init(scratchDirectory: URL = FileManager.default.temporaryDirectory) {
        self.scratchDirectory = scratchDirectory
        if let data = UserDefaults.standard.data(forKey: preferencesKey), let saved = try? JSONDecoder().decode(FormatSettings.self, from: data), let aspect = SocialAspect(rawValue: saved.aspect), Self.supportedResolutions.contains(saved.resolution), Self.supportedFrameRates.contains(saved.fps) {
            self.aspect = aspect; self.resolution = saved.resolution; self.fps = saved.fps
        }
    }
    private func persistSettings() {
        if let data = try? JSONEncoder().encode(FormatSettings(aspect: aspect.rawValue, resolution: resolution, fps: fps)) { UserDefaults.standard.set(data, forKey: preferencesKey) }
    }

    func cancel() { if isExporting { cancellationRequested = true; status = String(localized: "Cancelling…") } }

    /// Offline export has its own scene snapshot, sample clock, and GPU renderer.
    /// Preview playback and machine speed cannot skip or change output frames.
    func export(audioURL: URL?, render: RenderState, to destination: URL, segments: [StudioSegment] = [], appearances: [Int: VisualPreset] = [:],
                offline: OfflineOptions? = nil) async {
        guard !isExporting else { return }
        isExporting = true
        didFail = false
        error = nil
        phase = .preparing
        cancellationRequested = false
        progress = 0
        exportedURL = nil
        renderedFrames = 0
        totalFrames = 0
        framePreview = nil
        framesPerSecond = 0
        estimatedSecondsRemaining = nil
        status = String(localized: "Preparing export…")
        defer { isExporting = false; estimatedSecondsRemaining = nil }
        let outputResolution = offline?.resolution ?? resolution
        let dimensions = (offline?.aspect ?? aspect).dimensions(resolution: outputResolution)
        let frameRate = offline?.fps ?? fps
        let scene = snapshot(render)
        scene.projectMFramesPerSecond = frameRate
        var scratch: URL?
        let destinationAccess = SecurityScopedAccess(url: destination)
        let audioAccess = audioURL.map { SecurityScopedAccess(url: $0) }
        defer { withExtendedLifetime((destinationAccess, audioAccess)) {} }
        do {
            await Task.yield()
            guard StudioTimeline.valid(segments, sceneCount: RenderState.sceneNames.count) else { throw ExportError(String(localized: "Studio timeline is invalid")) }
            guard Self.supportedFrameRates.contains(frameRate), Self.supportedResolutions.contains(outputResolution) else {
                #if os(visionOS) || os(iOS)
                throw ExportError(String(localized: "Choose 720p, 1080p, or 4K and 24, 30, or 60 fps"))
                #else
                throw ExportError(String(localized: "Choose 720p, 1080p, or 4K and 24, 30, 60, or 120 fps (Experimental)"))
                #endif
            }
            guard audioURL?.standardizedFileURL != destination.standardizedFileURL else {
                throw ExportError(String(localized: "The output file must differ from the soundtrack"))
            }
            let spectrum: SoundtrackAnalyzer?
            if offline != nil, let audioURL {
                let preparation = Task.detached(priority: .userInitiated) {
                    PreparedSpectrum(analyzer: try SoundtrackAnalyzer(url: audioURL))
                }
                spectrum = try await withTaskCancellationHandler {
                    try await preparation.value.analyzer
                } onCancel: { preparation.cancel() }
            } else {
                spectrum = try audioURL.map { try SoundtrackAnalyzer(url: $0) }
            }
            let audioAsset = audioURL.map { AVURLAsset(url: $0) }
            let sourceDuration: Double
            if let audioAsset {
                sourceDuration = try await audioAsset.load(.duration).seconds
                guard sourceDuration.isFinite && sourceDuration > 0 else { throw ExportError(String(localized: "Soundtrack duration is unavailable")) }
            } else { sourceDuration = 15 }
            let start = 0.0
            let duration = min(offline?.previewSeconds ?? sourceDuration, sourceDuration)
            guard duration > 0, duration <= 24 * 60 * 60 else { throw ExportError(String(localized: "Soundtrack must be shorter than 24 hours")) }
            try checkCancellation()
            // NSSavePanel grants the output file, not arbitrary siblings in
            // its parent folder. Render in the app's sandbox temporary area.
            let work = (offline?.scratchDirectory ?? scratchDirectory).appendingPathComponent("PulseCanvas-export-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: work, withIntermediateDirectories: false)
            scratch = work
            defer { try? FileManager.default.removeItem(at: work) }
            let video = work.appendingPathComponent("frames.mp4")
            let renderer = VisualizerRenderer(state: scene)
            try renderer.prepareOffscreen(width: dimensions.width, height: dimensions.height)
            phase = .rendering
            try await encodeFrames(renderer: renderer, spectrum: spectrum, start: start,
                                   duration: duration, dimensions: dimensions, fps: frameRate, to: video, segments: segments, appearances: appearances)
            let result: URL
            if let audioAsset {
                phase = .muxing
                status = String(localized: "Adding soundtrack…")
                result = work.appendingPathComponent("complete.mp4")
                try await muxSoundtrack(asset: audioAsset, start: start, duration: duration, video: video, to: result)
            } else { result = video }
            try checkCancellation()
            phase = .validating
            if offline == nil && FileManager.default.fileExists(atPath: destination.path) {
                _ = try FileManager.default.replaceItemAt(destination, withItemAt: result)
            } else { try FileManager.default.moveItem(at: result, to: destination) }
            progress = 1
            exportedURL = destination
            if offline == nil { successfulSaveID = UUID() }
            status = String(localized: "Saved \(destination.lastPathComponent)")
        } catch is CancellationError {
            status = String(localized: "Export cancelled")
        } catch {
            self.error = error
            didFail = true
            status = String(localized: "Export failed: \(error.localizedDescription)")
        }
        if let scratch { try? FileManager.default.removeItem(at: scratch) }
    }

    private func snapshot(_ source: RenderState) -> RenderState {
        let copy = RenderState()
        copy.scene = source.scene; copy.speed = source.speed; copy.chaos = source.chaos; copy.brightness = source.brightness
        copy.liquidDetail = source.liquidDetail
        copy.zoomSpeed = source.zoomSpeed
        copy.haloCount = source.haloCount
        copy.particleSize = source.particleSize; copy.palette = source.palette; copy.fog = source.fog
        copy.rotation = source.rotation; copy.zoom = source.zoom; copy.motionBlur = source.motionBlur
        copy.strobeEnabled = source.strobeEnabled
        copy.strobeSensitivity = source.strobeSensitivity
        copy.strobeStrength = source.strobeStrength
        return copy
    }

    private func checkCancellation() throws {
        if cancellationRequested || Task.isCancelled { throw CancellationError() }
    }

    private func encodeFrames(renderer: VisualizerRenderer, spectrum: SoundtrackAnalyzer?, start: Double,
                              duration: Double, dimensions: (width: Int, height: Int), fps: Int, to url: URL, segments: [StudioSegment], appearances: [Int: VisualPreset]) async throws {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let bitrate = min(24_000_000, max(4_000_000, dimensions.width * dimensions.height * fps / 7))
        var settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: dimensions.width, AVVideoHeightKey: dimensions.height,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: bitrate,
                                               AVVideoExpectedSourceFrameRateKey: fps,
                                               AVVideoMaxKeyFrameIntervalKey: fps * 2,
                                               AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel]
        ]
        #if os(macOS)
        settings[AVVideoEncoderSpecificationKey] = [kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder as String: true]
        #endif
        // visionOS selects its encoder internally; the macOS specification key is unavailable there.
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: dimensions.width,
            kCVPixelBufferHeightKey as String: dimensions.height,
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ])
        guard writer.canAdd(input) else { throw ExportError(String(localized: "Cannot create H.264 encoder")) }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? ExportError(String(localized: "Cannot start H.264 encoder")) }
        writer.startSession(atSourceTime: .zero)
        var completed = false
        defer { if !completed { writer.cancelWriting() } }
        let count = Int(ceil(duration * Double(fps) - 0.00000001))
        totalFrames = count
        guard let device = renderer.offscreenDevice else { throw ExportError(String(localized: "Metal device is unavailable")) }
        var cache: CVMetalTextureCache?
        guard CVMetalTextureCacheCreate(nil, nil, device, nil, &cache) == kCVReturnSuccess, let cache else {
            throw ExportError(String(localized: "Cannot share GPU frames with the video encoder"))
        }
        var rateTime = ProcessInfo.processInfo.systemUptime
        var rateFrames = 0
        var lastPreview = -Double.infinity
        var activeStudioScene: Int? = nil
        for frame in 0..<count {
            try checkCancellation()
            let deadline = Date().addingTimeInterval(30)
            while !input.isReadyForMoreMediaData {
                try checkCancellation()
                guard writer.status == .writing else { throw writer.error ?? ExportError(String(localized: "Video encoder stopped")) }
                guard deadline.timeIntervalSinceNow > 0 else { throw ExportError(String(localized: "Video encoder timed out")) }
                try await Task.sleep(for: .milliseconds(2))
            }
            let sourceTime = start + Double(frame) / Double(fps)
            if let index = StudioTimeline.index(at: sourceTime, in: segments) {
                let scene = segments[index].scene
                if activeStudioScene != scene {
                    activeStudioScene = scene
                    renderer.state.scene = scene
                    let appearance = appearances[scene] ?? VisualPreset.defaults(for: scene)
                    appearance.apply(to: renderer.state)
                }
            }
            if renderer.state.scene >= RenderState.nativeSceneNames.count { renderer.state.audioPCM = try spectrum?.pcm(at: sourceTime) ?? [] }
            let features = try spectrum?.frame(at: sourceTime, clipStart: start, clipEnd: start + duration) ?? .silence
            guard let pool = adaptor.pixelBufferPool else { throw ExportError(String(localized: "Encoder pixel buffer pool is unavailable")) }
            var pixelBuffer: CVPixelBuffer?
            guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer) == kCVReturnSuccess,
                  let pixelBuffer else { throw ExportError(String(localized: "Cannot allocate an export frame")) }
            var surface: CVMetalTexture?
            guard CVMetalTextureCacheCreateTextureFromImage(nil, cache, pixelBuffer, nil, .bgra8Unorm,
                dimensions.width, dimensions.height, 0, &surface) == kCVReturnSuccess,
                let surface, let texture = CVMetalTextureGetTexture(surface) else {
                throw ExportError(String(localized: "Cannot map an encoder frame to the GPU"))
            }
            try await renderer.renderOffscreen(into: texture, time: sourceTime, audioBands: features.bands, audioPulse: features.pulse, audioMomentum: features.momentum, audioBeatMotionTime: features.beatMotionTime, audioTreblePulse: features.treblePulse, audioTrebleAttackTime: features.trebleAttackTime, audioEnvelopes: features.envelopes, audioSwell: features.swell)
            // Keep the Core Video texture wrapper alive through GPU completion.
            withExtendedLifetime(surface) {}
            try checkCancellation()
            guard adaptor.append(pixelBuffer, withPresentationTime: CMTime(value: Int64(frame), timescale: Int32(fps))) else {
                throw writer.error ?? ExportError(String(localized: "Cannot append export frame \(frame)"))
            }
            progress = 0.85 * Double(frame + 1) / Double(count)
            renderedFrames = frame + 1
            status = String(localized: "Rendering frame \(frame + 1) of \(count)")
            let now = ProcessInfo.processInfo.systemUptime
            let rateElapsed = now - rateTime
            if rateElapsed >= 0.5 {
                let rate = Double(frame + 1 - rateFrames) / rateElapsed
                framesPerSecond = framesPerSecond == 0 ? rate : framesPerSecond * 0.65 + rate * 0.35
                rateTime = now; rateFrames = frame + 1
            }
            if framesPerSecond > 0 && frame + 1 < count {
                estimatedSecondsRemaining = Double(count - frame - 1) / framesPerSecond
            }
            if now - lastPreview >= 0.2 || frame == count - 1 {
                updatePreview(pixelBuffer)
                lastPreview = now
            }
            await Task.yield()
        }
        writer.endSession(atSourceTime: CMTime(seconds: duration, preferredTimescale: 60_000))
        input.markAsFinished()
        estimatedSecondsRemaining = nil
        status = String(localized: "Finishing video…")
        await writer.finishWriting()
        try checkCancellation()
        guard writer.status == .completed else { throw writer.error ?? ExportError(String(localized: "Video encoding failed")) }
        completed = true
    }

    private func updatePreview(_ buffer: CVPixelBuffer) {
        var image: CGImage?
        guard VTCreateCGImageFromCVPixelBuffer(buffer, options: nil, imageOut: &image) == noErr, let image else { return }
        let scale = min(1, 480 / Double(max(image.width, image.height)))
        let width = max(1, Int(Double(image.width) * scale)), height = max(1, Int(Double(image.height) * scale))
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
        context.interpolationQuality = .low
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        framePreview = context.makeImage()
    }

    /// Copy the already encoded H.264 samples; encode only the trimmed soundtrack
    /// to AAC. Both composition tracks begin at zero and use the same clip length.
    private func muxSoundtrack(asset: AVURLAsset, start: Double, duration: Double, video: URL, to url: URL) async throws {
        let videoAsset = AVURLAsset(url: video)
        guard let videoSource = try await videoAsset.loadTracks(withMediaType: .video).first,
              let audioSource = try await asset.loadTracks(withMediaType: .audio).first else {
            throw ExportError(String(localized: "The soundtrack or rendered video track is missing"))
        }
        let formats = try await videoSource.load(.formatDescriptions)
        guard let videoFormat = formats.first else { throw ExportError(String(localized: "Video format is unavailable")) }
        let composition = AVMutableComposition()
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw ExportError(String(localized: "Cannot prepare soundtrack composition"))
        }
        let length = CMTime(seconds: duration, preferredTimescale: 60_000)
        try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: length), of: videoSource, at: .zero)
        try audioTrack.insertTimeRange(CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 60_000), duration: length), of: audioSource, at: .zero)
        let reader = try AVAssetReader(asset: composition)
        reader.timeRange = CMTimeRange(start: .zero, duration: length)
        let videoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
        let audioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 2, AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false, AVLinearPCMIsNonInterleaved: false
        ])
        videoOutput.alwaysCopiesSampleData = false
        audioOutput.alwaysCopiesSampleData = false
        guard reader.canAdd(videoOutput), reader.canAdd(audioOutput) else { throw ExportError(String(localized: "Cannot decode soundtrack composition")) }
        reader.add(videoOutput); reader.add(audioOutput)
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        writer.shouldOptimizeForNetworkUse = true
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: nil, sourceFormatHint: videoFormat)
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 2, AVEncoderBitRateKey: 192_000
        ])
        videoInput.expectsMediaDataInRealTime = false; audioInput.expectsMediaDataInRealTime = false
        guard writer.canAdd(videoInput), writer.canAdd(audioInput) else { throw ExportError(String(localized: "Cannot create MP4 soundtrack writer")) }
        writer.add(videoInput); writer.add(audioInput)
        guard writer.startWriting(), reader.startReading() else { throw writer.error ?? reader.error ?? ExportError(String(localized: "Cannot start soundtrack writer")) }
        writer.startSession(atSourceTime: .zero)
        var completed = false
        defer { if !completed { reader.cancelReading(); writer.cancelWriting() } }
        var videoFinished = false, audioFinished = false
        var batchCount = 0
        var lastProgressUpdate = ProcessInfo.processInfo.systemUptime
        var deadline = Date().addingTimeInterval(30)
        while !videoFinished || !audioFinished {
            try checkCancellation()
            guard writer.status == .writing, reader.status != .failed else {
                throw writer.error ?? reader.error ?? ExportError(String(localized: "Soundtrack writer stopped"))
            }
            var advanced = false
            for (output, input, isVideo) in [(videoOutput, videoInput, true), (audioOutput, audioInput, false)] {
                if (isVideo ? videoFinished : audioFinished) || !input.isReadyForMoreMediaData { continue }
                if let sample = output.copyNextSampleBuffer() {
                    guard input.append(sample) else { throw writer.error ?? ExportError(String(localized: "Cannot append soundtrack sample")) }
                    let time = CMSampleBufferGetPresentationTimeStamp(sample).seconds
                    let now = ProcessInfo.processInfo.systemUptime
                    if time.isFinite && now - lastProgressUpdate >= 0.1 {
                        progress = max(progress, min(0.99, 0.85 + 0.14 * time / duration))
                        lastProgressUpdate = now
                    }
                } else {
                    input.markAsFinished()
                    if isVideo { videoFinished = true } else { audioFinished = true }
                }
                advanced = true
            }
            if advanced {
                deadline = Date().addingTimeInterval(30)
                batchCount += 1
                if batchCount >= 32 { batchCount = 0; await Task.yield() }
            }
            else {
                guard deadline.timeIntervalSinceNow > 0 else { throw ExportError(String(localized: "Soundtrack encoding timed out")) }
                try await Task.sleep(for: .milliseconds(2))
            }
        }
        writer.endSession(atSourceTime: length)
        await writer.finishWriting()
        try checkCancellation()
        guard writer.status == .completed, reader.status == .completed else {
            throw writer.error ?? reader.error ?? ExportError(String(localized: "Soundtrack encoding failed"))
        }
        completed = true
    }
}

struct ExportError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
