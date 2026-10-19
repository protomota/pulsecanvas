import Foundation
import Combine

struct ProjectMError: LocalizedError {
    let message: String
    init(_ message: String) {self.message = message}
    var errorDescription: String? {message}
}

struct ProjectMPreset: Codable, Identifiable {
    let id: String
    let path: String
    let title: String
    let category: String
    var originalTitle: String? = nil
    var icon: String? = nil
}

/// The shared group scopes browsing and fresh visualizer assignments.
enum VisualizerRandomizerGroup: Hashable, Codable {
    case all
    case favorites
    case category(String)
    case custom

    var title: String {
        switch self {
        case .all: return "Randomize all"
        case .favorites: return "Randomize favorites"
        case .category(let name): return "Randomize \(name)"
        case .custom: return "Randomize pool"
        }
    }
}

struct VisualizerPool: Codable, Equatable, Sendable {
    var enabled = false
    var collection = ""
    var category = ""
    var favoritesOnly = false
}

@MainActor
final class ProjectMPresets: ObservableObject {
    static let shared = ProjectMPresets()
    @Published private(set) var pool = VisualizerPool()
    @Published private(set) var poolRevision = 0
    @Published private(set) var entries: [ProjectMPreset] = []
    private(set) var sceneNames: [String] = []
    @Published private(set) var favoriteIDs: Set<String> = []
    private var favoriteAppearances: [String: VisualPreset] = [:]
    @Published private(set) var favoritesBackupError: String?
    let favoritesBackupDirectory: URL?
    #if os(visionOS)
    private let backupEdition = "Vision-Pro"
    #elseif os(tvOS)
    private let backupEdition = "Apple-TV"
    #elseif os(iOS)
    private let backupEdition = "iPhone-iPad"
    #elseif STORE_BUILD
    private let backupEdition = "Mac-App-Store"
    #elseif LOCAL_BUILD
    private let backupEdition = "Creators-Local"
    #else
    private let backupEdition = "Creators"
    #endif
    #if STORE_BUILD
    private let poolKey = "PulseCanvas.metalVisualizerPool.v1"
    #else
    private let poolKey = "PulseCanvas.visualizerPool.v1"
    #endif
    private let defaults: UserDefaults
    #if STORE_BUILD
    private let favoritesKey = "PulseCanvas.metalEffectFavorites.v1"
    #else
    private let favoritesKey = "PulseCanvas.effectFavorites.v1"
    #endif
    let bundledRoot: URL
    let importedRoot: URL
    private var imported: [ProjectMPreset] = []
    private var importedIDs = Set<String>()
    private var nativeCount: Int { RenderState.nativeSceneNames.count }
    // Projects without stable identities predate expansion of the native catalog.
    // Their external preset indices always start at 31, regardless of today's count.
    private let legacyNativeCount = NativeEffects.legacyCount
    private var scenesByID: [String: Int] = [:]
    private var legacyIDs: [String] = []
    private(set) var retiredIDs: Set<String> = []
    let iconNames: [String]
    private static let nativeIcons = NativeEffects.all.map(\.icon)

    init(importedRoot: URL? = nil, defaults: UserDefaults = .standard, favoritesBackupDirectory: URL? = nil) {
        self.defaults = defaults
        if let data = defaults.data(forKey: poolKey), data.count < 4096,
           let saved = try? JSONDecoder().decode(VisualizerPool.self, from: data),
           saved.collection.count < 100, saved.category.count < 200 { pool = saved }
        let isolatedQA = Bundle.main.object(forInfoDictionaryKey: "PulseCanvasIsolatedTesting") as? Bool == true
        self.favoritesBackupDirectory = favoritesBackupDirectory ?? (defaults === UserDefaults.standard && !isolatedQA
            ? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("PulseCanvas/Favorites Backups", isDirectory: true) : nil)
        #if STORE_BUILD
        bundledRoot = Bundle.module.resourceURL ?? URL(fileURLWithPath: "/missing-resources")
        self.importedRoot = importedRoot ?? bundledRoot
        iconNames = Self.nativeIcons
        #else
        bundledRoot = [Bundle.module.resourceURL?.appendingPathComponent("Resources/ProjectM"), Bundle.module.resourceURL?.appendingPathComponent("ProjectM"), URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Sources/PulseCanvas/Resources/ProjectM")].compactMap({$0}).first(where: {FileManager.default.fileExists(atPath: $0.appendingPathComponent("catalog.json").path)}) ?? URL(fileURLWithPath: "/missing-projectm")
        iconNames = (try? PresetNaming(root: bundledRoot).icons).flatMap { $0.isEmpty ? nil : $0 } ?? ["sparkles"]
        self.importedRoot = importedRoot ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("PulseCanvas/ProjectM", isDirectory: true)
        entries = (try? JSONDecoder().decode([ProjectMPreset].self, from: Data(contentsOf: bundledRoot.appendingPathComponent("catalog.json")))) ?? []
        imported = (try? JSONDecoder().decode([ProjectMPreset].self, from: Data(contentsOf: self.importedRoot.appendingPathComponent("imports.json")))) ?? []
        importedIDs = Set(imported.map(\.id))
        legacyIDs = (try? JSONDecoder().decode([String].self, from: Data(contentsOf: bundledRoot.appendingPathComponent("legacy-identities.json")))) ?? entries.map(\.id)
        let retired = (try? JSONDecoder().decode([RetiredPreset].self, from: Data(contentsOf: bundledRoot.appendingPathComponent("retired-presets.json")))) ?? []
        retiredIDs = Set(retired.map(\.id))
        entries += imported
        #endif
        var savedFavorites = defaults.stringArray(forKey: favoritesKey)
        #if STORE_BUILD
        savedFavorites = savedFavorites ?? defaults.stringArray(forKey: "PulseCanvas.effectFavorites.v1")
        #endif
        #if LOCAL_BUILD
        // Seed a fresh isolated test build once, without altering the installed app.
        if savedFavorites == nil, defaults === UserDefaults.standard {
            savedFavorites = ["com.protomota.pulsecanvas", "com.protomota.pulsecanvas.direct"].flatMap {
                UserDefaults.standard.persistentDomain(forName: $0)?["PulseCanvas.effectFavorites.v1"] as? [String] ?? []
            }
            defaults.set(savedFavorites, forKey: favoritesKey)
        }
        #endif
        if let data = defaults.data(forKey: favoritesKey + ".appearances"),
           let saved = try? JSONDecoder().decode([String: VisualPreset].self, from: data) {
            favoriteAppearances = saved.filter { $0.value.isValid }
        }
        // An explicitly empty list stays empty; a missing preference can recover
        // from this edition's last successful automatic backup.
        if savedFavorites == nil, let directory = self.favoritesBackupDirectory,
           let data = try? Data(contentsOf: directory.appendingPathComponent("Favorites-\(backupEdition).json")),
           let backup = try? FavoritesBackup.read(data) {
            savedFavorites = backup.favorites.map(\.id)
            for favorite in backup.favorites { if let look = favorite.appearance { favoriteAppearances[favorite.id] = look } }
            defaults.set(savedFavorites, forKey: favoritesKey)
        }
        let savedIDs = Set(savedFavorites ?? [])
        rebuildNames()
        favoriteIDs = savedIDs.intersection(availableFavoriteIDs)
        favoriteAppearances = favoriteAppearances.filter { favoriteIDs.contains($0.key) }
        if favoriteIDs != savedIDs { persistFavorites() }
        else if !favoriteIDs.isEmpty { backUpFavorites() }
    }
    private func rebuildNames() {
        sceneNames = RenderState.nativeSceneNames + entries.map(\.title)
        scenesByID = Dictionary(uniqueKeysWithValues: entries.enumerated().map { ($0.element.id, $0.offset + nativeCount) })
        availableScenes = NativeEffects.libraryOrder + Array(nativeCount..<sceneNames.count)
        categories = categories(in: "")
    }
    private var availableFavoriteIDs: Set<String> { Set(availableScenes.map { identity(for: $0) }) }
    func identity(for scene: Int) -> String {preset(for: scene)?.id ?? "native:\(scene)"}
    func isFavorite(_ scene: Int) -> Bool {favoriteIDs.contains(identity(for: scene))}
    /// Every scene offered in the library, timeline and random choices. Retired native
    /// designs keep their IDs for migration but are never offered.
    private(set) var availableScenes: [Int] = []
    func icon(for scene: Int) -> String {
        if Self.nativeIcons.indices.contains(scene) { return Self.nativeIcons[scene] }
        return preset(for:scene)?.icon ?? iconNames[max(0,scene) % iconNames.count]
    }
    func toggleFavorite(_ scene: Int, appearance: VisualPreset? = nil) {
        guard availableScenes.contains(scene) else { return }
        let id = identity(for: scene)
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id); favoriteAppearances.removeValue(forKey: id)
        } else {
            favoriteIDs.insert(id)
            favoriteAppearances[id] = appearance.flatMap { $0.isValid ? $0 : nil } ?? VisualPreset.defaults(for: scene)
        }
        persistFavorites()
    }

    /// Upgrade ID-only favorites once from the editor's existing saved looks.
    /// Subsequent slider edits never rewrite an already saved favorite.
    func migrateFavoriteAppearances(_ appearance: (Int) -> VisualPreset) {
        var changed = false
        for scene in availableScenes where isFavorite(scene) && favoriteAppearances[identity(for: scene)] == nil {
            let value = appearance(scene)
            if value.isValid { favoriteAppearances[identity(for: scene)] = value; changed = true }
        }
        if changed { persistFavorites() }
    }

    func favoriteAppearance(for scene: Int) -> VisualPreset? {
        guard isFavorite(scene) else { return nil }
        if let saved = favoriteAppearances[identity(for: scene)] { return saved }
        // Legacy favorites without a saved look migrate once, never on each selection.
        let saved = VisualPreset.defaults(for: scene)
        favoriteAppearances[identity(for: scene)] = saved
        persistFavorites()
        return saved
    }

    func appearanceForSelection(_ scene: Int) -> VisualPreset {
        favoriteAppearance(for: scene) ?? .randomized()
    }

    func exportFavorites() throws -> Data {
        try FavoritesBackup(ids: favoriteIDs, appearances: favoriteAppearances) { id in
            if id.hasPrefix("native:"), let scene = Int(id.dropFirst(7)), sceneNames.indices.contains(scene) { return sceneNames[scene] }
            return scenesByID[id].map { sceneNames[$0] }
        }.encoded()
    }

    /// Merge installed favorites. Removed designs must not reappear from a backup
    /// or silently favorite a replacement the listener never selected.
    @discardableResult
    func importFavorites(_ data: Data) throws -> (added: Int, unavailable: Int) {
        let backup = try FavoritesBackup.read(data)
        let restored = Set(backup.favorites.map(\.id))
        let available = availableFavoriteIDs
        let installed = restored.intersection(available)
        let added = installed.subtracting(favoriteIDs).count
        for favorite in backup.favorites where installed.contains(favorite.id) {
            if let look = favorite.appearance { favoriteAppearances[favorite.id] = look }
        }
        favoriteIDs.formUnion(installed)
        persistFavorites()
        return (added, restored.subtracting(available).count)
    }

    private func persistFavorites() {
        if pool.enabled && pool.favoritesOnly { poolRevision &+= 1 }
        favoriteAppearances = favoriteAppearances.filter { favoriteIDs.contains($0.key) }
        defaults.set(favoriteIDs.sorted(), forKey: favoritesKey)
        if let data = try? JSONEncoder().encode(favoriteAppearances) { defaults.set(data, forKey: favoritesKey + ".appearances") }
        backUpFavorites()
    }

    private func backUpFavorites() {
        guard let directory = favoritesBackupDirectory else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try exportFavorites()
            let day = String(ISO8601DateFormatter().string(from: Date()).prefix(10))
            try data.write(to: directory.appendingPathComponent("Favorites-\(backupEdition)-\(day).json"), options: .atomic)
            try data.write(to: directory.appendingPathComponent("Favorites-\(backupEdition).json"), options: .atomic)
            favoritesBackupError = nil
        } catch { favoritesBackupError = "Automatic favorites backup failed: \(error.localizedDescription)" }
    }
    func category(for scene: Int) -> String {
        guard let preset = preset(for: scene) else {return NativeEffects.category(for: scene)}
        return preset.category.hasPrefix("Imported") ? "Imported" : String(preset.category.split(separator: "/").first ?? "ProjectM")
    }
    func collection(for scene: Int) -> String {
        guard let preset = preset(for: scene) else { return "Native Metal" }
        return importedIDs.contains(preset.id) ? "Imported" : "Cream of the Crop"
    }
    var collections: [String] {
        ["Native Metal", "Cream of the Crop", "Imported"].filter { collection in
            availableScenes.contains { self.collection(for: $0) == collection }
        }
    }
    private(set) var categories: [String] = []
    func categories(in collection: String) -> [String] {
        Set(availableScenes.filter { collection.isEmpty || self.collection(for: $0) == collection }
            .map { category(for: $0) }).sorted()
    }
    func folders(in category: String, collection: String = "") -> [String] {
        guard !category.isEmpty else { return [] }
        return Set(availableScenes.filter {
            self.category(for: $0) == category && (collection.isEmpty || self.collection(for: $0) == collection)
        }.compactMap { preset(for: $0)?.category }.filter { $0.contains("/") }).sorted()
    }
    /// The installed catalog remains intact for identities, migration and favorite backups.
    /// This separate pool limits only discovery and new assignments.
    var eligibleScenes: [Int] { scenes(in: pool) }
    func scenes(in pool: VisualizerPool) -> [Int] {
        guard pool.enabled else { return availableScenes }
        return availableScenes.filter {
            (pool.collection.isEmpty || collection(for: $0) == pool.collection)
                && (pool.category.isEmpty || category(for: $0) == pool.category)
                && (!pool.favoritesOnly || isFavorite($0))
        }
    }
    var randomizerGroup: VisualizerRandomizerGroup {
        guard pool.enabled else { return .all }
        if pool.collection.isEmpty {
            if pool.category.isEmpty { return pool.favoritesOnly ? .favorites : .all }
            if !pool.favoritesOnly { return .category(pool.category) }
        }
        return .custom
    }
    func setRandomizerGroup(_ group: VisualizerRandomizerGroup) {
        switch group {
        case .all: setPool(VisualizerPool())
        case .favorites: setPool(VisualizerPool(enabled: true, favoritesOnly: true))
        case .category(let name): setPool(VisualizerPool(enabled: true, category: name))
        case .custom: break
        }
    }
    func setPool(_ value: VisualizerPool) {
        guard value != pool, value.collection.count < 100, value.category.count < 200 else { return }
        pool = value
        poolRevision &+= 1
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: poolKey) }
    }
    var poolSummary: String {
        guard pool.enabled else { return "All visualizers" }
        let labels = [pool.collection, pool.category, pool.favoritesOnly ? "Favorites" : ""].filter { !$0.isEmpty }
        return labels.isEmpty ? "All visualizers" : labels.joined(separator: " · ")
    }
    func filteredScenes(query: String = "", collection: String = "", category: String = "",
                        folder: String = "", favoritesOnly: Bool = false) -> [Int] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return eligibleScenes.filter { scene in
            (!favoritesOnly || isFavorite(scene))
                && (collection.isEmpty || self.collection(for: scene) == collection)
                && (category.isEmpty || self.category(for: scene) == category)
                && (folder.isEmpty || preset(for: scene)?.category == folder)
                && (text.isEmpty || sceneNames[scene].localizedCaseInsensitiveContains(text)
                    || (preset(for: scene)?.originalTitle?.localizedCaseInsensitiveContains(text) ?? false)
                    || (preset(for: scene)?.category.localizedCaseInsensitiveContains(text) ?? false)
                    || self.category(for: scene).localizedCaseInsensitiveContains(text))
        }
    }
    func preset(for scene: Int) -> ProjectMPreset? {
        let index = scene - nativeCount
        return entries.indices.contains(index) ? entries[index] : nil
    }
    func url(for preset: ProjectMPreset) -> URL {
        (importedIDs.contains(preset.id) ? importedRoot : bundledRoot.appendingPathComponent("Presets")).appendingPathComponent(preset.path)
    }
    func texturePaths(for preset: ProjectMPreset) -> [URL] {
        [url(for: preset).deletingLastPathComponent(), importedRoot, bundledRoot.appendingPathComponent("Textures")]
    }
    func scene(for id: String) -> Int? { scenesByID[id] }
    /// Resolve old numeric scenes by their stable identities before applying settings.
    /// Retired effects and retired native designs open a replacement design; unavailable
    /// user imports still report an error.
    func migratedScene(_ scene: Int, identities: [Int: String]?) throws -> Int {
        guard scene >= 0 else { throw ProjectMError("Invalid visualizer index: \(scene).") }
        if let id = identities?[scene], id.hasPrefix("native:") {
            guard let index = Int(id.dropFirst(7)), RenderState.nativeSceneNames.indices.contains(index) else {
                throw ProjectMError("This project requires a native visualizer unavailable in this version: \(id).")
            }
            return NativeEffects.resolved(index)
        }
        if identities?[scene] == nil && scene < legacyNativeCount { return NativeEffects.resolved(scene) }
        #if STORE_BUILD
        throw ProjectMError("This project uses effects available only in the direct-download edition. Open it there to preserve its visualizers.")
        #else
        let index = scene - legacyNativeCount
        let legacy = legacyIDs.indices.contains(index) ? legacyIDs[index] : imported.indices.contains(index - legacyIDs.count) ? imported[index - legacyIDs.count].id : nil
        guard let id = identities == nil ? legacy : identities?[scene] else { throw ProjectMError("Missing identity for preset \(scene)") }
        if let current = scenesByID[id] { return current }
        if retiredIDs.contains(id) { return 22 }
        throw ProjectMError("This project requires a custom visualizer that is not installed: \(id).")
        #endif
    }
    func isRetiredScene(_ scene: Int, identities: [Int: String]?) -> Bool {
        if let id = identities?[scene], id.hasPrefix("native:") { return Int(id.dropFirst(7)).map(NativeEffects.isRetired) ?? false }
        if identities?[scene] == nil && scene < legacyNativeCount { return NativeEffects.isRetired(scene) }
        let index = scene - legacyNativeCount
        let id = identities == nil && legacyIDs.indices.contains(index) ? legacyIDs[index] : identities?[scene]
        return id.map { retiredIDs.contains($0) } ?? false
    }
    func identities(for scenes: Set<Int>) -> [Int: String] {
        Dictionary(uniqueKeysWithValues: scenes.filter { sceneNames.indices.contains($0) }.map { ($0, identity(for: $0)) })
    }
}

private struct RetiredPreset: Decodable { let id: String }

private struct PresetNaming: Decodable {
    let icons: [String]
    init(root: URL) throws {self = try JSONDecoder().decode(Self.self,from:Data(contentsOf:root.appendingPathComponent("naming.json")))}
}


/// Portable stable identities survive renamed effects and catalog reordering.
struct FavoritesBackup: Codable {
    struct Favorite: Codable {
        let id: String
        let name: String?
        var appearance: VisualPreset? = nil
    }
    let format: String
    let version: Int
    let savedAt: Date
    let favorites: [Favorite]

    init(ids: Set<String>, appearances: [String: VisualPreset] = [:], name: (String) -> String?) {
        format = "PulseCanvas Favorites"
        version = 2
        savedAt = Date()
        favorites = ids.sorted().map { Favorite(id: $0, name: name($0), appearance: appearances[$0]) }
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    static func read(_ data: Data) throws -> Self {
        guard data.count <= 10_000_000 else { throw invalid("The favorites backup is too large.") }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(Self.self, from: data)
        guard backup.format == "PulseCanvas Favorites", (1...2).contains(backup.version) else {
            throw invalid("Choose a supported PulseCanvas favorites backup.")
        }
        guard backup.favorites.count <= 100_000, backup.favorites.allSatisfy({
            ($0.appearance?.isValid ?? true) && !$0.id.isEmpty && $0.id.utf8.count <= 4096 && !$0.id.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) })
        }) else { throw invalid("The backup contains invalid favorite identities.") }
        return backup
    }

    private static func invalid(_ message: String) -> NSError {
        NSError(domain: "PulseCanvas.FavoritesBackup", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
