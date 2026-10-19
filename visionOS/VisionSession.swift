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
    @Published private(set) var loading = false
    @Published private(set) var loadingStations = false
    @Published var error: String?
    private let source: URL
    private let library: RadioLibrary
    private var catalog: RadioCatalog?
    private var catalogURL: URL?
    private var currentTrack: Int?
    private var queue = RadioQueue()
    private var task: Task<Void, Never>?
    private var wantsPlayback = false

    init(directory: URL? = nil, source: URL = URL(string: "https://radio.pulsecanvas.si/stations.json")!,
         presets: ProjectMPresets? = nil) {
        let root = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PulseCanvas/VisionRadio", isDirectory: true)
        self.source = source
        library = RadioLibrary(directory: root.appendingPathComponent("Audio"))
        studio = VisionStudio(directory: root.appendingPathComponent("Session"), library: presets)
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
        loadingStations = true; error = nil
        defer { loadingStations = false }
        do {
            stations = try await library.stations(at: source).stations
            if !stations.contains(where: { $0.id == stationID }) {
                stationID = stations.first?.id ?? "all-music"
                catalog = nil; catalogURL = nil; queue.reset(); currentTrack = nil
            }
        } catch { self.error = "Stations couldn't load. Check your connection and try again." }
    }
    func selectStation(_ id: String) {
        guard !loading, stations.contains(where: { $0.id == id }) else { return }
        if id != stationID { stationID = id; catalog = nil; catalogURL = nil; queue.reset(); currentTrack = nil }
        nextSong()
    }
    func nextSong() {
        guard !loading else { return }
        loading = true; wantsPlayback = true; error = nil
        studio.suspend()
        task = Task { [weak self] in
            guard let self else { return }
            defer { self.loading = false }
            do {
                if self.stations.isEmpty { await self.refreshStations() }
                try Task.checkCancellation()
                guard let station = self.stations.first(where: { $0.id == self.stationID }) else { throw RadioError.invalidCatalog }
                if self.catalog == nil {
                    let url = try station.resolvedURL(relativeTo: self.source)
                    self.catalog = try await self.library.catalog(at: url); self.catalogURL = url
                    self.queue.reset(); self.currentTrack = nil
                }
                guard let catalog = self.catalog, let url = self.catalogURL,
                      let next = self.queue.next(count: catalog.tracks.count, current: self.currentTrack, shuffle: true) else {
                    throw RadioError.allUnavailable
                }
                let track = catalog.tracks[next]
                let audio = try await self.library.localAudio(for: track, catalogURL: url)
                try Task.checkCancellation()
                guard await self.studio.loadRadioAudio(audio, title: track.title) else { return }
                guard !Task.isCancelled, self.wantsPlayback else { self.studio.suspend(); return }
                self.currentTrack = next
                self.studio.randomizeVisualizer()
                self.studio.togglePlayback()
            } catch is CancellationError { }
            catch { self.error = "Radio couldn't play this track. \(error.localizedDescription)" }
        }
    }
    func togglePlayback() {
        guard !loading else { return }
        guard currentTrack != nil else { nextSong(); return }
        wantsPlayback = !studio.transport.playing
        studio.togglePlayback()
    }
    func suspend() { wantsPlayback = false; task?.cancel(); studio.suspend() }
    /// Awaitable for local fixture checks; UI requests stay asynchronous and responsive.
    func waitForTrack() async { await task?.value }
}
