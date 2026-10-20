import AVFoundation
import Combine
import MediaPlayer

/// One playback session for Studio and Radio, including lock-screen controls.
@MainActor final class MobilePlaybackSession {
    private weak var audio: AudioController?
    private weak var radio: RadioController?
    private var observations = Set<AnyCancellable>()
    private var commands: [(MPRemoteCommand, Any)] = []
    private var hasPlayed = false
    private var resumeAfterInterruption = false

    init(audio: AudioController, radio: RadioController) {
        self.audio = audio; self.radio = radio
        let center = MPRemoteCommandCenter.shared()
        bind(center.playCommand) { $0.play() }
        bind(center.pauseCommand) { $0.pause() }
        bind(center.togglePlayPauseCommand) { session in
            if session.audio?.isPlaying == true || session.radio?.isActive == true && session.radio?.isPlaybackRequested == true {
                session.pause()
            } else { session.play() }
        }
        bind(center.nextTrackCommand) { $0.radio?.next() }
        let seek = center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let seconds = event.positionTime
            Task { @MainActor [weak self] in self?.seek(seconds) }
            return .success
        }
        commands.append((center.changePlaybackPositionCommand, seek))
        audio.objectWillChange.sink { [weak self] _ in
            Task { @MainActor [weak self] in self?.publish() }
        }.store(in: &observations)
        radio.objectWillChange.sink { [weak self] _ in
            Task { @MainActor [weak self] in self?.publish() }
        }.store(in: &observations)
        audio.visualizationUpdated.throttle(for: .seconds(1), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in self?.publish() }.store(in: &observations)
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: RunLoop.main).sink { [weak self] in self?.interruption($0) }.store(in: &observations)
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .receive(on: RunLoop.main).sink { [weak self] notification in
                guard let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                      AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable else { return }
                self?.pause()
            }.store(in: &observations)
        publish()
    }

    private func bind(_ command: MPRemoteCommand, action: @escaping @MainActor (MobilePlaybackSession) -> Void) {
        let token = command.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in if let self { action(self); self.publish() } }
            return .success
        }
        commands.append((command, token))
    }
    private func play() {
        guard let audio else { return }
        if radio?.isActive == true {
            if radio?.isPlaybackRequested != true { radio?.togglePlayback() }
        } else if !audio.isPlaying { audio.playPause() }
    }
    private func pause() {
        resumeAfterInterruption = false
        if radio?.isActive == true { radio?.pause() } else { audio?.pause() }
    }
    private func seek(_ seconds: Double) {
        guard let audio, audio.duration > 0, seconds.isFinite else { return }
        if radio?.isActive == true { radio?.seek(fraction: seconds / audio.duration) }
        else { audio.seek(fraction: seconds / audio.duration) }
        publish()
    }
    private func interruption(_ notification: Notification) {
        guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        if type == .began {
            let shouldResume = audio?.isPlaying == true || radio?.isActive == true && radio?.isPlaybackRequested == true
            pause(); resumeAfterInterruption = shouldResume
        } else if type == .ended {
            let options = AVAudioSession.InterruptionOptions(rawValue: notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0)
            let shouldResume = resumeAfterInterruption && options.contains(.shouldResume)
            resumeAfterInterruption = false
            if shouldResume { play() }
        }
        publish()
    }
    private func publish() {
        guard let audio, let radio else { return }
        hasPlayed = hasPlayed || audio.isPlaying
        let ready = hasPlayed && audio.selectedURL != nil
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = ready
        center.pauseCommand.isEnabled = ready
        center.togglePlayPauseCommand.isEnabled = ready
        center.nextTrackCommand.isEnabled = ready && radio.isActive && !radio.isLoading
        center.previousTrackCommand.isEnabled = false
        center.changePlaybackPositionCommand.isEnabled = ready && (!radio.isActive || radio.canSeek)
        guard ready else {
            // Loading the demo paused must not take over another app's controls.
            if hasPlayed { MPNowPlayingInfoCenter.default().nowPlayingInfo = nil }
            return
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: radio.isActive ? radio.currentTrack?.title ?? "PulseCanvas Radio" : audio.title,
            MPMediaItemPropertyAlbumTitle: "PulseCanvas Studio",
            MPMediaItemPropertyPlaybackDuration: audio.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: audio.playbackSeconds,
            MPNowPlayingInfoPropertyPlaybackRate: audio.isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
            MPNowPlayingInfoPropertyIsLiveStream: false
        ]
    }
    deinit { for (command, token) in commands { command.removeTarget(token) } }
}
