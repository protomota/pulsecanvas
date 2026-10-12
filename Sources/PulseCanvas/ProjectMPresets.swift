import Foundation
import Combine

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
    private let favoritesKey = "PulseCanvas.effectFavorites.v1"
    let bundledRoot: URL
    let importedRoot: URL
    private var imported: [ProjectMPreset] = []
    private var importedIDs = Set<String>()
    private let nativeCount = 31
    private var scenesByID: [String: Int] = [:]
    private var legacyIDs: [String] = []
    private(set) var retiredIDs: Set<String> = []
    let iconNames: [String]
    private static let nativeIcons = ["pyramid", "sun.haze", "circle.circle", "torus", "circle.grid.hex", "diamond", "circle.square", "waveform.path", "square.stack.3d.up", "hurricane", "sun.horizon", "rosette", "circle.hexagongrid", "wind", "point.3.connected.trianglepath.dotted", "asterisk", "atom", "wave.3.right", "infinity", "burst", "square.grid.3x3", "snowflake", "circle.hexagonpath", "drop", "bolt.horizontal", "tornado", "rainbow", "cube", "circle.dotted.circle", "water.waves", "squareshape.dashed.squareshape"]

    init(importedRoot: URL? = nil, defaults: UserDefaults = .standard) {
        self.defaults = defaults
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
        favoriteIDs = Set(defaults.stringArray(forKey: favoritesKey) ?? [])
        rebuildNames()
    }
    private func rebuildNames() {
        sceneNames = RenderState.nativeSceneNames + entries.map(\.title)
        scenesByID = Dictionary(uniqueKeysWithValues: entries.enumerated().map { ($0.element.id, $0.offset + nativeCount) })
    }
    func identity(for scene: Int) -> String {preset(for: scene)?.id ?? "native:\(scene)"}
    func isFavorite(_ scene: Int) -> Bool {favoriteIDs.contains(identity(for: scene))}
    var availableScenes: [Int] {Array(sceneNames.indices)}
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
    /// Retired effects use a native design; unavailable user imports still report an error.
    func migratedScene(_ scene: Int, identities: [Int: String]?) throws -> Int {
        guard scene >= nativeCount else { return scene }
        let index = scene - nativeCount
        let legacy = legacyIDs.indices.contains(index) ? legacyIDs[index] : imported.indices.contains(index - legacyIDs.count) ? imported[index - legacyIDs.count].id : nil
        guard let id = identities == nil ? legacy : identities?[scene] else { throw ProjectMError("Missing identity for preset \(scene)") }
        if let current = scenesByID[id] { return current }
        if retiredIDs.contains(id) { return 22 }
        throw ProjectMError("This project requires a custom visualizer that is not installed: \(id).")
    }
    func isRetiredScene(_ scene: Int, identities: [Int: String]?) -> Bool {
        let index = scene - nativeCount
        let id = identities == nil && legacyIDs.indices.contains(index) ? legacyIDs[index] : identities?[scene]
        return id.map { retiredIDs.contains($0) } ?? false
    }
    func identities(for scenes: Set<Int>) -> [Int: String] {
        Dictionary(uniqueKeysWithValues: scenes.compactMap { scene in preset(for: scene).map {(scene, $0.id)} })
    }
}

private struct RetiredPreset: Decodable { let id: String }

private struct PresetNaming: Decodable {
    let icons: [String]
    init(root: URL) throws {self = try JSONDecoder().decode(Self.self,from:Data(contentsOf:root.appendingPathComponent("naming.json")))}
}
