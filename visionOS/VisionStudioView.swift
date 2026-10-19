import SwiftUI
import UniformTypeIdentifiers

struct VisionStudioView: View {
    @ObservedObject var studio: VisionStudio
    @ObservedObject var session: VisionSession
    @Environment(\.openImmersiveSpace) private var openSpace
    @Environment(\.dismissImmersiveSpace) private var dismissSpace
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.scenePhase) private var phase
    @State private var importAudio = false
    @State private var importProject = false
    @State private var exportProject = false
    @State private var projectData = Data()
    @State private var locateAudio = false
    @State private var exportVideo = false
    @State private var changingSpace = false
    @State private var legal = false
    @State private var launchApplied = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 20) {
                VStack(spacing: 12) {
                    Picker("Workspace", selection: Binding(get: { session.radioMode }, set: { session.setRadioMode($0) })) {
                        Label("Studio", systemImage: "rectangle.split.3x1").tag(false)
                        Label("Radio", systemImage: "radio").tag(true)
                    }.pickerStyle(.segmented).disabled(session.immersiveActive)
                        .accessibilityIdentifier("workspacePicker")
                    if session.radioMode { VisionRadioControls(radio: session.radio) }
                    VisionLibrary(studio: studio)
                }.frame(width: 340)
                VStack(alignment: .leading, spacing: 12) {
                    Text(NativeEffects.names[studio.selectedScene]).font(.title2.bold()).lineLimit(1)
                        .accessibilityIdentifier("selectedVisualizerName")
                    Group {
                        if session.immersiveActive {
                            VStack(spacing: 16) {
                                Image(systemName: "visionpro").font(.largeTitle)
                                Text("Immersive viewing is active").font(.title3)
                            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if exportVideo {
                            Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else { VisualizerView(state: studio.render).frame(maxWidth: .infinity, maxHeight: .infinity) }
                    }
                        .aspectRatio(16.0 / 9, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .overlay(alignment: .center) {
                            if let error = studio.render.errorMessage { Text(error).padding().background(.regularMaterial) }
                        }
                    VisionTransportView(studio: studio, transport: studio.transport, radio: session.radioMode ? session.radio : nil)
                    if studio.needsSoundtrack {
                        Button("Locate soundtrack", systemImage: "waveform.badge.plus") { locateAudio = true }
                            .buttonStyle(.borderedProminent)
                    }
                    VisionStyleControls(studio: studio)
                }
            }
            if !session.radioMode { VisionTimelineView(studio: studio) }
        }.padding(.vertical, 20).padding(.leading, 12).padding(.trailing, 20)
            .frame(minWidth: 1100, minHeight: 780)
            .toolbar {
                ToolbarItemGroup(placement: .bottomOrnament) {
                    Button("Import audio", systemImage: "tray.and.arrow.down") { importAudio = true }.disabled(studio.loading || session.radioMode)
                        .labelStyle(.titleAndIcon)
                        .accessibilityIdentifier("importAudioButton")
                    Button("Open project", systemImage: "folder") { importProject = true }.disabled(studio.loading || session.radioMode)
                        .labelStyle(.titleAndIcon)
                    Button("Save project", systemImage: "internaldrive") {
                        do {
                            projectData = try studio.project.portableData(duration: studio.transport.duration, scene: studio.selectedScene)
                            exportProject = true
                        } catch { studio.message = "Couldn't save project: \(error.localizedDescription)" }
                    }.disabled(session.radioMode || studio.loading || studio.needsSoundtrack)
                        .labelStyle(.titleAndIcon)
                        .accessibilityIdentifier("saveProjectButton")
                    Button("Export MP4", systemImage: "film") { exportVideo = true }
                        .disabled(studio.loading || session.radioMode)
                        .accessibilityIdentifier("exportMP4Button")
                    Button("Legal & Credits", systemImage: "info.circle") { legal = true }
                    Spacer()
                    if studio.loading { ProgressView("Analyzing music…") }
                    HStack(spacing: 8) {
                        Text("Hide room").font(.callout)
                        Toggle("Hide room", isOn: $session.fullImmersion).labelsHidden()
                            .toggleStyle(.switch).disabled(session.immersiveActive)
                            .accessibilityIdentifier("hideRoomToggle")
                    }.fixedSize()
                    immersiveButton
                }
            }
            .sheet(isPresented: $legal) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("PulseCanvas Studio").font(.title.bold())
                    Text("Copyright © 2026 Protomota, LLC").foregroundStyle(.secondary)
                    Link("Source code on GitHub", destination: URL(string: "https://github.com/protomota/pulsecanvas")!)
                    ScrollView {
                        Text(Bundle.main.url(forResource: "PulseCanvas-LICENSE", withExtension: "txt", subdirectory: "Legal")
                            .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? "License unavailable")
                            .font(.body).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button("Done") { legal = false }.buttonStyle(.borderedProminent)
                }.padding(32).frame(width: 700, height: 620)
            }
            .sheet(isPresented: $exportVideo) { VisionVideoExportView(studio: studio) { exportVideo = false } }
            .task { await session.editor.start(); await applyLaunchOptions() }
            .task(id: session.radioMode) { if session.radioMode { await session.radio.refreshStations() } }
            .onChange(of: phase) { _, phase in if phase == .background && !session.immersiveActive { session.suspend() } }
            .fileImporter(isPresented: $importAudio, allowedContentTypes: [.audio]) { result in
                switch result {
                case .success(let url): Task { await studio.importAudio(url) }
                case .failure(let error): studio.message = error.localizedDescription
                }
            }
            .onOpenURL { openProject($0) }
            .fileImporter(isPresented: $locateAudio, allowedContentTypes: [.audio]) { result in
                switch result {
                case .success(let url): Task { await studio.importAudio(url, generateTimeline: false) }
                case .failure(let error): studio.message = error.localizedDescription
                }
            }
            .fileImporter(isPresented: $importProject, allowedContentTypes: [.pulseCanvas, .pulseVision, .json]) { result in
                switch result {
                case .success(let url): openProject(url)
                case .failure(let error): studio.message = error.localizedDescription
                }
            }
            .fileExporter(isPresented: $exportProject, document: VisionProjectDocument(data: projectData),
                contentType: .pulseCanvas, defaultFilename: "PulseCanvas Studio") { result in
                    if case .failure(let error) = result { studio.message = error.localizedDescription }
                }
            .alert("PulseCanvas Studio", isPresented: Binding(get: { studio.message != nil }, set: { if !$0 { studio.message = nil } })) {
                Button("OK") { studio.message = nil }
            } message: { Text(studio.message ?? "") }
    }

    private var immersiveButton: some View {
        Button {
            Task { await toggleImmersive() }
        } label: {
            Image(systemName: "visionpro").font(.title3)
                .frame(minWidth: 44, minHeight: 44)
        }.disabled(changingSpace)
            .accessibilityIdentifier("immersiveButton")
            .accessibilityLabel(session.immersiveActive ? "Leave full screen" : "Enter full screen")
            .help(session.immersiveActive ? "Leave full screen" : "Enter full screen")
    }

    private func toggleImmersive() async {
        changingSpace = true
        defer { changingSpace = false }
        if session.immersiveActive { await dismissSpace() }
        else {
            switch await openSpace(id: "visualizer-stage") {
            case .opened:
                session.immersiveActive = true
                session.studioWindowHidden = true
                dismissWindow(id: "studio")
            case .userCancelled: break
            case .error: studio.message = "Immersive viewing couldn't open. Your Studio remains available."
            @unknown default: break
            }
        }
    }

    /// Launch hooks for UI tests and recorded demos (see `VisionLaunchOptions`); applied once, after the soundtrack loads.
    private func applyLaunchOptions() async {
        let launch = VisionLaunchOptions.current
        guard !launchApplied, launch != VisionLaunchOptions(arguments: []) else { return }
        launchApplied = true
        let editor = session.editor
        if let hide = launch.hideRoom { session.fullImmersion = hide }
        if launch.visualizer != nil, let first = editor.project.clips.first {
            if let index = launch.visualizerIndex(in: NativeEffects.names) {
                editor.assign(index, to: first.id); editor.select(first)
            }
            if editor.project.clips.first?.scene != launch.visualizerIndex(in: NativeEffects.names) {
                NSLog("PulseCanvas launch hook: -PCVisualizer %@ is not an available visualizer in this build", launch.visualizer ?? "")
            }
        }
        if let seconds = launch.seek { editor.seek(seconds) }
        if launch.radio {
            session.setRadioMode(true)
            if launch.autoplay { session.radio.nextSong(); await session.radio.waitForTrack() }
        } else if launch.autoplay, !editor.transport.playing, editor.transport.duration > 0 {
            editor.togglePlayback()
        }
        if launch.openImmersive { await toggleImmersive() }
    }

    private func openProject(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            guard (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? Int.max) < 4_000_000 else { throw CocoaError(.fileReadCorruptFile) }
            let data = try Data(contentsOf: url)
            let project = try VisionProject.openPortable(data)
            Task { await studio.replaceProject(project) }
        } catch { studio.message = error.localizedDescription }
    }
}

private struct VisionRadioControls: View {
    @ObservedObject var radio: VisionRadio
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if radio.loadingStations {
                ProgressView("Loading stations…").frame(maxWidth: .infinity, minHeight: 48)
            } else {
                Picker("Station", selection: Binding(get: { radio.stationID }, set: { radio.selectStation($0) })) {
                    ForEach(radio.stations) { Text($0.title).tag($0.id) }
                }.pickerStyle(.menu).disabled(radio.stations.isEmpty || radio.loading)
                HStack {
                    Button { if !radio.studio.transport.playing { radio.togglePlayback() } } label: {
                        HStack(alignment: .center, spacing: 10) {
                            Image(systemName: "radio").frame(width: 24, height: 24)
                            Text("Play Radio")
                        }.font(.body.weight(.semibold)).frame(minHeight: 32, alignment: .center)
                    }.buttonStyle(.borderedProminent)
                    Button("Next song", systemImage: "forward.end.fill") { radio.nextSong() }
                        .labelStyle(.iconOnly)
                }.disabled(radio.loading || radio.stations.isEmpty)
            }
            if radio.loading { ProgressView("Preparing music…") }
            if let error = radio.error {
                Text(error).font(.caption).foregroundStyle(.secondary)
                Button("Retry stations") { Task { await radio.refreshStations() } }
            }
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct VisionLibrary: View {
    @ObservedObject var studio: VisionStudio
    @ObservedObject private var library = ProjectMPresets.shared
    @State private var query = ""
    private var scenes: [Int] { library.filteredScenes(query: query) }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visualizers").font(.title2.bold())
                .padding(.leading, 8)
            VisualizerRandomizerPicker(compact: true, fillsWidth: true)
            HStack(spacing: 8) {
                Button { studio.randomizeVisualizer() } label: {
                    Label("Random visualizer", systemImage: "shuffle")
                        .frame(maxWidth: .infinity, minHeight: 32)
                }.buttonStyle(.borderedProminent).disabled(library.eligibleScenes.isEmpty)
                    .accessibilityIdentifier("randomVisualizerButton")
                    .help("Choose another visualizer from the selected group. Saved visual settings stay unchanged.")
                Button { studio.randomizeLook() } label: {
                    Image(systemName: "dice.fill").font(.title3).frame(width: 32, height: 32)
                }.buttonStyle(.bordered)
                    .accessibilityLabel("Randomize current visual style")
                    .accessibilityIdentifier("randomizeStyleButton")
                    .help("Randomize the current visualizer's colors and motion settings")
            }
            TextField("Search visualizers", text: $query).textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("visualizerSearchField")
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(scenes, id: \.self) { scene in
                        HStack(spacing: 0) {
                            Button { studio.assign(scene) } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: library.icon(for: scene))
                                        .frame(width: 24).foregroundStyle(.tint)
                                    Text(NativeEffects.names[scene])
                                        .font(.body.weight(.medium))
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                }.padding(.leading, 8).padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                                    .contentShape(Rectangle())
                            }.buttonStyle(.plain).hoverEffect(.highlight)
                            Button { library.toggleFavorite(scene) } label: {
                                Image(systemName: library.isFavorite(scene) ? "heart.fill" : "heart")
                                    .frame(width: 44, height: 52).contentShape(Rectangle())
                            }.buttonStyle(.plain).hoverEffect(.highlight)
                                .accessibilityLabel("\(library.isFavorite(scene) ? "Unfavorite" : "Favorite") \(NativeEffects.names[scene])")
                        }.background(scene == studio.selectedScene ? Color.orange.opacity(0.18) : Color.white.opacity(0.04),
                                     in: RoundedRectangle(cornerRadius: 12))
                    }
                    if scenes.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "line.3.horizontal.decrease.circle").font(.title)
                            Text("No matching visualizers").font(.headline)
                        }.multilineTextAlignment(.center).padding(.vertical, 28).padding(.horizontal, 8)
                    }
                }.padding(.trailing, 6)
            }.scrollIndicators(.visible)
            Text("\(scenes.count) of \(NativeEffects.activeCount) effects")
                .font(.caption).foregroundStyle(.secondary).padding(.leading, 8)
        }
    }
}

private struct VisionTransportView: View {
    @ObservedObject var studio: VisionStudio
    @ObservedObject var transport: VisionTransport
    var radio: VisionRadio?
    var body: some View {
        VStack(spacing: 8) {
          Text(studio.project.audioTitle).font(.headline).lineLimit(1)
              .frame(maxWidth: .infinity, alignment: .leading)
          HStack(spacing: 16) {
            if let radio {
                VisionRadioPlaybackButton(radio: radio, transport: transport)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("playPauseButton")
            } else {
                Button { studio.togglePlayback() } label: {
                    Image(systemName: transport.playing ? "pause.fill" : "play.fill").frame(width: 32, height: 32)
                }.buttonStyle(.borderedProminent).disabled(studio.loading || transport.duration <= 0)
                    .accessibilityLabel(transport.playing ? "Pause" : "Play")
                    .accessibilityIdentifier("playPauseButton")
            }
            Text(Duration.seconds(transport.seconds).formatted(.time(pattern: .minuteSecond)))
                .monospacedDigit().frame(width: 60)
                .accessibilityIdentifier("elapsedTime")
            Slider(value: Binding(get: { transport.seconds }, set: { studio.seek($0) }),
                in: 0...max(1, transport.duration)).accessibilityLabel("Soundtrack position")
                .disabled(studio.loading || studio.needsSoundtrack || transport.duration <= 0)
            Text(Duration.seconds(transport.duration).formatted(.time(pattern: .minuteSecond)))
                .monospacedDigit().frame(width: 60)
            Image(systemName: studio.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
            Slider(value: $studio.volume, in: 0...1).frame(width: 110).accessibilityLabel("Volume")
          }
          if radio == nil { Toggle(isOn: Binding(get: { studio.loopPlayback }, set: { studio.loopPlayback = $0 })) {
              Label("Loop soundtrack", systemImage: "repeat")
          }.toggleStyle(.button)
              .accessibilityIdentifier("loopSoundtrackToggle")
              .help("Repeat the soundtrack and Studio timeline from the beginning")
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
    }
}

/// Radio can start before audio exists; only an in-progress song request blocks another tap.
struct VisionRadioPlaybackButton: View {
    @ObservedObject var radio: VisionRadio
    @ObservedObject var transport: VisionTransport
    var body: some View {
        Button { radio.togglePlayback() } label: {
            ZStack {
                if radio.loading { ProgressView().controlSize(.small) }
                else { Image(systemName: transport.playing ? "pause.fill" : "play.fill") }
            }.frame(width: 32, height: 32)
        }.disabled(radio.loading)
            .accessibilityLabel(radio.loading ? "Preparing Radio" : transport.playing ? "Pause Radio" : "Play Radio")
    }
}

private struct VisionStyleControls: View {
    @ObservedObject var studio: VisionStudio
    var clipID: UUID? = nil
    private var look: VisionLook {
        clipID.flatMap { studio.look(for: $0) } ?? studio.look
    }
    private var scene: Int {
        clipID.flatMap { id in studio.project.clips.first { $0.id == id }?.scene } ?? studio.selectedScene
    }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 24, alignment: .top), count: 3)
    private func value(_ key: WritableKeyPath<VisionLook, Float>) -> Binding<Float> {
        Binding(get: { look[keyPath: key] }, set: { value in studio.updateLook(for: clipID) { $0[keyPath: key] = value } })
    }
    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Picker("Palette", selection: Binding(get: { look.palette }, set: { value in studio.updateLook(for: clipID) { $0.palette = value } })) {
                    ForEach(VisualPalette.allCases, id: \.rawValue) { Text($0.title).tag($0.rawValue) }
                }
                Button("Reset") { studio.resetLook(for: clipID) }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                        control("Chaos", binding: value(\.chaos), range: 0...1)
                        control("Zoom speed", binding: value(\.zoomSpeed), range: 0...3)
                        control("Motion speed", binding: value(\.speed), range: 0...3)
                        control("Brightness", binding: value(\.brightness), range: 0.1...3)
                        control(NativeEffects.effect(scene)?.sizeLabel ?? "Particle size", binding: value(\.size), range: 0.3...6)
                        control("Depth / fog", binding: value(\.fog), range: 0...1)
                        control("Camera zoom", binding: value(\.zoom), range: 0.3...2)
                        control("Camera rotation", binding: value(\.rotation), range: -3.14...3.14)
                        control("Blur", binding: value(\.motionBlur), range: 0...0.9)
                        if let detail = NativeEffects.effect(scene)?.detailLabel {
                            control(detail, binding: value(\.detail), range: 0...1)
                        }
                        if scene == 28 {
                            control("Halo count", binding: Binding(get: { Float(look.haloCount) }, set: { count in
                                studio.updateLook(for: clipID) { $0.haloCount = Int(count.rounded()) }
                            }), range: 1...12, step: 1, digits: 0)
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Label("Hi-hat strobe", systemImage: "bolt.fill")
                            Toggle("Hi-hat strobe", isOn: Binding(get: { look.strobeEnabled }, set: { enabled in
                                studio.updateLook(for: clipID) { $0.strobeEnabled = enabled }
                            })).labelsHidden().toggleStyle(.switch).fixedSize()
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        if look.strobeEnabled {
                            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                                control("Sensitivity", binding: value(\.strobeSensitivity), range: 0.25...4)
                                control("Strength", binding: value(\.strobeStrength), range: 0.1...1)
                            }
                        }
                    }
                    if studio.immersiveActive && clipID == nil {
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                            control("Screen distance", binding: $studio.screenDistance, range: 2...5)
                            control("Screen height", binding: $studio.screenHeight, range: 0.8...2)
                        }
                    }
                }.padding(.trailing, 10)
            }.scrollIndicators(.visible).frame(maxHeight: 250)
        }
    }
    private func control(_ title: String, binding: Binding<Float>, range: ClosedRange<Float>, step: Float = 0.01, digits: Int = 2) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text(title); Spacer(); Text(binding.wrappedValue, format: .number.precision(.fractionLength(digits))).monospacedDigit() }
                .font(.caption)
            Slider(value: binding, in: range, step: step).accessibilityLabel(title)
        }
    }
}

private struct VisionTimelineView: View {
    @ObservedObject var studio: VisionStudio
    @State private var applying = false
    @State private var randomizing = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Studio", systemImage: "rectangle.split.3x1").font(.headline)
                Text("\(studio.project.clips.count) sections · \(Int(studio.project.bpm)) BPM").foregroundStyle(.secondary)
                Spacer()
                Button("Randomize timeline", systemImage: "shuffle") { randomizing = true }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("randomizeTimelineButton")
                    .disabled(studio.loading || studio.needsSoundtrack || studio.transport.duration <= 0)
                Button("Apply to all", systemImage: "slider.horizontal.3") { applying = true }
                    .disabled(studio.loading || studio.needsSoundtrack || studio.transport.duration <= 0)
            }
            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(studio.project.clips) { clip in
                        VisionTimelineCard(studio: studio, clip: clip)
                    }
                }
            }.frame(height: 160)
        }.sheet(isPresented: $applying) { VisionApplySettings(studio: studio) { applying = false } }
            .sheet(isPresented: $randomizing) { VisionRandomizeTimeline(studio: studio) { randomizing = false } }
    }
}

private struct VisionRandomizeTimeline: View {
    @ObservedObject var studio: VisionStudio
    @ObservedObject private var library = ProjectMPresets.shared
    let close: () -> Void
    @State private var visualizers = true
    @State private var barLengths = false
    @State private var error: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Label("Randomize timeline", systemImage: "shuffle").font(.title2.bold())
            Text("Choose what to replace across all \(studio.project.clips.count) Studio sections.")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Visualizers", isOn: $visualizers).toggleStyle(.switch)
                    .accessibilityIdentifier("randomizeTimelineVisualizers")
                Text("Current group: \(library.poolSummary)").font(.callout).foregroundStyle(.secondary)
                Toggle("Bar lengths", isOn: $barLengths).toggleStyle(.switch)
                    .accessibilityIdentifier("randomizeTimelineBars")
                Text("Choose 1–8 bars per section on the song’s beat grid. Tail sections may be trimmed or repeated to fit the song.")
                    .font(.callout).foregroundStyle(.secondary)
            }.padding(20).background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18))
            Text(barLengths ? "Soundtrack and saved visual styles stay unchanged." : "Timing, soundtrack and saved visual styles stay unchanged.")
                .font(.callout).foregroundStyle(.secondary)
            if let error { Text(error).font(.callout).foregroundStyle(.orange) }
            HStack {
                Button("Cancel", role: .cancel, action: close)
                Spacer()
                Button("Randomize timeline", systemImage: "shuffle") {
                    if studio.randomizeTimeline(visualizers: visualizers, barLengths: barLengths) { close() }
                    else { error = "No changes were made. Choose a larger visualizer group or fewer sections, then try again." }
                }.buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("confirmRandomizeTimelineButton")
                    .disabled(studio.loading || (!visualizers && !barLengths) || (visualizers && library.eligibleScenes.isEmpty))
            }
        }.padding(28).frame(width: 640)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("randomizeTimelineSheet")
    }
}

private struct VisionApplySettings: View {
    @ObservedObject var studio: VisionStudio
    let close: () -> Void
    @State private var includeBars = false
    @State private var bars = 4
    @State private var includeChaos = false
    @State private var chaos: Float = 0.5
    @State private var includeZoom = false
    @State private var zoom: Float = 1.5
    @State private var includeSpeed = false
    @State private var speed: Float = 1
    @State private var strobe = 0
    @State private var sensitivity: Float = 1
    @State private var strength: Float = 1
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Apply settings to all", systemImage: "slider.horizontal.3").font(.title2.bold())
            Text("Apply selected settings to every visualizer and Studio section. Other settings stay unchanged.")
                .foregroundStyle(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Toggle("Bars per section", isOn: $includeBars)
                    Stepper("\(bars) \(bars == 1 ? "bar" : "bars")", value: $bars, in: 1...64).disabled(!includeBars)
                    Divider()
                    setting("Chaos", included: $includeChaos, value: $chaos, range: 0...1)
                    setting("Zoom speed", included: $includeZoom, value: $zoom, range: 0...3)
                    setting("Motion speed", included: $includeSpeed, value: $speed, range: 0.05...3)
                    Divider()
                    Text("Hi-hat strobe").font(.headline)
                    Picker("Hi-hat strobe", selection: $strobe) {
                        Text("Keep unchanged").tag(0); Text("Add to all").tag(1); Text("Remove from all").tag(2)
                    }.pickerStyle(.segmented)
                    VStack(alignment: .leading) {
                        Text("Sensitivity · \(sensitivity, specifier: "%.2f")")
                        Slider(value: $sensitivity, in: 0.25...4).accessibilityLabel("Strobe sensitivity")
                        Text("Strength · \(strength, specifier: "%.2f")")
                        Slider(value: $strength, in: 0.1...1).accessibilityLabel("Strobe strength")
                    }.disabled(strobe != 1)
                }.padding(.trailing, 12)
            }.scrollIndicators(.visible)
            HStack {
                Button("Cancel", action: close)
                Spacer()
                Button("Apply selected settings") {
                    studio.applyCommonSettings(VisionCommonSettings(bars: includeBars ? bars : nil,
                        chaos: includeChaos ? chaos : nil, zoomSpeed: includeZoom ? zoom : nil,
                        motionSpeed: includeSpeed ? speed : nil,
                        strobeEnabled: strobe == 0 ? nil : strobe == 1,
                        strobeSensitivity: strobe == 1 ? sensitivity : nil,
                        strobeStrength: strobe == 1 ? strength : nil))
                    close()
                }.buttonStyle(.borderedProminent)
                    .disabled(!includeBars && !includeChaos && !includeZoom && !includeSpeed && strobe == 0)
            }
        }.padding(28).frame(width: 660, height: 720)
            .onAppear {
                bars = studio.project.clips[studio.selectedIndex].bars
                chaos = studio.look.chaos; zoom = studio.look.zoomSpeed; speed = studio.look.speed
                sensitivity = studio.look.strobeSensitivity; strength = studio.look.strobeStrength
            }
    }
    private func setting(_ title: String, included: Binding<Bool>, value: Binding<Float>, range: ClosedRange<Float>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(title, isOn: included)
            HStack {
                Slider(value: value, in: range).accessibilityLabel(title)
                Text(value.wrappedValue, format: .number.precision(.fractionLength(2))).monospacedDigit().frame(width: 50)
            }.disabled(!included.wrappedValue)
        }
    }
}

private struct VisionTimelineCard: View {
    @ObservedObject var studio: VisionStudio
    let clip: VisionClip
    @State private var choosing = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { studio.select(clip); choosing = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: NativeEffects.all[clip.scene].icon).foregroundStyle(.tint)
                    Text(NativeEffects.names[clip.scene]).font(.headline).lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down").font(.caption.weight(.semibold))
                }.frame(maxWidth: .infinity, minHeight: 52, alignment: .leading).contentShape(Rectangle())
            }.buttonStyle(.plain).hoverEffect(.highlight)
                .accessibilityLabel("Choose visualizer for \(NativeEffects.names[clip.scene]) section")
                .accessibilityIdentifier("chooseVisualizer-\(clip.id)")
                .popover(isPresented: $choosing, arrowEdge: .bottom) {
                    VisionClipPicker(studio: studio, clipID: clip.id) { choosing = false }
                        .presentationCompactAdaptation(.popover)
                }
            Stepper("\(clip.bars) \(clip.bars == 1 ? "bar" : "bars")",
                    value: Binding(get: { clip.bars }, set: { studio.bars($0, clip: clip.id) }), in: 1...64)
                .accessibilityLabel("Bars for \(NativeEffects.names[clip.scene])")
        }.padding(16).frame(width: 300)
            .background(studio.selected == clip.id ? Color.orange.opacity(0.2) : Color.white.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct VisionClipPicker: View {
    @ObservedObject var studio: VisionStudio
    @ObservedObject private var library = ProjectMPresets.shared
    let clipID: UUID
    let close: () -> Void
    @State private var query = ""
    @State private var favoritesOnly = false
    private var clip: VisionClip? { studio.project.clips.first { $0.id == clipID } }
    private var scenes: [Int] { library.filteredScenes(query: query, favoritesOnly: favoritesOnly) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Choose visualizer").font(.title2.bold())
                Spacer()
                Button("Done", action: close).buttonStyle(.borderedProminent)
            }
            if let clip {
                HStack(spacing: 12) {
                    TextField("Search visualizers", text: $query).textFieldStyle(.roundedBorder)
                    Toggle(isOn: $favoritesOnly) { Label("Favorites", systemImage: "heart.fill") }
                        .toggleStyle(.button)
                }
                VisualizerRandomizerPicker(compact: true, fillsWidth: true)
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(scenes, id: \.self) { scene in
                            HStack(spacing: 8) {
                                Button {
                                    studio.assign(scene, to: clipID)
                                    close()
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: library.icon(for: scene)).frame(width: 28).foregroundStyle(.tint)
                                        Text(NativeEffects.names[scene]).multilineTextAlignment(.leading)
                                        Spacer(minLength: 0)
                                        if scene == clip.scene { Image(systemName: "checkmark").foregroundStyle(.tint) }
                                    }.frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                                        .contentShape(Rectangle())
                                }.buttonStyle(.plain).hoverEffect(.highlight)
                                Button { library.toggleFavorite(scene) } label: {
                                    Image(systemName: library.isFavorite(scene) ? "heart.fill" : "heart")
                                        .frame(width: 44, height: 48)
                                }.buttonStyle(.plain).hoverEffect(.highlight)
                                    .accessibilityLabel("\(library.isFavorite(scene) ? "Unfavorite" : "Favorite") \(NativeEffects.names[scene])")
                            }.padding(.horizontal, 10)
                                .background(scene == clip.scene ? Color.orange.opacity(0.15) : Color.white.opacity(0.04),
                                            in: RoundedRectangle(cornerRadius: 12))
                        }
                        if scenes.isEmpty { Text("No matching visualizers").foregroundStyle(.secondary).padding(24) }
                    }.padding(.trailing, 6)
                }.frame(maxHeight: .infinity).scrollIndicators(.visible)
                Button("Surprise me", systemImage: "shuffle") {
                    let candidates = scenes.filter { $0 != clip.scene }
                    if let next = (candidates.isEmpty ? scenes : candidates).randomElement() {
                        studio.assign(next, to: clipID)
                        close()
                    }
                }.buttonStyle(.borderedProminent).disabled(scenes.isEmpty)
                    .accessibilityLabel("Surprise me")
                    .accessibilityIdentifier("surpriseClipVisualizerButton")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else { Text("Section unavailable"); Spacer() }
        }.padding(24).frame(width: 680, height: 680)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("clipVisualizerPicker")
    }
}
