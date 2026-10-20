import Foundation
import AVFoundation
import Combine
import CoreAudio

/// Ask the actual Mac audio server, rather than inspecting an engine's private state.
private func processHasRunningAudioOutput() throws -> Bool {
    var pid = getpid(), process = AudioObjectID(kAudioObjectUnknown)
    var size = UInt32(MemoryLayout<AudioObjectID>.size)
    var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyTranslatePIDToProcessObject,
        mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var result = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address,
        UInt32(MemoryLayout<pid_t>.size), &pid, &size, &process)
    guard result == noErr else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(result)) }
    guard process != kAudioObjectUnknown else { return false }
    address.mSelector = kAudioProcessPropertyIsRunningOutput
    var running: UInt32 = 0
    size = UInt32(MemoryLayout<UInt32>.size)
    result = AudioObjectGetPropertyData(process, &address, 0, nil, &size, &running)
    guard result == noErr else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(result)) }
    return running != 0
}

@main struct AudioSmoke {
    @MainActor static func main() async throws {
        let directory = URL(fileURLWithPath: CommandLine.arguments[1])
        let url = directory.appendingPathComponent("test-tone.caf")
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 132300)!
        buffer.frameLength = buffer.frameCapacity
        for channel in 0..<2 { for frame in 0..<Int(buffer.frameLength) { buffer.floatChannelData![channel][frame] = 0.4 * sin(Float(frame) * 2 * .pi * 440 / 44100) } }
        do { let file = try AVAudioFile(forWriting: url, settings: format.settings); try file.write(from: buffer) }
        let defaultAudio = AudioController()
        precondition(defaultAudio.loadDefaultSoundtrackIfNeeded())
        precondition(defaultAudio.selectedURL?.pathExtension == "mp3" && defaultAudio.title == "PulseCanvas")
        precondition(abs(defaultAudio.duration - 174.08) < 0.1 && !defaultAudio.isPlaying && defaultAudio.loopEnabled)
        defaultAudio.seek(fraction: 0.5)
        try await Task.sleep(nanoseconds: 100_000_000)
        precondition(defaultAudio.spectrum.max()! > 0.01, "Bundled MP3 must decode and drive visual analysis")
        let defaultPosition = defaultAudio.playbackSeconds
        precondition(defaultAudio.loadDefaultSoundtrackIfNeeded() && defaultAudio.playbackSeconds == defaultPosition)
        let bundledIdentifier = BundledSoundtrack.identifier(for: defaultAudio.selectedURL)
        precondition(bundledIdentifier == "pulsecanvas")
        let portableURL = try BundledSoundtrack.resolve(identifier: bundledIdentifier, externalURL: nil)
        precondition(portableURL == defaultAudio.selectedURL)
        let externalURL = try BundledSoundtrack.resolve(identifier: nil, externalURL: url)
        precondition(externalURL == url && BundledSoundtrack.identifier(for: url) == nil)
        do {
            _ = try BundledSoundtrack.resolve(identifier: "missing-track", externalURL: nil)
            preconditionFailure("Unknown bundled soundtracks must be rejected")
        } catch {}
        defaultAudio.clear()
        precondition(!defaultAudio.loadDefaultSoundtrackIfNeeded() && defaultAudio.selectedURL == nil,
                     "Clearing the default track must persist for this session")
        print("PASS bundled soundtrack: 174-second MP3 loads paused, decodes PCM, resolves portable project references and respects removal")
        let audio = AudioController()
        precondition(audio.loopEnabled, "Loop must start on")
        precondition(audio.load(url: url)); precondition(abs(audio.duration - 3) < 0.001)
        precondition(audio.loadDefaultSoundtrackIfNeeded() && audio.selectedURL == url && audio.duration == 3,
                     "Default loading must retain an imported or restored soundtrack")
        try await Task.sleep(nanoseconds: 100_000_000)
        let idleOutput = try processHasRunningAudioOutput()
        precondition(!idleOutput, "A loaded but paused Mac soundtrack must not run hardware output")
        precondition(audio.spectrum.max()! > 0.3, "Paused seek/load must analyze actual PCM")
        audio.playPause()
        var editorInvalidations = 0
        var visualizationFrames = 0
        let editorObserver = audio.objectWillChange.sink { editorInvalidations += 1 }
        let frameObserver = audio.visualizationUpdated.sink { visualizationFrames += 1 }
        try await Task.sleep(nanoseconds: 500_000_000)
        precondition(editorInvalidations == 0, "Audio telemetry must not invalidate the editor or preset buttons")
        precondition(visualizationFrames >= 10, "Renderer and Studio must still receive the audio clock")
        editorObserver.cancel(); frameObserver.cancel()
        print("PASS playback updates: renderer clock continues without editor/preset invalidations")
        precondition(audio.isPlaying && audio.playbackSeconds > 0.2 && audio.spectrum.max()! > 0.3)
        audio.pause(); let paused = audio.playbackSeconds
        try await Task.sleep(nanoseconds: 150_000_000)
        precondition(abs(paused - audio.playbackSeconds) < 0.01)
        let pausedOutput = try processHasRunningAudioOutput()
        precondition(!pausedOutput, "Pausing must release the Mac audio output callback")
        audio.playPause()
        try await Task.sleep(nanoseconds: 250_000_000)
        let resumedOutput = try processHasRunningAudioOutput()
        precondition(resumedOutput && audio.playbackSeconds > paused + 0.08 && audio.playbackSeconds < paused + 0.5,
                     "Resuming the hardware must continue at the paused position without a clock jump")
        audio.pause()
        print("PASS Mac hardware lifecycle: paused load and pause release output; resume retains the song position")
        audio.seek(fraction: 0.5)
        precondition(abs(audio.playbackSeconds - 1.5) < 0.01)
        audio.playPause()
        try await Task.sleep(nanoseconds: 300_000_000)
        precondition(audio.playbackSeconds > 1.6)
        audio.pause()
        precondition(audio.loopEnabled, "Loading and pausing must retain the default Loop setting")
        audio.loopEnabled = false
        audio.seek(fraction: 0.96); audio.playPause()
        try await Task.sleep(nanoseconds: 650_000_000)
        precondition(!audio.isPlaying && audio.progress == 1, "Playback with Loop off must stop at the end")
        audio.loopEnabled = true
        audio.seek(fraction: 0.96); audio.playPause()
        try await Task.sleep(nanoseconds: 650_000_000)
        precondition(audio.isPlaying && audio.playbackSeconds < 1, "Loop must restart at the beginning")
        precondition(audio.spectrum.max()! > 0.3, "Loop restart must resume PCM analysis")
        audio.pause(); let loopPaused = audio.playbackSeconds
        try await Task.sleep(nanoseconds: 200_000_000)
        precondition(!audio.isPlaying && abs(audio.playbackSeconds - loopPaused) < 0.01, "Pause must hold while Loop is on")
        audio.loopEnabled = false
        audio.seek(fraction: 0.96); audio.playPause()
        try await Task.sleep(nanoseconds: 650_000_000)
        precondition(!audio.isPlaying && audio.progress == 1, "Turning Loop off must stop at the next end")
        let boundary = 0.472
        audio.pause(); audio.seekToSection(start: boundary)
        precondition(audio.playbackSeconds >= boundary && audio.playbackSeconds < boundary + 0.00005, "Section seeking cannot land in the card to the left")
        for fullTrackLoop in [false, true] {
            audio.loopEnabled = fullTrackLoop
            var wraps = 0, previous = boundary
            let loopObserver = audio.visualizationUpdated.sink {
                if audio.playbackSeconds < previous - 0.1 { wraps += 1 }
                previous = audio.playbackSeconds
            }
            audio.playSection(start: boundary, end: 0.733)
            try await Task.sleep(nanoseconds: 1_000_000_000)
            loopObserver.cancel()
            precondition(audio.isPlaying && audio.previewSectionStart == boundary && wraps >= 2,
                         "Studio sections must repeat continuously, independently of the full-track Loop switch")
            precondition(audio.playbackSeconds >= boundary && audio.playbackSeconds < 0.733 && audio.spectrum.max()! > 0.3)
            audio.pause(); let sectionPaused = audio.playbackSeconds
            try await Task.sleep(nanoseconds: 350_000_000)
            precondition(!audio.isPlaying && audio.playbackSeconds == sectionPaused, "Pausing a section must prevent pending callbacks from restarting it")
        }
        audio.playSection(start: boundary, end: 0.733)
        try await Task.sleep(nanoseconds: 80_000_000)
        audio.playSection(start: boundary, end: 0.733)
        precondition(!audio.isPlaying, "Section Play must toggle pause independently")
        audio.playPause()
        try await Task.sleep(nanoseconds: 450_000_000)
        precondition(audio.isPlaying && audio.previewSectionStart == nil && audio.playbackSeconds > 0.733, "Normal playback must resume beyond the section")
        audio.pause()
        audio.playSection(start: boundary, end: 0.733)
        audio.seekToSection(start: 1.123)
        try await Task.sleep(nanoseconds: 450_000_000)
        precondition(audio.isPlaying && audio.playbackSeconds > 1.123 && audio.previewSectionStart == nil, "Seeking must invalidate the previous section's pending stop")
        audio.pause()
        print("PASS Studio audio: repeated section loops with full-track Loop off/on, fractional boundaries, PCM analysis, independent pause, normal resume and stale callback invalidation")
        audio.loopEnabled = false
        audio.selectSection(start: 1.123, end: 1.433)
        precondition(!audio.isPlaying && audio.playbackSeconds >= 1.123 && audio.playbackSeconds < 1.12305)
        let selectedPaused = audio.playbackSeconds
        try await Task.sleep(nanoseconds: 350_000_000)
        precondition(!audio.isPlaying && audio.playbackSeconds == selectedPaused, "Selecting a paused card must not start playback")
        audio.playSection(start: boundary, end: 0.733)
        try await Task.sleep(nanoseconds: 80_000_000)
        audio.selectSection(start: 1.123, end: 1.433)
        precondition(audio.isPlaying && audio.previewSectionStart == 1.123 && audio.playbackSeconds >= 1.123 && audio.playbackSeconds < 1.12305)
        try await Task.sleep(nanoseconds: 750_000_000)
        precondition(audio.isPlaying && audio.previewSectionStart == 1.123 && audio.playbackSeconds >= 1.123 && audio.playbackSeconds < 1.433 && audio.spectrum.max()! > 0.3,
                     "Selecting another card must loop its audio and invalidate the previous loop's callbacks")
        audio.selectSection(start: 1.123, end: 1.433)
        precondition(audio.isPlaying && audio.previewSectionStart == 1.123, "Selecting the playing card must not toggle it off")
        audio.pause(); audio.selectSection(start: boundary, end: 0.733)
        try await Task.sleep(nanoseconds: 350_000_000)
        precondition(!audio.isPlaying && audio.playbackSeconds >= boundary && audio.playbackSeconds < boundary + 0.00005 && !audio.loopEnabled)
        audio.playFullSoundtrack(); audio.selectSection(start: 1.123, end: 1.433)
        precondition(audio.isPlaying && audio.previewSectionStart == 1.123, "Selecting during full playback must keep playing the chosen section")
        audio.selectSection(start: .nan, end: 1.433)
        precondition(audio.isPlaying && audio.previewSectionStart == 1.123, "Invalid selection must leave playback unchanged")
        audio.pause(); audio.loopEnabled = true
        print("PASS Studio card selection: paused preview stays paused, running playback switches and loops the chosen card, same-card selection stays playing, PCM/bounds and stale callbacks verified")
        audio.playSection(start: boundary, end: 0.733, restart: true)
        precondition(audio.isPlaying && audio.previewSectionStart == boundary && audio.loopEnabled)
        try await Task.sleep(nanoseconds: 80_000_000)
        precondition(audio.playbackSeconds > boundary + 0.02)
        audio.playSection(start: boundary, end: 0.733, restart: true)
        precondition(audio.isPlaying && audio.previewSectionStart == boundary && audio.playbackSeconds >= boundary && audio.playbackSeconds < boundary + 0.00005, "Dice/shuffle must restart a playing section, not toggle it off")
        try await Task.sleep(nanoseconds: 80_000_000)
        audio.playSection(start: boundary, end: 0.733, restart: true)
        precondition(audio.isPlaying && audio.playbackSeconds < boundary + 0.00005, "Repeated rolls must continue to restart and play")
        try await Task.sleep(nanoseconds: 450_000_000)
        precondition(audio.isPlaying && audio.previewSectionStart == boundary && audio.playbackSeconds >= boundary && audio.playbackSeconds < 0.733, "Restart retains and loops the selected section bounds")
        print("PASS Studio replay: rolls restart paused/playing sections from their exact start, preserve Loop and invalidate stale completion callbacks")

        audio.pause()
        audio.loopEnabled = false
        audio.playSection(start: boundary, end: 0.733)
        audio.playFullSoundtrack()
        precondition(audio.isPlaying && audio.previewSectionStart == nil && !audio.loopEnabled, "Presentation must clear bounded section playback and retain Loop")
        try await Task.sleep(nanoseconds: 450_000_000)
        precondition(audio.isPlaying && audio.playbackSeconds > 0.733, "Presentation must continue across Studio boundaries")
        audio.pause(); audio.seek(fraction: 0.99); audio.playFullSoundtrack()
        try await Task.sleep(nanoseconds: 250_000_000)
        precondition(!audio.isPlaying && audio.progress == 1, "Presentation must finish at track end with Loop off")
        audio.playFullSoundtrack()
        precondition(audio.isPlaying && audio.playbackSeconds < 0.05, "Presentation must restart an ended soundtrack")
        audio.pause()
        print("PASS presentation audio: resumes full soundtrack beyond section, retains Loop, stops at end and restarts")
        audio.loopEnabled = true; audio.seek(fraction: 0.99); audio.playPause()
        audio.clear(); precondition(audio.selectedURL == nil && audio.duration == 0 && !audio.isPlaying)
        try await Task.sleep(nanoseconds: 350_000_000)
        precondition(!audio.isPlaying && audio.selectedURL == nil, "Clear must invalidate pending loop callbacks")
        print("PASS Loop: on by default, end stop when disabled, repeat with PCM analysis, pause, disable, clear")
        print("PASS soundtrack: load, paused analysis, real FFT, playback, pause, seek, resume, clear")

        let music = AudioController()
        let continuousPrepared = try PreparedSoundtrack(url: url)
        precondition(music.install(continuousPrepared, title: "Continuous Radio", playback: .radio))
        precondition(!music.isPlaying && music.title == "Continuous Radio")
        music.volume = 0.1
        music.playFullSoundtrack()
        try await Task.sleep(for: .milliseconds(350))
        precondition(music.isPlaying && music.playbackSeconds > 0.1 && music.spectrum.max()! > 0.3)
        music.pause(); let held = music.playbackSeconds
        try await Task.sleep(for: .milliseconds(150))
        precondition(!music.isPlaying && music.playbackSeconds == held)
        // Rapid scrubs may complete out of order on the asynchronous Mac player.
        music.seek(fraction: 0.8); music.seek(fraction: 0.2); music.seek(fraction: 0.6)
        try await Task.sleep(for: .milliseconds(250))
        precondition(!music.isPlaying && abs(music.playbackSeconds - music.duration * 0.6) < 0.001,
                     "A completed stale seek must not replace the latest paused scrub target")
        music.seek(fraction: 0.5)
        precondition(abs(music.playbackSeconds - music.duration * 0.5) < 0.001)
        music.playFullSoundtrack()
        try await Task.sleep(for: .milliseconds(150))
        precondition(music.isPlaying && music.playbackSeconds > held)
        var completions = 0
        music.onSoundtrackFinished = { completions += 1 }
        music.seek(fraction: 0.95)
        try await Task.sleep(for: .milliseconds(600))
        precondition(completions == 1 && !music.isPlaying && music.progress == 1,
            "Radio owns end-of-song even when Studio Loop is on")
        music.onSoundtrackFinished = nil; music.loopEnabled = true
        music.playFullSoundtrack(); music.seek(fraction: 0.95)
        try await Task.sleep(for: .milliseconds(600))
        precondition(music.isPlaying && music.playbackSeconds < 1, "Continuous playback must also honor normal full-song looping")
        music.playSection(start: boundary, end: 0.733, restart: true)
        try await Task.sleep(for: .milliseconds(600))
        precondition(music.isPlaying && music.previewSectionStart == boundary && music.playbackSeconds < 0.733,
            "Entering a Studio section from Radio must restore precise engine playback")
        music.clear()
        print("PASS continuous Radio playback: independent file player, clock/FFT, volume, pause/seek/resume, completion, full-song loop and precise Studio handoff")
    }
}
