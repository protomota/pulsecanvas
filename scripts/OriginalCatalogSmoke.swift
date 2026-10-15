import Foundation

/// Retirement must preserve surviving IDs and settings without making removed
/// styles selectable or applying their saved appearance to a different design.
@main struct OriginalCatalogSmoke {
    static func require(_ condition: Bool, _ message: String) throws {
        if !condition { throw NSError(domain: message, code: 1) }
    }
    @MainActor static func main() throws {
        let suite = "PulseCanvas.OriginalCatalogTest." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(["native:0", "native:22", "native:99", "old-external"], forKey: "PulseCanvas.effectFavorites.v1")
        let library = ProjectMPresets(defaults: defaults)
        try require(library.entries.isEmpty, "External presets remain selectable")
        try require(library.availableScenes == NativeEffects.activeScenes, "Library exposes inactive IDs")
        try require(library.availableScenes.count == NativeEffects.all.count - 12, "Wrong retirement count")
        for scene in NativeEffects.retiredScenes {
            try require(!library.availableScenes.contains(scene) && NativeEffects.effect(scene) == nil, "Retired effect is active")
            let migrated = try library.migratedScene(scene, identities: [scene: "native:\(scene)"])
            try require(migrated == NativeEffects.defaultScene, "Retired project scene was not migrated")
        }
        for scene in library.availableScenes {
            let migrated = try library.migratedScene(scene, identities: [scene: "native:\(scene)"])
            try require(migrated == scene, "Surviving native ID changed")
        }
        try require(library.favoriteIDs == ["native:0", "native:22", "native:99", "old-external"], "Stored favorites were discarded")
        var removed = VisualPreset(); removed.chaos = 0.1
        var kept = VisualPreset(); kept.chaos = 0.8
        struct Saved: Encodable { let presets: [Int: VisualPreset]; let identities: [Int: String] }
        let original = try JSONEncoder().encode(Saved(presets: [0: removed, 22: kept, 99: kept], identities: [0: "native:0", 22: "native:22", 99: "native:99"]))
        defaults.set(original, forKey: "PulseCanvas.studio.v1")
        let store = StudioStore(defaults: defaults)
        try require(store.presets[22] == kept && store.presets[99] == kept && store.presets[0] == nil, "Removed style overwrote surviving settings")
        try require(defaults.data(forKey: "PulseCanvas.studio.v1") == original, "Reading altered the original saved session")
        let backupKey = "PulseCanvas.metalStudio.v1.beforeOriginalOnly"
        try require(defaults.data(forKey: backupKey) == original, "Original backup missing")
        defaults.set(try JSONEncoder().encode(Saved(presets: [22: kept], identities: [22: "native:22"])), forKey: "PulseCanvas.metalStudio.v1")
        _ = StudioStore(defaults: defaults)
        try require(defaults.data(forKey: backupKey) == original, "Reload replaced the original migration backup")
        let project = CreatorProject(scene: 0, appearance: removed, aspect: "16:9", resolution: 1080, fps: 30,
            timeline: [StudioSegment(start: 0, end: 4, scene: 0, bars: 2), StudioSegment(start: 4, end: 8, scene: 99, bars: 3)],
            studioEnabled: true, visualPresets: [0: removed, 22: kept, 99: kept], effectIdentities: [0: "native:0", 22: "native:22", 99: "native:99"])
        let restored = try project.remapped(using: library)
        try require(restored.scene == 22 && restored.appearance == kept, "Retired project appearance was assigned to another design")
        try require(restored.timeline?.map(\.scene) == [22, 99] && restored.timeline?.map(\.bars) == [2, 3], "Timeline identities or bar lengths changed")
        let external = try library.migratedScene(31, identities: [31: "old-external"])
        try require(external == NativeEffects.defaultScene, "Old external index became a new native design")
        print("PASS: 12 retirements, \(library.availableScenes.count) surviving IDs, native-only choices, original session/favorite preservation and project/bar migration")
    }
}
