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

    init(importedRoot: URL? = nil, defaults: UserDefaults = .standard) {
        self.defaults = defaults
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
        #if STORE_BUILD
        favoriteIDs = Set((defaults.stringArray(forKey: favoritesKey) ?? defaults.stringArray(forKey: "PulseCanvas.effectFavorites.v1") ?? []).filter { $0.hasPrefix("native:") }.map(Self.currentIdentity))
        #else
        favoriteIDs = Set((defaults.stringArray(forKey: favoritesKey) ?? []).map(Self.currentIdentity))
        #endif
        rebuildNames()
    }
    private func rebuildNames() {
        sceneNames = RenderState.nativeSceneNames + entries.map(\.title)
        scenesByID = Dictionary(uniqueKeysWithValues: entries.enumerated().map { ($0.element.id, $0.offset + nativeCount) })
        availableScenes = NativeEffects.activeIDs + Array(nativeCount..<sceneNames.count)
    }
    /// A favorite saved for a retired design follows it to its replacement.
    private static func currentIdentity(_ id: String) -> String {
        guard id.hasPrefix("native:"), let scene = Int(id.dropFirst(7)) else { return id }
        return "native:\(NativeEffects.resolved(scene))"
    }
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
        let id = identity(for: scene)
        if favoriteIDs.contains(id) {favoriteIDs.remove(id)} else {favoriteIDs.insert(id)}
        defaults.set(favoriteIDs.sorted(), forKey: favoritesKey)
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
