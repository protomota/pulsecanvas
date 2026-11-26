#if os(macOS) && DIRECT_BUILD && !STORE_BUILD
@preconcurrency import AVFoundation
import Foundation

@MainActor
final class PulseMCPJobs {
    static let maxPending = 3
    private static let historyLimit = 200

    struct Format: Codable {
        let aspect: String
        let resolution: Int
        let fps: Int
    }

    struct Job: Codable, Identifiable {
        let id: String
        let signature: String
        let requestKey: String
        let destination: String
        let projectPath: String?
        let sourcePath: String
        let sourceBytes: Int
        let sourceModified: Date
        let settings: Format
        let previewSeconds: Double?
        let overwrite: Bool
        let project: CreatorProject
        let timeline: [PulseMCPScene]
        let duration: Double
        let usedFallback: Bool
        var phase = "queued"
        var artifact: Artifact?
        var errorCode: String?
        var errorMessage: String?
        var manifestPath: String?
        var pending: Bool { ["queued", "preparing", "rendering", "muxing", "validating"].contains(phase) }
    }

    struct Artifact: Codable {
        var path: String
        let durationSeconds: Double
        let width: Int
        let height: Int
        let fps: Double
        let expectedFrames: Int
        let videoCodec: String
        let audioCodec: String
        let bytes: Int
    }

    struct SaveReceipt: Codable {
        let key: String
        let signature: String
        let path: String
        let project: CreatorProject
        let duration: Double
    }

    struct Ledger: Codable {
        var jobs: [Job] = []
        var saves: [SaveReceipt] = []
    }

    private let access: PulseMCPAccess
    private let exporter: SocialExportController
    private let url: URL
    private var ledger = Ledger()
    private var loadError: Error?
    private var worker: Task<Void, Never>?
    private var active: String?
    private(set) var pendingCount = 0

    init(access: PulseMCPAccess, exporter: SocialExportController) {
        self.access = access
        self.exporter = exporter
        url = PulseMCPMailbox.configuredRoot.appendingPathComponent("jobs.json")
        do {
            _ = try PulseMCPMailbox.root()
            if FileManager.default.fileExists(atPath: url.path) {
                ledger = try JSONDecoder().decode(Ledger.self, from: Data(contentsOf: url))
                var recovered = ledger
                for index in recovered.jobs.indices where recovered.jobs[index].pending {
                    cleanupInterrupted(recovered.jobs[index])
                    recovered.jobs[index].phase = "failed"
                    recovered.jobs[index].errorCode = "EXPORT_INTERRUPTED"
                    recovered.jobs[index].errorMessage = "PulseCanvas closed before this export completed. Start a new export with a new request key."
                }
                try write(recovered)
            }
        } catch { loadError = error }
    }

    private func cleanupInterrupted(_ job: Job) {
        guard UUID(uuidString: job.id) != nil,
              let output = try? access.authorize(job.destination, in: [.output], writing: true) else { return }
        defer { withExtendedLifetime(output.scope) {} }
        let folder = workDirectory(destination: output.url, id: job.id)
        let marker = folder.appendingPathComponent("owner")
        guard let properties = try? folder.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]),
              properties.isDirectory == true, properties.isSymbolicLink != true,
              (try? marker.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])).map({
                  $0.isRegularFile == true && $0.isSymbolicLink != true && $0.fileSize == job.id.utf8.count
              }) == true,
              (try? Data(contentsOf: marker)) == Data(job.id.utf8) else { return }
        try? FileManager.default.removeItem(at: folder)
    }

    private func workDirectory(destination: URL, id: String) -> URL {
        destination.deletingLastPathComponent().appendingPathComponent(".PulseCanvas-" + id, isDirectory: true)
    }

    func requireStorage() throws {
        if loadError != nil {
            throw PulseMCPError("JOB_STORAGE_UNAVAILABLE", "PulseCanvas could not read or save its job history. Check the AgentConnection folder before retrying.")
        }
    }

    func job(_ id: String) throws -> Job {
        try requireStorage()
        guard let job = ledger.jobs.first(where: { $0.id == id }) else {
            throw PulseMCPError("JOB_NOT_FOUND", "Read list_exports to find the retained ID.")
        }
        return job
    }

    func recent(_ limit: Int) throws -> [Job] {
        try requireStorage()
        return Array(ledger.jobs.suffix(limit).reversed())
    }

    func repeatJob(key: String, signature: String) throws -> Job? {
        try requireStorage()
        if ledger.saves.contains(where: { $0.key == key }) { throw keyConflict() }
        guard let previous = ledger.jobs.first(where: { $0.requestKey == key }) else { return nil }
        guard previous.signature == signature else { throw keyConflict() }
        return previous
    }

    func repeatSave(key: String, signature: String) throws -> SaveReceipt? {
        try requireStorage()
        if ledger.jobs.contains(where: { $0.requestKey == key }) { throw keyConflict() }
        guard let receipt = ledger.saves.first(where: { $0.key == key }) else { return nil }
        guard receipt.signature == signature else { throw keyConflict() }
        return receipt
    }

    func rememberSave(_ receipt: SaveReceipt) throws {
        var next = ledger
        next.saves.append(receipt)
        if next.saves.count > Self.historyLimit { next.saves.removeFirst() }
        try write(next)
    }

    private func keyConflict() -> PulseMCPError {
        PulseMCPError("REQUEST_KEY_CONFLICT", "Use a new request key for a different operation or different arguments.")
    }

    func checkCapacity(destination: URL) throws {
        try requireStorage()
        guard pendingCount < Self.maxPending,
              !ledger.jobs.contains(where: { $0.pending && $0.destination == destination.path }) else {
            throw PulseMCPError("EXPORT_BUSY", "Wait for a pending export or choose an unused destination.")
        }
    }

    func checkOutput(_ destination: URL, overwrite: Bool) throws {
        let manifest = Self.manifestURL(destination)
        try Self.checkDestination(destination, overwrite: overwrite)
        try Self.checkDestination(manifest, overwrite: overwrite)
        let fm = FileManager.default
        guard overwrite && (fm.fileExists(atPath: destination.path) || fm.fileExists(atPath: manifest.path)) else { return }
        let known = ledger.jobs.last { $0.phase == "completed" && $0.destination == destination.path }
        guard let known, let artifact = known.artifact, known.manifestPath == manifest.path,
              let size = try? destination.resourceValues(forKeys: [.fileSizeKey]).fileSize, size == artifact.bytes,
              let manifestSize = try? manifest.resourceValues(forKeys: [.fileSizeKey]).fileSize, manifestSize <= 2_000_000,
              let data = try? Data(contentsOf: manifest),
              let metadata = try? JSONSerialization.jsonObject(with: data) as? PulseMCP.Object,
              metadata["jobId"] as? String == known.id
        else {
            throw PulseMCPError("OUTPUT_EXISTS", "Use a new name. PulseCanvas can replace only an export it previously recorded at this path.")
        }
    }

    func submit(_ job: Job) throws {
        var next = ledger
        next.jobs.append(job)
        if next.jobs.count > Self.historyLimit, let index = next.jobs.firstIndex(where: { !$0.pending }) {
            next.jobs.remove(at: index)
        }
        try write(next)
        kick()
    }

    func failPreparation(_ queued: Job, error: Error) {
        var job = queued
        job.phase = "failed"
        let failure = Self.error(error, defaultCode: "PROJECT_SAVE_FAILED")
        job.errorCode = failure.code
        job.errorMessage = failure.message
        try? record(job)
    }

    private func write(_ next: Ledger) throws {
        let data = try JSONEncoder().encode(next)
        try data.write(to: url, options: .atomic)
        ledger = next
        pendingCount = ledger.jobs.filter(\.pending).count
    }

    private func record(_ job: Job) throws {
        guard let index = ledger.jobs.firstIndex(where: { $0.id == job.id }) else { return }
        var next = ledger
        next.jobs[index] = job
        do { try write(next) }
        catch {
            // Never report an unpersisted completion. Stop accepting further work
            // until the storage problem is resolved and the app restarts.
            loadError = error
            throw error
        }
    }

    private func kick() {
        guard worker == nil else { return }
        worker = Task { [weak self] in await self?.drain() }
    }

    private func drain() async {
        defer { active = nil; worker = nil }
        while let job = ledger.jobs.first(where: { $0.phase == "queued" }), loadError == nil, !Task.isCancelled {
            if exporter.isExporting {
                try? await Task.sleep(for: .milliseconds(150))
                continue
            }
            active = job.id
            let task = Task { await run(job) }
            activeTask = task
            await task.value
            activeTask = nil
            active = nil
        }
    }

    private var activeTask: Task<Void, Never>?

    func cancel(_ id: String) throws -> Job {
        var job = try self.job(id)
        guard job.pending else { return job }
        if id == active {
            activeTask?.cancel()
            exporter.cancel()
        } else {
            job.phase = "cancelled"
            try record(job)
        }
        return job
    }

    func details(_ job: Job) -> PulseMCP.Object {
        let live = active == job.id && job.pending
        var result: PulseMCP.Object = [
            "id": job.id, "phase": live && exporter.isExporting ? exporter.phase.rawValue : job.phase,
            "progress": job.phase == "completed" ? 1.0 : live ? min(exporter.progress, 0.99) : 0.0,
            "framesRendered": live ? exporter.renderedFrames : job.artifact?.expectedFrames ?? 0,
            "totalFrames": live ? exporter.totalFrames : job.artifact?.expectedFrames ?? 0,
            "destination": job.destination, "previewOnly": job.previewSeconds != nil
        ]
        result["projectPath"] = job.projectPath
        result["manifestPath"] = job.manifestPath
        if let eta = live ? exporter.estimatedSecondsRemaining : nil { result["etaSeconds"] = eta }
        if let artifact = job.artifact, let data = try? JSONEncoder().encode(artifact) {
            result["artifact"] = try? JSONSerialization.jsonObject(with: data)
        }
        if let code = job.errorCode, let message = job.errorMessage {
            result["error"] = ["code": code, "message": message]
        }
        return result
    }

    private func run(_ queued: Job) async {
        var job = queued
        do {
            try Task.checkCancellation()
            guard access.enabled, access.rendering else { throw revoked() }
            let source = try access.authorize(job.sourcePath, in: [.input])
            let output = try access.authorize(job.destination, in: [.output], writing: true)
            defer { withExtendedLifetime((source.scope, output.scope)) {} }
            let identity = try Self.sourceIdentity(source.url)
            guard identity.bytes == job.sourceBytes, identity.modified == job.sourceModified else {
                throw PulseMCPError("AUDIO_CHANGED", "The source file changed since submission. Reload it and start a new export.")
            }
            let destination = output.url
            let manifestPath = Self.manifestURL(destination)
            try checkOutput(destination, overwrite: job.overwrite)
            let work = workDirectory(destination: destination, id: job.id)
            try FileManager.default.createDirectory(at: work, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            defer { try? FileManager.default.removeItem(at: work) }
            try Data(job.id.utf8).write(to: work.appendingPathComponent("owner"), options: .withoutOverwriting)
            let staged = work.appendingPathComponent("video.mp4")
            let manifest = work.appendingPathComponent("manifest.json")
            let snapshot: CreatorProject
            do {
                snapshot = try job.project.remapped(using: .shared)
                let allScenes = Set((snapshot.timeline ?? []).map(\.scene)).union([snapshot.scene])
                guard allScenes.isSubset(of: Set(ProjectMPresets.shared.availableScenes)),
                      job.project.effectIdentities?[job.project.scene] == ProjectMPresets.shared.identity(for: snapshot.scene),
                      job.timeline.count == (snapshot.timeline ?? []).count,
                      zip(job.timeline, snapshot.timeline ?? []).allSatisfy({ $0.visualizerId == ProjectMPresets.shared.identity(for: $1.scene) })
                else { throw CocoaError(.fileReadCorruptFile) }
            } catch { throw PulseMCPError("UNSUPPORTED_EFFECT", "An effect used by the saved export is no longer installed. Restore it and submit another job.") }
            guard let aspect = SocialAspect.allCases.first(where: { $0.agentName == job.settings.aspect }) else {
                throw PulseMCPError("UNSUPPORTED_FORMAT", "Read the current export capabilities.")
            }
            job.phase = "preparing"
            try record(job)
            let state = RenderState()
            state.scene = snapshot.scene
            snapshot.appearance.apply(to: state)
            await exporter.export(audioURL: source.url, render: state, to: staged,
                                  segments: snapshot.studioEnabled == true ? (snapshot.timeline ?? []) : [],
                                  appearances: snapshot.visualPresets ?? [:],
                                  offline: .init(aspect: aspect, resolution: job.settings.resolution, fps: job.settings.fps,
                                                 scratchDirectory: work, previewSeconds: job.previewSeconds))
            try Task.checkCancellation()
            if let error = exporter.error { throw error }
            guard exporter.exportedURL == staged else { throw CancellationError() }
            job.phase = "validating"
            try record(job)
            let duration = min(job.previewSeconds ?? job.duration, job.duration)
            let dimensions = aspect.dimensions(resolution: job.settings.resolution)
            var artifact = try await Self.validate(staged, dimensions: dimensions, fps: job.settings.fps, duration: duration)
            try Task.checkCancellation()
            guard access.enabled, access.rendering else { throw revoked() }
            let liveGrant = try access.authorize(job.destination, in: [.output], writing: true)
            let liveInput = try access.authorize(job.sourcePath, in: [.input])
            defer { withExtendedLifetime((liveGrant.scope, liveInput.scope)) {} }
            let finalSource = try Self.sourceIdentity(liveInput.url)
            guard finalSource.bytes == job.sourceBytes, finalSource.modified == job.sourceModified else {
                throw PulseMCPError("AUDIO_CHANGED", "The source file changed during the render. Reload it and start a new export.")
            }
            artifact.path = destination.path
            let details: PulseMCP.Object = ["jobId": job.id, "appVersion": PulseMCPAccess.version,
                "appEdition": PulseMCPAccess.edition, "sourcePath": job.sourcePath, "sourceBytes": job.sourceBytes,
                "sourceModified": ISO8601DateFormatter().string(from: job.sourceModified), "projectPath": job.projectPath as Any? ?? NSNull(),
                "seed": job.project.generationSeed as Any? ?? NSNull(), "timeline": job.timeline.map(\.payload),
                "settings": ["aspect": job.settings.aspect, "resolution": job.settings.resolution, "fps": job.settings.fps],
                "artifact": try JSONSerialization.jsonObject(with: JSONEncoder().encode(artifact))]
            try JSONSerialization.data(withJSONObject: details, options: [.prettyPrinted, .sortedKeys]).write(to: manifest)
            try checkOutput(destination, overwrite: job.overwrite)
            try Self.publish(staged, to: destination, overwrite: job.overwrite)
            do { try Self.publish(manifest, to: manifestPath, overwrite: job.overwrite) }
            catch {
                if !job.overwrite { try? FileManager.default.removeItem(at: destination) }
                throw error
            }
            job.phase = "completed"
            job.artifact = artifact
            job.manifestPath = manifestPath.path
            try record(job)
        } catch is CancellationError {
            job.phase = "cancelled"
            try? record(job)
        } catch {
            job.phase = "failed"
            job.artifact = nil
            job.manifestPath = nil
            let failure = Self.error(error)
            job.errorCode = failure.code
            job.errorMessage = failure.message
            try? record(job)
        }
    }

    private func revoked() -> PulseMCPError {
        PulseMCPError("PERMISSION_REQUIRED", "Rendering access was disabled. Review Settings → Agent access before submitting another export.")
    }

    static func error(_ error: Error, defaultCode: String = "EXPORT_FAILED") -> PulseMCPError {
        if let error = error as? PulseMCPError { return error }
        var underlying: NSError? = error as NSError
        while let current = underlying {
            if (current.domain == NSPOSIXErrorDomain && current.code == Int(ENOSPC)) ||
               (current.domain == NSCocoaErrorDomain && current.code == NSFileWriteOutOfSpaceError) {
                return PulseMCPError("DISK_FULL", "Free space on the authorized output drive or choose another output folder.")
            }
            if (current.domain == NSPOSIXErrorDomain && current.code == Int(EEXIST)) ||
               (current.domain == NSCocoaErrorDomain && current.code == NSFileWriteFileExistsError) {
                return PulseMCPError("OUTPUT_EXISTS", "Choose a new output path.")
            }
            underlying = current.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        return PulseMCPError(defaultCode, "\(error.localizedDescription) Check the source, authorized folder and available storage before retrying.")
    }

    static func sourceIdentity(_ url: URL) throws -> (bytes: Int, modified: Date) {
        let values = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        guard let bytes = values.fileSize, let modified = values.contentModificationDate else {
            throw PulseMCPError("AUDIO_UNAVAILABLE", "Choose a readable audio file in the authorized input folder.")
        }
        return (bytes, modified)
    }

    static func manifestURL(_ video: URL) -> URL { video.deletingPathExtension().appendingPathExtension("render.json") }

    static func checkDestination(_ url: URL, overwrite: Bool) throws {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        let symbol = try? FileManager.default.destinationOfSymbolicLink(atPath: url.path)
        guard symbol == nil, !isDirectory.boolValue, !exists || overwrite else {
            throw PulseMCPError("OUTPUT_EXISTS", "Choose a new destination; directories and symbolic links are never overwritten.")
        }
    }

    static func publish(_ staged: URL, to destination: URL, overwrite: Bool) throws {
        try checkDestination(destination, overwrite: overwrite)
        if overwrite {
            guard rename(staged.path, destination.path) == 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
        } else {
            guard renamex_np(staged.path, destination.path, UInt32(RENAME_EXCL)) == 0 else {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
            }
        }
    }

    private static func validate(_ url: URL, dimensions: (width: Int, height: Int), fps: Int, duration: Double) async throws -> Artifact {
        let asset = AVURLAsset(url: url)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        let failure = PulseMCPError("MEDIA_VALIDATION_FAILED", "The MP4 did not match the requested audio and video format.")
        guard videoTracks.count == 1, audioTracks.count == 1,
              let video = videoTracks.first, let audio = audioTracks.first else { throw failure }
        let actual = try await asset.load(.duration).seconds
        let size = try await video.load(.naturalSize)
        let rate = try await video.load(.nominalFrameRate)
        let videoRange = try await video.load(.timeRange)
        let audioRange = try await audio.load(.timeRange)
        let videoCodec = try await video.load(.formatDescriptions).first.map(CMFormatDescriptionGetMediaSubType)
        let audioCodec = try await audio.load(.formatDescriptions).first.map(CMFormatDescriptionGetMediaSubType)
        let tolerance = max(2 / Double(fps), 0.06)
        let bytes = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard bytes > 0, abs(actual - duration) <= tolerance, Int(size.width) == dimensions.width,
              Int(size.height) == dimensions.height, abs(Double(rate) - Double(fps)) < 0.5,
              videoCodec == kCMVideoCodecType_H264, audioCodec == kAudioFormatMPEG4AAC,
              abs(videoRange.start.seconds - audioRange.start.seconds) <= tolerance,
              abs(videoRange.duration.seconds - audioRange.duration.seconds) <= tolerance else { throw failure }
        let frames = Int(ceil(duration * Double(fps) - 0.00000001))
        let scan = Task.detached {
            try await Self.checkVideoSamples(url, fps: fps, expected: frames)
        }
        try await withTaskCancellationHandler { try await scan.value } onCancel: { scan.cancel() }
        return Artifact(path: url.path, durationSeconds: actual, width: dimensions.width, height: dimensions.height,
                        fps: Double(rate), expectedFrames: frames, videoCodec: "h264", audioCodec: "aac", bytes: bytes)
    }

    nonisolated private static func checkVideoSamples(_ url: URL, fps: Int, expected: Int) async throws {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw PulseMCPError("MEDIA_VALIDATION_FAILED", "The video track could not be opened for decoding.")
        }
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        ])
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else {
            throw PulseMCPError("MEDIA_VALIDATION_FAILED", "The decoder rejected the encoded video track.")
        }
        reader.add(output)
        guard reader.startReading() else {
            throw reader.error ?? PulseMCPError("MEDIA_VALIDATION_FAILED", "The decoder could not start.")
        }
        var frames = 0
        var mediaStart: Double?
        defer { if reader.status == .reading { reader.cancelReading() } }
        while let sample = output.copyNextSampleBuffer() {
            try Task.checkCancellation()
            guard CMSampleBufferGetImageBuffer(sample) != nil else { continue }
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sample).seconds
            if mediaStart == nil { mediaStart = timestamp }
            let elapsed = timestamp - (mediaStart ?? timestamp)
            guard timestamp.isFinite, abs(elapsed - Double(frames) / Double(fps)) < 0.001 else {
                throw PulseMCPError("MEDIA_VALIDATION_FAILED", "Decoded frame \(frames + 1) does not match the requested frame cadence.")
            }
            frames += 1
        }
        guard reader.status == .completed, frames == expected else {
            throw reader.error ?? PulseMCPError("MEDIA_VALIDATION_FAILED", "The decoder found \(frames) frames. Expected \(expected).")
        }
    }

}

struct PulseMCPScene: Codable {
    let visualizerId: String
    let startSeconds: Double
    let endSeconds: Double
    let bars: Int?
    var payload: PulseMCP.Object {
        var object: PulseMCP.Object = ["visualizerId": visualizerId, "startSeconds": startSeconds, "endSeconds": endSeconds]
        object["bars"] = bars.flatMap { (1...128).contains($0) ? $0 : nil }
        return object
    }
}

extension SocialAspect {
    var agentName: String { PulseMCP.aspectNames[Self.allCases.firstIndex(of: self)!] }
}
#endif
