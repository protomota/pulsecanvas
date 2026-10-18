import SwiftUI
import UniformTypeIdentifiers

struct VisionStudioView: View {
    @ObservedObject var studio: VisionStudio
    @Environment(\.openImmersiveSpace) private var openSpace
    @Environment(\.dismissImmersiveSpace) private var dismissSpace
    @Environment(\.scenePhase) private var phase
    @State private var importAudio = false
    @State private var importProject = false
    @State private var exportProject = false
    @State private var changingSpace = false
    @State private var legal = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 20) {
                VisionLibrary(studio: studio).frame(width: 250)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(NativeEffects.names[studio.selectedScene]).font(.title2.bold()).lineLimit(1)
                        Spacer()
                        Label("Native Metal", systemImage: "sparkles").foregroundStyle(.secondary)
                    }
                    VisualizerView(state: studio.render)
                        .aspectRatio(16.0 / 9, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .overlay(alignment: .center) {
                            if let error = studio.render.errorMessage { Text(error).padding().background(.regularMaterial) }
                        }
                    VisionTransportView(studio: studio, transport: studio.transport)
                    VisionStyleControls(studio: studio)
                }
            }
            VisionTimelineView(studio: studio)
        }.padding(24)
            .frame(minWidth: 1100, minHeight: 780)
            .toolbar {
                ToolbarItemGroup(placement: .bottomOrnament) {
                    Button("Import audio", systemImage: "waveform.badge.plus") { importAudio = true }.disabled(studio.loading)
                    Button("Open project", systemImage: "folder") { importProject = true }.disabled(studio.loading)
                    Button("Save project", systemImage: "square.and.arrow.up") { exportProject = true }
                    Button("Legal & Credits", systemImage: "info.circle") { legal = true }
                    Spacer()
                    if studio.loading { ProgressView("Analyzing music…") }
                    Button(studio.immersiveActive ? "Leave immersive view" : "Immersive view", systemImage: "visionpro") {
                        Task {
                            changingSpace = true
                            defer { changingSpace = false }
                            if studio.immersiveActive { await dismissSpace() }
                            else {
                                switch await openSpace(id: "visualizer-stage") {
                                case .opened: break
                                case .userCancelled: break
                                case .error: studio.message = "Immersive viewing couldn't open. Your Studio remains available."
                                @unknown default: break
                                }
                            }
                        }
                    }.disabled(changingSpace)
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
            .task { await studio.start() }
            .onChange(of: phase) { _, phase in if phase == .background { studio.suspend() } }
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

private struct VisionLibrary: View {
    @ObservedObject var studio: VisionStudio
    @ObservedObject private var library = ProjectMPresets.shared
    @State private var category = ""
    @State private var query = ""
    @State private var favorites = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visualizers").font(.title2.bold())
            VisualizerPoolButton(compact: true)
            TextField("Search visualizers", text: $query).textFieldStyle(.roundedBorder)
            Picker("Category", selection: $category) {
                Text("All categories").tag("")
                ForEach(library.categories, id: \.self) { Text($0).tag($0) }
            }
            Toggle("Favorites", isOn: $favorites)
            List(library.filteredScenes(query: query, category: category, favoritesOnly: favorites), id: \.self) { scene in
                HStack(spacing: 8) {
                    Button { studio.assign(scene) } label: {
                        Label(NativeEffects.names[scene], systemImage: library.icon(for: scene))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading).contentShape(Rectangle())
                    }.buttonStyle(.plain).hoverEffect(.highlight)
                    Button { library.toggleFavorite(scene) } label: {
                        Image(systemName: library.isFavorite(scene) ? "heart.fill" : "heart")
                    }.buttonStyle(.borderless).accessibilityLabel("Favorite \(NativeEffects.names[scene])")
                }.listRowBackground(scene == studio.selectedScene ? Color.orange.opacity(0.18) : Color.clear)
            }.listStyle(.plain)
            Text("\(NativeEffects.activeCount) native effects").font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct VisionTransportView: View {
    @ObservedObject var studio: VisionStudio
    @ObservedObject var transport: VisionTransport
    var body: some View {
        HStack(spacing: 16) {
            Button { studio.togglePlayback() } label: {
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
                Text("\(studio.project.clips.count) scenes · \(Int(studio.project.bpm)) BPM").foregroundStyle(.secondary)
                Spacer()
                Button("Move left", systemImage: "arrow.left") { studio.moveClip(-1) }.disabled(studio.selectedIndex == 0)
                Button("Move right", systemImage: "arrow.right") { studio.moveClip(1) }.disabled(studio.selectedIndex == studio.project.clips.count - 1)
                Button("Add scene", systemImage: "plus") { studio.addClip() }
                Button("Remove", systemImage: "minus") { studio.removeClip() }.disabled(studio.project.clips.count == 1)
            }
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
