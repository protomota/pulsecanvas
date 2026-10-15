import AVFoundation
import Combine
import CryptoKit
import Foundation

@main struct RadioSmoke {
    @MainActor static func wait(_ description: String, until condition: () -> Bool) async throws {
        for _ in 0..<500 {
            if condition() { return }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        fatalError("Timed out: \(description)")
    }

    @MainActor static func main() async throws {
        setbuf(stdout, nil)
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent("PulseCanvas-Radio-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporary) }
        let suite = "PulseCanvas.RadioSmoke." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let audioDirectory = temporary.appendingPathComponent("audio")
        try FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        var tracks: [RadioTrack] = []
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        for index in 0..<3 {
            let url = audioDirectory.appendingPathComponent("\(index).m4a")
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 44100 * 3)!
            buffer.frameLength = buffer.frameCapacity
            for channel in 0..<2 { for frame in 0..<Int(buffer.frameLength) {
                buffer.floatChannelData![channel][frame] = 0.3 * sin(Float(frame) * 2 * .pi * Float(220 + index * 110) / 44100)
            } }
            do {
                let file = try AVAudioFile(forWriting: url, settings: [AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 44100, AVNumberOfChannelsKey: 2, AVEncoderBitRateKey: 128000])
                try file.write(from: buffer)
            }
            let data = try Data(contentsOf: url)
            tracks.append(RadioTrack(id: UUID().uuidString, title: "Test song \(index)", genre: "Test", duration: 3,
                audio: "audio/\(index).m4a", sha256: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined(), byteCount: data.count))
        }
        let catalogURL = temporary.appendingPathComponent("catalog.json")
        let catalog = RadioCatalog(version: 1, title: "Test radio", tracks: tracks)
        try JSONEncoder().encode(catalog).write(to: catalogURL)
        _ = try RadioCatalog.decode(Data(contentsOf: catalogURL), from: catalogURL)
        var bad = try JSONSerialization.jsonObject(with: Data(contentsOf: catalogURL)) as! [String: Any]
        var badTracks = bad["tracks"] as! [[String: Any]]
        badTracks[0]["audio"] = "../../outside.m4a"; bad["tracks"] = badTracks
        do {
            _ = try RadioCatalog.decode(JSONSerialization.data(withJSONObject: bad), from: catalogURL)
            fatalError("Escaping local audio path accepted")
        } catch {}
        badTracks[0]["audio"] = "http://example.com/music.m4a"; bad["tracks"] = badTracks
        do {
            _ = try RadioCatalog.decode(JSONSerialization.data(withJSONObject: bad), from: URL(string: "https://example.com/catalog.json")!)
            fatalError("HTTP audio accepted")
        } catch {}
        print("PASS catalog validation: relative paths, HTTPS requirement and local folder boundaries")

        var queue = RadioQueue(), current: Int?
        for _ in 0..<4 {
            var round: [Int] = []
            for _ in 0..<15 {
                let next = queue.next(count: 15, current: current, shuffle: true)!
                precondition(next != current); round.append(next); current = next
            }
            precondition(Set(round).count == 15)
        }
        var preferredQueue = RadioQueue()
        let preferred: Set<Int> = [2, 5, 9]
        let firstRound = (0..<12).map { _ in preferredQueue.next(count: 12, current: nil, shuffle: true, prioritized: preferred)! }
        precondition(Set(firstRound.prefix(3)) == preferred && Set(firstRound).count == 12)
        for _ in 0..<100 {
            let next = preferredQueue.next(count: 12, current: current, shuffle: true, prioritized: preferred)!
            precondition(next != current); current = next
        }
        precondition(preferredQueue.next(count: 0, current: nil, shuffle: true, prioritized: preferred) == nil)
        print("PASS favorites-first shuffle: favorite tier first, all station songs once per round, no adjacent repeats")
        precondition(queue.next(count: 1, current: 0, shuffle: true) == 0)
        precondition(queue.next(count: 0, current: nil, shuffle: false) == nil)
        print("PASS shuffle: all songs once per round, no repeat across rounds, one/zero track libraries")
        let visualPlan = SongSegmentation(boundaries: (0...18).map(Double.init), bpm: 120)
        let visualSchedule = RadioVisualSchedule.make(plan: visualPlan, pool: [10, 18, 22], bars: 4)
        for offset in stride(from: 0, to: 18, by: 3) {
            precondition(Set(visualSchedule[offset..<offset + 3].map(\.scene)) == [10, 18, 22])
        }
        precondition(zip(visualSchedule, visualSchedule.dropFirst()).allSatisfy { $0.scene != $1.scene })
        print("PASS visual shuffle: exhaust the favorites pool before repeating, without adjacent repeats")
        let mixedPool = [10, 18, 22, 31, 42]
        for favoriteSet: Set<Int> in [[10], [10, 18, 22]] {
            for _ in 0..<40 {
                let mixed = RadioVisualSchedule.make(plan: visualPlan, pool: mixedPool, bars: 4, favorites: favoriteSet)
                precondition(mixed.count == 18 && mixed.first?.start == 0 && mixed.last?.end == 18)
                for favorite in favoriteSet { precondition(mixed.filter { $0.scene == favorite }.count == 1) }
                precondition(mixed.dropFirst(favoriteSet.count).allSatisfy { !favoriteSet.contains($0.scene) })
                precondition(zip(mixed, mixed.dropFirst()).allSatisfy { $0.scene != $1.scene })
            }
        }
        let unheard = RadioVisualSchedule.make(plan: visualPlan, pool: mixedPool, bars: 4,
            favorites: [10, 18], played: [10], previous: 10)
        precondition(!unheard.contains { $0.scene == 10 } && unheard.filter { $0.scene == 18 }.count == 1)
        let allFavorite = RadioVisualSchedule.make(plan: visualPlan, pool: [10, 18, 22], bars: 4, favorites: [10, 18, 22])
        precondition(allFavorite.count == 3 && Set(allFavorite.map(\.scene)).count == 3 && allFavorite.last?.end == 18)
        let shortPlan = SongSegmentation(boundaries: [0, 1, 2], bpm: 120)
        let shortSong = RadioVisualSchedule.make(plan: shortPlan, pool: mixedPool, bars: 4, favorites: [10, 18, 22])
        precondition(shortSong.count == 2 && Set(shortSong.map(\.scene)).count == 2)
        print("PASS mixed visuals: one/three favorites once per song, random non-favorite fill, short songs, spent favorites and all-favorite galleries")

        let library = RadioLibrary(directory: temporary.appendingPathComponent("cache"))
        let cached = try await library.localAudio(for: tracks[0], catalogURL: catalogURL)
        try Data("broken cache".utf8).write(to: cached)
        let repaired = try await library.localAudio(for: tracks[0], catalogURL: catalogURL)
        let repairedData = try Data(contentsOf: repaired), originalData = try Data(contentsOf: audioDirectory.appendingPathComponent("0.m4a"))
        precondition(repairedData == originalData)
        print("PASS cache integrity: modified cached audio is replaced with verified source")

        let audio = AudioController(), studio = StudioStore(defaults: defaults), render = RenderState()
        audio.volume = 0
        precondition(audio.load(url: audioDirectory.appendingPathComponent("0.m4a")))
        audio.seek(fraction: 0.4)
        let originalURL = audio.selectedURL, originalProgress = audio.progress
        studio.isStudio = true
        studio.makeTimeline(audio.segmentPlan()!, render: render)
        let originalTimeline = studio.segments
        let secondCatalogURL = temporary.appendingPathComponent("genre.json")
        try JSONEncoder().encode(RadioCatalog(version: 1, title: "A future genre", tracks: [tracks[2]])).write(to: secondCatalogURL)
        let stationsURL = temporary.appendingPathComponent("stations.json")
        let stations = RadioStationDirectory(version: 1, stations: [
            RadioStation(id: "all-music", title: "All Music", description: "All genres", catalog: "catalog.json"),
            RadioStation(id: "future-genre", title: "Future Genre", description: "One genre", catalog: "genre.json")])
        try JSONEncoder().encode(stations).write(to: stationsURL)
        _ = try RadioStationDirectory.decode(Data(contentsOf: stationsURL), from: stationsURL)
        let favorites = ProjectMPresets(defaults: defaults, favoritesBackupDirectory: temporary.appendingPathComponent("favorites"))
        favorites.toggleFavorite(NativeEffects.activeIDs[0]); favorites.toggleFavorite(NativeEffects.activeIDs[1])
        let radio = RadioController(library: library, defaults: defaults, presets: favorites)
        precondition(radio.shuffle, "Radio should shuffle by default")
        radio.shuffle = false // Preserve deterministic index assertions for the transport suite.
        precondition(abs(radio.volume - 0.7) < 0.001, "Radio defaults to 70%, independently of the muted editor")
        radio.volume = 0 // Keep the test tones silent; this is an isolated preference suite.
        radio.attach(audio: audio)
        radio.loadCatalog(at: stationsURL)
        try await wait("catalog") { radio.canStart }
        precondition(radio.stations.count == 2 && radio.stationID == "all-music")
        radio.start(at: 0)
        try await wait("first song") { radio.currentIndex == 0 && !radio.isLoading }
        precondition(audio.isPlaying && audio.title == tracks[0].title && studio.isStudio)
        let songPosition = audio.playbackSeconds
        radio.toggleFavoriteSong(tracks[0])
        precondition(radio.isFavoriteSong(tracks[0]) && radio.favoriteSongs.count == 1)
        precondition(audio.isPlaying && radio.currentIndex == 0 && audio.playbackSeconds >= songPosition,
            "Favoriting a song must not interrupt playback")
        let savedSong = radio.favoriteSongs[0]
        let reopened = RadioController(library: library, defaults: defaults, presets: favorites)
        precondition(reopened.favoriteSongs.count == 1 && reopened.isFavoriteSong(tracks[0]), "Song favorites must persist across launch")
        precondition(reopened.favoriteSongs[0].catalogURL == catalogURL && reopened.favoriteSongs[0].sourceURL == stationsURL)
        radio.toggleFavoriteSong(tracks[0]); precondition(radio.favoriteSongs.isEmpty)
        radio.toggleFavoriteSong(tracks[0]); precondition(radio.favoriteSongs.count == 1)
        precondition(radio.sceneTitle == RenderState.sceneNames[radio.visualizer.scene])
        print("PASS song favorites: save/remove, persisted metadata, independent identities and uninterrupted playback")
        precondition(StudioTimeline.valid(radio.segments, sceneCount: RenderState.sceneNames.count))
        precondition(abs(radio.segments.last!.end - audio.duration) < 0.001)
        precondition(radio.usesFavorites && favorites.isFavorite(radio.visualizer.scene))
        for scene in favorites.availableScenes where favorites.isFavorite(scene) {
            precondition(radio.segments.filter { $0.scene == scene }.count <= 1)
        }
        precondition(radio.segments.allSatisfy { $0.bars == 4 })
        radio.barsPerVisualizer = 1
        precondition(radio.segments.allSatisfy { $0.bars == 1 } && abs(radio.segments.last!.end - audio.duration) < 0.001)
        let visualBefore = radio.visualizer.scene, timeBefore = audio.playbackSeconds
        let timingBefore = radio.segments.map { [$0.start, $0.end] }
        radio.randomizeCurrentVisualizer()
        precondition(radio.visualizer.scene != visualBefore && favorites.isFavorite(radio.visualizer.scene))
        precondition(radio.segments.map { [$0.start, $0.end] } == timingBefore && audio.playbackSeconds == timeBefore && audio.isPlaying)
        print("PASS Randomize: immediate favorite switch, unchanged song position and beat schedule")
        precondition(studio.segments.map(\.scene) == originalTimeline.map(\.scene), "Radio must not modify the editor timeline")
        print("PASS independent visuals: favorites once, radio bar control and unchanged editor timeline")
        let keptOnScreen = radio.visualizer.scene
        favorites.toggleFavorite(NativeEffects.activeIDs[0]); favorites.toggleFavorite(NativeEffects.activeIDs[1])
        try await wait("visual favorites update") { !radio.usesFavorites }
        precondition(radio.visualizer.scene == keptOnScreen && audio.isPlaying,
            "Favoriting must preserve the current visual and music while updating subsequent scenes")
        favorites.toggleFavorite(NativeEffects.activeIDs[0]); favorites.toggleFavorite(NativeEffects.activeIDs[1])
        try await wait("visual favorites restored") { radio.usesFavorites }
        precondition(radio.segments.dropFirst().allSatisfy { !favorites.isFavorite($0.scene) },
            "Rebuilding preferences replayed a favorite already shown in this song")
        print("PASS live visual favorites: next scenes refresh without changing the current visualizer or interrupting music")
        audio.seek(fraction: 0.98)
        try await wait("end advances even with soundtrack Loop on") { radio.currentIndex == 1 && !radio.isLoading }
        precondition(favorites.isFavorite(radio.visualizer.scene), "A new song must reset its per-favorite quota")
        precondition(audio.title == tracks[1].title && audio.isPlaying)
        precondition(audio.volume == radio.volume, "Song changes must retain the user's radio volume")
        radio.togglePlayback(); precondition(!audio.isPlaying)
        radio.togglePlayback(); precondition(audio.isPlaying)
        radio.start(at: 2)
        try await wait("last song") { radio.currentIndex == 2 && !radio.isLoading }
        audio.seek(fraction: 0.98)
        try await wait("playlist wrap") { radio.currentIndex == 0 && !radio.isLoading }
        print("PASS playback: full-song completion, automatic next, playlist wrap, pause/resume and complete Studio coverage")

        radio.next(); radio.next()
        precondition(radio.isLoading && radio.isPlaybackRequested, "Skipping while playing must keep the Pause transport state during preparation")
        try await wait("rapid double skip") { radio.currentIndex == 2 && !radio.isLoading }
        radio.next(); radio.leave()
        try await Task.sleep(nanoseconds: 300_000_000)
        precondition(!radio.isActive && !radio.isLoading && !audio.isPlaying && audio.onSoundtrackFinished == nil)
        precondition(audio.volume == 0, "Leaving radio must restore the previous editor volume")
        precondition(audio.selectedURL?.standardizedFileURL == originalURL?.standardizedFileURL && abs(audio.progress - originalProgress) < 0.001,
            "Restore: \(String(describing: audio.selectedURL)) / \(String(describing: originalURL)), progress \(audio.progress) / \(originalProgress)")
        precondition(studio.segments.map(\.scene) == originalTimeline.map(\.scene))
        precondition(studio.segments.map(\.end) == originalTimeline.map(\.end))
        print("PASS cancellation: rapid skips advance independently, leaving cancels pending work and restores the editor paused")

        radio.selectStation("future-genre")
        try await wait("future station") { !radio.isCatalogLoading && radio.stationID == "future-genre" }
        precondition(radio.catalog?.tracks.count == 1 && radio.sourceText == stationsURL.absoluteString)
        favorites.toggleFavorite(NativeEffects.activeIDs[0]); favorites.toggleFavorite(NativeEffects.activeIDs[1])
        radio.start()
        try await wait("no favorites fallback") { !radio.isLoading }
        precondition(!radio.usesFavorites && radio.segments.allSatisfy { favorites.availableScenes.contains($0.scene) })
        let fallbackScene = radio.visualizer.scene
        radio.randomizeCurrentVisualizer()
        precondition(radio.visualizer.scene != fallbackScene && favorites.availableScenes.contains(radio.visualizer.scene))
        radio.leave()
        print("PASS station architecture: distinct catalogs, stable directory, persisted station selection and full-library fallback")

        radio.playFavoriteSong(savedSong)
        try await wait("favorite from another station") { radio.isActive && !radio.isLoading && radio.currentTrack?.id == tracks[0].id }
        precondition(audio.isPlaying && radio.stationID == "all-music", "Selecting a saved song must switch station and play that exact song")
        radio.leave()
        radio.selectStation("future-genre")
        try await wait("restore genre for refresh") { !radio.isCatalogLoading && radio.stationID == "future-genre" }
        print("PASS song favorites: selecting a saved song across stations opens Radio and starts the requested track")

        try JSONEncoder().encode(RadioCatalog(version: 1, title: "Updated without an app release", tracks: tracks)).write(to: secondCatalogURL)
        radio.loadSavedCatalogIfNeeded(refresh: true)
        try await wait("static JSON refresh") { !radio.isCatalogLoading && radio.catalog?.title == "Updated without an app release" }
        precondition(radio.catalog?.tracks.count == 3 && radio.stationID == "future-genre")
        radio.start(); radio.shutdown()
        try await Task.sleep(nanoseconds: 100_000_000)
        precondition(!radio.isActive && !radio.isLoading && !audio.isPlaying && audio.onSoundtrackFinished == nil)
        print("PASS static JSON refresh and shutdown: new songs load without a release, pending transitions cannot restart audio")

        // Removal requires a complete, successfully fetched catalog; neither a
        // genre subset nor a failed read is evidence of deletion.
        precondition(radio.isFavoriteSong(tracks[0]), "A genre subset removed another station's favorite")
        let offline = temporary.appendingPathComponent("catalog-offline.json")
        try FileManager.default.moveItem(at: catalogURL, to: offline)
        await radio.refreshFavoriteSongs()
        precondition(radio.isFavoriteSong(tracks[0]), "A failed catalog read removed a favorite")
        try FileManager.default.moveItem(at: offline, to: catalogURL)
        try JSONEncoder().encode(RadioCatalog(version: 1, title: "Removed first song", tracks: Array(tracks.dropFirst()))).write(to: catalogURL)
        radio.playFavoriteSong(savedSong)
        try await wait("removed favorite") { !radio.isCatalogLoading && radio.favoritePlaybackError != nil }
        precondition(!radio.isFavoriteSong(tracks[0]) && !radio.isActive, "Removed song was retained or played")
        let afterRemoval = RadioController(library: library, defaults: defaults, presets: favorites)
        precondition(!afterRemoval.isFavoriteSong(tracks[0]), "Removed favorite returned after relaunch")
        radio.toggleFavoriteSong(tracks[1]); precondition(radio.isFavoriteSong(tracks[1]))
        try JSONEncoder().encode(RadioCatalog(version: 1, title: "Empty library", tracks: [])).write(to: catalogURL)
        await radio.refreshFavoriteSongs()
        precondition(radio.favoriteSongs.isEmpty, "An empty complete library must remove its remaining favorites")
        radio.loadCatalog(at: catalogURL)
        try await wait("empty catalog") { !radio.isCatalogLoading }
        precondition(!radio.canStart)
        radio.start(); precondition(!radio.isActive, "An empty library must not start playback")
        print("PASS favorite removal: missing songs are pruned and persisted, genre/offline reads preserve valid picks, empty libraries are safe")

        // Every entry passes integrity but contains undecodable audio: retry must be bounded.
        let invalidData = Data("Not an audio file".utf8)
        let badFile = audioDirectory.appendingPathComponent("bad.m4a")
        try invalidData.write(to: badFile)
        let invalidTracks = (0..<2).map { index in RadioTrack(id: UUID().uuidString, title: "Unavailable \(index)", genre: "Test", duration: 3,
            audio: "audio/bad.m4a", sha256: SHA256.hash(data: invalidData).map { String(format: "%02x", $0) }.joined(), byteCount: invalidData.count) }
        try JSONEncoder().encode(RadioCatalog(version: 1, title: "Unavailable", tracks: invalidTracks)).write(to: catalogURL)
        radio.loadCatalog(at: catalogURL)
        try await wait("unavailable catalog") { radio.canStart && radio.catalog?.title == "Unavailable" }
        radio.start()
        try await wait("bounded failed library") { !radio.isLoading }
        precondition(radio.status == RadioError.allUnavailable.localizedDescription)
        radio.leave()
        print("PASS failure handling: all-broken playlist stops after one pass")

        if CommandLine.arguments.count > 1 {
            let argument = CommandLine.arguments[1]
            let realURL = argument.hasPrefix("https://") ? URL(string: argument)! : URL(fileURLWithPath: argument)
            let real = try await library.catalog(at: realURL)
            var total = 0.0, slowest = 0.0
            for track in real.tracks {
                let url = try await library.localAudio(for: track, catalogURL: realURL)
                let start = Date()
                let prepared = try await Task.detached { try PreparedSoundtrack(url: url) }.value
                let elapsed = Date().timeIntervalSince(start)
                slowest = max(slowest, elapsed)
                precondition(audio.install(prepared, title: track.title))
                precondition(abs(audio.duration - track.duration) < 0.1)
                let plan = audio.segmentPlan()!
                studio.segments = []; studio.makeTimeline(plan, render: render)
                precondition(StudioTimeline.valid(studio.segments, sceneCount: RenderState.sceneNames.count))
                precondition(plan.boundaries.first == 0 && abs(plan.boundaries.last! - audio.duration) < 0.001)
                audio.seek(fraction: 0.5)
                precondition(audio.spectrum.max()! > 0)
                total += track.duration
                print(String(format: "PASS %@: %.2fs preparation, %d clips covering %.2fs", track.title, elapsed, studio.segments.count, audio.duration))
            }
            audio.clear()
            print(String(format: "PASS all %d real tracks: %.1f minutes, slowest local preparation %.2fs", real.tracks.count, total / 60, slowest))
        }
    }
}
