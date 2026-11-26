import Foundation

/// Direct-download edition: numeric scene indices saved before the native catalog grew
/// must keep pointing at the same external presets, never at newly added native designs.
@main struct NativeMigrationSmoke {
    struct Stored: Codable { var presets: [Int: VisualPreset]; var identities: [Int: String]? }

    @MainActor static func main() throws {
        let suite = "PulseCanvas.NativeMigration." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let library = ProjectMPresets(defaults: defaults)
        let nativeCount = RenderState.nativeSceneNames.count
        precondition(nativeCount == NativeEffects.all.count, "Unexpected native catalog size \(nativeCount)")
        let legacy = try JSONDecoder().decode([String].self, from: Data(contentsOf: library.bundledRoot.appendingPathComponent("legacy-identities.json")))

        // 1. Every pre-expansion external index, with or without saved identities.
        var resolved = 0, retired = 0
        for (offset, id) in legacy.enumerated() {
            let old = NativeEffects.legacyCount + offset
            if library.retiredIDs.contains(id) {
                let fallback = try library.migratedScene(old, identities: nil)
                precondition(fallback == 22)
                retired += 1; continue
            }
            for identities in [nil, [old: id]] as [[Int: String]?] {
                let scene = try library.migratedScene(old, identities: identities)
                precondition(scene >= nativeCount, "Old external index \(old) became native scene \(scene)")
                precondition(library.identity(for: scene) == id, "Old external index \(old) lost its identity")
            }
            resolved += 1
        }
        // 2. Old indices that now overlap the new native range are external, explicitly.
        for old in NativeEffects.legacyCount..<nativeCount where !library.retiredIDs.contains(legacy[old - NativeEffects.legacyCount]) {
            let scene = try library.migratedScene(old, identities: nil)
            precondition(scene >= nativeCount)
        }
        // 3. A saved identity map without an entry for an external index is an error, never native.
        do { _ = try library.migratedScene(40, identities: [5: "native:5"]); preconditionFailure("Missing identity must not fall back to native") } catch is ProjectMError {}
        // 4. Released native IDs stay put, retired ones open their replacement; native identities round-trip.
        for scene in 0..<NativeEffects.legacyCount { let kept = try library.migratedScene(scene, identities: nil); precondition(kept == NativeEffects.resolved(scene)) }
        let ids = library.identities(for: Set(0..<nativeCount))
        for scene in 0..<nativeCount {
            precondition(ids[scene] == "native:\(scene)")
            let direct = try library.migratedScene(scene, identities: ids)
            let aliased = try library.migratedScene(scene + 5000, identities: [scene + 5000: "native:\(scene)"])
            precondition(direct == NativeEffects.resolved(scene) && aliased == direct)
        }
        print("PASS identities: \(resolved) legacy external presets keep their identity at index ≥ \(nativeCount), \(retired) retired fall back, natives 0–\(nativeCount - 1) round-trip")

        // 4b. Retired designs: IDs reserved, never offered, always resolved to an active design.
        let retiredNative = NativeEffects.all.indices.filter(NativeEffects.isRetired)
        let receipt = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: "docs/metal-keeper-selection.json"))) as! [String: Any]
        let selected = Set(receipt["keepers"] as! [Int])
        // The review covered the first `reservedIDs` slots; designs appended after it are new and offered.
        let reviewed = receipt["reservedIDs"] as! Int
        precondition(Set(NativeEffects.activeIDs.filter { $0 < reviewed }) == selected, "Offered effects must match the approved red-label selection")
        precondition(Set(retiredNative) == Set(0..<reviewed).subtracting(selected), "All unselected IDs must be reserved and withdrawn")
        precondition(NativeEffects.activeIDs.filter { $0 >= reviewed } == Array(reviewed..<nativeCount), "Designs added after the review must be offered")
        precondition(retiredNative.allSatisfy { !NativeEffects.isRetired(NativeEffects.resolved($0)) })
        precondition(Set(library.availableScenes).isDisjoint(with: retiredNative) && library.availableScenes.count == library.sceneNames.count - retiredNative.count)
        precondition(Set(NativeEffects.timelineOrder).isDisjoint(with: retiredNative))
        let render = RenderState()
        precondition(!NativeEffects.isRetired(render.scene), "A new session must open an active design")
        for scene in retiredNative { render.scene = scene; precondition(render.scene == NativeEffects.resolved(scene)) }
        print("PASS retired: \(retiredNative.count) withdrawn designs are hidden and resolve to replacements in projects and live state")

        // 5. Saved Studio styles from the 31-effect release.
        var a = VisualPreset(); a.chaos = 0.11
        var b = VisualPreset(); b.chaos = 0.22
        var c = VisualPreset(); c.chaos = 0.33
        let firstActive = legacy.firstIndex { !library.retiredIDs.contains($0) }!
        let laterActive = legacy.indices.dropFirst(40).first { !library.retiredIDs.contains(legacy[$0]) }!
        let oldFirst = NativeEffects.legacyCount + firstActive, oldLater = NativeEffects.legacyCount + laterActive
        precondition(oldLater < nativeCount, "Pick an old external index inside the new native range")
        defaults.set(try JSONEncoder().encode(Stored(presets: [12: a, 5: c, oldFirst: b, oldLater: c], identities: nil)), forKey: "PulseCanvas.studio.v1")
        let store = StudioStore(defaults: defaults)
        precondition(store.presets[12] == a)
        precondition(store.presets[5] == nil && store.presets[NativeEffects.resolved(5)] == nil, "A retired design's style must not attach to its replacement")
        precondition(store.presets[library.scene(for: legacy[firstActive])!] == b)
        precondition(store.presets[library.scene(for: legacy[laterActive])!] == c)
        precondition(store.presets[oldFirst] == nil && store.presets[oldLater] == nil, "Old external styles must not attach to new native designs")
        print("PASS saved styles: release-era styles at \(oldFirst) and \(oldLater) moved to their presets; native styles untouched")

        // 6. A release-era project with a timeline across the overlapping range.
        let timeline = [StudioSegment(start: 0, end: 4, scene: 3), StudioSegment(start: 4, end: 8, scene: oldFirst), StudioSegment(start: 8, end: 12, scene: oldLater)]
        let project = CreatorProject(scene: oldLater, appearance: c, aspect: "16:9", resolution: 1080, fps: 30, timeline: timeline,
                                     studioEnabled: true, visualPresets: [3: a, oldFirst: b, oldLater: c], effectIdentities: nil)
        let remapped = try project.remapped(using: library)
        precondition(remapped.scene == library.scene(for: legacy[laterActive])!)
        precondition(remapped.timeline!.map(\.scene) == [NativeEffects.resolved(3), library.scene(for: legacy[firstActive])!, library.scene(for: legacy[laterActive])!])
        precondition(remapped.visualPresets?[3] == nil && remapped.visualPresets?[NativeEffects.resolved(3)] == nil)
        precondition(remapped.timeline!.allSatisfy { $0.scene < NativeEffects.legacyCount || $0.scene >= nativeCount })
        let saved = try JSONDecoder().decode(CreatorProject.self, from: JSONEncoder().encode(remapped))
        let reopened = try saved.remapped(using: library)
        precondition(reopened.timeline!.map(\.scene) == remapped.timeline!.map(\.scene))
        print("PASS project: release-era timeline keeps ProjectM sections external and round-trips with stable identities")

        // 7. Favorites are stored by identity and survive catalog growth.
        defaults.set(["native:12", "native:5", "native:31", legacy[firstActive]], forKey: "PulseCanvas.effectFavorites.v1")
        let favorites = ProjectMPresets(defaults: defaults)
        precondition(favorites.isFavorite(12) && favorites.isFavorite(31) && favorites.isFavorite(favorites.scene(for: legacy[firstActive])!))
        precondition(favorites.favoriteIDs == Set(["native:12", "native:31", legacy[firstActive]]), "A retired favorite must be removed rather than replaced")
        precondition(!favorites.isFavorite(oldFirst), "An old external index must not inherit a favorite")
        print("PASS favorites: native and external favorites keep their identities")
    }
}
