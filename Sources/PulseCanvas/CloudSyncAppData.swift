import Foundation

/// Only portable user choices cross devices. Volume, playback state, authorization
/// bookmarks, support clicks and downloaded public Radio caches stay on each device.
@MainActor enum CloudSyncAppData {
    struct SavedLooks: Codable { var presets: [Int: VisualPreset]; var identities: [Int: String]? }
    static let visionLooksKey = "PulseCanvas.cloudLooks.v1"
    private static func normalized(_ saved: SavedLooks, library: ProjectMPresets) -> [Int: VisualPreset] {
        var result: [Int: VisualPreset] = [:]
        for scene in saved.presets.keys.sorted() where !library.isRetiredScene(scene, identities: saved.identities) {
            guard let look = saved.presets[scene], look.isValid,
                  let resolved = try? library.migratedScene(scene, identities: saved.identities),
                  library.availableScenes.contains(resolved), result[resolved] == nil else { continue }
            result[resolved] = look
        }
        return result
    }
    static func canDeleteSong(_ change: CloudSyncChange) -> Bool {
        #if os(visionOS)
        guard let song = try? JSONDecoder().decode(FavoriteRadioSong.self, from: change.payload) else { return false }
        return song.sourceURL.absoluteString == "https://radio.pulsecanvas.si/stations.json"
        #else
        return true
        #endif
    }
    static func snapshot(defaults: UserDefaults = .standard, library suppliedLibrary: ProjectMPresets? = nil) throws -> (values: [String: Data], scope: Set<String>) {
        let library = suppliedLibrary ?? .shared
        var values: [String: Data] = [:], scope = Set<String>()
        let backup = try FavoritesBackup.read(library.exportFavorites())
        for scene in library.availableScenes {
            let id = library.identity(for: scene)
            scope.insert("visualFavorite:" + id); scope.insert("look:" + id)
        }
        for favorite in backup.favorites { values["visualFavorite:" + favorite.id] = try CloudSyncLedger.encoded(favorite) }
        #if os(visionOS)
        if let data = defaults.data(forKey: visionLooksKey), let looks = try? JSONDecoder().decode([String: VisualPreset].self, from: data) {
            for (id, look) in looks where look.isValid { values["look:" + id] = try CloudSyncLedger.encoded(look) }
        }
        #else
        #if STORE_BUILD
        let key = "PulseCanvas.metalStudio.v1"
        #else
        let key = "PulseCanvas.studio.v1"
        #endif
        if let data = defaults.data(forKey: key), let saved = try? JSONDecoder().decode(SavedLooks.self, from: data) {
            for (scene, look) in normalized(saved, library: library) {
                values["look:" + library.identity(for: scene)] = try CloudSyncLedger.encoded(look)
            }
        }
        #endif
        if let data = defaults.data(forKey: "PulseCanvas.radio.favoriteSongs.v1") {
            let songs = try JSONDecoder().decode([FavoriteRadioSong].self, from: data)
            for song in songs where song.isValid && song.sourceURL.scheme == "https" && song.catalogURL.scheme == "https" {
                let portable = FavoriteRadioSong(track: song.track, sourceURL: song.sourceURL, catalogURL: song.catalogURL,
                    stationID: song.stationID, folderBookmark: nil)
                values["songFavorite:" + song.id] = try CloudSyncLedger.encoded(portable)
            }
        }
        // Songs removed from a successfully refreshed local library are explicit
        // changes. The caller adds its previous local song IDs to this scope.
        scope.formUnion(values.keys.filter { $0.hasPrefix("songFavorite:") })
        return (values, scope)
    }

    static func validate(_ change: CloudSyncChange) throws {
        _ = try change.validated()
        guard !change.deleted else { return }
        switch change.kind {
        case .visualFavorite:
            let value = try JSONDecoder().decode(FavoritesBackup.Favorite.self, from: change.payload)
            guard value.id == change.key, value.appearance?.isValid ?? true, (value.name?.count ?? 0) < 1000 else { throw CocoaError(.fileReadCorruptFile) }
        case .songFavorite:
            let value = try JSONDecoder().decode(FavoriteRadioSong.self, from: change.payload)
            guard value.id == change.key, value.isValid, value.folderBookmark == nil,
                  value.sourceURL.scheme == "https", value.catalogURL.scheme == "https" else { throw CocoaError(.fileReadCorruptFile) }
        case .look:
            guard try JSONDecoder().decode(VisualPreset.self, from: change.payload).isValid else { throw CocoaError(.fileReadCorruptFile) }
        case .project:
            _ = try JSONDecoder().decode(CloudProjectInfo.self, from: change.payload).validated()
        }
    }

    static func apply(_ changes: [CloudSyncChange], defaults: UserDefaults = .standard, library suppliedLibrary: ProjectMPresets? = nil) throws {
        let library = suppliedLibrary ?? .shared
        try changes.forEach(validate)
        let favorites = try changes.filter { $0.kind == .visualFavorite && !$0.deleted }.map {
            try JSONDecoder().decode(FavoritesBackup.Favorite.self, from: $0.payload)
        }
        library.applyCloudFavorites(favorites, removed: Set(changes.filter { $0.kind == .visualFavorite && $0.deleted }.map(\.key)))
        var songs = (defaults.data(forKey: "PulseCanvas.radio.favoriteSongs.v1").flatMap { try? JSONDecoder().decode([FavoriteRadioSong].self, from: $0) } ?? [])
        for change in changes where change.kind == .songFavorite {
            songs.removeAll { $0.id == change.key }
            if !change.deleted { songs.append(try JSONDecoder().decode(FavoriteRadioSong.self, from: change.payload)) }
        }
        defaults.set(try CloudSyncLedger.encoded(songs.sorted { $0.id < $1.id }), forKey: "PulseCanvas.radio.favoriteSongs.v1")
        let scenes = Dictionary(uniqueKeysWithValues: library.availableScenes.map { (library.identity(for: $0), $0) })
        #if os(visionOS)
        var looks = defaults.data(forKey: visionLooksKey).flatMap { try? JSONDecoder().decode([String: VisualPreset].self, from: $0) } ?? [:]
        for change in changes where change.kind == .look && scenes[change.key] != nil {
            looks[change.key] = change.deleted ? nil : try JSONDecoder().decode(VisualPreset.self, from: change.payload)
        }
        defaults.set(try CloudSyncLedger.encoded(looks), forKey: visionLooksKey)
        #else
        #if STORE_BUILD
        let key = "PulseCanvas.metalStudio.v1"
        #else
        let key = "PulseCanvas.studio.v1"
        #endif
        var saved = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(SavedLooks.self, from: $0) } ?? SavedLooks(presets: [:])
        let normalized = normalized(saved, library: library)
        if normalized != saved.presets, defaults.data(forKey: key + ".beforeICloud") == nil {
            defaults.set(defaults.data(forKey: key), forKey: key + ".beforeICloud")
        }
        saved.presets = normalized
        for change in changes where change.kind == .look {
            guard let scene = scenes[change.key] else { continue }
            saved.presets[scene] = change.deleted ? nil : try JSONDecoder().decode(VisualPreset.self, from: change.payload)
        }
        saved.identities = library.identities(for: Set(saved.presets.keys))
        defaults.set(try CloudSyncLedger.encoded(saved), forKey: key)
        #endif
        NotificationCenter.default.post(name: .pulseCanvasCloudDataApplied, object: nil)
    }
}
