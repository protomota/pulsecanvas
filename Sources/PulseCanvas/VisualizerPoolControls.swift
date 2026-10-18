import SwiftUI

/// One shared choice pool for the strip, Library, Studio and randomizers.
struct VisualizerPoolButton: View {
    @ObservedObject private var library = ProjectMPresets.shared
    var compact = false
    @State private var showing = false
    var body: some View {
        Button { showing = true } label: {
            Label(library.pool.enabled ? "Pool · \(library.eligibleScenes.count)" : "Visualizer pool",
                  systemImage: library.pool.enabled ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
        #if os(macOS)
        .buttonStyle(StudioButtonStyle(treatment: library.pool.enabled ? .accent : .secondary, compact: compact))
        #else
        .buttonStyle(.bordered)
        #endif
        .accessibilityLabel("Visualizer pool")
        .accessibilityValue(library.pool.enabled ? library.poolSummary : "Off; all visualizers")
        .help("Choose categories or favorites for browsing, Studio and randomizers")
        .popover(isPresented: $showing) { VisualizerPoolSettings { showing = false } }
    }
}

/// The selection is shared by the editor, Studio randomizers and Radio.
struct VisualizerRandomizerPicker: View {
    @ObservedObject private var library = ProjectMPresets.shared
    var compact = false
    @State private var showSettings = false
    var body: some View {
        Menu {
            Picker("Randomize visualizers", selection: Binding(get: { library.randomizerGroup }, set: { library.setRandomizerGroup($0) })) {
                Text("Randomize all").tag(VisualizerRandomizerGroup.all)
                Text("Randomize favorites").tag(VisualizerRandomizerGroup.favorites)
                Divider()
                ForEach(library.categories, id: \.self) { category in
                    Text("Randomize \(category)").tag(VisualizerRandomizerGroup.category(category))
                }
                if library.randomizerGroup == .custom {
                    Text("Randomize \(library.poolSummary)").tag(VisualizerRandomizerGroup.custom)
                }
            }.labelsHidden().pickerStyle(.inline)
            Divider()
            Button("Customize visualizer pool…") { showSettings = true }
        } label: {
            HStack(spacing: 10) {
                Text(library.randomizerGroup == .custom ? "Randomize \(library.poolSummary)" : library.randomizerGroup.title).lineLimit(1)
                Image(systemName: "chevron.down").font(.caption.weight(.semibold))
            }
        }
        #if os(macOS)
        .menuStyle(.borderlessButton).menuIndicator(.hidden)
        .buttonStyle(StudioButtonStyle(treatment: library.pool.enabled ? .accent : .secondary, compact: compact))
        #else
        .buttonStyle(.bordered)
        #endif
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel("Randomize visualizer group")
        .accessibilityValue(library.randomizerGroup.title)
        .help("Choose all visualizers, favorites, or a category for browsing, Studio and Radio. Saved visual settings stay unchanged.")
        .popover(isPresented: $showSettings) { VisualizerPoolSettings { showSettings = false } }
    }
}

private struct VisualizerPoolSettings: View {
    @ObservedObject private var library = ProjectMPresets.shared
    let close: () -> Void
    @State private var draft = VisualizerPool()
    private let accent = Color(red: 0.95, green: 0.68, blue: 0.55)
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Visualizer pool", systemImage: "line.3.horizontal.decrease.circle")
                .font(.title2.bold())
            Text("Choose the visualizers available throughout the app.")
                .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Toggle("Limit visualizers", isOn: $draft.enabled)
                #if os(macOS)
                .toggleStyle(StudioSwitchStyle())
                #else
                .toggleStyle(.switch)
                #endif
            VStack(spacing: 14) {
                choice("Collection", value: $draft.collection, options: library.collections, all: "All collections")
                choice("Category", value: $draft.category, options: library.categories(in: draft.collection), all: "All categories")
                Toggle(isOn: $draft.favoritesOnly) { Label("Favorites only", systemImage: "heart.fill") }
                    #if os(macOS)
                    .toggleStyle(StudioSwitchStyle())
                    #else
                    .toggleStyle(.switch)
                    #endif
            }.disabled(!draft.enabled).opacity(draft.enabled ? 1 : 0.5)
            let count = library.scenes(in: draft).count
            Label("\(count.formatted()) matching visualizers", systemImage: count == 0 ? "exclamationmark.circle" : "checkmark.circle")
                .foregroundStyle(count == 0 ? Color.orange : accent)
            if count == 0 {
                Text("Choose another category, add favorites, or turn the limit off. Randomizers stay idle when the pool is empty.")
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Text("Applies to the visualizer strip, Library, Studio pickers and randomizers. Saved scenes keep their assignments until you replace or randomize them. Small pools repeat to fill a timeline.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Cancel", action: close)
                Spacer()
                Button(draft.enabled ? "Use this pool" : "Show all visualizers") { library.setPool(draft); close() }
                    #if os(macOS)
                    .buttonStyle(StudioButtonStyle(treatment: .primary))
                    #else
                    .buttonStyle(.borderedProminent)
                    #endif
            }
            #if os(macOS)
            .buttonStyle(StudioButtonStyle())
            #endif
        }.padding(24).frame(width: 420).tint(accent)
            .onAppear { draft = library.pool }
            .onChange(of: draft.collection) { _, _ in draft.category = "" }
    }
    private func choice(_ title: String, value: Binding<String>, options: [String], all: String) -> some View {
        HStack {
            Text(title).frame(width: 85, alignment: .leading)
            Picker(title, selection: value) {
                Text(all).tag("")
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }.labelsHidden().frame(maxWidth: .infinity).controlSize(.large)
        }
    }
}
