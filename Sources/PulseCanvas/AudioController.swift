import Foundation
import AVFoundation
import Combine

/// Mobile AVAudioPlayer callbacks are independent of the Studio engine.
@MainActor private final class RadioPlaybackCompletion: NSObject, AVAudioPlayerDelegate {
    var finished: ((AVAudioPlayer, Bool) -> Void)?
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self, weak player] in
            guard let player else { return }
            self?.finished?(player, flag)
        }
    }
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self, weak player] in
            guard let player else { return }
            self?.finished?(player, false)
        }
    }
}

enum SoundtrackPlayback { case studio, radio }

#if os(macOS)
/// File playback through the Mac media pipeline. Audio decoding/output stays off
/// the visualization clock; seeks publish their target until AVPlayer finishes.
@MainActor private final class MacRadioPlayback {
    private let player: AVPlayer
    private let item: AVPlayerItem
    private var observers: [NSObjectProtocol] = []
    private var statusObserver: NSKeyValueObservation?
    private var pendingTime: Double?
    private var seekRevision = UUID()
    private(set) var isPlaying = false
    let duration: Double
    var finished: ((Bool) -> Void)?
    var volume: Float { get { player.volume } set { player.volume = newValue } }
    var currentTime: Double {
        get {
            if let pendingTime { return pendingTime }
            let time = player.currentTime().seconds
            return time.isFinite ? min(duration, max(0, time)) : 0
        }
        set {
            let target = min(duration, max(0, newValue))
            let revision = UUID(); seekRevision = revision; pendingTime = target
            player.seek(to: CMTime(seconds: target, preferredTimescale: 600_000),
                        toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, self.seekRevision == revision else { return }
                    self.pendingTime = nil
                }
            }
        }
    }

    init(url: URL, duration: Double) {
        self.duration = duration
        item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player.actionAtItemEnd = .pause
        // Radio plays complete local copies, including downloaded catalog music.
        player.automaticallyWaitsToMinimizeStalling = false
        observers.append(NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, self.pendingTime == nil,
                          self.currentTime >= self.duration - 0.1 else { return }
                    self.complete(success: true)
                }
            })
        observers.append(NotificationCenter.default.addObserver(forName: AVPlayerItem.failedToPlayToEndTimeNotification,
            object: item, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.complete(success: false) }
            })
        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .failed else { return }
            Task { @MainActor [weak self] in self?.complete(success: false) }
        }
    }
    deinit { observers.forEach(NotificationCenter.default.removeObserver); player.pause() }
    func prepareToPlay() -> Bool { item.status != .failed }
    func play() -> Bool {
        guard item.status != .failed else { return false }
        isPlaying = true; player.play(); return true
    }
    func pause() { isPlaying = false; player.pause() }
    func stop() { pause(); currentTime = 0 }
    private func complete(success: Bool) {
        guard isPlaying else { return }
        isPlaying = false; player.pause(); finished?(success)
    }
}
private typealias ContinuousAudioPlayer = MacRadioPlayback
#else
private typealias ContinuousAudioPlayer = AVAudioPlayer
#endif

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
    @Published var volume: Float = 0.7 {
        didSet {
            let gain = volume.isFinite ? min(1, max(0, volume)) : 0
            engine.mainMixerNode.outputVolume = gain
            continuousPlayer?.volume = gain
        }
    }
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var continuousPlayer: ContinuousAudioPlayer?
    private let continuousCompletion = RadioPlaybackCompletion()
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
    func install(_ prepared: PreparedSoundtrack, title displayTitle: String? = nil, playback: SoundtrackPlayback = .studio) -> Bool {
        do {
            let opened = prepared.file, url = prepared.url
            #if os(macOS)
            let radioPlayer = playback == .radio ? MacRadioPlayback(url: url,
                duration: Double(opened.length) / opened.processingFormat.sampleRate) : nil
            #else
            let radioPlayer = playback == .radio ? try AVAudioPlayer(contentsOf: url) : nil
            #endif
            stop()
            // Format changes must happen while the Studio graph is stopped.
            engine.stop(); continuousPlayer = nil
            analyzer = prepared.analyzer
            file = opened
            if let radioPlayer {
                guard radioPlayer.duration.isFinite, radioPlayer.duration > 0 else { throw SoundtrackError.empty }
                radioPlayer.volume = volume.isFinite ? min(1, max(0, volume)) : 0
                #if os(macOS)
                radioPlayer.finished = { [weak self, weak radioPlayer] success in
                    guard let radioPlayer else { return }
                    self?.radioPlaybackFinished(radioPlayer, succeeded: success)
                }
                #else
                radioPlayer.numberOfLoops = 0
                radioPlayer.delegate = continuousCompletion
                continuousCompletion.finished = { [weak self] completed, success in
                    self?.radioPlaybackFinished(completed, succeeded: success)
                }
                #endif
                guard radioPlayer.prepareToPlay() else { throw SoundtrackError.cannotPrepare }
                continuousPlayer = radioPlayer
            } else {
                prepareStudioEngine(for: opened)
            }
            soundtrackAccess = prepared.access
            soundtrackBookmark = BundledSoundtrack.identifier(for: url) == nil ? try? prepared.access.readOnlyBookmark() : nil
            selectedURL = url
            title = displayTitle ?? url.deletingPathExtension().lastPathComponent
            duration = radioPlayer?.duration ?? Double(opened.length) / opened.processingFormat.sampleRate
            schedule(from: 0, playing: false)
            analyze(frame: 0)
            status = "Soundtrack ready"
            return true
        } catch { status = "Cannot open soundtrack: \(error.localizedDescription)"; return false }
    }

    func clear() {
        stop(); continuousPlayer = nil; continuousCompletion.finished = nil; file = nil; analyzer = nil; selectedURL = nil; title = "Add a soundtrack"; duration = 0
        soundtrackAccess = nil; soundtrackBookmark = nil
        engine.stop(); status = "Choose music to sync your visuals"
    }

    func segmentPlan(beatsPerSection: Int = 16) -> SongSegmentation? {
        guard let plan = analyzer?.segmentPlan(beatsPerSection: beatsPerSection) else { return nil }
        guard continuousPlayer != nil else { return plan }
        // Container priming can make a player's audible duration differ by
        // a few samples from AVAudioFile. End Radio scenes on the playback clock.
        return SongSegmentation(boundaries: plan.boundaries.filter { $0 < duration } + [duration], bpm: plan.bpm)
    }

    private func prepareStudioEngine(for file: AVAudioFile) {
        engine.stop()
        engine.disconnectNodeOutput(player)
        engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
        engine.prepare()
    }

    private func radioPlaybackFinished(_ completed: ContinuousAudioPlayer, succeeded: Bool) {
        guard continuousPlayer === completed, isPlaying, !completed.isPlaying else { return }
        if succeeded { finishSoundtrack() }
        else { isPlaying = false; status = "Audio playback stopped unexpectedly" }
    }

    private func activatePlaybackSession() throws {
        #if !os(macOS)
        let session = AVAudioSession.sharedInstance()
        if session.category != .playback { try session.setCategory(.playback, mode: .default) }
        try session.setActive(true)
        #endif
    }

    private func startPlaybackEngine() -> Bool {
        do {
            if !engine.isRunning { try activatePlaybackSession(); try engine.start() }
            return true
        } catch { status = "Audio playback couldn't start: \(error.localizedDescription)"; return false }
    }
    func playPause() {
        guard file != nil else { return }
        if let continuousPlayer {
            if isPlaying {
                updateProgress(); continuousPlayer.pause(); isPlaying = false; status = "Paused"
            } else {
                do {
                    try activatePlaybackSession()
                    if progress >= 0.9999 { continuousPlayer.currentTime = 0; progress = 0; playbackSeconds = 0 }
                    isPlaying = continuousPlayer.play()
                    status = isPlaying ? "Playing soundtrack" : "Audio playback couldn't start"
                } catch { status = "Audio playback couldn't start: \(error.localizedDescription)" }
            }
            return
        }
        if !isPlaying && !startPlaybackEngine() { return }
        if isPlaying {
            updateProgress(); player.pause()
            #if os(macOS)
            // A paused player alone leaves the Mac hardware's I/O callback active.
            engine.pause()
            #endif
            isPlaying = false; status = "Paused"
        }
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
        generation = UUID(); player.stop(); continuousPlayer?.stop(); continuousPlayer?.currentTime = 0; isPlaying = false; segmentStart = 0
        #if os(macOS)
        engine.pause()
        #endif
        previewSectionStart = nil; previewSectionEnd = nil
        progress = 0; playbackSeconds = 0; spectrum = [Float](repeating: 0, count: 32); beatPulse = 0; momentum = 0; beatMotionTime = 0; envelopes = .zero; swell = 0; treblePulse = 0; trebleAttackTime = nil
        visualizationUpdated.send()
    }

    /// Loop the selected section until paused or replaced; style controls restart it.
    func playSection(start: Double, end: Double, restart: Bool = false) {
        guard let file, start.isFinite, end.isFinite, start >= 0, end > start, end <= duration + 0.001 else { return }
        if !restart && isPlaying && previewSectionStart == start { pause(); return }
        if continuousPlayer != nil {
            continuousPlayer?.stop(); continuousPlayer = nil; continuousCompletion.finished = nil
            prepareStudioEngine(for: file)
        }
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
        guard fraction.isFinite else { return }
        let fraction = min(1, max(0, fraction))
        let frame = continuousPlayer == nil ? fraction * Double(file.length) : fraction * duration * file.processingFormat.sampleRate
        seek(frame: min(file.length - 1, AVAudioFramePosition(frame)))
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
        playbackSeconds = continuousPlayer?.currentTime ?? Double(frame) / file.processingFormat.sampleRate
        progress = duration > 0 ? playbackSeconds / duration : 0
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
        if let continuousPlayer {
            generation = UUID(); previewSectionStart = nil; previewSectionEnd = nil
            continuousPlayer.currentTime = min(duration, Double(start) / file.processingFormat.sampleRate)
            if playing {
                do { try activatePlaybackSession(); isPlaying = continuousPlayer.play() }
                catch { isPlaying = false; status = "Audio playback couldn't start: \(error.localizedDescription)" }
            } else { continuousPlayer.pause(); isPlaying = false }
            return
        }
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
                self.finishSoundtrack()
            }
        }
        if playing { player.play() }
        isPlaying = playing
    }

    private func finishSoundtrack() {
        let finished = isPlaying ? onSoundtrackFinished : nil
        if isPlaying && loopEnabled && finished == nil {
            schedule(from: 0, playing: true)
            progress = 0; playbackSeconds = 0; analyze(frame: 0)
            status = "Playing soundtrack · Looping"
            return
        }
        isPlaying = false; progress = 1; playbackSeconds = duration
        #if os(macOS)
        engine.pause()
        #endif
        beatPulse = 0; momentum = 0; envelopes = .zero; swell = 0; treblePulse = 0; trebleAttackTime = nil
        spectrum = [Float](repeating: 0, count: 32)
        visualizationUpdated.send(); status = "End of soundtrack"
        finished?()
    }

    private func updateProgress(fromTimer: Bool = false) {
        if fromTimer && !visualizationEnabled {
            let now = ProcessInfo.processInfo.systemUptime
            guard now - lastBackgroundProgressRefresh >= 1 else { return }
            lastBackgroundProgressRefresh = now
        }
        if let continuousPlayer {
            guard isPlaying, let file else { return }
            playbackSeconds = min(duration, max(0, continuousPlayer.currentTime))
            progress = duration > 0 ? playbackSeconds / duration : 0
            analyze(frame: AVAudioFramePosition(playbackSeconds * file.processingFormat.sampleRate))
            return
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
    case empty, cannotPrepare
    var errorDescription: String? {
        switch self {
        case .empty: return "This file has no audio samples."
        case .cannotPrepare: return "This soundtrack couldn't be prepared for playback."
        }
    }
}
