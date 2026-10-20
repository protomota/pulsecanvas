import SwiftUI

/// A soundtrack picker, separate from Radio's listening and station controls.
@MainActor struct StudioMusicPicker: View {
    @StateObject private var catalog: StudioMusicCatalog
    let favoriteIDs: Set<String>
    let useSong: (URL, String) async throws -> Void
    let close: () -> Void
    @State private var favoritesOnly = false
    @State private var search = ""
    @FocusState private var searchFocused: Bool
    @State private var adding: String?
    @State private var error: String?
    @State private var addition: Task<Void, Never>?

    init(source: URL, folderBookmark: Data? = nil, library: RadioLibrary = RadioLibrary(), favoriteIDs: Set<String>,
         useSong: @escaping (URL, String) async throws -> Void, close: @escaping () -> Void) {
        _catalog = StateObject(wrappedValue: StudioMusicCatalog(source: source, folderBookmark: folderBookmark, library: library))
        self.favoriteIDs = favoriteIDs; self.useSong = useSong; self.close = close
    }

    private var songs: [RadioTrack] { catalog.matching(search: search, favoritesOnly: favoritesOnly, favoriteIDs: favoriteIDs) }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Choose music", systemImage: "music.note.list").font(.title2.bold())
                Spacer()
                Button("Cancel") { addition?.cancel(); close() }.accessibilityIdentifier("cancelStudioMusic")
            }
            Text("Add a song as your Studio soundtrack, then create and export your video.").foregroundStyle(.secondary)
            Picker("Songs", selection: $favoritesOnly) {
                Text("All songs").tag(false)
                Label("Favorites", systemImage: "heart.fill").tag(true)
            }.pickerStyle(.segmented).accessibilityIdentifier("studioMusicFilter")
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search songs or genres", text: $search).textFieldStyle(.plain)
                    .focused($searchFocused).autocorrectionDisabled()
                    .onSubmit { searchFocused = false }
                    .accessibilityIdentifier("studioMusicSearch")
                if !search.isEmpty {
                    Button { searchFocused = false; search = "" } label: {
                        Image(systemName: "xmark.circle.fill").frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel("Clear song search").accessibilityIdentifier("clearStudioMusicSearch")
                }
            }.padding(.horizontal, 14).frame(minHeight: 48)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            if catalog.loading {
                ProgressView("Loading music…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let failure = catalog.error {
                ContentUnavailableView {
                    Label("Music couldn’t load", systemImage: "wifi.exclamationmark")
                } description: { Text(failure) } actions: {
                    Button("Try again") { Task { await catalog.load() } }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if songs.isEmpty {
                ContentUnavailableView(favoritesOnly ? "No matching favorite songs" : "No matching songs",
                    systemImage: favoritesOnly ? "heart" : "music.note",
                    description: Text(favoritesOnly ? "Save songs with the heart in Radio, or choose All songs." : "Try another search."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(songs) { song in
                            Button { add(song) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: favoriteIDs.contains(song.id) ? "heart.fill" : "music.note")
                                        .foregroundStyle(.orange).frame(width: 24)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(song.title).font(.headline).lineLimit(1)
                                        Text("\(song.genre) · \(duration(song.duration))").font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 8)
                                    if adding == song.id { ProgressView().controlSize(.small) }
                                    else { Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(.orange) }
                                }.padding(14).frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                                    .contentShape(RoundedRectangle(cornerRadius: 12))
                            }.buttonStyle(.plain).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                                .accessibilityLabel("Use \(song.title) in Studio").accessibilityIdentifier("studioMusicSong-\(song.id)")
                        }
                    }
                }
            }
            if adding != nil { Label("Downloading and preparing your soundtrack…", systemImage: "arrow.down.circle").font(.callout).foregroundStyle(.secondary) }
            if let error { Text(error).font(.callout).foregroundStyle(.red).accessibilityIdentifier("studioMusicError") }
        }.padding(24)
            .background(Color(red: 0.12, green: 0.10, blue: 0.14)).tint(Color(red: 0.95, green: 0.68, blue: 0.55))
            .task { await catalog.load() }
            .onDisappear { addition?.cancel() }
            .interactiveDismissDisabled(adding != nil)
    }
    private func add(_ song: RadioTrack) {
        guard adding == nil else { return }
        searchFocused = false
        adding = song.id; error = nil
        addition = Task {
            defer { adding = nil }
            do {
                let url = try await catalog.audio(for: song)
                try Task.checkCancellation()
                try await useSong(url, song.title)
                close()
            } catch is CancellationError { }
            catch { self.error = error.localizedDescription }
        }
    }
    private func duration(_ seconds: Double) -> String {
        String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }
}
