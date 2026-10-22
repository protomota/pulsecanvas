import SwiftUI

private let tvAccent = Color(red: 0.91, green: 0.65, blue: 0.52)

struct TVPlayerView: View {
    @ObservedObject var player: TVPlayer
    @State private var controls = true
    @State private var panel: TVPanel?
    @Environment(\.scenePhase) private var phase
    enum TVPanel: String, Identifiable { case library, music, style, legal; var id: String { rawValue } }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VisualizerView(state: player.studio.render).ignoresSafeArea()
            if controls {
                LinearGradient(colors: [.clear, .black.opacity(0.92)], startPoint: .center, endPoint: .bottom).ignoresSafeArea().allowsHitTesting(false)
                TVControls(player: player, studio: player.studio, transport: player.studio.transport,
                           panel: $panel, controls: $controls)
                    .padding(.horizontal, 70).padding(.bottom, 60)
            }
            if player.loading || player.studio.loading {
                ProgressView("Preparing music…").padding(32).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if let message = player.studio.render.errorMessage {
                Text(message).padding(32).background(.black.opacity(0.85)).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .tint(tvAccent)
        .onPlayPauseCommand { player.togglePlayback(); controls = true }
        .onExitCommand { controls.toggle() }
        .onMoveCommand { _ in if !controls { controls = true } }
        .sheet(item: $panel) { panel in
            switch panel {
            case .library: TVLibrary(studio: player.studio)
            case .music: TVMusic(player: player)
            case .style: TVStyle(studio: player.studio)
            case .legal: TVLegal()
            }
        }
        .task { await player.start() }
        .onChange(of: phase) { _, phase in if phase == .background { player.suspend() } }
        .alert("PulseCanvas Studio", isPresented: Binding(get: { player.error != nil || player.studio.message != nil }, set: { if !$0 { player.error = nil; player.studio.message = nil } })) {
            Button("OK") { player.error = nil; player.studio.message = nil }
        } message: { Text(player.error ?? player.studio.message ?? "") }
    }
}

private struct TVControls: View {
    @ObservedObject var player: TVPlayer
    @ObservedObject var studio: VisionStudio
    @ObservedObject var transport: VisionTransport
    @ObservedObject private var library = ProjectMPresets.shared
    @Binding var panel: TVPlayerView.TVPanel?
    @Binding var controls: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("PULSECANVAS STUDIO").font(.caption.weight(.semibold)).tracking(4).foregroundStyle(tvAccent)
            HStack {
                Button { library.toggleFavorite(studio.selectedScene) } label: {
                    Image(systemName: library.isFavorite(studio.selectedScene) ? "heart.fill" : "heart")
                }.accessibilityLabel("Favorite visualizer")
                Text(NativeEffects.names[studio.selectedScene]).font(.system(size: 52, weight: .bold)).lineLimit(1)
                Spacer()
            }
            HStack(spacing: 24) {
                Button { player.togglePlayback() } label: {
                    Label(transport.playing ? "Pause" : "Play", systemImage: transport.playing ? "pause.fill" : "play.fill").frame(width: 140)
                }
                    .disabled(studio.loading || transport.duration <= 0)
                Button("Visualizers", systemImage: "square.grid.2x2") { panel = .library }
                Button("Randomize", systemImage: "shuffle") { player.randomizeVisualizer() }
                Button("Visual style", systemImage: "slider.horizontal.3") { panel = .style }
                Button("Hide controls", systemImage: "rectangle.compress.vertical") { controls = false }
            }
            HStack(spacing: 24) {
                Label(studio.project.audioTitle, systemImage: "waveform").lineLimit(1)
                Spacer()
                Text(Duration.seconds(transport.seconds).formatted(.time(pattern: .minuteSecond))).monospacedDigit()
                Button("Music & Radio", systemImage: "radio") { panel = .music }
                Button("Next song", systemImage: "forward.end.fill") { player.nextSong() }.disabled(player.loading)
                Button("Settings", systemImage: "gearshape") { panel = .legal }
            }.font(.callout)
            ProgressView(value: transport.seconds, total: max(1, transport.duration)).tint(tvAccent)
        }
    }
}

private struct TVLibrary: View {
    @ObservedObject var studio: VisionStudio
    @ObservedObject private var library = ProjectMPresets.shared
    @State private var category = ""
    @State private var favorites = false
    @Environment(\.dismiss) private var dismiss
    private var scenes: [Int] { library.filteredScenes(query: "", category: category, favoritesOnly: favorites) }
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack { Text("Visualizers").font(.largeTitle.bold()); Spacer(); Button("Done") { dismiss() } }
            HStack(spacing: 30) {
                Picker("Category", selection: $category) {
                    Text("All categories").tag("")
                    ForEach(library.categories, id: \.self) { Text($0).tag($0) }
                }.pickerStyle(.menu)
                Toggle("Favorites", isOn: $favorites)
                Text("\(scenes.count) visualizers").foregroundStyle(.secondary)
            }
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 30), count: 4), spacing: 32) {
                    ForEach(scenes, id: \.self) { scene in
                        Button { studio.assign(scene); dismiss() } label: {
                            VStack(alignment: .leading, spacing: 18) {
                                Image(systemName: NativeEffects.all[scene].icon).font(.system(size: 44)).foregroundStyle(tvAccent)
                                Text(NativeEffects.names[scene]).font(.headline).lineLimit(1).minimumScaleFactor(0.7)
                            }.frame(maxWidth: .infinity, minHeight: 135, alignment: .leading).padding(24)
                        }.buttonStyle(.card)
                    }
                }.padding(20)
            }
            if scenes.isEmpty { Text("No favorites in this category yet. Use the heart while watching a visualizer.").foregroundStyle(.secondary) }
        }.padding(70).tint(tvAccent)
    }
}

private struct TVMusic: View {
    @ObservedObject var player: TVPlayer
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack { Text("Radio stations").font(.largeTitle.bold()); Spacer(); Button("Done") { dismiss() } }
            Text("Music and station names refresh from the PulseCanvas online library.").foregroundStyle(.secondary)
            if player.stations.isEmpty { ProgressView("Loading stations…") }
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(player.stations) { station in
                        Button { player.selectStation(station.id); dismiss() } label: {
                            HStack { VStack(alignment: .leading, spacing: 8) { Text(station.title).font(.title3.bold()); Text(station.description).font(.callout).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "play.fill") }
                                .frame(maxWidth: .infinity, alignment: .leading).padding(24)
                        }.buttonStyle(.card).disabled(player.loading)
                    }
                }.padding(20)
            }
            if player.stations.isEmpty { Button("Retry") { player.nextSong(reload: true); dismiss() } }
        }.padding(70).tint(tvAccent)
    }
}

private struct TVStyle: View {
    @ObservedObject var studio: VisionStudio
    @Environment(\.dismiss) private var dismiss
    private func adjust(_ title: String, key: WritableKeyPath<VisionLook, Float>, step: Float, limits: ClosedRange<Float>) -> some View {
        HStack(spacing: 36) {
            Text(title).frame(width: 260, alignment: .leading)
            Button("Decrease", systemImage: "minus") { studio.updateLook { $0[keyPath: key] = max(limits.lowerBound, $0[keyPath: key] - step) } }
            Text(studio.look[keyPath: key], format: .number.precision(.fractionLength(1))).monospacedDigit().frame(width: 70)
            Button("Increase", systemImage: "plus") { studio.updateLook { $0[keyPath: key] = min(limits.upperBound, $0[keyPath: key] + step) } }
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            HStack { Text("Visual style").font(.largeTitle.bold()); Spacer(); Button("Done") { dismiss() } }
            Picker("Palette", selection: Binding(get: { studio.look.palette }, set: { value in studio.updateLook { $0.palette = value } })) {
                ForEach(VisualPalette.allCases, id: \.rawValue) { Text($0.title).tag($0.rawValue) }
            }.pickerStyle(.menu)
            adjust("Chaos · music response", key: \.chaos, step: 0.1, limits: 0...1)
            adjust("Zoom speed", key: \.zoomSpeed, step: 0.2, limits: 0...3)
            adjust("Motion speed", key: \.speed, step: 0.2, limits: 0...3)
            Button("Reset to defaults") { studio.resetLook() }
            Spacer()
        }.padding(80).tint(tvAccent)
    }
}

private struct TVLegal: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack { Text("PulseCanvas Studio").font(.largeTitle.bold()); Spacer(); Button("Done") { dismiss() } }
            Button("Welcome to PulseCanvas Studio", systemImage: "sparkles") {
                dismiss()
                NotificationCenter.default.post(name: .pulseCanvasOnboarding, object: nil)
            }.accessibilityIdentifier("settingsWelcomePulseCanvas")
            Text("Copyright © 2026 Protomota, LLC")
            Text("Source: github.com/protomota/pulsecanvas").foregroundStyle(tvAccent)
            ScrollView { Text(Bundle.main.url(forResource: "PulseCanvas-LICENSE", withExtension: "txt", subdirectory: "Legal").flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? "License unavailable").font(.callout) }
        }.padding(80)
    }
}
