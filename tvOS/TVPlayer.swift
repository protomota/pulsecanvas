import Combine
import Foundation

/// The TV streams the same public, server-managed station directory as the Mac.
@MainActor final class TVPlayer: ObservableObject {
    let studio: VisionStudio
    @Published private(set) var stations: [RadioStation] = []
    @Published private(set) var stationID = "all-music"
    @Published private(set) var loading = false
    @Published var error: String?
    private let source = URL(string: "https://radio.pulsecanvas.si/stations.json")!
    private let radio: RadioLibrary
    private var catalog: RadioCatalog?
    private var catalogURL: URL?
    private var trackID: String?
    private var radioActive = false
    private var wantsPlayback = false
    private var ticker: AnyCancellable?
    private var task: Task<Void, Never>?
    private var started = false

    init() {
        let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PulseCanvas", isDirectory: true)
        studio = VisionStudio(directory: cache.appendingPathComponent("Studio"))
        radio = RadioLibrary(directory: cache.appendingPathComponent("Radio"))
        stationID = UserDefaults.standard.string(forKey: "PulseCanvas.tv.station") ?? "all-music"
        ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self, self.radioActive, self.wantsPlayback, !self.loading,
                  !self.studio.transport.playing, self.studio.transport.duration > 0,
                  self.studio.transport.seconds >= self.studio.transport.duration - 0.3 else { return }
            self.nextSong()
        }
    }
    func start() async {
        guard !started else { return }; started = true
        await studio.start()
        do {
            stations = try await radio.stations(at: source).stations
            if !stations.contains(where: { $0.id == stationID }) { stationID = stations.first?.id ?? "all-music" }
        } catch { self.error = "Stations couldn't load. The included soundtrack is ready to play. Try Radio again to reconnect." }
    }
    func togglePlayback() {
        guard !loading else { return }
        wantsPlayback = !studio.transport.playing
        studio.togglePlayback()
    }
    func selectStation(_ id: String) {
        guard !loading else { return }
        stationID = id; UserDefaults.standard.set(id, forKey: "PulseCanvas.tv.station")
        nextSong(reload: true)
    }
    func nextSong(reload: Bool = false) {
        guard !loading else { return }
        loading = true
        task = Task { [weak self] in
            guard let self else { return }
            defer { self.loading = false }
            do {
                if self.stations.isEmpty { self.stations = try await self.radio.stations(at: self.source).stations }
                guard let station = self.stations.first(where: { $0.id == self.stationID }) ?? self.stations.first else { throw RadioError.invalidCatalog }
                if reload || self.catalog == nil {
                    self.catalog = nil; self.catalogURL = nil
                    let url = try station.resolvedURL(relativeTo: self.source)
                    self.catalog = try await self.radio.catalog(at: url); self.catalogURL = url
                }
                guard let catalog = self.catalog, let url = self.catalogURL, !catalog.tracks.isEmpty else { throw RadioError.allUnavailable }
                let candidates = catalog.tracks.filter { $0.id != self.trackID }
                guard let track = (candidates.isEmpty ? catalog.tracks : candidates).randomElement() else { return }
                let local = try await self.radio.localAudio(for: track, catalogURL: url)
                guard !Task.isCancelled else { return }
                guard await self.studio.loadRadioAudio(local, title: track.title) else { return }
                guard !Task.isCancelled else { self.studio.suspend(); return }
                self.trackID = track.id; self.radioActive = true; self.wantsPlayback = true
                self.randomizeVisualizer(); self.studio.togglePlayback()
            } catch { self.error = "Radio couldn't play this track. Check your connection and try again. \(error.localizedDescription)" }
        }
    }
    func randomizeVisualizer() {
        let choices = ProjectMPresets.shared.eligibleScenes.filter { $0 != studio.selectedScene }
        if let next = choices.randomElement() { studio.assign(next) }
    }
    func suspend() { wantsPlayback = false; task?.cancel(); studio.suspend() }
}
