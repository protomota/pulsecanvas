import Combine
import Foundation

@MainActor
final class RadioController: ObservableObject {
    let visualizer = RenderState()
    @Published private(set) var catalog: RadioCatalog?
    @Published private(set) var stations: [RadioStation] = []
    @Published private(set) var stationID = "all-music"
    @Published private(set) var currentIndex: Int?
    @Published private(set) var isActive = false
    @Published private(set) var isLoading = false
    @Published private(set) var isCatalogLoading = false
    @Published private(set) var status = "Choose a radio library to begin"
    var visualizerGroup: VisualizerRandomizerGroup { presets.randomizerGroup }
    @Published private(set) var favoriteSongsOnly = false
    @Published private(set) var visualizerChoices: [Int] = []
    var usesFavorites: Bool { visualizerGroup == .favorites && !visualizerChoices.isEmpty }
    var canRandomizeVisualizer: Bool { !isLoading && visualizerChoices.contains { $0 != visualizer.scene } }
    var visualizerGroupMessage: String? {
        guard visualizerChoices.isEmpty else { return nil }
        return visualizerGroup == .favorites
            ? "No favorite visualizers in this pool. Add a heart or choose another group."
            : "No visualizers in this group. Choose another group or change the visualizer pool."
    }
    var musicGroupID: String { favoriteSongsOnly ? "favorite-songs" : stationID }
    var eligibleTrackIndices: [Int] {
        guard let catalog else { return [] }
        let favorites = Set(favoriteSongs.map(\.id))
        return catalog.tracks.indices.filter { !favoriteSongsOnly || favorites.contains(catalog.tracks[$0].id) }
    }
    @Published private(set) var sceneTitle = ""
    @Published private(set) var favoriteSongs: [FavoriteRadioSong] = []
    @Published private(set) var favoritePlaybackError: String?
    private let favoriteSongsKey = "PulseCanvas.radio.favoriteSongs.v1"
    @Published var volume: Float = 0.7 {
        didSet {
            defaults.set(volume, forKey: "PulseCanvas.radio.volume")
            if isActive { audio?.volume = volume }
        }
    }
    @Published var barsPerVisualizer: Int = 4 {
        didSet {
            guard Self.barChoices.contains(barsPerVisualizer) else { barsPerVisualizer = 4; return }
            defaults.set(barsPerVisualizer, forKey: "PulseCanvas.radio.bars")
            if isActive && !isLoading { rebuildVisuals() }
        }
    }
    static let barChoices = [1, 2, 4, 8, 16]
    @Published var shuffle = true { didSet { queue.reset(); discardPrefetch() } }
    @Published private(set) var sourceText: String
    private(set) var segments: [StudioSegment] = []
    let soundtrackInstalled = PassthroughSubject<Void, Never>()
    var currentTrack: RadioTrack? { currentIndex.flatMap { catalog?.tracks.indices.contains($0) == true ? catalog?.tracks[$0] : nil } }
    var stationTitle: String { stations.first { $0.id == stationID }?.title ?? catalog?.title ?? "All Music" }
    var canStart: Bool { !eligibleTrackIndices.isEmpty && !visualizerChoices.isEmpty && !isCatalogLoading }
    private let library: RadioLibrary
    private let defaults: UserDefaults
    private let presets: ProjectMPresets
    private var directoryURL: URL?
    private var catalogURL: URL?
    private var catalogAccess: SecurityScopedAccess?
    private var queue = RadioQueue()
    private var task: Task<Void, Never>?
    private var prefetch: Task<Void, Never>?
    private var upcomingIndex: Int?
    private var preparedNext: (index: Int, audio: PreparedSoundtrack)?
    private var revision = UUID()
    private var wantsPlayback = true
    private var requestedIndex: Int?
    private var hasRadioAudio = false
    private var refreshingFavorites = false
    private var visualFavoritesObserver: AnyCancellable?
    private var visualPoolObserver: AnyCancellable?
    private var visualCatalogObserver: AnyCancellable?
    private var playedVisualizers = Set<Int>()
    private weak var audio: AudioController?
    private var snapshot: Snapshot?
    private struct Snapshot {
        let url: URL?
        let bookmark: Data?
        let progress: Double
        let title: String
        let loop: Bool
        let volume: Float
    }

    init(library: RadioLibrary = RadioLibrary(), defaults: UserDefaults = .standard, presets: ProjectMPresets? = nil) {
        self.library = library; self.defaults = defaults; self.presets = presets ?? .shared
        sourceText = defaults.string(forKey: "PulseCanvas.radio.catalogURL")
            ?? Bundle.main.object(forInfoDictionaryKey: "PulseCanvasRadioCatalogURL") as? String
            ?? "https://radio.pulsecanvas.si/stations.json"
        if let data = defaults.data(forKey: favoriteSongsKey), data.count <= 8_000_000,
           let saved = try? JSONDecoder().decode([FavoriteRadioSong].self, from: data), saved.count <= 2_000 {
            var seen = Set<String>()
            favoriteSongs = saved.filter { $0.isValid && seen.insert($0.id).inserted }
        }
        visualizerChoices = self.presets.eligibleScenes
        favoriteSongsOnly = defaults.bool(forKey: "PulseCanvas.radio.favoriteSongsOnly.v1")
        let bars = defaults.integer(forKey: "PulseCanvas.radio.bars")
        barsPerVisualizer = Self.barChoices.contains(bars) ? bars : 4
        if let savedVolume = defaults.object(forKey: "PulseCanvas.radio.volume") as? NSNumber {
            let value = savedVolume.floatValue
            volume = value.isFinite ? min(1, max(0, value)) : 0.7
        }
        visualFavoritesObserver = self.presets.$favoriteIDs.dropFirst().sink { [weak self] _ in
            // @Published sends before storing the new set; read it on the next turn.
            Task { @MainActor [weak self] in
                guard let self, self.presets.pool.enabled, self.presets.pool.favoritesOnly else { return }
                self.refreshVisualizerGroup()
            }
        }
        visualPoolObserver = self.presets.$pool.dropFirst().sink { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.refreshVisualizerGroup()
            }
        }
        visualCatalogObserver = self.presets.$entries.dropFirst().sink { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshVisualizerGroup() }
        }
    }

    func selectVisualizerGroup(_ group: VisualizerRandomizerGroup) {
        presets.setRandomizerGroup(group)
        refreshVisualizerGroup()
    }

    /// Keep transport and bar boundaries intact; replace an out-of-group current look immediately.
    private func refreshVisualizerGroup() {
        visualizerChoices = presets.eligibleScenes
        guard isActive, !isLoading, let audio else { return }
        let available = visualizerChoices
        if !available.isEmpty, !available.contains(visualizer.scene),
           let index = StudioTimeline.index(at: audio.playbackSeconds, in: segments),
           let scene = available.randomElement() {
            segments[index].scene = scene
            sceneTitle = ""
            follow(time: audio.playbackSeconds)
        }
        rebuildVisuals(keepingCurrent: true)
    }

    func selectMusicGroup(_ id: String, startPlayback: Bool = false) {
        let favorites = id == "favorite-songs"
        favoriteSongsOnly = favorites
        defaults.set(favorites, forKey: "PulseCanvas.radio.favoriteSongsOnly.v1")
        queue.reset(); discardPrefetch()
        let station = favorites ? "all-music" : id
        defaults.set(station, forKey: "PulseCanvas.radio.station")
        selectStation(station, startPlayback: startPlayback)
        if startPlayback, !isCatalogLoading { start() }
        if isActive, !isCatalogLoading, let currentIndex, let catalog, let catalogURL {
            prepareNextTrack(after: currentIndex, catalog: catalog, catalogURL: catalogURL)
        }
    }

    func playFavoriteStation() { selectMusicGroup("favorite-songs", startPlayback: true) }

    func attach(audio: AudioController) { self.audio = audio }
    /// Preserve the requested transport state through a temporary download/decode pause.
    var isPlaybackRequested: Bool { isLoading ? wantsPlayback : audio?.isPlaying == true }

    func isFavoriteSong(_ track: RadioTrack) -> Bool { favoriteSongs.contains { $0.id == track.id } }

    func toggleFavoriteSong(_ track: RadioTrack) {
        if let index = favoriteSongs.firstIndex(where: { $0.id == track.id }) {
            favoriteSongs.remove(at: index)
        } else {
            guard let catalogURL, let directoryURL, favoriteSongs.count < 2_000,
                  catalog?.tracks.contains(where: { $0.id == track.id }) == true else { return }
            let song = FavoriteRadioSong(track: track, sourceURL: directoryURL, catalogURL: catalogURL,
                stationID: stationID, folderBookmark: try? catalogAccess?.readOnlyBookmark())
            guard song.isValid else { return }
            favoriteSongs.append(song)
        }
        persistFavoriteSongs()
    }

    private func persistFavoriteSongs() {
        if let data = try? JSONEncoder().encode(favoriteSongs) { defaults.set(data, forKey: favoriteSongsKey) }
        queue.reset(); discardPrefetch()
        if isActive, !isLoading, let currentIndex, let catalog, let catalogURL {
            prepareNextTrack(after: currentIndex, catalog: catalog, catalogURL: catalogURL)
        }
    }

    func refreshFavoriteSongs() async {
        guard !refreshingFavorites else { return }
        refreshingFavorites = true
        defer { refreshingFavorites = false }
        var checked = Set<URL>()
        for song in favoriteSongs where checked.insert(song.sourceURL).inserted {
            let folder = SecurityScopedAccess.resolve(bookmark: song.folderBookmark, fallback: song.sourceURL.deletingLastPathComponent())
            let source = song.sourceURL.isFileURL ? folder.appendingPathComponent(song.sourceURL.lastPathComponent) : song.sourceURL
            let access = source.isFileURL ? SecurityScopedAccess(url: folder) : nil
            defer { withExtendedLifetime(access) {} }
            guard let complete = try? await library.completeCatalog(at: source), !Task.isCancelled else { continue }
            reconcileFavoriteSongs(complete.catalog, source: song.sourceURL, catalogURL: complete.url, station: complete.stationID)
        }
    }

    private func reconcileFavoriteSongs(_ complete: RadioCatalog, source: URL, catalogURL: URL, station: String) {
        let tracks = Dictionary(uniqueKeysWithValues: complete.tracks.map { ($0.id, $0) })
        let retained = favoriteSongs.compactMap { song -> FavoriteRadioSong? in
            guard song.sourceURL == source else { return song }
            guard let track = tracks[song.id] else { return nil }
            return FavoriteRadioSong(track: track, sourceURL: source, catalogURL: catalogURL,
                stationID: station, folderBookmark: song.folderBookmark)
        }
        guard retained != favoriteSongs else { return }
        favoriteSongs = retained
        persistFavoriteSongs()
    }

    func playFavoriteSong(_ song: FavoriteRadioSong) {
        guard song.isValid else { return }
        favoritePlaybackError = nil
        let folder = SecurityScopedAccess.resolve(bookmark: song.folderBookmark, fallback: song.sourceURL.deletingLastPathComponent())
        let source = song.sourceURL.isFileURL ? folder.appendingPathComponent(song.sourceURL.lastPathComponent) : song.sourceURL
        loadCatalog(at: source, access: source.isFileURL ? SecurityScopedAccess(url: folder) : nil,
                    preferredStationID: song.stationID, playTrackID: song.id)
    }

    func loadSavedCatalogIfNeeded(refresh: Bool = false) {
        guard (catalog == nil || refresh), !isCatalogLoading, !sourceText.isEmpty, let url = URL(string: sourceText) else { return }
        let bookmark = url.isFileURL ? defaults.data(forKey: "PulseCanvas.radio.folderBookmark") : nil
        let directory = SecurityScopedAccess.resolve(bookmark: bookmark, fallback: url.deletingLastPathComponent())
        loadCatalog(at: url.isFileURL ? directory.appendingPathComponent(url.lastPathComponent) : url,
                    access: url.isFileURL ? SecurityScopedAccess(url: directory) : nil)
    }

    /// A stations directory is the public entry point. A direct catalog also works for local testing.
    func loadCatalog(at url: URL, access: SecurityScopedAccess? = nil, preferredStationID: String? = nil, playTrackID: String? = nil) {
        leave()
        task?.cancel(); revision = UUID(); let token = revision
        isCatalogLoading = true; status = "Loading radio library…"
        task = Task { [weak self, library] in
            let lease = access
            do {
                let stationList: [RadioStation]
                let stationURL: URL
                if url.lastPathComponent == "stations.json" {
                    let directory = try await library.stations(at: url)
                    stationList = directory.stations
                    let savedID = preferredStationID ?? (self?.favoriteSongsOnly == true ? "all-music" : self?.defaults.string(forKey: "PulseCanvas.radio.station"))
                    let selected = stationList.first { $0.id == savedID } ?? stationList[0]
                    stationURL = try selected.resolvedURL(relativeTo: url)
                } else {
                    stationList = [RadioStation(id: "all-music", title: "All Music", description: "Every genre, one station", catalog: url.absoluteString)]
                    stationURL = url
                }
                let loaded = try await library.catalog(at: stationURL)
                try Task.checkCancellation()
                guard let self, self.revision == token else { return }
                self.catalog = loaded; self.catalogURL = stationURL; self.catalogAccess = lease
                self.stations = stationList; self.directoryURL = url
                self.stationID = try stationList.first { try $0.resolvedURL(relativeTo: url) == stationURL }?.id ?? stationList[0].id
                self.sourceText = url.absoluteString; self.currentIndex = nil; self.queue.reset()
                self.defaults.set(url.absoluteString, forKey: "PulseCanvas.radio.catalogURL")
                self.defaults.set(try? lease?.readOnlyBookmark(), forKey: "PulseCanvas.radio.folderBookmark")
                if stationList.count == 1 || self.stationID == "all-music" {
                    self.reconcileFavoriteSongs(loaded, source: url, catalogURL: stationURL, station: self.stationID)
                }
                self.isCatalogLoading = false; self.status = "\(loaded.tracks.count) songs · Ready to play"
                Task { [weak self] in await self?.refreshFavoriteSongs() }
                if let playTrackID {
                    if let index = loaded.tracks.firstIndex(where: { $0.id == playTrackID }) { self.start(at: index) }
                    else {
                        self.status = "This favorite is no longer available in its radio library."
                        self.favoritePlaybackError = self.status
                    }
                }
            } catch {
                guard let self, self.revision == token else { return }
                self.isCatalogLoading = false; self.status = error.localizedDescription
                if playTrackID != nil { self.favoritePlaybackError = self.status }
            }
        }
    }

    func selectStation(_ id: String, startPlayback: Bool = false) {
        guard id != stationID, let station = stations.first(where: { $0.id == id }), let directoryURL,
              let url = try? station.resolvedURL(relativeTo: directoryURL) else { return }
        let resume = isActive || startPlayback
        leave(); revision = UUID(); let token = revision
        isCatalogLoading = true; status = "Loading \(station.title)…"
        task = Task { [weak self, library] in
            do {
                let loaded = try await library.catalog(at: url)
                try Task.checkCancellation()
                guard let self, self.revision == token else { return }
                self.catalog = loaded; self.catalogURL = url; self.stationID = id
                self.defaults.set(id, forKey: "PulseCanvas.radio.station")
                self.currentIndex = nil; self.queue.reset(); self.isCatalogLoading = false
                self.status = "\(loaded.tracks.count) songs · Ready to play"
                if resume { self.start() }
            } catch {
                guard let self, self.revision == token else { return }
                self.isCatalogLoading = false; self.status = error.localizedDescription
            }
        }
    }

    func start(at index: Int? = nil) {
        guard canStart, let audio else { return }
        if !isActive {
            hasRadioAudio = false
            snapshot = Snapshot(url: audio.selectedURL, bookmark: audio.soundtrackBookmark, progress: audio.progress,
                title: audio.title, loop: audio.loopEnabled, volume: audio.volume)
            isActive = true
            audio.volume = volume
        }
        wantsPlayback = true
        audio.onSoundtrackFinished = { [weak self] in self?.next() }
        guard let selected = index.flatMap({ eligibleTrackIndices.contains($0) ? $0 : nil })
            ?? queuedTrack(after: currentIndex) else { return }
        loadTrack(at: selected)
    }

    func next() {
        guard isActive, let index = upcomingIndex ?? queuedTrack(after: requestedIndex ?? currentIndex) else { return }
        loadTrack(at: index)
    }

    private func queuedTrack(after current: Int?) -> Int? {
        let choices = eligibleTrackIndices
        guard let next = queue.next(count: choices.count, current: current.flatMap { choices.firstIndex(of: $0) }, shuffle: shuffle) else { return nil }
        return choices[next]
    }

    func togglePlayback() {
        guard isActive, let audio else { return }
        if !isLoading && !hasRadioAudio { start(at: currentIndex); return }
        if isLoading { wantsPlayback.toggle(); status = wantsPlayback ? "Preparing next song…" : "Next song will start paused" }
        else { if audio.isPlaying { audio.pause() } else { audio.playFullSoundtrack() }; wantsPlayback = audio.isPlaying }
    }

    /// Reroll only within the selected group, without restarting the music.
    func randomizeCurrentVisualizer() {
        guard isActive, !isLoading, let audio,
              let index = StudioTimeline.index(at: audio.playbackSeconds, in: segments) else { return }
        let alternatives = visualizerChoices.filter { $0 != visualizer.scene }
        let unheard = alternatives.filter { !playedVisualizers.contains($0) }
        guard let scene = (unheard.isEmpty ? alternatives : unheard).randomElement() else { return }
        segments[index].scene = scene
        follow(time: audio.playbackSeconds)
        rebuildVisuals(keepingCurrent: true)
    }

    func pause() {
        wantsPlayback = false; audio?.pause()
        if isLoading { task?.cancel(); revision = UUID(); isLoading = false; requestedIndex = nil; status = "Radio paused" }
    }

    func leave() {
        task?.cancel(); discardPrefetch(); revision = UUID()
        isCatalogLoading = false; isLoading = false; requestedIndex = nil
        guard isActive, let audio else { return }
        audio.onSoundtrackFinished = nil; audio.pause(); isActive = false
        if let saved = snapshot {
            if let url = saved.url {
                if audio.load(url: url, bookmark: saved.bookmark) { audio.seek(fraction: saved.progress) }
            } else { audio.clear() }
            audio.loopEnabled = saved.loop
            audio.volume = saved.volume
            soundtrackInstalled.send()
        }
        snapshot = nil; segments = []; hasRadioAudio = false; status = "Radio stopped · Your soundtrack restored"
    }

    /// App shutdown cancels downloads and completions without reloading the editor song.
    func shutdown() {
        task?.cancel(); discardPrefetch(); revision = UUID()
        audio?.onSoundtrackFinished = nil; audio?.stop()
        isActive = false; isLoading = false; isCatalogLoading = false
        requestedIndex = nil; snapshot = nil; segments = []; hasRadioAudio = false
    }

    func follow(time: Double) {
        guard isActive, let index = StudioTimeline.index(at: time, in: segments) else { return }
        let scene = segments[index].scene
        playedVisualizers.insert(scene)
        guard visualizer.scene != scene || sceneTitle.isEmpty else { return }
        visualizer.scene = scene
        presets.appearanceForSelection(scene).apply(to: visualizer)
        sceneTitle = RenderState.sceneNames[scene]
    }

    private func rebuildVisuals(keepingCurrent: Bool = false, previousScene: Int? = nil) {
        guard let audio, let plan = audio.segmentPlan(beatsPerSection: barsPerVisualizer * 4) else { return }
        visualizerChoices = presets.eligibleScenes
        let available = visualizerChoices
        if !sceneTitle.isEmpty, let index = StudioTimeline.index(at: audio.playbackSeconds, in: segments) {
            var retained = Array(segments.prefix(index + 1))
            let last = retained.removeLast()
            let end = keepingCurrent ? last.end : plan.boundaries.first(where: { $0 > audio.playbackSeconds }) ?? audio.duration
            retained.append(StudioSegment(start: last.start, end: end, scene: visualizer.scene, bars: barsPerVisualizer))
            let remaining = SongSegmentation(boundaries: [end] + plan.boundaries.filter { $0 > end }, bpm: plan.bpm)
            let future = RadioVisualSchedule.make(plan: remaining, pool: available, bars: barsPerVisualizer,
                previous: visualizer.scene)
            if future.isEmpty, end < audio.duration {
                let held = retained.removeLast()
                retained.append(StudioSegment(start: held.start, end: audio.duration, scene: held.scene, bars: held.bars))
            }
            segments = retained + future
        } else {
            segments = RadioVisualSchedule.make(plan: plan, pool: available, bars: barsPerVisualizer,
                previous: previousScene)
        }
        follow(time: audio.playbackSeconds)
    }

    private func discardPrefetch() {
        prefetch?.cancel(); prefetch = nil; upcomingIndex = nil; preparedNext = nil
    }

    private func loadTrack(at first: Int) {
        guard let audio, let catalog, let catalogURL, eligibleTrackIndices.contains(first) else { return }
        let choices = eligibleTrackIndices
        let ready = preparedNext?.index == first ? preparedNext?.audio : nil
        task?.cancel(); discardPrefetch(); revision = UUID(); let token = revision
        requestedIndex = first
        audio.pause(); isLoading = true; status = "Preparing \(catalog.tracks[first].title)…"
        task = Task { [weak self, library] in
            var index = first
            var attempted = Set<Int>()
            while attempted.insert(index).inserted {
                do {
                    let track = catalog.tracks[index]
                    let prepared: PreparedSoundtrack
                    if index == first, let ready { prepared = ready }
                    else {
                        let url = try await library.localAudio(for: track, catalogURL: catalogURL)
                        prepared = try await Task.detached(priority: .userInitiated) { try PreparedSoundtrack(url: url) }.value
                    }
                    try Task.checkCancellation()
                    guard let self, self.revision == token, self.isActive else { return }
                    let previousScene = self.hasRadioAudio ? self.visualizer.scene : nil
                    guard audio.install(prepared, title: track.title) else { throw RadioError.download }
                    self.hasRadioAudio = true
                    self.currentIndex = index; self.requestedIndex = nil; self.isLoading = false
                    self.segments = []; self.playedVisualizers = []; self.sceneTitle = ""
                    self.rebuildVisuals(previousScene: previousScene); self.soundtrackInstalled.send()
                    self.status = "\(track.title) · \(track.genre)"
                    if self.wantsPlayback { audio.playFullSoundtrack() }
                    // Download AND analyze the next song while this song plays.
                    self.prepareNextTrack(after: index, catalog: catalog, catalogURL: catalogURL)
                    return
                } catch {
                    guard let self, self.revision == token, !Task.isCancelled else { return }
                    self.status = "Skipping \(catalog.tracks[index].title): \(error.localizedDescription)"
                    guard let position = choices.firstIndex(of: index) else { break }
                    index = choices[(position + 1) % choices.count]
                }
            }
            guard let self, self.revision == token else { return }
            self.isLoading = false; self.requestedIndex = nil; self.wantsPlayback = false
            self.status = RadioError.allUnavailable.localizedDescription
        }
    }

    private func prepareNextTrack(after index: Int, catalog: RadioCatalog, catalogURL: URL) {
        guard let nextIndex = queuedTrack(after: index) else { return }
        upcomingIndex = nextIndex
        let next = catalog.tracks[nextIndex], token = revision
        prefetch = Task { [weak self, library] in
            do {
                let url = try await library.localAudio(for: next, catalogURL: catalogURL)
                let prepared = try await Task.detached(priority: .utility) { try PreparedSoundtrack(url: url) }.value
                try Task.checkCancellation()
                guard let self, self.revision == token else { return }
                self.preparedNext = (nextIndex, prepared)
            } catch { /* The transition retries and reports failures if needed. */ }
        }
    }
}
