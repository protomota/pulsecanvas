import Foundation
import CryptoKit
import Combine

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
        precondition(studio.project.clips.count > 1 && studio.project.barBoundaries != nil)
        let analyzer = try SoundtrackAnalyzer(url: URL(fileURLWithPath: "Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3"))
        let macGrid = analyzer.segmentPlan(beatsPerSection: 4)
        precondition(studio.project.barBoundaries == macGrid.boundaries)
        precondition(studio.segments[0].end == macGrid.boundaries[4])
        let defaultMacCuts = Array(analyzer.segmentPlan().boundaries.dropFirst())
        precondition(studio.segments.count == defaultMacCuts.count
                     && zip(studio.segments.map(\.end), defaultMacCuts).allSatisfy { abs($0 - $1) < 0.001 },
                     "The default four-bar timing must match Mac's 16-beat section plan")
        let untouched = studio.project.looks
        studio.applyCommonSettings(VisionCommonSettings(bars: 1))
        precondition(studio.project.looks == untouched && studio.project.clips.allSatisfy { $0.bars == 1 })
        precondition(studio.segments.map(\.end) == Array(macGrid.boundaries.dropFirst()))
        studio.seek(macGrid.boundaries[1] - 0.1); studio.togglePlayback()
        try await Task.sleep(for: .milliseconds(350))
        precondition(studio.selectedIndex == 1 && studio.transport.playing)
        studio.applyCommonSettings(VisionCommonSettings(chaos: 0.72, zoomSpeed: 2, motionSpeed: 1.2,
            strobeEnabled: true, strobeSensitivity: 1.7, strobeStrength: 0.4))
        precondition(studio.transport.playing && NativeEffects.activeIDs.allSatisfy {
            let look = studio.project.looks[$0]!
            return look.chaos == 0.72 && look.zoomSpeed == 2 && look.speed == 1.2 && look.strobeEnabled && look.strobeStrength == 0.4
                && look.palette == VisionLook(scene: $0).palette
        })
        let beforeRemoval = studio.look
        studio.applyCommonSettings(VisionCommonSettings(strobeEnabled: false))
        precondition(!studio.render.strobeEnabled && studio.look.chaos == beforeRemoval.chaos && studio.look.strobeSensitivity == 1.7)
        let beforeInvalid = studio.project.clips
        studio.applyCommonSettings(VisionCommonSettings(bars: 0, chaos: .nan))
        precondition(studio.project.clips == beforeInvalid)
        studio.suspend()
        studio.applyCommonSettings(VisionCommonSettings(bars: 4))
        studio.seek(0); studio.select(studio.project.clips[0])
        precondition(studio.segments.last?.end == studio.transport.duration)
        print("PASS Mac timing parity: identical bar grid, one-bar live scene switch, four-bar refill, selective apply-all/strobe removal/invalid input")
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
        let editing = studio.project.clips[0].id
        let following = studio.project.clips[1].id
        let otherScenes = NativeEffects.activeIDs.filter { $0 != 22 }
        studio.assign(22, to: editing)
        studio.assign(otherScenes[1], to: following)
        studio.seek(studio.segments[0].end - 0.1)
        studio.togglePlayback()
        try await Task.sleep(for: .milliseconds(350))
        precondition(studio.selected == following && studio.transport.playing)
        let playheadBeforeEdit = studio.transport.seconds
        studio.assign(otherScenes[0], to: editing)
        precondition(studio.project.clips.first(where: { $0.id == editing })?.scene == otherScenes[0])
        precondition(studio.selected == following && studio.render.scene == otherScenes[1])
        precondition(studio.transport.seconds == playheadBeforeEdit && studio.transport.playing,
                     "A card picker must edit its original clip without moving playback to a different section")
        studio.updateLook(for: editing) { $0.chaos = 0.13 }
        precondition(studio.look(for: editing)?.chaos == 0.13 && studio.render.chaos != 0.13)
        studio.updateLook(for: editing) {
            $0.strobeEnabled = true; $0.strobeSensitivity = 2.3; $0.strobeStrength = 0.65
        }
        let strobeLook = studio.look(for: editing)!
        precondition(strobeLook.strobeEnabled && strobeLook.strobeSensitivity == 2.3 && strobeLook.strobeStrength == 0.65)
        let strobeRoundTrip = try JSONDecoder().decode(VisionProject.self, from: JSONEncoder().encode(studio.project))
        precondition(strobeRoundTrip.looks[otherScenes[0]] == strobeLook && studio.selected == following)
        studio.resetLook(for: editing)
        precondition(studio.look(for: editing) == VisionLook(scene: otherScenes[0]))
        let pickerLooks = studio.project.looks
        precondition(studio.randomizeVisualizer(for: editing))
        precondition(studio.project.looks == pickerLooks && studio.selected == following)
        studio.randomizeLook(for: editing)
        precondition(studio.look(for: editing)?.isValid == true && studio.selected == following)
        let missingClip = UUID()
        let beforeMissing = studio.project.clips
        studio.assign(22, to: missingClip); studio.updateLook(for: missingClip) { $0.chaos = 0.2 }
        studio.resetLook(for: missingClip)
        precondition(!studio.randomizeVisualizer(for: missingClip) && studio.project.clips == beforeMissing)
        studio.suspend()
        // Restore the appearance used by the independent autosave assertions below.
        studio.assign(22, to: editing); studio.updateLook(for: editing) { $0.chaos = 0.91; $0.palette = 3 }
        print("PASS card picker: stable clip targeting during playback, no seek, shared style edits/reset, randomizers and missing-clip safety")
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
        precondition(radio.stations.isEmpty && radio.studio.transport.duration == 0)
        radio.togglePlayback()
        precondition(radio.loading, "First Play must immediately queue a song without preloaded stations or audio")
        radio.togglePlayback() // Ignore repeated taps while preparing the first song.
        await radio.waitForTrack()
        precondition(radio.stations.map(\.title) == ["All Music"] && !radio.loadingStations && !radio.loading)
        precondition(radio.error == nil && radio.studio.transport.playing && !radio.studio.loopPlayback)
        let firstTitle = radio.studio.project.audioTitle
        radio.togglePlayback()
        precondition(!radio.studio.transport.playing)
        radio.togglePlayback()
        precondition(radio.studio.transport.playing && radio.studio.project.audioTitle == firstTitle,
                     "After cold-start playback, Play must resume the same song rather than choosing another")
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
        let loadingRadio = VisionRadio(directory: directory.appendingPathComponent("LoadingRadioCache"),
            source: fixtures.appendingPathComponent("stations.json"), presets: presets)
        loadingRadio.studio.volume = 0
        // Request Play as soon as the UI observes loading, before the directory can finish.
        let startOnLoading = loadingRadio.$loadingStations.filter { $0 }.prefix(1).sink { _ in
            loadingRadio.togglePlayback()
        }
        await loadingRadio.refreshStations()
        await loadingRadio.waitForTrack()
        withExtendedLifetime(startOnLoading) {}
        precondition(loadingRadio.error == nil && loadingRadio.studio.transport.playing
                     && !loadingRadio.loading && !loadingRadio.loadingStations,
                     "Play must await the in-flight station directory and start a track")
        loadingRadio.suspend()
        print("PASS Radio first Play: cold start, repeated taps, pause/resume and Play during initial station loading")
        let portable = VisionStudio(directory: directory.appendingPathComponent("Portable"), library: presets)
        portable.volume = 0
        var incoming = VisionProject()
        incoming.clips = [VisionClip(scene: 22, bars: 1), VisionClip(scene: otherScenes[1], bars: 4)]
        incoming.looks[22] = VisionLook(scene: 22); incoming.looks[22]!.chaos = 0.37
        incoming.externalAudioURL = URL(fileURLWithPath: "/Missing/Track.wav")
        incoming.importedTimeline = [StudioSegment(start: 0, end: 1.5, scene: 22, bars: 1),
            StudioSegment(start: 1.5, end: studio.transport.duration, scene: otherScenes[1], bars: 4)]
        await portable.replaceProject(incoming)
        precondition(portable.needsSoundtrack && portable.audioURL == nil && portable.project.clips == incoming.clips)
        await portable.importAudio(URL(fileURLWithPath: "Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3"), generateTimeline: false)
        precondition(!portable.needsSoundtrack && portable.audioURL != nil && portable.project.clips == incoming.clips)
        precondition(portable.look(for: incoming.clips[0].id)?.chaos == 0.37
            && portable.segments.map(\.end) == incoming.importedTimeline!.map(\.end))
        print("PASS portable project audio relocation: missing audio waits without demo substitution; locating the song preserves exact cuts, card IDs and looks")
        print("PASS loop boundary/restart, loop persistence, category/favorites cascade, empty/single pools and independent style dice")
        print("PASS Vision transport: actual soundtrack import/analysis, per-scene bars, shared appearance, add/move/remove, seek, playback clock/audio bands, pause and autosave restoration")
    }
}
