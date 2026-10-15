import Foundation

@main struct StoreEditionSmoke {
    @MainActor static func main() throws {
        let suite = "PulseCanvas.StoreEditionTest." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(["native:22", "native:3", "upstream-preset"], forKey: "PulseCanvas.effectFavorites.v1")
        let library = ProjectMPresets(defaults: defaults)
        precondition(library.availableScenes == NativeEffects.activeIDs && library.entries.isEmpty)
        let emptyStore = StudioStore(defaults: defaults), defaultRender = RenderState()
        for scene in NativeEffects.activeIDs {
            defaultRender.scene = scene; emptyStore.apply(to: defaultRender)
            precondition(emptyStore.preset(defaultRender) == VisualPreset.defaults(for: scene))
            precondition(VisualPreset.defaults(for: scene).isValid)
        }
        // Removed and unavailable favorites are pruned rather than mapped to another design.
        precondition(library.isFavorite(22) && !library.isFavorite(NativeEffects.resolved(3)) && !library.isFavorite(3))
        precondition(library.availableScenes.filter(library.isFavorite).count == 1)
        precondition(library.favoriteIDs == ["native:22"], "Removed and unavailable favorites must be pruned")
        library.toggleFavorite(10)
        precondition(Set(defaults.stringArray(forKey: "PulseCanvas.metalEffectFavorites.v1")!) == ["native:22", "native:10"])
        precondition(ProjectMPresets(defaults: defaults).isFavorite(10))
        let native = VisualPreset(speed: 1.7, palette: 3, chaos: 0.3)
        struct Legacy: Encodable { let presets: [Int: VisualPreset]; let identities: [Int: String] }
        let legacy = try JSONEncoder().encode(Legacy(presets: [22: native, 31: native], identities: [22: "native:22", 31: "upstream-preset"]))
        defaults.set(legacy, forKey: "PulseCanvas.studio.v1")
        let store = StudioStore(defaults: defaults)
        precondition(store.presets[22] == native && store.presets[31] == nil)
        let render = RenderState(); render.scene = 22; store.apply(to: render)
        render.chaos = 0.7; store.save(render)
        precondition(defaults.data(forKey: "PulseCanvas.studio.v1") == legacy)
        precondition(StudioStore(defaults: defaults).presets[22]?.chaos == 0.7)
        // The same old external numeric index is now occupied by a native design.
        // Stable identity, not the new catalog boundary, decides how to restore it.
        precondition(RenderState.nativeSceneNames.count > 31)
        var newProject = CreatorProject(scene: 31, appearance: native, aspect: "16:9", resolution: 1080, fps: 30)
        newProject.effectIdentities = library.identities(for: [31])
        let restoredNew = try newProject.remapped(using: library)
        precondition(restoredNew.scene == 31 && restoredNew.appearance == native)
        native.apply(to: render); render.scene = 31; store.save(render)
        precondition(StudioStore(defaults: defaults).presets[31] == native)
        let aliased = try library.migratedScene(999, identities: [999: "native:31"])
        precondition(aliased == 31)
        do { _ = try library.migratedScene(0, identities: [0: "native:999"]); preconditionFailure("Unknown native IDs must fail") } catch is ProjectMError {}
        let project = CreatorProject(scene: 31, appearance: native, aspect: "16:9", resolution: 1080, fps: 30)
        do {
            _ = try project.remapped(using: library)
            preconditionFailure("Full-library project must not silently lose its presets")
        } catch {
            precondition(error.localizedDescription.contains("direct-download"))
        }
        print("PASS Metal edition: \(library.availableScenes.count) effects; expanded native identities survive save/load; old external index 31 stays external; full-library settings untouched")
    }
}
