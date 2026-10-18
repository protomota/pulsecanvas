import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor
struct VisualizerBrowser: View {
    @ObservedObject private var library = ProjectMPresets.shared
    let selected: Int
    var heading: String? = nil
    let choose: (Int) -> Void
    @State private var query = ""
    @State private var collection = ""
    @State private var category = ""
    @State private var folder = ""
    @State private var favoritesOnly = false
    @State private var backupMessage = ""
    @State private var backupFailed = false
    @FocusState private var searchFocused: Bool
    private let accent = Color(red: 0.95, green: 0.68, blue: 0.55)
    private var matches: [Int] {
        library.filteredScenes(query: query, collection: collection, category: category,
            folder: folder, favoritesOnly: favoritesOnly)
    }
    private var folders: [String] {
        library.folders(in: category, collection: collection)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(heading ?? "Library").font(.headline)
                Spacer()
                VisualizerPoolButton(compact: true)
                Text("\(matches.count.formatted()) \(matches.count == 1 ? "effect" : "effects")").font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    TextField("Search visualizers", text: $query)
                        .textFieldStyle(.plain).font(.system(size: 15))
                        .focused($searchFocused).accessibilityLabel("Search visualizers")
                }.padding(.horizontal, 12).frame(height: 44)
                    .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 11))
                    .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(searchFocused ? accent : .white.opacity(0.13), lineWidth: searchFocused ? 2 : 1))
                    .contentShape(RoundedRectangle(cornerRadius: 11))
                    .onTapGesture { searchFocused = true }
                Button {favoritesOnly.toggle()} label: {
                    Label("Favorites", systemImage: favoritesOnly ? "heart.fill" : "heart")
                }.buttonStyle(StudioButtonStyle(treatment: favoritesOnly ? .accent : .secondary, compact: true))
                    .accessibilityLabel(favoritesOnly ? "Show all effects" : "Show favorite effects")
            }
            HStack {
                filterMenu("Collection", selection: $collection, options: library.collections, emptyTitle: "All collections")
                filterMenu("Category", selection: $category, options: library.categories(in: collection), emptyTitle: "All categories")
            }
            if !folders.isEmpty {
                HStack {
                    filterMenu("Folder", selection: $folder, options: folders, emptyTitle: "All folders", prefix: category + "/")
                }
            }
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(matches, id: \.self) { scene in
                        HStack(spacing: 0) {
                            Button { choose(scene) } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: library.icon(for:scene)).font(.system(size:18, weight:.light)).frame(width: 28, height:32).foregroundStyle(.orange.opacity(0.85))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(RenderState.sceneNames[scene]).font(.system(size: 12, weight: .medium)).lineLimit(1)
                                        Text(library.preset(for: scene)?.category ?? "Native Metal · \(library.category(for: scene))").font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                    Spacer()
                                    if selected == scene { Image(systemName: "checkmark").foregroundStyle(.orange) }
                                }.padding(.horizontal, 12).frame(maxWidth: .infinity, minHeight: 52)
                                    .contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityLabel("Use \(RenderState.sceneNames[scene])")
                                .help("Select visualizer")
                            Button {library.toggleFavorite(scene)} label: {
                                Image(systemName: library.isFavorite(scene) ? "heart.fill" : "heart")
                                    .foregroundStyle(library.isFavorite(scene) ? Color.orange : .secondary)
                                    .frame(width: 44, height: 52).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                                .accessibilityLabel("\(library.isFavorite(scene) ? "Unfavorite" : "Favorite") \(RenderState.sceneNames[scene])")
                        }.background(selected == scene ? Color.orange.opacity(0.12) : .white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                            .help(library.preset(for:scene)?.originalTitle ?? RenderState.sceneNames[scene])
                    }
                }
            }.frame(height: 430)
            if matches.isEmpty {Text(favoritesOnly ? "Tap an effect’s heart to add it to Favorites." : (library.pool.enabled ? "No matches in your visualizer pool. Change the pool or turn its limit off." : "No matching visualizers")).foregroundStyle(.secondary).font(.caption)}
            HStack {
                Menu {
                    Button("Export favorites…", systemImage: "square.and.arrow.up", action: exportFavorites)
                    Button("Import favorites…", systemImage: "square.and.arrow.down", action: importFavorites)
                    if let directory = library.favoritesBackupDirectory {
                        Divider()
                        Button("Show automatic backups") { NSWorkspace.shared.open(directory) }
                    }
                } label: {
                    Label("Back up favorites", systemImage: "heart.circle")
                }.menuStyle(.borderlessButton).fixedSize()
                    .help("Export or restore favorites across builds and Macs. Imports keep your existing favorites.")
                Spacer()
                Button {if let scene = matches.randomElement() {choose(scene)}} label: {Label("Surprise me", systemImage: "shuffle")}
                    .buttonStyle(StudioButtonStyle(compact: true)).disabled(matches.isEmpty)
                    .help("Choose randomly from the current search, category, or favorites")
            }
            if !backupMessage.isEmpty || library.favoritesBackupError != nil {
                Text(library.favoritesBackupError ?? backupMessage).font(.caption)
                    .foregroundStyle(backupFailed || library.favoritesBackupError != nil ? Color.red : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }.padding(18).frame(width: 680)
            .onChange(of: category) {_,_ in folder = ""}
            .onChange(of: collection) {_,_ in category = ""; folder = ""}
    }

    private func exportFavorites() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "PulseCanvas-Favorites.json"
        panel.title = "Back up favorites"
        panel.message = "Save a portable backup to restore in another build or on another Mac."
        present(panel) { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try library.exportFavorites().write(to: url, options: .atomic)
                backupFailed = false; backupMessage = "Favorites backup saved."
            } catch { backupFailed = true; backupMessage = "Couldn't save favorites: \(error.localizedDescription)" }
        }
    }

    private func importFavorites() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false; panel.canChooseDirectories = false
        panel.title = "Restore favorites"
        panel.message = "Import a PulseCanvas favorites backup. Your current favorites will be kept."
        present(panel) { response in
            guard response == .OK, let url = panel.url else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let restored = try library.importFavorites(Data(contentsOf: url))
                backupFailed = false
                backupMessage = "Added \(restored.added) favorites."
                if restored.unavailable > 0 { backupMessage += " Skipped \(restored.unavailable) effects that aren't in this edition’s gallery." }
            } catch { backupFailed = true; backupMessage = "Couldn't import favorites: \(error.localizedDescription)" }
        }
    }

    private func present(_ panel: NSSavePanel, completion: @escaping (NSApplication.ModalResponse) -> Void) {
        if let window = NSApp.keyWindow { panel.beginSheetModal(for: window, completionHandler: completion) }
        else { panel.begin(completionHandler: completion) }
    }

    private func filterMenu(_ title: String, selection: Binding<String>, options: [String], emptyTitle: String, prefix: String = "") -> some View {
        HStack(spacing: 8) {
            Text(title).font(.system(size: 13))
            Menu {
                Button { selection.wrappedValue = "" } label: {
                    if selection.wrappedValue.isEmpty { Label(emptyTitle, systemImage: "checkmark") }
                    else { Text(emptyTitle) }
                }
                ForEach(options, id: \.self) { option in
                    Button { selection.wrappedValue = option } label: {
                        if selection.wrappedValue == option { Label(option.replacingOccurrences(of: prefix, with: ""), systemImage: "checkmark") }
                        else { Text(option.replacingOccurrences(of: prefix, with: "")) }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(selection.wrappedValue.isEmpty ? emptyTitle : selection.wrappedValue.replacingOccurrences(of: prefix, with: ""))
                        .font(.system(size: 14)).lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }.contentShape(Rectangle())
            }.menuStyle(.button).menuIndicator(.hidden)
                .buttonStyle(StudioButtonStyle(compact: true))
                .accessibilityLabel("Visualizer \(title.lowercased())")
                .accessibilityValue(selection.wrappedValue.isEmpty ? emptyTitle : selection.wrappedValue.replacingOccurrences(of: prefix, with: ""))
        }
    }
}
