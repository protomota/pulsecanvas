import Combine
import Foundation

/// Radio has its own transport and timeline; listening never overwrites a Studio project.
@MainActor final class VisionSession: ObservableObject {
    let editor: VisionStudio
    let radio: VisionRadio
    @Published private(set) var radioMode = false
    @Published var immersiveActive = false
    @Published var fullImmersion = true
    @Published var studioWindowHidden = false
    @Published var edgeSmoothing = true
    var activeStudio: VisionStudio { radioMode ? radio.studio : editor }

    init(editor: VisionStudio? = nil, radio: VisionRadio? = nil) {
        self.editor = editor ?? VisionStudio(); self.radio = radio ?? VisionRadio()
    }
    func setRadioMode(_ enabled: Bool) {
        guard enabled != radioMode, !immersiveActive else { return }
        if radioMode { radio.suspend() } else { editor.suspend() }
        radioMode = enabled
    }
    func suspend() { editor.suspend(); radio.suspend() }
}

@MainActor final class VisionRadio: ObservableObject {
    let studio: VisionStudio
    @Published private(set) var stations: [RadioStation] = []
    @Published private(set) var stationID = "all-music"
    @Published private(set) var favoriteSongs: [FavoriteRadioSong] = []
    @Published private(set) var favoriteSongsOnly = false
    @Published private(set) var loading = false
    @Published private(set) var loadingStations = false
    @Published var error: String?
    @Published private(set) var isPersonalMusic = false
    @Published private(set) var folderImportNotice: String?
    @Published var shuffle = true { didSet { queue.reset() } }
    var hasPersonalMusic: Bool { defaults.url(forKey: PersonalRadioMusic.catalogKey) != nil }
    var personalMusicTitle: String { isPersonalMusic ? catalog?.title ?? "My music folder" : "My music folder" }
    private var folderTask: Task<Void, Never>?
    private let source: URL
    var studioMusicSource: URL { source }
    var studioMusicLibrary: RadioLibrary { library }
    private let library: RadioLibrary
    private let defaults: UserDefaults
    private let favoriteSongsKey = "PulseCanvas.radio.favoriteSongs.v1"
    var musicGroupID: String { isPersonalMusic ? "my-music" : favoriteSongsOnly ? "favorite-songs" : stationID }
    var playingTrack: RadioTrack? {
        currentTrack.flatMap { index in catalog?.tracks.indices.contains(index) == true ? catalog?.tracks[index] : nil }
    }
    private var eligibleTrackIndices: [Int] {
        guard let catalog else { return [] }
        let favorites = Set(favoriteSongs.map(\.id))
        return catalog.tracks.indices.filter { !favoriteSongsOnly || favorites.contains(catalog.tracks[$0].id) }
    }
    private var catalog: RadioCatalog?
    private var catalogURL: URL?
    private var currentTrack: Int?
    private var queue = RadioQueue()
    private var task: Task<Void, Never>?
    private var wantsPlayback = false

    init(directory: URL? = nil, source: URL = URL(string: "https://radio.pulsecanvas.si/stations.json")!,
         presets: ProjectMPresets? = nil, defaults: UserDefaults = .standard) {
        let root = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PulseCanvas/VisionRadio", isDirectory: true)
        self.source = source
        self.defaults = defaults
        let personal = defaults.bool(forKey: PersonalRadioMusic.activeKey) && defaults.url(forKey: PersonalRadioMusic.catalogKey) != nil
        isPersonalMusic = personal
        if let data = defaults.data(forKey: favoriteSongsKey), data.count <= 8_000_000,
           let saved = try? JSONDecoder().decode([FavoriteRadioSong].self, from: data), saved.count <= 2_000 {
            var seen = Set<String>()
            favoriteSongs = saved.filter { $0.sourceURL == source && $0.isValid && seen.insert($0.id).inserted }
        }
        favoriteSongsOnly = !personal && defaults.bool(forKey: "PulseCanvas.radio.favoriteSongsOnly.v1")
        library = RadioLibrary(directory: root.appendingPathComponent("Audio"))
        studio = VisionStudio(directory: root.appendingPathComponent("Session"), library: presets)
        studio.randomizesPlaybackLooks = true
        studio.loopPlayback = false
        studio.onPlaybackFinished = { [weak self] in
            guard let self, self.wantsPlayback else { return }
            self.nextSong()
        }
    }
    private var stationsTask: Task<Void, Never>?
    /// Loads the station list. A second caller while a load is in flight waits for that load instead of returning at
    /// once: Play Radio pressed before the list arrived used to find no stations and report an invalid catalog.
    func refreshStations() async {
        if let stationsTask { await stationsTask.value; return }
        let task = Task { await self.loadStations() }
        stationsTask = task
        await task.value
        stationsTask = nil
    }
    private func loadStations() async {
        loadingStations = !isPersonalMusic; error = nil
        defer { loadingStations = false }
        do {
            stations = try await library.stations(at: source).stations
            if !isPersonalMusic && !stations.contains(where: { $0.id == stationID }) {
                stationID = stations.first?.id ?? "all-music"
                catalog = nil; catalogURL = nil; queue.reset(); currentTrack = nil
            }
        } catch { if !isPersonalMusic { self.error = "Stations couldn't load. Check your connection and try again." } }
    }
    func importMusicFolder(_ folder: URL) {
        guard !loading else { return }
        loading = true; error = nil; folderImportNotice = nil
        let previous = defaults.url(forKey: PersonalRadioMusic.catalogKey)
        folderTask = Task { [weak self, library] in
            do {
                let result = try await library.importMusicFolder(folder)
                guard let self, !Task.isCancelled else {
                    await library.removePersonalCopy(at: result.url); return
                }
                self.defaults.set(result.url, forKey: PersonalRadioMusic.catalogKey)
                self.loading = false; self.folderTask = nil
                self.selectStation("my-music")
                if result.skipped > 0 { self.folderImportNotice = "\(result.skipped) unsupported files skipped." }
                await library.removePersonalCopy(at: previous)
            } catch {
                if !Task.isCancelled { self?.loading = false; self?.error = error.localizedDescription }
            }
        }
    }

    func selectStation(_ id: String) {
        guard !loading else { return }
        if id == "my-music" {
            guard hasPersonalMusic else { return }
            isPersonalMusic = true; favoriteSongsOnly = false
            defaults.set(true, forKey: PersonalRadioMusic.activeKey)
            catalog = nil; catalogURL = nil; currentTrack = nil; queue.reset()
            nextSong(); return
        }
        if stations.isEmpty {
            Task { [weak self] in
                guard let self else { return }
                await self.refreshStations()
                if self.stations.isEmpty { self.error = "Stations couldn't load. Your local music remains available." }
                else { self.selectStation(id) }
            }
            return
        }
        if isPersonalMusic {
            isPersonalMusic = false; catalog = nil; catalogURL = nil; currentTrack = nil; queue.reset()
            defaults.set(false, forKey: PersonalRadioMusic.activeKey)
        }
        if id == "favorite-songs" {
            guard !loading else { return }
            favoriteSongsOnly = true
            defaults.set(true, forKey: "PulseCanvas.radio.favoriteSongsOnly.v1")
            if let all = stations.first(where: { $0.id == "all-music" }) ?? (stations.count == 1 ? stations.first : nil) {
                selectLoadedStation(all.id)
            } else { error = "The full music library isn't available. Try refreshing stations." }
            return
        }
        guard !loading, stations.contains(where: { $0.id == id }) else { return }
        favoriteSongsOnly = false
        defaults.set(false, forKey: "PulseCanvas.radio.favoriteSongsOnly.v1")
        selectLoadedStation(id)
    }
    private func selectLoadedStation(_ id: String) {
        if id != stationID { stationID = id; catalog = nil; catalogURL = nil; queue.reset(); currentTrack = nil }
        queue.reset()
        nextSong()
    }
    func isFavoriteSong(_ track: RadioTrack) -> Bool { favoriteSongs.contains { $0.id == track.id } }
    func toggleFavoriteSong(_ track: RadioTrack) {
        guard !isPersonalMusic || isFavoriteSong(track) else { return }
        if let index = favoriteSongs.firstIndex(where: { $0.id == track.id }) {
            favoriteSongs.remove(at: index)
        } else if let catalogURL, catalog?.tracks.contains(where: { $0.id == track.id }) == true,
                  favoriteSongs.count < 2_000 {
            let song = FavoriteRadioSong(track: track, sourceURL: source, catalogURL: catalogURL,
                stationID: stationID, folderBookmark: nil)
            guard song.isValid else { return }
            favoriteSongs.append(song)
        }
        persistFavorites()
        if favoriteSongsOnly && favoriteSongs.isEmpty { suspend() }
    }
    private func persistFavorites() {
        if let data = try? JSONEncoder().encode(favoriteSongs) { defaults.set(data, forKey: favoriteSongsKey) }
        queue.reset()
    }
    private var refreshingFavorites = false
    /// Only the full, successfully loaded catalog can establish that a saved song was removed.
    private func reconcileFavorites(_ complete: RadioCatalog, url: URL, stationID: String) {
        let tracks = Dictionary(uniqueKeysWithValues: complete.tracks.map { ($0.id, $0) })
        let retained = favoriteSongs.compactMap { song -> FavoriteRadioSong? in
            guard let track = tracks[song.id] else { return nil }
            return FavoriteRadioSong(track: track, sourceURL: source, catalogURL: url,
                stationID: stationID, folderBookmark: nil)
        }
        if retained != favoriteSongs { favoriteSongs = retained; persistFavorites() }
    }
    func refreshFavoriteSongs() async {
        guard !refreshingFavorites, !favoriteSongs.isEmpty else { return }
        refreshingFavorites = true
        defer { refreshingFavorites = false }
        guard let complete = try? await library.completeCatalog(at: source), !Task.isCancelled else { return }
        reconcileFavorites(complete.catalog, url: complete.url, stationID: complete.stationID)
        if favoriteSongsOnly && favoriteSongs.isEmpty { suspend() }
    }
    func playFavoriteSong(_ song: FavoriteRadioSong) {
        guard !loading, favoriteSongs.contains(where: { $0.id == song.id }) else { return }
        isPersonalMusic = false; defaults.set(false, forKey: PersonalRadioMusic.activeKey)
        favoriteSongsOnly = true
        defaults.set(true, forKey: "PulseCanvas.radio.favoriteSongsOnly.v1")
        // Refresh the full catalog before selecting the saved identity.
        stationID = "all-music"; catalog = nil; catalogURL = nil; currentTrack = nil; queue.reset()
        nextSong(preferredTrackID: song.id)
    }
    func nextSong(preferredTrackID: String? = nil) {
        guard !loading else { return }
        if favoriteSongsOnly && favoriteSongs.isEmpty {
            suspend(); error = "No favorite songs yet. Tap a song's heart in Radio to save it."; return
        }
        loading = true; wantsPlayback = true; error = nil
        studio.suspend()
        task = Task { [weak self] in
            guard let self else { return }
            defer { self.loading = false }
            do {
                if self.isPersonalMusic {
                    if self.catalog == nil {
                        guard let url = self.defaults.url(forKey: PersonalRadioMusic.catalogKey) else { throw RadioError.invalidCatalog }
                        self.catalog = try await self.library.catalog(at: url); self.catalogURL = url
                        self.queue.reset(); self.currentTrack = nil
                    }
                } else {
                    if self.stations.isEmpty { await self.refreshStations() }
                    try Task.checkCancellation()
                    let selectedID = self.favoriteSongsOnly ? "all-music" : self.stationID
                    guard let station = self.stations.first(where: { $0.id == selectedID })
                        ?? (self.stations.count == 1 ? self.stations.first : nil) else { throw RadioError.invalidCatalog }
                    self.stationID = station.id
                    if self.catalog == nil {
                        let url = try station.resolvedURL(relativeTo: self.source)
                        self.catalog = try await self.library.catalog(at: url); self.catalogURL = url
                        self.queue.reset(); self.currentTrack = nil
                        if station.id == "all-music" || self.stations.count == 1, let catalog = self.catalog {
                            self.reconcileFavorites(catalog, url: url, stationID: station.id)
                        }
                    }
                }
                let choices = self.eligibleTrackIndices
                guard let catalog = self.catalog, let url = self.catalogURL else { throw RadioError.invalidCatalog }
                let preferred = preferredTrackID.flatMap { id in choices.first(where: { catalog.tracks[$0].id == id }) }
                if preferredTrackID != nil && preferred == nil {
                    self.error = "This song is no longer available in Radio."; return
                }
                guard let first = preferred ?? self.queue.next(count: choices.count,
                    current: self.currentTrack.flatMap { choices.firstIndex(of: $0) }, shuffle: self.shuffle).map({ choices[$0] }) else {
                    throw RadioError.allUnavailable
                }
                let others = choices.filter { $0 != first }
                let candidates = [first] + (self.shuffle ? others.shuffled() : others)
                var loadedIndex: Int?
                for next in candidates {
                    try Task.checkCancellation()
                    let track = catalog.tracks[next]
                    do {
                        let audio = try await self.library.localAudio(for: track, catalogURL: url)
                        try Task.checkCancellation()
                        if await self.studio.loadRadioAudio(audio, title: track.title) { loadedIndex = next; break }
                    } catch is CancellationError { throw CancellationError() }
                    catch { continue }
                }
                guard let loadedIndex else { throw RadioError.allUnavailable }
                guard !Task.isCancelled, self.wantsPlayback else { self.studio.suspend(); return }
                self.currentTrack = loadedIndex
                self.studio.randomizeVisualizer()
                #if os(visionOS)
                VisionLaunchOptions.current.applyCaptureSequence(to: self.studio)
                #endif
                self.studio.togglePlayback()
            } catch is CancellationError { }
            catch { self.error = "Radio couldn't play this track. \(error.localizedDescription)" }
        }
    }
    func togglePlayback() {
        guard !loading else { return }
        if favoriteSongsOnly && (playingTrack.map { !isFavoriteSong($0) } ?? true) { nextSong(); return }
        guard currentTrack != nil else { nextSong(); return }
        wantsPlayback = !studio.transport.playing
        studio.togglePlayback()
    }
    func suspend() {
        wantsPlayback = false
        if folderTask != nil { folderTask?.cancel(); folderTask = nil; loading = false }
        task?.cancel(); studio.suspend()
    }
    /// Awaitable for local fixture checks; UI requests stay asynchronous and responsive.
    func waitForTrack() async { await task?.value }
}
