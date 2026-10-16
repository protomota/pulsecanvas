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

@MainActor
final class ProjectMPresets: ObservableObject {
    static let shared = ProjectMPresets()
    @Published private(set) var entries: [ProjectMPreset] = []
    private(set) var sceneNames: [String] = []
    @Published private(set) var favoriteIDs: Set<String> = []
    @Published private(set) var favoritesBackupError: String?
    let favoritesBackupDirectory: URL?
    #if STORE_BUILD
    private let backupEdition = "Mac-App-Store"
    #elseif LOCAL_BUILD
    private let backupEdition = "Creators-Local"
    #else
    private let backupEdition = "Creators"
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
        self.favoritesBackupDirectory = favoritesBackupDirectory ?? (defaults === UserDefaults.standard
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
        // An explicitly empty list stays empty; a missing preference can recover
        // from this edition's last successful automatic backup.
        if savedFavorites == nil, let directory = self.favoritesBackupDirectory,
           let data = try? Data(contentsOf: directory.appendingPathComponent("Favorites-\(backupEdition).json")),
           let backup = try? FavoritesBackup.read(data) {
            savedFavorites = backup.favorites.map(\.id)
            defaults.set(savedFavorites, forKey: favoritesKey)
        }
        let savedIDs = Set(savedFavorites ?? [])
        rebuildNames()
        favoriteIDs = savedIDs.intersection(availableFavoriteIDs)
        if favoriteIDs != savedIDs { persistFavorites() }
        else if !favoriteIDs.isEmpty { backUpFavorites() }
    }
    private func rebuildNames() {
        sceneNames = RenderState.nativeSceneNames + entries.map(\.title)
        scenesByID = Dictionary(uniqueKeysWithValues: entries.enumerated().map { ($0.element.id, $0.offset + nativeCount) })
        availableScenes = NativeEffects.libraryOrder + Array(nativeCount..<sceneNames.count)
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
    func toggleFavorite(_ scene: Int) {
        guard availableScenes.contains(scene) else { return }
        let id = identity(for: scene)
        if favoriteIDs.contains(id) {favoriteIDs.remove(id)} else {favoriteIDs.insert(id)}
        persistFavorites()
    }

    func exportFavorites() throws -> Data {
        try FavoritesBackup(ids: favoriteIDs) { id in
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
        favoriteIDs.formUnion(installed)
        persistFavorites()
        return (added, restored.subtracting(available).count)
    }

    private func persistFavorites() {
        defaults.set(favoriteIDs.sorted(), forKey: favoritesKey)
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
        guard let preset = preset(for: scene) else {return "PulseCanvas"}
        return preset.category.hasPrefix("Imported") ? "Imported" : String(preset.category.split(separator: "/").first ?? "ProjectM")
    }
    var categories: [String] { ["PulseCanvas"] + Set(entries.map { $0.category.hasPrefix("Imported") ? "Imported" : String($0.category.split(separator: "/").first ?? "ProjectM") }).sorted() }
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
    }
    let format: String
    let version: Int
    let savedAt: Date
    let favorites: [Favorite]

    init(ids: Set<String>, name: (String) -> String?) {
        format = "PulseCanvas Favorites"
        version = 1
        savedAt = Date()
        favorites = ids.sorted().map { Favorite(id: $0, name: name($0)) }
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
        guard backup.format == "PulseCanvas Favorites", backup.version == 1 else {
            throw invalid("Choose a supported PulseCanvas favorites backup.")
        }
        guard backup.favorites.count <= 100_000, backup.favorites.allSatisfy({
            !$0.id.isEmpty && $0.id.utf8.count <= 4096 && !$0.id.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) })
        }) else { throw invalid("The backup contains invalid favorite identities.") }
        return backup
    }

    private static func invalid(_ message: String) -> NSError {
        NSError(domain: "PulseCanvas.FavoritesBackup", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
