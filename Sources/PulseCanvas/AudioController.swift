import Foundation
import AVFoundation
import Combine

/// A single project soundtrack, with real PCM analysis for the preview.
@MainActor
final class AudioController: ObservableObject {
    @Published private(set) var selectedURL: URL?
    @Published private(set) var title = "Add a soundtrack"
    @Published private(set) var duration = 0.0
    @Published private(set) var isPlaying = false
    private(set) var progress = 0.0
    private(set) var playbackSeconds = 0.0
    @Published private(set) var status = "Choose music to sync your visuals"
    private(set) var spectrum = [Float](repeating: 0, count: 32)
    private(set) var beatPulse: Float = 0
    private(set) var trebleAttackTime: Double? = nil
    private(set) var treblePulse: Float = 0
    private(set) var momentum: Float = 0
    private(set) var beatMotionTime: Double = 0
    private(set) var envelopes = SIMD4<Float>(repeating: 0)
    private(set) var swell: Float = 0
    @Published private(set) var previewSectionStart: Double?
    // High-rate audio data bypasses ObservableObject; only playback widgets observe it.
    let visualizationUpdated = PassthroughSubject<Void, Never>()
    private var visualizationEnabled = true
    private var lastBackgroundProgressRefresh: TimeInterval = 0
    /// Background listening keeps its playback clock and completion callbacks,
    /// without spending CPU on audio features for an invisible renderer.
    func setVisualizationEnabled(_ enabled: Bool) {
        visualizationEnabled = enabled
        if enabled { updateProgress() }
    }
    private var previewSectionEnd: Double?
    @Published var loopEnabled = true
    /// Radio owns full-song completion; bounded Studio previews still loop normally.
    var onSoundtrackFinished: (() -> Void)?
    @Published var volume: Float = 0.7 { didSet { engine.mainMixerNode.outputVolume = min(1, max(0, volume)) } }
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var file: AVAudioFile?
    private var analyzer: SoundtrackAnalyzer?
    private var segmentStart: AVAudioFramePosition = 0
    private var generation = UUID()
    private var timer: Timer?
    private var attemptedDefaultSoundtrack = false
    private var soundtrackAccess: SecurityScopedAccess?
    private(set) var soundtrackBookmark: Data?

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        engine.mainMixerNode.outputVolume = volume
        timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.updateProgress(fromTimer: true) }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    @discardableResult
    func loadDefaultSoundtrackIfNeeded() -> Bool {
        guard !attemptedDefaultSoundtrack else { return selectedURL != nil }
        attemptedDefaultSoundtrack = true
        guard selectedURL == nil else { return true }
        guard let url = BundledSoundtrack.url else { return false }
        return load(url: url)
    }

    @discardableResult
    func load(url: URL, bookmark: Data? = nil) -> Bool {
        do {
            let url = SecurityScopedAccess.resolve(bookmark: bookmark, fallback: url)
            return install(try PreparedSoundtrack(url: url))
        } catch { status = "Cannot open soundtrack: \(error.localizedDescription)"; return false }
    }

    /// Prepared on a worker, then transferred exclusively to the playback actor.
    @discardableResult
    func install(_ prepared: PreparedSoundtrack, title displayTitle: String? = nil) -> Bool {
        do {
            let opened = prepared.file, url = prepared.url
            stop()
            analyzer = prepared.analyzer
            file = opened
            engine.disconnectNodeOutput(player)
            engine.connect(player, to: engine.mainMixerNode, format: opened.processingFormat)
            engine.prepare()
            #if os(macOS)
            try engine.start()
            #endif
            soundtrackAccess = prepared.access
            soundtrackBookmark = BundledSoundtrack.identifier(for: url) == nil ? try? prepared.access.readOnlyBookmark() : nil
            selectedURL = url
            title = displayTitle ?? url.deletingPathExtension().lastPathComponent
            duration = Double(opened.length) / opened.processingFormat.sampleRate
            schedule(from: 0, playing: false)
            analyze(frame: 0)
            status = "Soundtrack ready"
            return true
        } catch { status = "Cannot open soundtrack: \(error.localizedDescription)"; return false }
    }

    func clear() {
        stop(); file = nil; analyzer = nil; selectedURL = nil; title = "Add a soundtrack"; duration = 0
        soundtrackAccess = nil; soundtrackBookmark = nil
        engine.stop(); status = "Choose music to sync your visuals"
    }

    func segmentPlan(beatsPerSection: Int = 16) -> SongSegmentation? { analyzer?.segmentPlan(beatsPerSection: beatsPerSection) }

    private func startPlaybackEngine() -> Bool {
        do {
            #if !os(macOS)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            if !engine.isRunning { try engine.start() }
            return true
        } catch { status = "Audio playback couldn't start: \(error.localizedDescription)"; return false }
    }
    func playPause() {
        guard file != nil else { return }
        if !isPlaying && !startPlaybackEngine() { return }
        if isPlaying { updateProgress(); player.pause(); isPlaying = false; status = "Paused" }
        else {
            if progress >= 0.9999 { schedule(from: 0, playing: true) }
            else {
                if previewSectionStart != nil { seek(fraction: progress) }
                player.play(); isPlaying = true
            }
            status = "Playing soundtrack"
        }
    }

    /// Leave any bounded section preview and play the complete Studio timeline.
    func playFullSoundtrack() {
        guard file != nil else { return }
        seek(fraction: progress >= 0.9999 ? 0 : progress)
        if !isPlaying { playPause() }
    }

    func pause() { if isPlaying { playPause() } }

    func stop() {
        generation = UUID(); player.stop(); isPlaying = false; segmentStart = 0
        previewSectionStart = nil; previewSectionEnd = nil
        progress = 0; playbackSeconds = 0; spectrum = [Float](repeating: 0, count: 32); beatPulse = 0; momentum = 0; beatMotionTime = 0; envelopes = .zero; swell = 0; treblePulse = 0; trebleAttackTime = nil
        visualizationUpdated.send()
    }

    /// Loop the selected section until paused or replaced; style controls restart it.
    func playSection(start: Double, end: Double, restart: Bool = false) {
        guard let file, start.isFinite, end.isFinite, start >= 0, end > start, end <= duration + 0.001 else { return }
        if !restart && isPlaying && previewSectionStart == start { pause(); return }
        let rate = file.processingFormat.sampleRate
        let first = min(file.length - 1, AVAudioFramePosition(start == 0 ? 0 : ceil((start * rate).nextUp)))
        let last = min(file.length, AVAudioFramePosition(end * rate))
        guard last > first else { return }
        previewSectionStart = start; previewSectionEnd = end
        progress = Double(first) / Double(file.length); playbackSeconds = Double(first) / rate
        analyze(frame: first)
        schedule(from: first, playing: true, end: last)
        status = "Playing Studio section · Looping"
    }

    /// Selecting a card preserves playback: switch a running loop, or seek while paused.
    func selectSection(start: Double, end: Double) {
        guard file != nil, start.isFinite, end.isFinite, start >= 0, end > start, end <= duration + 0.001 else { return }
        if isPlaying { playSection(start: start, end: end, restart: true) }
        else { seekToSection(start: start) }
    }

    func seek(fraction: Double) {
        guard let file else { return }
        let fraction = min(1, max(0, fraction))
        seek(frame: min(file.length - 1, AVAudioFramePosition(fraction * Double(file.length))))
    }

    func seekToSection(start: Double) {
        guard let file, start.isFinite, start >= 0, start < duration else { return }
        let rate = file.processingFormat.sampleRate
        // Stay inside the selected section when its boundary lies between samples.
        let first = start == 0 ? 0 : ceil((start * rate).nextUp)
        seek(frame: min(file.length - 1, AVAudioFramePosition(first)))
    }

    private func seek(frame: AVAudioFramePosition) {
        guard let file else { return }
        previewSectionStart = nil; previewSectionEnd = nil
        schedule(from: frame, playing: isPlaying)
        progress = Double(frame) / Double(file.length)
        playbackSeconds = Double(frame) / file.processingFormat.sampleRate
        analyze(frame: frame)
    }

    func visualizationPCM(at time: Double) -> [Float] { (try? analyzer?.pcm(at: time)) ?? [] }

    private func analyze(frame: AVAudioFramePosition) {
        defer { visualizationUpdated.send() }
        guard visualizationEnabled else { return }
        guard let file, let analyzer else { return }
        do {
            let features = try analyzer.frame(at: Double(frame) / file.processingFormat.sampleRate,
                                              clipStart: 0, clipEnd: duration)
            spectrum = features.bands
            beatPulse = features.pulse
            momentum = features.momentum
            beatMotionTime = features.beatMotionTime
            envelopes = features.envelopes; swell = features.swell
            trebleAttackTime = features.trebleAttackTime
            treblePulse = features.treblePulse
        } catch {
            spectrum = [Float](repeating: 0, count: 32); beatPulse = 0; momentum = 0; beatMotionTime = 0; envelopes = .zero; swell = 0; treblePulse = 0; trebleAttackTime = nil
            status = "Audio analysis failed: \(error.localizedDescription)"
        }
    }

    private func schedule(from start: AVAudioFramePosition, playing: Bool, end: AVAudioFramePosition? = nil) {
        guard let file else { return }
        if playing && !startPlaybackEngine() { return }
        if end == nil { previewSectionStart = nil; previewSectionEnd = nil }
        generation = UUID(); let token = generation
        player.stop(); segmentStart = start
        let remaining = AVAudioFrameCount(min(Int64(UInt32.max), (end ?? file.length) - start))
        player.scheduleSegment(file, startingFrame: start, frameCount: remaining, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == token else { return }
                if let end {
                    guard self.isPlaying else { return }
                    self.schedule(from: start, playing: true, end: end)
                    self.playbackSeconds = Double(start) / file.processingFormat.sampleRate
                    self.progress = self.playbackSeconds / self.duration
                    self.analyze(frame: start)
                    self.status = "Playing Studio section · Looping"
                    return
                }
                let finished = self.isPlaying ? self.onSoundtrackFinished : nil
                if self.isPlaying && self.loopEnabled && finished == nil {
                    self.schedule(from: 0, playing: true)
                    self.progress = 0; self.playbackSeconds = 0
                    self.analyze(frame: 0)
                    self.status = "Playing soundtrack · Looping"
                    return
                }
                self.isPlaying = false; self.progress = 1; self.playbackSeconds = self.duration
                self.beatPulse = 0; self.momentum = 0; self.envelopes = .zero; self.swell = 0; self.treblePulse = 0; self.trebleAttackTime = nil; self.spectrum = [Float](repeating: 0, count: 32)
                self.visualizationUpdated.send()
                self.status = "End of soundtrack"
                finished?()
            }
        }
        if playing { player.play() }
        isPlaying = playing
    }

    private func updateProgress(fromTimer: Bool = false) {
        if fromTimer && !visualizationEnabled {
            let now = ProcessInfo.processInfo.systemUptime
            guard now - lastBackgroundProgressRefresh >= 1 else { return }
            lastBackgroundProgressRefresh = now
        }
        guard isPlaying, let file, let time = player.lastRenderTime, let position = player.playerTime(forNodeTime: time) else { return }
        playbackSeconds = min(previewSectionEnd.map { max(0, $0 - 1 / file.processingFormat.sampleRate) } ?? duration, max(0, Double(segmentStart) / file.processingFormat.sampleRate + max(0, Double(position.sampleTime) / file.processingFormat.sampleRate - player.outputPresentationLatency)))
        progress = duration > 0 ? playbackSeconds / duration : 0
        analyze(frame: AVAudioFramePosition(playbackSeconds * file.processingFormat.sampleRate))
    }
}

/// The worker must relinquish this object before the main actor installs it.
/// AVAudioFile and its analyzer are never accessed concurrently.
final class PreparedSoundtrack: @unchecked Sendable {
    let url: URL
    let access: SecurityScopedAccess
    let file: AVAudioFile
    let analyzer: SoundtrackAnalyzer
    init(url: URL) throws {
        self.url = url
        access = SecurityScopedAccess(url: url)
        file = try AVAudioFile(forReading: url)
        guard file.length > 0 else { throw SoundtrackError.empty }
        analyzer = try SoundtrackAnalyzer(url: url)
    }
}

private enum SoundtrackError: LocalizedError {
    case empty
    var errorDescription: String? { "This file has no audio samples." }
}
