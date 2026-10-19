import AppKit
import Combine
import SwiftUI

@MainActor
struct RadioLibraryView: View {
    @ObservedObject var radio: RadioController
    let dismiss: () -> Void
    @State private var source = ""
    @State private var opening = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("PulseCanvas Radio", systemImage: "dot.radiowaves.left.and.right").font(.title2)
                Spacer()
                Button("Done", action: dismiss)
            }
            Text("Music and visuals on shuffle. Choose all, favorites, or a station.")
                .foregroundStyle(.secondary)
            if Bundle.main.object(forInfoDictionaryKey: "PulseCanvasRadioDeveloperMode") as? Bool == true {
            DisclosureGroup("Library source") {
            HStack {
                TextField("HTTPS catalog URL", text: $source).textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Radio catalog URL")
                Button("Load library") {
                    if let url = URL(string: source.trimmingCharacters(in: .whitespacesAndNewlines)), url.scheme == "https" {
                        radio.loadCatalog(at: url)
                    }
                }.disabled(URL(string: source)?.scheme != "https" || radio.isCatalogLoading)
            }
            }
            HStack {
                Button("Open local library…", action: openLocalLibrary)
                Text("Choose a folder containing catalog.json and its audio files.").font(.caption).foregroundStyle(.secondary)
            }
            }
            Divider()
            if opening || radio.isCatalogLoading {
                VStack(spacing: 16) {
                    ProgressView().controlSize(.large).tint(Color(red: 0.95, green: 0.68, blue: 0.55))
                    Text("Loading Radio…").font(.headline)
                    Text("Getting stations and songs ready.").font(.callout).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityElement(children: .combine)
            } else {
            HStack {
                Text(radio.favoriteSongsOnly ? "Favorite songs" : radio.stationTitle).font(.headline)
                Spacer()
                Button {
                    if radio.isActive { radio.next() } else { radio.start() }
                    dismiss()
                } label: {
                    Label(radio.isActive ? "Next song" : "Play radio",
                          systemImage: radio.isActive ? "forward.end.fill" : "play.fill")
                        .frame(minWidth: 104)
                }
                .buttonStyle(StudioButtonStyle(treatment: .primary))
                .disabled(!radio.canStart)
            }
            RadioMusicGroupPicker(radio: radio)
            if let message = radio.visualizerGroupMessage {
                HStack {
                    Text(message).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    VisualizerRandomizerPicker(compact: true)
                }
            }
            if let station = radio.stations.first(where: { $0.id == radio.stationID }), !radio.favoriteSongsOnly {
                Text(station.description).font(.caption).foregroundStyle(.secondary)
            }
            if radio.favoriteSongsOnly {
                FavoriteSongsView(radio: radio) { song in
                    radio.playFavoriteSong(song)
                    if radio.isActive { dismiss() }
                }
            } else if let catalog = radio.catalog {
                List(Array(catalog.tracks.enumerated()), id: \.element.id) { index, track in
                    HStack(spacing: 8) {
                    Button {
                        radio.start(at: index); dismiss()
                    } label: {
                        HStack {
                            Image(systemName: radio.isActive && radio.currentIndex == index ? "speaker.wave.2.fill" : "play.circle")
                            VStack(alignment: .leading, spacing: 3) {
                                Text(track.title)
                                Text(track.genre).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%d:%02d", Int(track.duration) / 60, Int(track.duration) % 60))
                                .monospacedDigit().foregroundStyle(.secondary)
                        }.padding(.vertical, 4).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    Button { radio.toggleFavoriteSong(track) } label: {
                        Image(systemName: radio.isFavoriteSong(track) ? "heart.fill" : "heart")
                            .frame(width: 44, height: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .accessibilityLabel("\(radio.isFavoriteSong(track) ? "Unfavorite" : "Favorite") song \(track.title)")
                    }
                }.frame(minHeight: 160, maxHeight: .infinity).disabled(radio.isCatalogLoading)
            } else {
                ContentUnavailableView("Choose a radio library", systemImage: "music.note.list",
                description: Text("Your radio library will appear here when it finishes loading."))
                    .frame(height: 220)
            }
            }
            HStack {
                if radio.isLoading { ProgressView().controlSize(.small) }
                Text(radio.isCatalogLoading ? "" : radio.status).font(.callout).foregroundStyle(.secondary).lineLimit(2)
                Spacer()
                if radio.isActive { Button("Leave radio") { radio.leave(); dismiss() } }
            }
            Text("Radio downloads music to this Mac for playback and analysis. Your own soundtracks stay on your Mac.")
                .font(.caption).foregroundStyle(.secondary)
        }.padding(24).frame(width: 670, height: 650)
            .onAppear { source = radio.sourceText; radio.loadSavedCatalogIfNeeded(refresh: !radio.isActive); opening = false }
            .onChange(of: radio.isActive) { _, active in if active && radio.favoriteSongsOnly { dismiss() } }
    }

    private func openLocalLibrary() {
        let picker = NSOpenPanel()
        picker.canChooseFiles = false; picker.canChooseDirectories = true; picker.allowsMultipleSelection = false
        picker.message = "Choose the radio library folder containing catalog.json and the audio folder"
        guard picker.runModal() == .OK, let folder = picker.url else { return }
        let index = FileManager.default.fileExists(atPath: folder.appendingPathComponent("stations.json").path) ? "stations.json" : "catalog.json"
        radio.loadCatalog(at: folder.appendingPathComponent(index), access: SecurityScopedAccess(url: folder))
    }
}

@MainActor
struct FavoriteSongsView: View {
    @ObservedObject var radio: RadioController
    let play: (FavoriteRadioSong) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Favorite songs").font(.headline)
                Spacer()
                Text("\(radio.favoriteSongs.count) \(radio.favoriteSongs.count == 1 ? "song" : "songs")")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Button {
                radio.playFavoriteStation()
            } label: {
                Label("Play favorite songs", systemImage: "shuffle")
            }.buttonStyle(StudioButtonStyle(treatment: .primary))
                .disabled(radio.favoriteSongs.isEmpty || radio.isCatalogLoading || radio.isLoading)
            Text("Choose a song to open Radio and start listening.").font(.callout).foregroundStyle(.secondary)
            if radio.favoriteSongs.isEmpty {
                ContentUnavailableView("No favorite songs yet", systemImage: "heart",
                    description: Text("Tap a song’s heart in Radio to save it here."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(radio.favoriteSongs.sorted { $0.track.title.localizedStandardCompare($1.track.title) == .orderedAscending }) { song in
                            HStack(spacing: 0) {
                                Button { play(song) } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "play.circle.fill").font(.title2).foregroundStyle(.orange)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(song.track.title).font(.system(size: 13, weight: .medium)).lineLimit(1)
                                            Text(song.track.genre).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                        }
                                        Spacer(minLength: 8)
                                    }.padding(12).frame(maxWidth: .infinity, minHeight: 56).contentShape(Rectangle())
                                }.buttonStyle(.plain).accessibilityLabel("Play \(song.track.title) in Radio")
                                Button { radio.toggleFavoriteSong(song.track) } label: {
                                    Image(systemName: "heart.fill").foregroundStyle(.orange)
                                        .frame(width: 44, height: 56).contentShape(Rectangle())
                                }.buttonStyle(.plain).accessibilityLabel("Unfavorite song \(song.track.title)")
                            }.background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
            if radio.isCatalogLoading || radio.isLoading {
                HStack { ProgressView().controlSize(.small); Text(radio.status).font(.caption) }
            } else if let error = radio.favoritePlaybackError {
                Text(error).font(.caption).foregroundStyle(.secondary)
            }
        }.frame(minHeight: 220)
            .task { await radio.refreshFavoriteSongs() }
    }
}

/// The editor's Library keeps visualizer browsing and saved songs in separate tabs.
@MainActor
struct PulseCanvasLibraryView: View {
    @ObservedObject var radio: RadioController
    let selected: Int
    var appearance: ((Int) -> VisualPreset)? = nil
    let choose: (Int) -> Void
    let dismiss: () -> Void
    @State private var favoriteSongsSelected = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button { favoriteSongsSelected = false } label: { Label("Visualizers", systemImage: "square.grid.2x2") }
                    .buttonStyle(StudioButtonStyle(treatment: favoriteSongsSelected ? .secondary : .accent, compact: true))
                Button { favoriteSongsSelected = true } label: { Label("Favorite songs", systemImage: "heart") }
                    .buttonStyle(StudioButtonStyle(treatment: favoriteSongsSelected ? .accent : .secondary, compact: true))
                Spacer()
            }.padding(.horizontal, 18).padding(.top, 18)
            if favoriteSongsSelected {
                FavoriteSongsView(radio: radio) { song in
                    radio.playFavoriteSong(song)
                    if radio.isActive { dismiss() }
                }.padding(18).frame(height: 560)
            } else {
                VisualizerBrowser(selected: selected, heading: "Visualizers", appearance: appearance, choose: choose)
            }
            HStack { Spacer(); Button("Done", action: dismiss).buttonStyle(StudioButtonStyle(compact: true)) }.padding(18)
        }.frame(width: 680)
            .onChange(of: radio.isActive) { _, active in if active && favoriteSongsSelected { dismiss() } }
    }
}

/// An independent listening surface: there are no Studio cards or appearance editors.
@MainActor
struct RadioPlayerView: View {
    @ObservedObject var radio: RadioController
    @ObservedObject var audio: AudioController
    @ObservedObject var render: RenderState
    @ObservedObject private var presets = ProjectMPresets.shared
    @State private var playbackRevision = 0
    @StateObject private var presentation = RadioPresentationController()
    @State private var controlsVisible = true
    @State private var hideControls: Task<Void, Never>?
    @State private var showLibrary = false
    @State private var trackingMenus = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            VisualizerView(state: render).ignoresSafeArea()
            if controlsVisible || !radio.isPlaybackRequested || radio.isLoading {
            controls.padding(20)
            .transition(.opacity)
            }
        }.background(Color.black)
            .background(StudioWindowReader(attach: presentation.attach).frame(width: 0, height: 0))
            .background(RadioPointerActivity(activity: revealControls).frame(width: 0, height: 0))
            .contentShape(Rectangle())
            .onAppear { revealControls() }
            .onChange(of: presentation.isFullScreen) { _, _ in revealControls() }
            .onChange(of: audio.isPlaying) { _, _ in revealControls() }
            .onChange(of: showLibrary) { _, _ in revealControls() }
            .onReceive(NotificationCenter.default.publisher(for: NSMenu.didBeginTrackingNotification)) { _ in
                trackingMenus += 1; hideControls?.cancel()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSMenu.didEndTrackingNotification)) { _ in
                trackingMenus = max(0, trackingMenus - 1)
                if trackingMenus == 0 { revealControls() }
            }
            .onDisappear { hideControls?.cancel(); presentation.restore() }
            .sheet(isPresented: $showLibrary) {
                RadioLibraryView(radio: radio) { showLibrary = false }
                    .dismissOnOutsideClick { showLibrary = false }
            }
    }

    private var visualizerRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    Label("Radio", systemImage: "dot.radiowaves.left.and.right").font(.headline)
                    currentVisualizer
                    visualizerControls
                    Spacer(minLength: 8)
                    presentationControls
                }
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        Label("Radio", systemImage: "dot.radiowaves.left.and.right").font(.headline)
                        currentVisualizer
                        Spacer(minLength: 8)
                        presentationControls
                    }
                    HStack { visualizerControls; Spacer(minLength: 0) }
                }
            }
            if let message = radio.visualizerGroupMessage {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var currentVisualizer: some View {
        if !radio.sceneTitle.isEmpty {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Visualizer").font(.caption2).foregroundStyle(.secondary)
                    Text(radio.sceneTitle).font(.callout.weight(.medium))
                        .lineLimit(1).truncationMode(.tail)
                }
                .help(radio.sceneTitle)
                .accessibilityElement(children: .combine)
                Button {
                    presets.toggleFavorite(render.scene, appearance: VisualPreset(render: render))
                    revealControls()
                } label: {
                    Image(systemName: presets.isFavorite(render.scene) ? "heart.fill" : "heart")
                }
                .buttonStyle(StudioButtonStyle(compact: true, circular: true))
                .accessibilityLabel(presets.isFavorite(render.scene) ? "Unfavorite visualizer" : "Favorite visualizer")
                .help(presets.isFavorite(render.scene) ? "Remove \(radio.sceneTitle) from Favorites" : "Add \(radio.sceneTitle) to Favorites")
            }
            .frame(maxWidth: 320, alignment: .leading)
        }
    }


    private var visualizerControls: some View {
        HStack(spacing: 12) {
            Button { radio.randomizeCurrentVisualizer(); revealControls() } label: {
                Label("Randomize", systemImage: "shuffle")
            }.buttonStyle(StudioButtonStyle(compact: true))
                .help("Choose another visualizer from the selected group without restarting the song")
                .disabled(!radio.canRandomizeVisualizer)
            VisualizerRandomizerPicker(compact: true)
                .onChange(of: radio.visualizerGroup) { _, _ in revealControls() }
            Picker("Bars per visualizer", selection: $radio.barsPerVisualizer) {
                ForEach(RadioController.barChoices, id: \.self) { Text("\($0) \($0 == 1 ? "bar" : "bars")").tag($0) }
            }.labelsHidden().frame(width: 96).controlSize(.large)
                .help("How many bars each Radio visualizer plays")
        }.fixedSize(horizontal: true, vertical: false)
    }

    private var presentationControls: some View {
        HStack(spacing: 12) {
            Button {
                presentation.toggle(); revealControls()
            } label: {
                Label(presentation.isFullScreen ? "Exit full screen" : "Present",
                      systemImage: presentation.isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
            }.buttonStyle(StudioButtonStyle(compact: true))
            Button("Back to editor") { radio.leave() }.buttonStyle(StudioButtonStyle(compact: true))
        }.fixedSize(horizontal: true, vertical: false)
    }

    private var controls: some View {
        let _ = playbackRevision
        return VStack(alignment: .leading, spacing: 12) {
            visualizerRow
            Divider().overlay(.white.opacity(0.12))
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(radio.isLoading ? "Preparing next song…" : radio.currentTrack?.title ?? "Radio")
                            .font(.title3.weight(.semibold)).lineLimit(1)
                        Button {
                            if let track = radio.currentTrack { radio.toggleFavoriteSong(track); revealControls() }
                        } label: {
                            Image(systemName: radio.currentTrack.map(radio.isFavoriteSong) == true ? "heart.fill" : "heart")
                        }.buttonStyle(StudioButtonStyle(compact: true, circular: true))
                            .disabled(radio.currentTrack == nil || radio.isLoading)
                            .opacity(radio.currentTrack == nil ? 0 : 1)
                            .accessibilityLabel(radio.currentTrack.map(radio.isFavoriteSong) == true ? "Unfavorite song" : "Favorite song")
                            .help("Save or remove this song in Library → Favorite songs")
                    }.frame(minHeight: 44)
                    Text(radio.isLoading || !audio.isPlaying ? radio.status : radio.currentTrack?.genre ?? "")
                        .font(.callout).foregroundStyle(.secondary).lineLimit(1).frame(height: 17)
                }
                Spacer()
                RadioMusicGroupPicker(radio: radio).frame(width: 240)
                    .onChange(of: radio.musicGroupID) { _, _ in revealControls() }
                Button { showLibrary = true; revealControls() } label: {
                    Label("Library", systemImage: "music.note.list")
                }.buttonStyle(StudioButtonStyle(compact: true))
            }
            HStack(spacing: 18) {
                Button { radio.togglePlayback() } label: {
                    Label(radio.isPlaybackRequested ? "Pause" : "Play", systemImage: radio.isPlaybackRequested ? "pause.fill" : "play.fill")
                        .frame(width: 58)
                }.buttonStyle(StudioButtonStyle(treatment: .primary, compact: true))
                Button { radio.next() } label: { Label("Skip", systemImage: "forward.end.fill") }
                    .buttonStyle(StudioButtonStyle(compact: true)).disabled(!radio.canStart)
                ProgressView(value: radio.isLoading ? 0 : audio.progress).tint(Color(red: 0.95, green: 0.68, blue: 0.55))
                Text("\(format(audio.playbackSeconds)) / \(format(audio.duration))").monospacedDigit().font(.caption)
                    .frame(width: 112, alignment: .trailing)
                Image(systemName: "speaker.wave.2")
                Slider(value: $radio.volume, in: 0...1).frame(width: 80).accessibilityLabel("Radio volume")
            }
        }.padding(20).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .onReceive(audio.visualizationUpdated.throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)) { playbackRevision &+= 1 }
    }

    private func format(_ value: Double) -> String {
        let seconds = max(0, Int(value)); return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func revealControls() {
        hideControls?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { controlsVisible = true }
        hideControls = Task { @MainActor in
            do { try await Task.sleep(for: .seconds(3)) } catch { return }
            guard audio.isPlaying, !radio.isLoading, !showLibrary, trackingMenus == 0 else { return }
            withAnimation(.easeOut(duration: 0.3)) { controlsVisible = false }
        }
    }
}

@MainActor
private struct RadioMusicGroupPicker: View {
    @ObservedObject var radio: RadioController
    var body: some View {
        Picker("Music", selection: Binding(get: { radio.musicGroupID }, set: { radio.selectMusicGroup($0) })) {
            ForEach(radio.stations) { station in Text(station.title).tag(station.id) }
            Text("Favorite songs").tag("favorite-songs")
        }.labelsHidden().pickerStyle(.menu).controlSize(.large)
            .accessibilityLabel("Radio music station")
    }
}

/// Native renderer surfaces can consume SwiftUI hover tracking. Observe actual
/// pointer events in this Radio window without consuming clicks or monitoring other apps.
private struct RadioPointerActivity: NSViewRepresentable {
    let activity: () -> Void
    func makeNSView(context: Context) -> RadioPointerView {
        let view = RadioPointerView()
        view.activity = activity
        return view
    }
    func updateNSView(_ view: RadioPointerView, context: Context) { view.activity = activity }
    static func dismantleNSView(_ view: RadioPointerView, coordinator: ()) { view.stop() }
}

private final class RadioPointerView: NSView {
    var activity: () -> Void = {}
    private var monitor: Any?
    private weak var monitoredWindow: NSWindow?
    private var previousMouseMovedEvents = false
    private var lastActivity = -Double.infinity

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stop()
        guard let window else { return }
        monitoredWindow = window
        previousMouseMovedEvents = window.acceptsMouseMovedEvents
        window.acceptsMouseMovedEvents = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown, .rightMouseDown, .scrollWheel]) { [weak self] event in
            MainActor.assumeIsolated {
                guard let self, event.window === self.monitoredWindow else { return }
                let now = ProcessInfo.processInfo.systemUptime
                guard now - self.lastActivity >= 0.1 else { return }
                self.lastActivity = now
                self.activity()
            }
            return event
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil }
        monitoredWindow?.acceptsMouseMovedEvents = previousMouseMovedEvents
        monitoredWindow = nil
    }
}

/// Radio always fills the window. Its full-screen state never reads export aspect settings.
@MainActor
final class RadioPresentationController: NSObject, ObservableObject {
    @Published private(set) var isFullScreen = false
    private weak var window: NSWindow?
    private var startedFullScreen: Bool?
    private var keyboardMonitor: Any?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(changed(_:)), name: NSWindow.didEnterFullScreenNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changed(_:)), name: NSWindow.didExitFullScreenNotification, object: nil)
    }

    func attach(_ window: NSWindow?) {
        self.window = window
        guard let window else { return }
        let full = window.styleMask.contains(.fullScreen)
        if startedFullScreen == nil { startedFullScreen = full }
        if isFullScreen != full { isFullScreen = full }
        if keyboardMonitor == nil {
            keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, self.isFullScreen, event.keyCode == 53,
                      event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty else { return event }
                if !event.isARepeat { self.toggle() }
                return nil
            }
        }
    }

    func toggle() { window?.toggleFullScreen(nil) }

    func restore() {
        if let keyboardMonitor { NSEvent.removeMonitor(keyboardMonitor); self.keyboardMonitor = nil }
        if startedFullScreen == false, window?.styleMask.contains(.fullScreen) == true { window?.toggleFullScreen(nil) }
    }

    @objc private func changed(_ notification: Notification) {
        guard let source = notification.object as? NSWindow, source === window else { return }
        isFullScreen = source.styleMask.contains(.fullScreen)
    }
}
