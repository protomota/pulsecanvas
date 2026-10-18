import Foundation
import CryptoKit

@main struct VisionTransportSmoke {
    @MainActor static func main() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("VisionStudio-test-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let suite = "VisionStudio-test-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let presets = ProjectMPresets(defaults: defaults)
        let studio = VisionStudio(directory: directory, library: presets)
        studio.volume = 0
        await studio.importAudio(URL(fileURLWithPath: "Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3"))
        precondition(studio.message == nil && studio.transport.duration > 30 && !studio.loading)
        precondition(studio.project.clips.count > 1 && studio.project.beatBoundaries != nil)
        let first = studio.project.clips[0]
        studio.bars(2, clip: first.id)
        precondition(studio.project.clips[0].bars == 2)
        studio.assign(22); studio.updateLook { $0.chaos = 0.91; $0.palette = 3 }
        precondition(studio.render.scene == 22 && studio.render.chaos == 0.91 && studio.render.palette == 3)
        let savedLooks = studio.project.looks
        let category = presets.category(for: 22)
        presets.setRandomizerGroup(.category(category))
        let eligible = Set(presets.filteredScenes())
        precondition(!eligible.isEmpty && eligible.allSatisfy { presets.category(for: $0) == category })
        for _ in 0..<30 {
            precondition(studio.randomizeVisualizer() && eligible.contains(studio.selectedScene))
            precondition(studio.project.looks == savedLooks, "Switching a visualizer must not randomize settings")
        }
        presets.setRandomizerGroup(.favorites)
        precondition(presets.filteredScenes().isEmpty && !studio.randomizeVisualizer())
        presets.toggleFavorite(22)
        precondition(presets.filteredScenes() == [22] && studio.randomizeVisualizer() && studio.selectedScene == 22)
        let barsBefore = studio.project.clips.map(\.bars)
        studio.randomizeLook()
        precondition(studio.look.isValid && studio.look != savedLooks[22] && studio.project.clips.map(\.bars) == barsBefore)
        studio.updateLook { $0.chaos = 0.91; $0.palette = 3 }
        presets.setRandomizerGroup(.all)
        precondition(presets.filteredScenes().count == NativeEffects.activeCount)
        let count = studio.project.clips.count
        studio.addClip(); precondition(studio.project.clips.count == count + 1)
        studio.assign(22); precondition(studio.look.chaos == 0.91)
        studio.moveClip(1); studio.removeClip(); precondition(studio.project.clips.count == count)
        studio.seek(8); precondition(abs(studio.transport.seconds - 8) < 0.05)
        precondition(studio.render.audioBands.contains { $0 > 0 })
        studio.togglePlayback()
        try await Task.sleep(for: .milliseconds(350))
        precondition(studio.transport.playing && (studio.render.playbackTime ?? 0) > 8.1)
        studio.suspend(); precondition(!studio.transport.playing && studio.render.paused)
        var completions = 0
        studio.onPlaybackFinished = { completions += 1 }
        studio.loopPlayback = true
        studio.seek(studio.transport.duration - 0.2); studio.togglePlayback()
        try await Task.sleep(for: .milliseconds(650))
        precondition(studio.transport.playing && studio.transport.seconds < 2 && studio.selectedIndex == 0)
        precondition(completions == 0, "Looping must not finish or stop at the track boundary")
        studio.loopPlayback = false
        studio.seek(studio.transport.duration - 0.2)
        try await Task.sleep(for: .milliseconds(650))
        precondition(!studio.transport.playing && completions == 1)
        let restored = VisionStudio(directory: directory, library: presets)
        restored.volume = 0; await restored.start()
        precondition(restored.message == nil && restored.project.looks[22]?.chaos == 0.91)
        precondition(restored.project.clips.count == count && restored.transport.duration > 30)
        precondition(!restored.loopPlayback, "Loop preference must survive autosave restoration")
        let filesBefore = Set(try FileManager.default.contentsOfDirectory(atPath: directory.path))
        let loaded = await studio.loadRadioAudio(URL(fileURLWithPath: "Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3"), title: "Cached Radio test")
        precondition(loaded && studio.project.audioTitle == "Cached Radio test" && studio.project.audioFile == nil)
        let filesAfter = Set(try FileManager.default.contentsOfDirectory(atPath: directory.path))
        precondition(filesAfter == filesBefore,
                     "Radio playback must not duplicate cached audio on each song")
        precondition(!studio.transport.playing && studio.render.audioBands.count == 32)
        print("PASS cached Radio audio: title, analysis, paused start, no duplicate audio copies")
        // Local server-schema fixtures exercise the real Radio downloader and transport.
        let fixtures = directory.appendingPathComponent("RadioFixtures")
        try FileManager.default.createDirectory(at: fixtures, withIntermediateDirectories: true)
        let soundtrack = try Data(contentsOf: URL(fileURLWithPath: "Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3"))
        try soundtrack.write(to: fixtures.appendingPathComponent("song.mp3"))
        let hash = SHA256.hash(data: soundtrack).map { String(format: "%02x", $0) }.joined()
        let tracks = (1...2).map { i in RadioTrack(id: UUID().uuidString, title: "Fixture song \(i)", genre: "Electronic",
            duration: 60, audio: "song.mp3", sha256: hash, byteCount: soundtrack.count) }
        try JSONEncoder().encode(RadioCatalog(version: 1, title: "Test music", tracks: tracks))
            .write(to: fixtures.appendingPathComponent("catalog.json"))
        try JSONEncoder().encode(RadioStationDirectory(version: 1, stations: [
            RadioStation(id: "all-music", title: "All Music", description: "Fixture", catalog: "catalog.json")]))
            .write(to: fixtures.appendingPathComponent("stations.json"))
        let radio = VisionRadio(directory: directory.appendingPathComponent("RadioCache"),
            source: fixtures.appendingPathComponent("stations.json"), presets: presets)
        presets.setRandomizerGroup(.category(category))
        radio.studio.volume = 0
        let session = VisionSession(editor: restored, radio: radio)
        let editorBefore = try Data(contentsOf: directory.appendingPathComponent("Studio-autosave.json"))
        session.setRadioMode(true)
        precondition(session.activeStudio === radio.studio && session.activeStudio !== restored)
        await radio.refreshStations()
        precondition(radio.stations.map(\.title) == ["All Music"] && !radio.loadingStations)
        radio.nextSong(); await radio.waitForTrack()
        precondition(radio.error == nil && radio.studio.transport.playing && !radio.studio.loopPlayback)
        precondition(radio.studio.project.clips.allSatisfy { eligible.contains($0.scene) },
                     "Radio's generated timeline must use the same selected category as the library and randomizer")
        let title = radio.studio.project.audioTitle
        radio.studio.seek(radio.studio.transport.duration - 0.2)
        try await Task.sleep(for: .milliseconds(700)); await radio.waitForTrack()
        precondition(radio.error == nil && radio.studio.transport.playing && radio.studio.project.audioTitle != title,
                     "Radio must automatically advance rather than loop one track")
        session.setRadioMode(false)
        precondition(session.activeStudio === restored && !radio.studio.transport.playing)
        let editorAfter = try Data(contentsOf: directory.appendingPathComponent("Studio-autosave.json"))
        precondition(editorAfter == editorBefore,
                     "Radio must never overwrite the user's Studio session")
        print("PASS Vision Radio: station JSON, verified audio, autoplay next track, mode switching and independent Studio storage")
        print("PASS loop boundary/restart, loop persistence, category/favorites cascade, empty/single pools and independent style dice")
        print("PASS Vision transport: actual soundtrack import/analysis, per-scene bars, shared appearance, add/move/remove, seek, playback clock/audio bands, pause and autosave restoration")
    }
}
