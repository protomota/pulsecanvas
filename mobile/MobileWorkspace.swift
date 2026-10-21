import SwiftUI
import StoreKit
import UniformTypeIdentifiers
import UIKit

private enum MobileSheet: String, Identifiable {
    case library, style, export, about, apply, music
    var id: String { rawValue }
}

enum MobileTheme {
    static let background = Color(red: 0.12, green: 0.10, blue: 0.14)
    static let panel = Color(red: 0.19, green: 0.16, blue: 0.21)
    static let accent = Color(red: 0.95, green: 0.68, blue: 0.55)
}

struct MobileButton: ButtonStyle {
    var prominent = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14).frame(minHeight: 44)
            .foregroundStyle(prominent ? MobileTheme.background : .white)
            .background(prominent ? MobileTheme.accent : MobileTheme.panel, in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(.white.opacity(prominent ? 0 : 0.1)))
            .contentShape(RoundedRectangle(cornerRadius: 13))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct MobileWorkspace: View {
    @ObservedObject var editor: MobileEditor
    @ObservedObject var studio: StudioStore
    @ObservedObject var audio: AudioController
    @ObservedObject var radio: RadioController
    @ObservedObject var engagement: CreatorEngagement
    @ObservedObject private var library = ProjectMPresets.shared
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var phase
    @State private var sheet: MobileSheet?
    @State private var audioPicker = false
    @State private var projectPicker = false
    @State private var savingProject = false
    @State private var projectDocument = MobileProjectDocument(data: Data())
    @State private var randomizePrompt = false

    init(editor: MobileEditor) {
        self.editor = editor; studio = editor.studio; audio = editor.audio
        radio = editor.radio; engagement = editor.engagement
    }
    private var canRequestReview: Bool {
        engagement.pendingExportThanks && sheet == nil && phase == .active
            && !editor.presenting && !audio.isPlaying && !editor.loading && editor.message == nil
    }
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                header(compact: geometry.size.width < 700)
                    .padding(.trailing, geometry.safeAreaInsets.trailing)
                Divider().overlay(.white.opacity(0.08))
                if editor.selectedTab == 1 {
                    MobileRadio(editor: editor, trailingControlInset: geometry.safeAreaInsets.trailing, present: { editor.presenting = true })
                } else {
                    HStack(spacing: 0) {
                        if geometry.size.width >= 850 && geometry.size.height >= 500 {
                            MobileLibrary(editor: editor, close: nil)
                                .frame(width: min(255, geometry.size.width * 0.26))
                            Divider()
                        }
                        if geometry.size.width >= 650 && geometry.size.width > geometry.size.height {
                            studioContent(size: geometry.size, bounded: true)
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("mobileStudioLandscape")
                        } else {
                            ScrollView { studioContent(size: geometry.size, bounded: false) }
                        }
                    }
                }
            }
            // Media uses the space below Duo's side status region. Only the
            // header reserves its trailing inset so buttons avoid system controls.
            .ignoresSafeArea(.container, edges: .trailing)
            .background(MobileTheme.background).tint(MobileTheme.accent)
        }
        .task { await editor.start() }
        .task { await editor.radio.refreshFavoriteSongs() }
        .task { await engagement.observeStorefront() }
        .task(id: canRequestReview) {
            guard canRequestReview else { return }
            do { try await Task.sleep(for: .seconds(11)) } catch { return }
            if canRequestReview, engagement.presentExportThanks() { requestReview() }
        }
        .onChange(of: phase) { _, value in editor.setForeground(value == .active, inBackground: value == .background) }
        .sheet(item: $sheet) { item in
            NavigationStack {
                Group {
                    switch item {
                    case .library: MobileLibrary(editor: editor, close: { sheet = nil })
                    case .style: MobileStyle(editor: editor)
                    case .export: MobileExport(editor: editor)
                    case .about: MobileAbout()
                    case .apply: MobileApply(editor: editor)
                    case .music:
                        StudioMusicPicker(source: radio.studioMusicSource, folderBookmark: radio.studioMusicFolderBookmark,
                            library: radio.studioMusicLibrary, favoriteIDs: Set(radio.favoriteSongs.map(\.id)), useSong: editor.importLibrarySong, close: { sheet = nil })
                            .toolbar(.hidden, for: .navigationBar)
                    }
                }.navigationTitle(title(item)).navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { sheet = nil }.disabled(editor.exporter.isExporting) } }
                    .background(MobileTheme.background)
            }.tint(MobileTheme.accent).preferredColorScheme(.dark)
        }
        .fileImporter(isPresented: $audioPicker, allowedContentTypes: [.audio]) { result in
            switch result {
            case .success(let url): Task { await editor.importAudio(url) }
            case .failure(let error): editor.message = error.localizedDescription
            }
        }
        .fileImporter(isPresented: $projectPicker, allowedContentTypes: [.pulseCanvasProject, .json]) { result in
            switch result {
            case .success(let url):
                let access = SecurityScopedAccess(url: url)
                do { let data = try Data(contentsOf: url); Task { await editor.openProject(data); withExtendedLifetime(access) {} } }
                catch { editor.message = error.localizedDescription }
            case .failure(let error): editor.message = error.localizedDescription
            }
        }
        .onOpenURL { url in
            let access = SecurityScopedAccess(url: url)
            do {
                let data = try Data(contentsOf: url)
                Task { await editor.openProject(data); withExtendedLifetime(access) {} }
            } catch { editor.message = error.localizedDescription }
        }
        .fileExporter(isPresented: $savingProject, document: projectDocument, contentType: .pulseCanvasProject,
                      defaultFilename: "PulseCanvas Studio.pulsecanvas") { result in
            if case .failure(let error) = result { editor.message = error.localizedDescription }
        }
        .alert("PulseCanvas Studio", isPresented: Binding(get: { editor.message != nil }, set: { if !$0 { editor.message = nil } })) {
            Button("OK") { editor.message = nil }
        } message: { Text(editor.message ?? "") }
        .confirmationDialog("Randomize this timeline?", isPresented: $randomizePrompt, titleVisibility: .visible) {
            Button("Randomize visualizers") { _ = editor.studio.randomizeTimeline(editor.render); editor.saveSession() }
            Button("Randomize bar lengths") {
                if let grid = editor.audio.segmentPlan(beatsPerSection: 4) { _ = editor.studio.randomizeBars(grid: grid, render: editor.render); editor.saveSession() }
            }
        } message: { Text("This replaces the chosen visualizers or scene lengths throughout your Studio timeline.") }
        .fullScreenCover(isPresented: $editor.presenting) { MobilePresentation(editor: editor) }
    }
    @ViewBuilder private func studioContent(size: CGSize, bounded: Bool) -> some View {
        if bounded && size.height < 500 {
            // The closed display in landscape is too short to stack a preview
            // above full scene cards. Give each its own column instead.
            HStack(spacing: 16) {
                MobilePreview(editor: editor, style: { sheet = .style }, present: { editor.presenting = true })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                VStack(spacing: 12) {
                    MobileTransport(audio: editor.audio)
                    timeline
                }.frame(maxWidth: .infinity)
            }.padding(12)
        } else {
            VStack(spacing: bounded ? 12 : 16) {
                MobilePreview(editor: editor, style: { sheet = .style }, present: { editor.presenting = true })
                    .frame(maxHeight: bounded ? .infinity : max(220, size.height * 0.52))
                MobileTransport(audio: editor.audio)
                timeline
            }.padding(size.width < 600 ? 12 : bounded ? 16 : 20)
        }
    }
    private func title(_ item: MobileSheet) -> String {
        switch item {
        case .library: "Visualizers"
        case .style: "Visual style"
        case .export: "Export video"
        case .about: "About & Support"
        case .apply: "Apply to all"
        case .music: "Choose music"
        }
    }
    private var windowControlClearance: CGFloat {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return 0 }
        if #available(iOS 26, *) { return 28 }
        return 0
    }
    private func header(compact: Bool) -> some View {
        HStack(spacing: 12) {
            Picker("Workspace", selection: $editor.selectedTab) { Text("Studio").tag(0); Text("Radio").tag(1) }
                .pickerStyle(.segmented).frame(maxWidth: compact ? 175 : 225)
                .onChange(of: editor.selectedTab) { _, tab in if tab == 0 { editor.radio.leave() } else { editor.audio.pause() } }
            Spacer(minLength: 0)
            Button { sheet = .library } label: { Image(systemName: "square.grid.2x2").frame(width: 20) }
                .accessibilityLabel("Open visualizer library").accessibilityIdentifier("mobileLibraryButton")
            Menu {
                Button("Choose music", systemImage: "music.note.list") { sheet = .music }
                Button("Import audio", systemImage: "waveform.badge.plus") { audioPicker = true }
                Button("Open project", systemImage: "folder") { projectPicker = true }
                Button("Save project", systemImage: "internaldrive") {
                    do { projectDocument = MobileProjectDocument(data: try editor.projectData()); savingProject = true }
                    catch { editor.message = error.localizedDescription }
                }.disabled(radio.isActive && radio.isPersonalMusic)
                Button("Export MP4", systemImage: "film") { sheet = .export }
                    .disabled(audio.selectedURL == nil || radio.isActive && (!radio.canSeek || radio.isPersonalMusic))
                Divider()
                Button("About & Support", systemImage: "info.circle") { sheet = .about }
            } label: { Image(systemName: "ellipsis").frame(width: 20) }.accessibilityLabel("Project actions")
        }.buttonStyle(MobileButton()).padding(.horizontal, 16).padding(.vertical, 10)
            // Keep the tabs leading, below iPadOS's window-control strip.
            .padding(.top, windowControlClearance)
            .disabled(editor.loading || editor.exporter.isExporting)
    }
    private var timeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Studio", systemImage: "rectangle.split.3x1").font(.headline)
                Spacer()
                Button { sheet = .apply } label: { Image(systemName: "slider.horizontal.3") }.accessibilityLabel("Apply to all")
                Button { randomizePrompt = true } label: { Image(systemName: "shuffle") }.accessibilityLabel("Randomize timeline")
            }.buttonStyle(MobileButton())
            if editor.needsSoundtrack {
                Button("Locate soundtrack", systemImage: "waveform.badge.plus") { audioPicker = true }.buttonStyle(MobileButton(prominent: true))
            }
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(Array(editor.studio.segments.enumerated()), id: \.offset) { index, clip in
                            MobileClip(editor: editor, index: index, clip: clip, choose: { editor.selectClip(index); sheet = .library }).id(index)
                        }
                    }.padding(.vertical, 3)
                }.frame(height: 154).accessibilityIdentifier("mobileStudioTimeline")
                    .onChange(of: studio.selectedSegment) { _, index in
                        guard audio.isPlaying, studio.segments.indices.contains(index) else { return }
                        withAnimation(.easeInOut(duration: 0.25)) { proxy.scrollTo(index, anchor: .center) }
                    }
            }
        }
    }
}

private struct MobilePreview: View {
    @ObservedObject var editor: MobileEditor
    @ObservedObject var render: RenderState
    @ObservedObject private var library = ProjectMPresets.shared
    let style: () -> Void
    let present: () -> Void
    init(editor: MobileEditor, style: @escaping () -> Void, present: @escaping () -> Void) {
        self.editor = editor; self.render = editor.render; self.style = style; self.present = present
    }
    var body: some View {
        VStack(spacing: 10) {
            VisualizerView(state: render).aspectRatio(16 / 9.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16)).accessibilityIdentifier("mobileVisualizerPreview")
            if let error = render.errorMessage { Text(error).foregroundStyle(.red).accessibilityIdentifier("mobileRenderError") }
            HStack(spacing: 8) {
                Button { library.toggleFavorite(render.scene, appearance: VisualPreset(render: render)) } label: {
                    Image(systemName: library.isFavorite(render.scene) ? "heart.fill" : "heart").frame(width: 16)
                }.accessibilityLabel("Favorite visualizer")
                Text(library.sceneNames[render.scene]).font(.headline).lineLimit(1).accessibilityIdentifier("mobileVisualizerName")

                Spacer(minLength: 0)
                Button { editor.studio.randomizeScene(render); editor.saveSession() } label: { Image(systemName: "shuffle") }.accessibilityLabel("Random visualizer")
                Button(action: style) { Image(systemName: "slider.horizontal.3") }.accessibilityLabel("Visual style")
                Button(action: present) { Image(systemName: "arrow.up.left.and.arrow.down.right") }.accessibilityLabel("Present visualizer")
            }.buttonStyle(MobileButton())
        }
    }
}

struct MobileTransport: View {
    @ObservedObject var audio: AudioController
    @State private var fraction = 0.0
    @State private var seconds = 0.0
    @State private var seeking = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(audio.title).font(.subheadline.weight(.medium)).lineLimit(1)
            HStack(spacing: 12) {
                Button { audio.playPause() } label: { Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill").frame(width: 30) }
                    .buttonStyle(MobileButton(prominent: true)).accessibilityLabel(audio.isPlaying ? "Pause" : "Play").accessibilityIdentifier("mobilePlaybackButton")
                Text(Self.time(seconds)).monospacedDigit().font(.caption)
                Slider(value: $fraction, in: 0...1, onEditingChanged: { editing in
                    seeking = editing
                    if !editing { audio.seek(fraction: fraction) }
                }).accessibilityLabel("Soundtrack position")
                Text(Self.time(audio.duration)).monospacedDigit().font(.caption)
                Toggle(isOn: $audio.loopEnabled) { Image(systemName: "repeat") }.toggleStyle(.button).accessibilityLabel("Loop soundtrack")
            }
        }.onReceive(audio.visualizationUpdated) { _ in if !seeking { fraction = audio.progress; seconds = audio.playbackSeconds } }
    }
    static func time(_ seconds: Double) -> String { let value = Int(max(0, seconds.isFinite ? seconds : 0)); return String(format: "%d:%02d", value / 60, value % 60) }
}

private struct MobileClip: View {
    @ObservedObject var editor: MobileEditor
    @ObservedObject var studio: StudioStore
    let index: Int
    let clip: StudioSegment
    let choose: () -> Void
    init(editor: MobileEditor, index: Int, clip: StudioSegment, choose: @escaping () -> Void) {
        self.editor = editor; studio = editor.studio; self.index = index; self.clip = clip; self.choose = choose
    }
    var body: some View {
        ZStack {
            Button { editor.selectClip(index) } label: { RoundedRectangle(cornerRadius: 15).fill(MobileTheme.panel) }
                .buttonStyle(.plain).accessibilityLabel("Select scene \(index + 1)")
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(MobileTransport.time(clip.start)) – \(MobileTransport.time(clip.end))").font(.caption).allowsHitTesting(false)
                    Spacer()
                    Button { editor.selectClip(index, play: true) } label: { Image(systemName: "play.fill").frame(width: 36, height: 36) }
                        .accessibilityLabel("Play scene \(index + 1)")
                }
                Button(action: choose) { HStack { Text(editor.library.sceneNames[clip.scene]).lineLimit(1); Spacer(); Image(systemName: "chevron.down") } }
                    .accessibilityLabel("Choose visualizer for scene \(index + 1)")
                Stepper("\(studio.barCount(for: clip)) bars", value: Binding(get: { studio.barCount(for: clip) }, set: { editor.setBars($0, at: index) }), in: 1...64)
                    .font(.caption).accessibilityIdentifier("sceneBars-\(index)")
            }.padding(14)
        }.frame(width: 260, height: 148)
            .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(studio.selectedSegment == index ? MobileTheme.accent : .white.opacity(0.12), lineWidth: 1.5))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(studio.selectedSegment == index ? "currentStudioClip" : "studioClip-\(index)")
    }
}

struct MobileLibrary: View {
    @ObservedObject var editor: MobileEditor
    @ObservedObject private var library = ProjectMPresets.shared
    let close: (() -> Void)?
    @State private var query = ""
    var body: some View {
        VStack(spacing: 12) {
            TextField("Search visualizers", text: $query).textFieldStyle(.plain).padding(.horizontal, 12).frame(height: 48)
                .background(MobileTheme.panel, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityIdentifier(close == nil ? "sidebarVisualizerSearch" : "modalVisualizerSearch")
            VisualizerRandomizerPicker(fillsWidth: true)
            List(library.filteredScenes(query: query, category: "", favoritesOnly: false), id: \.self) { scene in
                if library.eligibleScenes.contains(scene) {
                    HStack {
                        Button {
                            if editor.radio.isActive { editor.radio.leave(); editor.selectedTab = 0 }
                            editor.choose(scene); close?()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: library.icon(for: scene)).foregroundStyle(MobileTheme.accent).frame(width: 28)
                                Text(library.sceneNames[scene]).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                            }.frame(minHeight: 44).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                        Button { library.toggleFavorite(scene, appearance: editor.studio.presets[scene]) } label: {
                            Image(systemName: library.isFavorite(scene) ? "heart.fill" : "heart").frame(width: 44, height: 44)
                        }.buttonStyle(.borderless).accessibilityLabel("Favorite \(library.sceneNames[scene])")
                    }.listRowBackground(MobileTheme.panel)
                }
            }.listStyle(.plain).scrollContentBackground(.hidden)
        }.padding(12)
    }
}

struct MobileStyle: View {
    @ObservedObject var editor: MobileEditor
    @ObservedObject var render: RenderState
    init(editor: MobileEditor) { self.editor = editor; render = editor.render }
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                HStack {
                    Text(editor.library.sceneNames[render.scene]).font(.headline).lineLimit(1)
                    Spacer()
                    Button("Reset") { editor.studio.reset(render) }
                    Button { editor.studio.randomize(render) } label: { Image(systemName: "dice.fill").font(.title2) }.accessibilityLabel("Randomize visual style")
                }.buttonStyle(MobileButton())
                Picker("Palette", selection: $render.palette) { ForEach(VisualPalette.allCases, id: \.rawValue) { Text($0.title).tag($0.rawValue) } }
                    .pickerStyle(.menu).accessibilityIdentifier("mobilePalettePicker")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 24)], spacing: 24) {
                    control("Chaos", value: $render.chaos, range: 0...1)
                    control("Motion speed", value: $render.speed, range: 0.05...3)
                    control("Zoom speed", value: $render.zoomSpeed, range: 0...3)
                    control("Brightness", value: $render.brightness, range: 0.3...2)
                    control("Element size", value: $render.particleSize, range: 0.2...4)
                    control("Depth", value: $render.fog, range: 0...1)
                    control("Liquid detail", value: $render.liquidDetail, range: 0...1)
                    control("Content blur", value: $render.motionBlur, range: 0...1)
                }
                Toggle("Hi-hat strobe", isOn: $render.strobeEnabled).accessibilityIdentifier("mobileStrobeToggle")
                if render.strobeEnabled {
                    Text("Adds rapid flashes in time with high-frequency percussion.").font(.caption).foregroundStyle(.secondary)
                    control("Strobe sensitivity", value: $render.strobeSensitivity, range: 0.25...4)
                    control("Strobe strength", value: $render.strobeStrength, range: 0.1...1)
                }
            }.padding(24)
        }.accessibilityIdentifier("mobileStyleScroll")
            .onDisappear { editor.studio.save(render); editor.saveSession() }
    }
    private func control(_ title: String, value: Binding<Float>, range: ClosedRange<Float>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text(title); Spacer(); Text(value.wrappedValue, format: .number.precision(.fractionLength(2))).foregroundStyle(.secondary).monospacedDigit() }
            Slider(value: value, in: range).accessibilityLabel(title)
        }
    }
}

struct MobileApply: View {
    @ObservedObject var editor: MobileEditor
    @State private var bars = 4
    @State private var chaos: Float = 0.6
    @State private var zoom: Float = 1.5
    @State private var speed: Float = 1
    @State private var useBars = false
    @State private var useChaos = false
    @State private var useZoom = false
    @State private var useSpeed = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Form {
            Section("Change selected settings across the timeline") {
                Toggle("Bars per scene", isOn: $useBars)
                if useBars { Stepper("\(bars) bars", value: $bars, in: 1...64).accessibilityIdentifier("mobileCommonBars") }
                Toggle("Chaos", isOn: $useChaos)
                if useChaos { Slider(value: $chaos, in: 0...1).accessibilityLabel("Common chaos") }
                Toggle("Zoom speed", isOn: $useZoom)
                if useZoom { Slider(value: $zoom, in: 0...3).accessibilityLabel("Common zoom speed") }
                Toggle("Motion speed", isOn: $useSpeed)
                if useSpeed { Slider(value: $speed, in: 0.05...3).accessibilityLabel("Common motion speed") }
            }
            Button("Apply to all scenes") {
                editor.studio.applyCommonSettings(chaos: useChaos ? chaos : nil, zoomSpeed: useZoom ? zoom : nil, motionSpeed: useSpeed ? speed : nil, render: editor.render)
                if useBars, let grid = editor.audio.segmentPlan(beatsPerSection: 4) { _ = editor.studio.setBars(bars, grid: grid, render: editor.render) }
                editor.saveSession(); dismiss()
            }.disabled(!useBars && !useChaos && !useZoom && !useSpeed)
        }
    }
}
