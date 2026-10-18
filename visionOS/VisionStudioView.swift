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
    @State private var changingSpace = false
    @State private var legal = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 20) {
                VStack(spacing: 12) {
                    Picker("Workspace", selection: Binding(get: { session.radioMode }, set: { session.setRadioMode($0) })) {
                        Label("Studio", systemImage: "rectangle.split.3x1").tag(false)
                        Label("Radio", systemImage: "radio").tag(true)
                    }.pickerStyle(.segmented).disabled(session.immersiveActive)
                    if session.radioMode { VisionRadioControls(radio: session.radio) }
                    VisionLibrary(studio: studio)
                    immersiveButton
                }.frame(width: 340)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(NativeEffects.names[studio.selectedScene]).font(.title2.bold()).lineLimit(1)
                        Spacer()
                        Label("Native Metal", systemImage: "sparkles").foregroundStyle(.secondary)
                    }
                    Group {
                        if session.immersiveActive {
                            VStack(spacing: 16) {
                                Image(systemName: "visionpro").font(.largeTitle)
                                Text("Immersive viewing is active").font(.title3)
                                Text("The window preview pauses to give the immersive view the GPU.").foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else { VisualizerView(state: studio.render).frame(maxWidth: .infinity, maxHeight: .infinity) }
                    }
                        .aspectRatio(16.0 / 9, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .overlay(alignment: .center) {
                            if let error = studio.render.errorMessage { Text(error).padding().background(.regularMaterial) }
                        }
                    VisionTransportView(studio: studio, transport: studio.transport, radio: session.radioMode ? session.radio : nil)
                    VisionStyleControls(studio: studio)
                    Toggle("Full immersion · hide the room", isOn: $session.fullImmersion)
                        .disabled(session.immersiveActive)
                    if session.immersiveActive {
                        Button("Hide Studio window", systemImage: "eye.slash") {
                            session.studioWindowHidden = true; dismissWindow(id: "studio")
                        }
                    } else {
                        Text("Immersive viewing hides the Studio window. Pinch the visual to show controls and return.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if !session.radioMode { VisionTimelineView(studio: studio) }
        }.padding(.vertical, 20).padding(.leading, 12).padding(.trailing, 20)
            .frame(minWidth: 1100, minHeight: 780)
            .toolbar {
                ToolbarItemGroup(placement: .bottomOrnament) {
                    Button("Import audio", systemImage: "waveform.badge.plus") { importAudio = true }.disabled(studio.loading || session.radioMode)
                    Button("Open project", systemImage: "folder") { importProject = true }.disabled(studio.loading || session.radioMode)
                    Button("Save project", systemImage: "square.and.arrow.up") { exportProject = true }.disabled(session.radioMode)
                    Button("Legal & Credits", systemImage: "info.circle") { legal = true }
                    Spacer()
                    if studio.loading { ProgressView("Analyzing music…") }
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
            .task { await session.editor.start() }
            .task(id: session.radioMode) { if session.radioMode { await session.radio.refreshStations() } }
            .onChange(of: phase) { _, phase in if phase == .background && !session.immersiveActive { session.suspend() } }
            .fileImporter(isPresented: $importAudio, allowedContentTypes: [.audio]) { result in
                switch result {
                case .success(let url): Task { await studio.importAudio(url) }
                case .failure(let error): studio.message = error.localizedDescription
                }
            }
            .onOpenURL { openProject($0) }
            .fileImporter(isPresented: $importProject, allowedContentTypes: [.pulseVision, .json]) { result in
                switch result {
                case .success(let url): openProject(url)
                case .failure(let error): studio.message = error.localizedDescription
                }
            }
            .fileExporter(isPresented: $exportProject, document: VisionProjectDocument(project: studio.project),
                contentType: .pulseVision, defaultFilename: "PulseCanvas Studio") { result in
                    if case .failure(let error) = result { studio.message = error.localizedDescription }
                }
            .alert("PulseCanvas Studio", isPresented: Binding(get: { studio.message != nil }, set: { if !$0 { studio.message = nil } })) {
                Button("OK") { studio.message = nil }
            } message: { Text(studio.message ?? "") }
    }

    private var immersiveButton: some View {
        Button {
            Task {
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
        } label: {
            Label(session.immersiveActive ? "Leave immersive view" : "Watch full screen",
                  systemImage: "arrow.up.left.and.arrow.down.right")
                .frame(maxWidth: .infinity, minHeight: 32)
        }.buttonStyle(.borderedProminent).disabled(changingSpace)
    }

    private func openProject(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            guard (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? Int.max) < 4_000_000 else { throw CocoaError(.fileReadCorruptFile) }
            let data = try Data(contentsOf: url)
            let project = try JSONDecoder().decode(VisionProject.self, from: data).validated()
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
                    Button("Play Radio", systemImage: "radio") { if !radio.studio.transport.playing { radio.togglePlayback() } }
                        .buttonStyle(.borderedProminent)
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
                    .help("Choose another visualizer from the selected group. Saved visual settings stay unchanged.")
                Button { studio.randomizeLook() } label: {
                    Image(systemName: "dice.fill").font(.title3).frame(width: 32, height: 32)
                }.buttonStyle(.bordered)
                    .accessibilityLabel("Randomize current visual style")
                    .help("Randomize the current visualizer's colors and motion settings")
            }
            TextField("Search visualizers", text: $query).textFieldStyle(.roundedBorder)
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
                            Text("Choose another group, add favorites, or clear your search.")
                                .font(.callout).foregroundStyle(.secondary)
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
          HStack(spacing: 16) {
            Button { if let radio { radio.togglePlayback() } else { studio.togglePlayback() } } label: {
                Image(systemName: transport.playing ? "pause.fill" : "play.fill").frame(width: 32, height: 32)
            }.buttonStyle(.borderedProminent).disabled(studio.loading || transport.duration <= 0)
            VStack(alignment: .leading) {
                Text(studio.project.audioTitle).font(.headline).lineLimit(1)
                Slider(value: Binding(get: { transport.seconds }, set: { studio.seek($0) }),
                    in: 0...max(1, transport.duration)).accessibilityLabel("Soundtrack position")
            }
            Text(Duration.seconds(transport.seconds).formatted(.time(pattern: .minuteSecond)))
                .monospacedDigit().frame(width: 60)
            Image(systemName: studio.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
            Slider(value: $studio.volume, in: 0...1).frame(width: 110).accessibilityLabel("Volume")
          }
          if radio == nil { Toggle(isOn: Binding(get: { studio.loopPlayback }, set: { studio.loopPlayback = $0 })) {
              Label("Loop soundtrack", systemImage: "repeat")
          }.toggleStyle(.button)
              .help("Repeat the soundtrack and Studio timeline from the beginning")
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
    }
}

private struct VisionStyleControls: View {
    @ObservedObject var studio: VisionStudio
    private func value(_ key: WritableKeyPath<VisionLook, Float>) -> Binding<Float> {
        Binding(get: { studio.look[keyPath: key] }, set: { value in studio.updateLook { $0[keyPath: key] = value } })
    }
    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Picker("Palette", selection: Binding(get: { studio.look.palette }, set: { value in studio.updateLook { $0.palette = value } })) {
                    ForEach(VisualPalette.allCases, id: \.rawValue) { Text($0.title).tag($0.rawValue) }
                }
                Button("Reset") { studio.resetLook() }
            }
            HStack(spacing: 24) {
                control("Chaos", binding: value(\.chaos), range: 0...1)
                control("Zoom speed", binding: value(\.zoomSpeed), range: 0...3)
                control("Motion speed", binding: value(\.speed), range: 0...3)
            }
            if studio.immersiveActive {
                HStack(spacing: 24) {
                    control("Screen distance", binding: $studio.screenDistance, range: 2...5)
                    control("Screen height", binding: $studio.screenHeight, range: 0.8...2)
                }
            }
        }
    }
    private func control(_ title: String, binding: Binding<Float>, range: ClosedRange<Float>) -> some View {
        VStack(alignment: .leading) {
            HStack { Text(title); Spacer(); Text(binding.wrappedValue, format: .number.precision(.fractionLength(2))).monospacedDigit() }
                .font(.caption)
            Slider(value: binding, in: range).accessibilityLabel(title)
        }
    }
}

private struct VisionTimelineView: View {
    @ObservedObject var studio: VisionStudio
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Studio", systemImage: "rectangle.split.3x1").font(.headline)
                Text("\(studio.project.clips.count) sections · \(Int(studio.project.bpm)) BPM").foregroundStyle(.secondary)
                Spacer()
            }
            Text("Select a section, choose its visualizer on the left, and set how many bars it plays.")
                .font(.caption).foregroundStyle(.secondary)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(studio.project.clips) { clip in
                        VStack(alignment: .leading, spacing: 12) {
                            Button { studio.select(clip) } label: {
                                Label(NativeEffects.names[clip.scene], systemImage: NativeEffects.all[clip.scene].icon)
                                    .font(.headline).lineLimit(1).frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                                    .contentShape(Rectangle())
                            }.buttonStyle(.plain).hoverEffect(.highlight)
                            Stepper("\(clip.bars) \(clip.bars == 1 ? "bar" : "bars")", value: Binding(get: { clip.bars }, set: { studio.bars($0, clip: clip.id) }), in: 1...64)
                                .accessibilityLabel("Bars for \(NativeEffects.names[clip.scene])")
                        }.padding(16).frame(width: 260)
                            .background(studio.selected == clip.id ? Color.orange.opacity(0.2) : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
                    }
                }
            }.frame(height: 145)
        }
    }
}
