import Foundation
import CryptoKit
import Combine

@main struct VisionTransportSmoke {
    @MainActor static func main() async throws {
        setbuf(stdout, nil)
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
                && look.palette == (untouched[$0] ?? VisionLook(scene: $0)).palette
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
            precondition(studio.look.isValid && studio.look != savedLooks[studio.selectedScene], "New non-favorite selections get fresh looks")
        }
        presets.setRandomizerGroup(.favorites)
        precondition(presets.filteredScenes().count == NativeEffects.activeCount && studio.randomizeVisualizer())
        precondition(presets.favoritesFallbackMessage != nil)
        presets.toggleFavorite(22, appearance: savedLooks[22]?.preset)
        precondition(presets.filteredScenes() == [22] && studio.randomizeVisualizer() && studio.selectedScene == 22)
        precondition(studio.look.preset == presets.favoriteAppearance(for: 22))
        let favoriteSnapshot = studio.look
        let barsBefore = studio.project.clips.map(\.bars)
        studio.randomizeLook()
        precondition(studio.look.isValid && studio.look != savedLooks[22] && studio.project.clips.map(\.bars) == barsBefore)
        studio.updateLook { $0.chaos = 0.91; $0.palette = 3 }
        presets.setRandomizerGroup(.all)
        precondition(presets.filteredScenes().count == NativeEffects.activeCount)
        let count = studio.project.clips.count
        studio.addClip(); precondition(studio.project.clips.count == count + 1)
        studio.assign(22); precondition(studio.look == favoriteSnapshot && studio.look.preset == presets.favoriteAppearance(for: 22))
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
        precondition(studio.selected == following && studio.look(for: editing)?.isValid == true)
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
        let tracks = (1...3).map { i in RadioTrack(id: UUID().uuidString, title: "Fixture song \(i)", genre: "Electronic",
            duration: 60, audio: "song.mp3", sha256: hash, byteCount: soundtrack.count) }
        try JSONEncoder().encode(RadioCatalog(version: 1, title: "Test music", tracks: tracks))
            .write(to: fixtures.appendingPathComponent("catalog.json"))
        try JSONEncoder().encode(RadioStationDirectory(version: 1, stations: [
            RadioStation(id: "all-music", title: "All Music", description: "Fixture", catalog: "catalog.json")]))
            .write(to: fixtures.appendingPathComponent("stations.json"))
        let radio = VisionRadio(directory: directory.appendingPathComponent("RadioCache"),
            source: fixtures.appendingPathComponent("stations.json"), presets: presets, defaults: defaults)
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
            source: fixtures.appendingPathComponent("stations.json"), presets: presets, defaults: defaults)
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
        let currentSong = radio.playingTrack!
        radio.toggleFavoriteSong(currentSong)
        precondition(radio.isFavoriteSong(currentSong) && radio.favoriteSongs.count == 1)
        let reopenedRadio = VisionRadio(directory: directory.appendingPathComponent("ReopenedRadio"),
            source: fixtures.appendingPathComponent("stations.json"), presets: presets, defaults: defaults)
        precondition(reopenedRadio.isFavoriteSong(currentSong), "Song hearts must survive a new Radio instance")
        radio.selectStation("favorite-songs"); await radio.waitForTrack()
        precondition(radio.error == nil && radio.favoriteSongsOnly && radio.playingTrack == currentSong)
        radio.nextSong(); await radio.waitForTrack()
        precondition(radio.playingTrack == currentSong && radio.studio.transport.playing,
                     "One favorite must form a favorites-only station, without falling back to other music")
        let secondFavorite = tracks.first { $0.id != currentSong.id }!
        radio.toggleFavoriteSong(secondFavorite)
        for _ in 0..<4 {
            let previous = radio.playingTrack
            radio.nextSong(); await radio.waitForTrack()
            precondition(radio.playingTrack != previous && radio.playingTrack.map(radio.isFavoriteSong) == true)
        }
        let favoritesReopened = VisionRadio(directory: directory.appendingPathComponent("FavoritesReopenedRadio"),
            source: fixtures.appendingPathComponent("stations.json"), presets: presets, defaults: defaults)
        precondition(favoritesReopened.favoriteSongsOnly && favoritesReopened.favoriteSongs.count == 2)
        let genreTrack = tracks.first { $0.id != currentSong.id && $0.id != secondFavorite.id }!
        try JSONEncoder().encode(RadioCatalog(version: 1, title: "Genre", tracks: [genreTrack]))
            .write(to: fixtures.appendingPathComponent("genre.json"))
        try JSONEncoder().encode(RadioStationDirectory(version: 1, stations: [
            RadioStation(id: "all-music", title: "All Music", description: "Fixture", catalog: "catalog.json"),
            RadioStation(id: "genre", title: "Genre", description: "Subset", catalog: "genre.json")]))
            .write(to: fixtures.appendingPathComponent("stations.json"))
        await radio.refreshStations()
        radio.selectStation("genre"); await radio.waitForTrack()
        precondition(radio.playingTrack == genreTrack && radio.favoriteSongs.count == 2,
                     "A genre subset must not remove saved songs from other stations")
        radio.playFavoriteSong(radio.favoriteSongs.first { $0.id == currentSong.id }!); await radio.waitForTrack()
        precondition(radio.playingTrack == currentSong, "Selecting a saved song must play that exact song")
        radio.toggleFavoriteSong(currentSong); radio.toggleFavoriteSong(secondFavorite)
        radio.togglePlayback(); await radio.waitForTrack()
        precondition(!radio.studio.transport.playing && radio.error != nil && radio.favoriteSongs.isEmpty,
                     "Empty favorites must pause, explain what to do, and never fall back to all songs")
        radio.selectStation("all-music"); await radio.waitForTrack()
        precondition(radio.error == nil && !radio.favoriteSongsOnly && radio.studio.transport.playing)
        radio.toggleFavoriteSong(currentSong); radio.suspend()
        let catalogPath = fixtures.appendingPathComponent("catalog.json")
        let originalCatalog = try Data(contentsOf: catalogPath)
        try Data("invalid".utf8).write(to: catalogPath)
        await radio.refreshFavoriteSongs()
        precondition(radio.isFavoriteSong(currentSong), "Offline or invalid catalogs must not erase favorites")
        let removedSong = radio.favoriteSongs.first!
        radio.toggleFavoriteSong(secondFavorite)
        try JSONEncoder().encode(RadioCatalog(version: 1, title: "Retired song", tracks: tracks.filter { $0.id != currentSong.id }))
            .write(to: catalogPath)
        let startupCleanup = VisionRadio(directory: directory.appendingPathComponent("StartupCleanupRadio"),
            source: fixtures.appendingPathComponent("stations.json"), presets: presets, defaults: defaults)
        await startupCleanup.refreshFavoriteSongs()
        precondition(!startupCleanup.isFavoriteSong(currentSong) && startupCleanup.isFavoriteSong(secondFavorite)
                     && startupCleanup.stations.isEmpty && startupCleanup.playingTrack == nil && !startupCleanup.studio.transport.playing,
                     "Startup cleanup must keep available songs and remove retired songs without starting Radio")
        let startupReopened = VisionRadio(directory: directory.appendingPathComponent("StartupReopenedRadio"),
            source: fixtures.appendingPathComponent("stations.json"), presets: presets, defaults: defaults)
        precondition(!startupReopened.isFavoriteSong(currentSong) && startupReopened.isFavoriteSong(secondFavorite),
                     "Startup cleanup must stay persisted after relaunch")
        radio.playFavoriteSong(removedSong); await radio.waitForTrack()
        precondition(radio.error != nil && !radio.studio.transport.playing && !radio.isFavoriteSong(currentSong),
                     "A retired saved song must be pruned and reported instead of playing a different song")
        radio.toggleFavoriteSong(secondFavorite)
        try JSONEncoder().encode(RadioCatalog(version: 1, title: "Removed song", tracks: tracks.filter { $0.id != currentSong.id }))
            .write(to: catalogPath)
        await radio.refreshFavoriteSongs()
        precondition(radio.favoriteSongs.isEmpty)
        let prunedRadio = VisionRadio(directory: directory.appendingPathComponent("PrunedRadio"),
            source: fixtures.appendingPathComponent("stations.json"), presets: presets, defaults: defaults)
        precondition(prunedRadio.favoriteSongs.isEmpty, "Removed songs must stay removed after reopening")
        try originalCatalog.write(to: catalogPath)
        print("PASS Vision song favorites: persisted hearts, one/multiple/empty favorites stations, exact song playback, All restore, failed refresh retention and removed-song pruning")
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
        presets.setRandomizerGroup(.all)
        let importedEnds = portable.segments.map(\.end)
        let importedIDs = portable.project.clips.map(\.id)
        let importedLooks = portable.project.looks
        precondition(portable.randomizeTimeline())
        precondition(portable.segments.map(\.end) == importedEnds && portable.project.clips.map(\.id) == importedIDs
                     && portable.project.looks != importedLooks && portable.project.importedTimeline != nil,
                     "Visualizers-only randomization must preserve exact imported cuts and IDs while creating fresh looks")
        portable.updateLook { $0.size = 5.75; $0.rotation = 1.2; $0.motionBlur = 0.65; $0.fog = 0.2; $0.detail = 0.85; $0.haloCount = 10 }
        precondition(portable.render.particleSize == 5.75 && portable.render.rotation == 1.2
                     && portable.render.motionBlur == 0.65 && portable.render.fog == 0.2
                     && portable.render.liquidDetail == 0.85 && portable.render.haloCount == 10)
        let looksBeforeTimeline = portable.project.looks
        let urlBeforeTimeline = portable.audioURL
        portable.seek(8); portable.togglePlayback()
        precondition(portable.randomizeTimeline(barLengths: true, chooseLength: { 2 }))
        precondition(portable.transport.playing && abs(portable.transport.seconds - 8) < 0.1
                     && portable.project.looks != looksBeforeTimeline && portable.audioURL == urlBeforeTimeline)
        precondition(portable.project.importedTimeline == nil && portable.segments.last?.end == portable.transport.duration
                     && portable.project.clips.allSatisfy { $0.bars == 2 }
                     && Set(portable.project.clips.map(\.scene)).count == portable.project.clips.count)
        portable.suspend()
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        for scene in NativeEffects.activeIDs where presets.isFavorite(scene) { presets.toggleFavorite(scene) }
        presets.setRandomizerGroup(.favorites)
        precondition(portable.randomizeTimeline(barLengths: true, chooseLength: { 4 })
                     && presets.favoritesFallbackMessage != nil,
                     "An empty favorites selection must still randomize the full timeline")
        presets.setRandomizerGroup(.category("Missing category"))
        let beforeEmptyPool = try encoder.encode(portable.project)
        precondition(!portable.randomizeTimeline(barLengths: true, chooseLength: { 8 }))
        let afterEmptyPool = try encoder.encode(portable.project)
        precondition(afterEmptyPool == beforeEmptyPool, "Combined randomization failures must be atomic")
        let barsOnlyLooks = portable.project.looks
        let orderedScenes = portable.project.clips.map(\.scene)
        precondition(portable.randomizeTimeline(visualizers: false, barLengths: true, chooseLength: { 8 }))
        precondition(zip(portable.project.clips.map(\.scene), orderedScenes).allSatisfy { $0.0 == $0.1 }
                     && portable.project.looks == barsOnlyLooks, "Bars-only must preserve visualizer order and shared looks")
        presets.setRandomizerGroup(.favorites)
        presets.toggleFavorite(22)
        precondition(portable.randomizeTimeline(barLengths: true, chooseLength: { 1 }))
        precondition(portable.project.clips.allSatisfy { $0.scene == 22 && $0.bars == 1 }
                     && portable.segments.last?.end == portable.transport.duration)
        let afterSinglePool = try encoder.encode(portable.project)
        precondition(!portable.randomizeTimeline(visualizers: false, barLengths: false))
        precondition(!portable.randomizeTimeline(barLengths: true, chooseLength: { 9 }))
        let afterRejectedInput = try encoder.encode(portable.project)
        precondition(afterRejectedInput == afterSinglePool)
        let autosavedTimeline = try JSONDecoder().decode(VisionProject.self,
            from: Data(contentsOf: directory.appendingPathComponent("Portable/Studio-autosave.json")))
        precondition(autosavedTimeline.clips == portable.project.clips && autosavedTimeline.looks == portable.project.looks)
        print("PASS whole timeline: exact cuts, shared styles/render bindings, playback position, atomic failures, empty/single pools, bars-only order, full coverage and autosave")
        print("PASS loop boundary/restart, loop persistence, category/favorites cascade, empty/single pools and independent style dice")
        print("PASS Vision transport: actual soundtrack import/analysis, per-scene bars, shared appearance, add/move/remove, seek, playback clock/audio bands, pause and autosave restoration")
        let librarySong = directory.appendingPathComponent("Library song.m4a")
        try FileManager.default.copyItem(at: studio.audioURL!, to: librarySong)
        let libraryStudio = VisionStudio(directory: directory.appendingPathComponent("LibraryStudio"), library: presets)
        let imported = await libraryStudio.importAudio(librarySong, title: "Picked from music")
        precondition(imported && libraryStudio.project.audioTitle == "Picked from music")
        let permanentURL = libraryStudio.audioURL!
        try FileManager.default.removeItem(at: librarySong)
        precondition(FileManager.default.fileExists(atPath: permanentURL.path) && !libraryStudio.segments.isEmpty)
        let restoredLibraryStudio = VisionStudio(directory: directory.appendingPathComponent("LibraryStudio"), library: presets)
        await restoredLibraryStudio.start()
        precondition(restoredLibraryStudio.audioURL == permanentURL && restoredLibraryStudio.project.audioTitle == "Picked from music")
        precondition(restoredLibraryStudio.transport.duration > 0 && !restoredLibraryStudio.needsSoundtrack)
        print("PASS Studio library song: chosen title, permanent copy, timeline and reopening after source removal")
    }
}
