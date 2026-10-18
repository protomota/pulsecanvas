import AVFoundation
import Combine
import Foundation

@MainActor final class VisionTransport: ObservableObject {
    @Published var seconds = 0.0
    @Published var duration = 0.0
    @Published var playing = false
}

/// Constructed off the main actor, then transferred once; analysis is read only on the main actor thereafter.
private struct VisionAnalysis: @unchecked Sendable { let value: SoundtrackAnalyzer }

@MainActor private final class VisionPlaybackCompletion: NSObject, AVAudioPlayerDelegate {
    var finished: (() -> Void)?
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in if flag { self?.finished?() } }
    }
}

@MainActor final class VisionStudio: ObservableObject {
    @Published private(set) var project = VisionProject() { didSet { timelineCache = nil } }
    @Published var selected: UUID?
    @Published private(set) var loading = false
    @Published var message: String?
    @Published var immersiveActive = false
    @Published var screenDistance: Float = 3
    @Published var screenHeight: Float = 1.4
    @Published var volume: Float = 0.7 { didSet { player?.volume = volume } }
    let render = RenderState()
    let transport = VisionTransport()
    private var player: AVAudioPlayer?
    private var analyzer: SoundtrackAnalyzer?
    private var ticker: AnyCancellable?
    private var currentScene: Int?
    private var revision = UUID()
    private var loadingCount = 0
    private var started = false
    private var timelineCache: [StudioSegment]?
    private let completion = VisionPlaybackCompletion()
    var onPlaybackFinished: (() -> Void)?
    private let library: ProjectMPresets
    private let directory: URL
    var selectedIndex: Int { project.clips.firstIndex { $0.id == selected } ?? 0 }
    var selectedScene: Int { project.clips[selectedIndex].scene }
    var look: VisionLook { project.looks[selectedScene] ?? VisionLook(scene: selectedScene) }
    var segments: [StudioSegment] {
        if let timelineCache { return timelineCache }
        let result = project.segments(duration: transport.duration)
        timelineCache = result
        return result
    }
    var loopPlayback: Bool {
        get { project.loopPlayback }
        set {
            project.loopPlayback = newValue
            player?.numberOfLoops = audioLoopCount
            save()
        }
    }
    private var audioLoopCount: Int {
        #if os(tvOS)
        // Radio advances tracks at the end; the Vision Pro loop preference must not block it.
        return 0
        #else
        return project.loopPlayback ? -1 : 0
        #endif
    }

    init(directory: URL? = nil, library: ProjectMPresets? = nil) {
        self.library = library ?? .shared
        self.directory = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if let data = try? Data(contentsOf: self.directory.appendingPathComponent("Studio-autosave.json")),
           let saved = try? JSONDecoder().decode(VisionProject.self, from: data).validated() { project = saved }
        selected = project.clips.first?.id
        completion.finished = { [weak self] in self?.onPlaybackFinished?() }
        applyAppearance()
        #if os(visionOS)
        let tickInterval = 1.0 / 60
        #else
        let tickInterval = 1.0 / 30
        #endif
        ticker = Timer.publish(every: tickInterval, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.tick() }
    }

    func start(force: Bool = false) async {
        guard force || !started else { return }; started = true
        if let file = project.audioFile, FileManager.default.fileExists(atPath: directory.appendingPathComponent(file).path) {
            await loadAudio(directory.appendingPathComponent(file), generateTimeline: false)
        } else if let bundled = Bundle.main.url(forResource: "PulseCanvas", withExtension: "mp3", subdirectory: "NativeAssets/Audio") {
            if project.audioFile != nil { message = "Import this project's soundtrack again. Audio files aren't embedded in project backups." }
            await loadAudio(bundled, generateTimeline: project.clips.count == 1)
        }
    }

    func importAudio(_ url: URL) async {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            let name = UUID().uuidString + "." + url.pathExtension
            let destination = directory.appendingPathComponent(name)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: url, to: destination)
            guard await loadAudio(destination, generateTimeline: true) else {
                try? FileManager.default.removeItem(at: destination); return
            }
            project.audioFile = name; project.audioTitle = url.deletingPathExtension().lastPathComponent; save()
        } catch { message = error.localizedDescription }
    }

    @discardableResult private func loadAudio(_ url: URL, generateTimeline: Bool) async -> Bool {
        let token = UUID(); revision = token; loadingCount += 1; loading = true
        defer { loadingCount -= 1; loading = loadingCount > 0 }
        do {
            let prepared = try await Task.detached(priority: .userInitiated) { VisionAnalysis(value: try SoundtrackAnalyzer(url: url)) }.value
            guard revision == token else { return false }
            let next = try AVAudioPlayer(contentsOf: url)
            guard next.duration.isFinite, next.duration > 0 else { throw CocoaError(.fileReadCorruptFile) }
            next.numberOfLoops = audioLoopCount
            next.delegate = completion
            next.prepareToPlay(); next.volume = volume
            player?.stop(); player = next; analyzer = prepared.value
            transport.duration = next.duration; timelineCache = nil; transport.seconds = 0; transport.playing = false
            let plan = prepared.value.segmentPlan()
            project.beatBoundaries = prepared.value.segmentPlan(beatsPerSection: 1).boundaries
            let choices = self.library.pool.enabled ? self.library.eligibleScenes : NativeEffects.timelineOrder
            if generateTimeline && !choices.isEmpty {
                project.bpm = min(300, max(20, plan.bpm ?? 120))
                project.clips = plan.boundaries.dropLast().enumerated().map {
                    VisionClip(scene: choices[$0.offset % choices.count])
                }
                if project.clips.isEmpty { project.clips = [VisionClip(scene: NativeEffects.defaultScene)] }
                project.clips = Array(project.clips.prefix(500)); selected = project.clips.first?.id
            }
            applyAppearance(); save(); tick(); return true
        } catch { if revision == token { message = error.localizedDescription }; return false }
    }

    /// Radio owns its verified cache; do not duplicate each download into Documents.
    @discardableResult func loadRadioAudio(_ url: URL, title: String) async -> Bool {
        guard await loadAudio(url, generateTimeline: true) else { return false }
        project.audioFile = nil; project.audioTitle = title; save(); return true
    }

    func togglePlayback() {
        guard !loading, let player else { return }
        if player.isPlaying { player.pause() } else {
            do {
                #if os(visionOS) || os(tvOS)
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                #endif
                if player.currentTime >= player.duration - 0.05 { player.currentTime = 0 }
                player.play()
            } catch { message = "Audio playback couldn't start: \(error.localizedDescription)" }
        }
        transport.playing = player.isPlaying; render.paused = !player.isPlaying
    }
    func seek(_ seconds: Double) {
        guard seconds.isFinite else { return }
        player?.currentTime = min(transport.duration, max(0, seconds)); transport.seconds = player?.currentTime ?? 0; tick()
    }
    func select(_ clip: VisionClip) {
        selected = clip.id
        let index = selectedIndex
        if segments.indices.contains(index) { seek(segments[index].start) }
        applyAppearance()
    }
    func assign(_ scene: Int) {
        guard self.library.eligibleScenes.contains(scene) else { return }
        project.clips[selectedIndex].scene = scene; applyAppearance(); save()
    }
    /// Match the Mac randomizer: change the assignment, keeping every saved style intact.
    @discardableResult func randomizeVisualizer() -> Bool {
        let eligible = library.eligibleScenes
        let different = eligible.filter { $0 != selectedScene }
        guard let next = (different.isEmpty ? eligible : different).randomElement() else { return false }
        assign(next)
        return true
    }
    func randomizeLook() {
        updateLook {
            $0.palette = VisualPalette.allCases.randomElement()?.rawValue ?? $0.palette
            $0.speed = Float.random(in: 0.6...1.8)
            $0.zoomSpeed = Float.random(in: 0...2.5)
            $0.chaos = Float.random(in: 0.3...1)
            $0.zoom = Float.random(in: 0.65...1.4)
            $0.brightness = Float.random(in: 0.8...1.5)
            $0.size = Float.random(in: 0.5...1.8)
            $0.detail = Float.random(in: 0.2...1)
            $0.fog = Float.random(in: 0...0.6)
        }
    }
    func updateLook(_ body: (inout VisionLook) -> Void) {
        var value = look; body(&value)
        guard value.isValid else { return }
        project.looks[selectedScene] = value; applyAppearance(); save()
    }
    func resetLook() { project.looks.removeValue(forKey: selectedScene); applyAppearance(); save() }
    func bars(_ value: Int, clip: UUID) {
        guard let i = project.clips.firstIndex(where: { $0.id == clip }), (1...64).contains(value) else { return }
        project.clips[i].bars = value; save(); tick()
    }
    func addClip() {
        guard project.clips.count < 500 else { return }
        guard let next = self.library.eligibleScenes.first(where: { $0 != selectedScene }) ?? self.library.eligibleScenes.first else { return }
        let clip = VisionClip(scene: next); project.clips.insert(clip, at: selectedIndex + 1); selected = clip.id
        applyAppearance(); save()
    }
    func removeClip() {
        guard project.clips.count > 1 else { return }
        let index = selectedIndex; project.clips.remove(at: index)
        selected = project.clips[min(index, project.clips.count - 1)].id; applyAppearance(); save()
    }
    func moveClip(_ offset: Int) {
        let i = selectedIndex, next = i + offset
        guard project.clips.indices.contains(next) else { return }
        project.clips.swapAt(i, next); save()
    }
    func replaceProject(_ value: VisionProject) async {
        do { let validated = try value.validated(); suspend(); project = validated; selected = project.clips.first?.id; applyAppearance(); save(); await start(force: true) }
        catch { message = error.localizedDescription }
    }
    func suspend() { player?.pause(); transport.playing = false; render.paused = true }

    private func applyAppearance() {
        let look = self.look
        render.scene = selectedScene; currentScene = selectedScene
        render.speed = look.speed; render.zoomSpeed = look.zoomSpeed; render.chaos = look.chaos
        render.brightness = look.brightness; render.particleSize = look.size; render.liquidDetail = look.detail
        render.fog = look.fog; render.zoom = look.zoom; render.palette = look.palette; render.strobeEnabled = false
    }
    private func tick() {
        guard let player else { return }
        let time = player.currentTime
        if abs(time - transport.seconds) >= 0.1 { transport.seconds = time }
        if transport.playing != player.isPlaying { transport.playing = player.isPlaying }
        render.paused = !player.isPlaying; render.playbackTime = time
        if player.isPlaying, let index = StudioTimeline.index(at: time, in: segments), project.clips.indices.contains(index) {
            let clip = project.clips[index]
            if selected != clip.id { selected = clip.id }
            if currentScene != clip.scene { applyAppearance() }
        }
        if let features = try? analyzer?.frame(at: time, clipStart: 0, clipEnd: player.duration) {
            render.audioBands = features.bands; render.audioPulse = features.pulse; render.audioSwell = features.swell
            render.audioEnvelopes = features.envelopes; render.audioMomentum = features.momentum
            render.audioBeatMotionTime = features.beatMotionTime; render.audioTreblePulse = features.treblePulse
            render.audioTrebleAttackTime = features.trebleAttackTime
        }
    }
    private func save() {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try JSONEncoder().encode(project).write(to: directory.appendingPathComponent("Studio-autosave.json"), options: .atomic)
        } catch { message = "Couldn't save this Studio session: \(error.localizedDescription)" }
    }
}
