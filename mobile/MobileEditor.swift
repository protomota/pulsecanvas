import AVFoundation
import Combine
import Foundation
#if DEBUG
import CryptoKit
#endif

/// The iPhone/iPad UI uses the production Mac audio, Studio, Radio and export models.
@MainActor final class MobileEditor: ObservableObject {
    let render = RenderState()
    let audio = AudioController()
    let studio = StudioStore()
    let radio: RadioController
    let exporter = SocialExportController()
    let engagement = CreatorEngagement()
    let library = ProjectMPresets.shared
    @Published var loading = false
    @Published var message: String?
    @Published var presenting = false
    @Published var selectedTab = 0
    @Published var needsSoundtrack = false
    private var pendingProject: CreatorProject?
    private var observations = Set<AnyCancellable>()
    private var started = false
    private var foreground = true
    private var playbackSession: MobilePlaybackSession?
    private let documents: URL
    private var autosave: URL { documents.appendingPathComponent("Studio-autosave.pulsecanvas") }

    init() {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        #if DEBUG
        let qa = ProcessInfo.processInfo.arguments.contains("-PCMobileQA")
        documents = qa
            ? FileManager.default.temporaryDirectory.appendingPathComponent("Mobile-QA-\(UUID().uuidString)") : base
        if qa {
            let suite = "PulseCanvas.MobileRadio.QA"
            let defaults = UserDefaults(suiteName: suite)!
            defaults.removePersistentDomain(forName: suite)
            radio = RadioController(defaults: defaults)
        } else { radio = RadioController() }
        #else
        documents = base
        radio = RadioController()
        #endif
        radio.attach(audio: audio)
        playbackSession = MobilePlaybackSession(audio: audio, radio: radio)
        studio.apply(to: render)
        audio.visualizationUpdated.sink { [weak self] in self?.tick() }.store(in: &observations)
        studio.$segments.dropFirst().debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveSession() }.store(in: &observations)
        studio.$presets.dropFirst().debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveSession() }.store(in: &observations)
    }
    var currentRender: RenderState { selectedTab == 1 ? radio.visualizer : render }

    func start() async {
        guard !started else { return }; started = true
        do { try await Task.detached {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
        }.value }
        catch { message = "Audio could not start: \(error.localizedDescription)" }
        studio.isStudio = true
        if let data = try? Data(contentsOf: autosave) {
            await openProject(data); return
        }
        if let demo = BundledSoundtrack.url {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-PCMobileQA") {
                do {
                    try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
                    let sample = documents.appendingPathComponent("Demo.m4a")
                    guard let export = AVAssetExportSession(asset: AVURLAsset(url: demo), presetName: AVAssetExportPresetAppleM4A) else { throw CocoaError(.fileReadCorruptFile) }
                    let radioQA = ProcessInfo.processInfo.arguments.contains("-PCMobileRadioQA")
                    let seconds = radioQA ? 30.0 : 8.0
                    export.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: seconds, preferredTimescale: 600))
                    try await export.export(to: sample, as: .m4a)
                    await load(sample, copy: false)
                    if radioQA {
                        let data = try Data(contentsOf: sample)
                        let track = RadioTrack(id: "00000000-0000-4000-8000-000000000001", title: "Radio test soundtrack", genre: "Electronic", duration: seconds,
                            audio: sample.lastPathComponent, sha256: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined(), byteCount: data.count)
                        let url = documents.appendingPathComponent("catalog.json")
                        let second = RadioTrack(id: "00000000-0000-4000-8000-000000000002", title: "Radio test soundtrack 2", genre: track.genre, duration: track.duration,
                            audio: track.audio, sha256: track.sha256, byteCount: track.byteCount)
                        try JSONEncoder().encode(RadioCatalog(version: 1, title: "Test Radio", tracks: [track, second])).write(to: url)
                        if ProcessInfo.processInfo.arguments.contains("-PCMobileFolderQA") {
                            selectedTab = 1
                            let album = documents.appendingPathComponent("My album")
                            try FileManager.default.createDirectory(at: album, withIntermediateDirectories: true)
                            try FileManager.default.copyItem(at: sample, to: album.appendingPathComponent("Personal song.m4a"))
                            radio.loadCatalog(at: url)
                            // Keep the real asynchronous import path; isolated QA preferences/storage only.
                            Task { @MainActor in
                                while radio.isCatalogLoading { try? await Task.sleep(for: .milliseconds(50)) }
                                radio.importMusicFolder(album, into: documents.appendingPathComponent("PersonalRadio"))
                            }
                        } else { radio.loadCatalog(at: url) }
                    }
                    return
                } catch { message = error.localizedDescription; return }
            }
            #endif
            await load(demo, copy: false)
        }
    }
    func importAudio(_ url: URL) async {
        radio.leave(); selectedTab = 0
        await load(url, copy: true)
    }
    func importLibrarySong(_ url: URL, title: String) async throws {
        guard !loading, !exporter.isExporting else { throw CocoaError(.userCancelled) }
        loading = true
        defer { loading = false }
        let folder = documents.appendingPathComponent("StudioMusic", isDirectory: true)
        let prepared = try await Task.detached(priority: .userInitiated) {
            let copy = try StudioMusicStorage.copy(url, title: title, into: folder)
            do { return try PreparedSoundtrack(url: copy) }
            catch { try? FileManager.default.removeItem(at: copy.deletingLastPathComponent()); throw error }
        }.value
        do { try Task.checkCancellation() }
        catch { try? FileManager.default.removeItem(at: prepared.url.deletingLastPathComponent()); throw error }
        radio.leave()
        guard audio.install(prepared, title: title) else { throw CocoaError(.fileReadCorruptFile) }
        selectedTab = 0; pendingProject = nil; needsSoundtrack = false
        studio.isStudio = true; studio.segments = []
        if let plan = audio.segmentPlan() { studio.makeTimeline(plan, render: render) }
        loading = false; tick(); saveSession()
    }
    private func load(_ url: URL, copy: Bool) async {
        guard !loading else { return }; loading = true
        defer { loading = false }
        let lease = SecurityScopedAccess(url: url)
        do {
            try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
            let destination = copy ? documents.appendingPathComponent(UUID().uuidString + "." + url.pathExtension) : url
            let prepared = try await Task.detached(priority: .userInitiated) {
                if copy { try FileManager.default.copyItem(at: url, to: destination) }
                do { return try PreparedSoundtrack(url: destination) }
                catch { if copy { try? FileManager.default.removeItem(at: destination) }; throw error }
            }.value
            let title = BundledSoundtrack.identifier(for: url) == nil ? url.deletingPathExtension().lastPathComponent : "PulseCanvas"
            guard audio.install(prepared, title: title) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            if let project = pendingProject {
                try apply(project); pendingProject = nil; needsSoundtrack = false
            } else {
                studio.segments = []
                if let plan = audio.segmentPlan() { studio.makeTimeline(plan, render: render) }
            }
            tick(); saveSession()
        } catch { message = error.localizedDescription }
        withExtendedLifetime(lease) {}
    }
    func choose(_ scene: Int) {
        guard library.eligibleScenes.contains(scene), !exporter.isExporting else { return }
        radio.leave(); studio.selectScene(scene, render: render); saveSession()
    }
    func useAtPlayhead() {
        if studio.segments.isEmpty, let plan = audio.segmentPlan() { studio.makeTimeline(plan, render: render) }
        _ = studio.assignAtPlayhead(audio.playbackSeconds, render: render); saveSession()
    }
    func selectClip(_ index: Int, play: Bool = false) {
        guard studio.segments.indices.contains(index) else { return }
        radio.leave(); studio.isStudio = true; studio.selectedSegment = index
        let clip = studio.segments[index]
        if play { audio.playSection(start: clip.start, end: clip.end, restart: true) }
        else { audio.selectSection(start: clip.start, end: clip.end) }
        studio.follow(time: clip.start, render: render)
    }
    func setBars(_ value: Int, at index: Int) {
        guard let grid = audio.segmentPlan(beatsPerSection: 4) else { return }
        audio.pause(); _ = studio.setBars(value, at: index, grid: grid, render: render); saveSession()
    }
    func setForeground(_ active: Bool, inBackground: Bool = false) {
        foreground = active
        audio.setVisualizationEnabled(active)
        if active { tick() }
        else {
            // iOS permits audio playback in the background, not Metal rendering.
            render.paused = true; radio.visualizer.paused = true
            if inBackground { exporter.cancel() }
            saveSession()
        }
    }
    private func tick() {
        guard foreground else { return }
        let target = currentRender
        target.audioTrebleAttackTime = audio.trebleAttackTime
        target.audioTreblePulse = audio.treblePulse; target.audioBeatMotionTime = audio.beatMotionTime
        target.audioMomentum = audio.momentum; target.audioPulse = audio.beatPulse
        target.audioBands = audio.spectrum; target.audioEnvelopes = audio.envelopes; target.audioSwell = audio.swell
        target.playbackTime = audio.selectedURL == nil ? nil : audio.playbackSeconds; target.paused = !audio.isPlaying
        if radio.isActive { radio.follow(time: audio.playbackSeconds) }
        else if !exporter.isExporting { studio.follow(time: audio.playbackSeconds, render: render) }
    }
    func projectData() throws -> Data {
        guard !radio.isActive || !radio.isPersonalMusic else { throw CocoaError(.userCancelled) }
        studio.save(render)
        let bundled = BundledSoundtrack.identifier(for: audio.selectedURL)
        let project = CreatorProject(soundtrack: bundled == nil ? audio.selectedURL : nil, scene: render.scene,
            appearance: studio.preset(render), aspect: exporter.aspect.rawValue, resolution: exporter.resolution, fps: exporter.fps,
            timeline: studio.segments, studioEnabled: studio.isStudio, visualPresets: studio.presets,
            barsPerSection: studio.barsPerSection,
            effectIdentities: library.identities(for: Set(studio.presets.keys).union(studio.segments.map(\.scene)).union([render.scene])),
            bundledSoundtrack: bundled, soundtrackBookmark: audio.soundtrackBookmark, loopPlayback: audio.loopEnabled)
        return try JSONEncoder().encode(project)
    }
    func openProject(_ data: Data) async {
        do {
            guard data.count < 8_000_000 else { throw CocoaError(.fileReadCorruptFile) }
            let project = try JSONDecoder().decode(CreatorProject.self, from: data).remapped(using: library)
            guard project.version == 1, project.appearance.isValid,
                  project.visualPresets?.values.allSatisfy(\.isValid) ?? true,
                  StudioTimeline.valid(project.timeline ?? [], sceneCount: RenderState.sceneNames.count),
                  SocialAspect(rawValue: project.aspect) != nil, [720, 1080, 2160].contains(project.resolution),
                  SocialExportController.supportedFrameRates.contains(project.fps),
                  project.barsPerSection.map({ (1...64).contains($0) }) ?? true else { throw CocoaError(.fileReadCorruptFile) }
            radio.leave(); selectedTab = 0; pendingProject = project
            let reference = try BundledSoundtrack.resolve(identifier: project.bundledSoundtrack, externalURL: project.soundtrack)
            if let reference {
                let bookmarked = SecurityScopedAccess.resolve(bookmark: project.soundtrackBookmark, fallback: reference)
                let local = documents.appendingPathComponent(reference.lastPathComponent)
                let source = FileManager.default.fileExists(atPath: bookmarked.path) ? bookmarked : local
                guard FileManager.default.fileExists(atPath: source.path) else { needsSoundtrack = true; return }
                await load(source, copy: false)
            } else { audio.clear(); try apply(project); pendingProject = nil }
        } catch { message = "Couldn't open this project: \(error.localizedDescription)" }
    }
    private func apply(_ project: CreatorProject) throws {
        guard (project.timeline?.last?.end ?? 0) <= audio.duration + 0.05 else { throw CocoaError(.fileReadCorruptFile) }
        studio.presets = project.visualPresets ?? [:]; studio.segments = project.timeline ?? []
        studio.isStudio = project.studioEnabled ?? false; studio.selectedSegment = 0
        studio.barsPerSection = project.barsPerSection ?? 4
        render.scene = project.scene; studio.apply(project.appearance, to: render)
        exporter.aspect = SocialAspect(rawValue: project.aspect)!; exporter.resolution = project.resolution; exporter.fps = project.fps
        audio.loopEnabled = project.loopPlayback ?? true
        studio.detectedBPM = audio.segmentPlan()?.bpm
    }
    func saveSession() {
        guard !loading, !radio.isActive, audio.selectedURL != nil else { return }
        do { try projectData().write(to: autosave, options: .atomic) }
        catch { message = "Couldn't save this session: \(error.localizedDescription)" }
    }
}
