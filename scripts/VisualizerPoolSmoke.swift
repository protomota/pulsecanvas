import Foundation

@main struct VisualizerPoolSmoke {
    @MainActor static func main() throws {
        let suite = "PulseCanvas.PoolTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let library = ProjectMPresets(defaults: defaults)
        let installed = library.availableScenes
        precondition(!library.pool.enabled && library.eligibleScenes == installed)
        library.toggleFavorite(22); library.toggleFavorite(10)
        library.setPool(VisualizerPool(enabled: true, category: "Tunnels"))
        let tunnels = installed.filter { library.category(for: $0) == "Tunnels" }
        precondition(library.eligibleScenes == tunnels && library.filteredScenes() == tunnels)
        let migrated = try library.migratedScene(10, identities: [10: "native:10"])
        precondition(library.availableScenes == installed && migrated == 10)
        precondition(library.isFavorite(10), "Filtering must never prune installed favorites")
        library.setPool(VisualizerPool(enabled: true, category: "Tunnels", favoritesOnly: true))
        precondition(library.eligibleScenes == [22])
        let revision = library.poolRevision
        library.toggleFavorite(22)
        precondition(library.eligibleScenes == tunnels && library.poolRevision != revision)
        precondition(library.favoritesFallbackMessage != nil)
        precondition(library.availableScenes == installed && library.isFavorite(10))
        let restored = ProjectMPresets(defaults: defaults)
        precondition(restored.pool == library.pool && restored.eligibleScenes == tunnels)
        library.toggleFavorite(18)
        library.setPool(VisualizerPool(enabled: true, favoritesOnly: true))
        precondition(Set(library.eligibleScenes) == [10, 18])
        let store = StudioStore(defaults: defaults, library: library), render = RenderState()
        store.isStudio = true
        store.segments = (0..<12).map { StudioSegment(start: Double($0 * 8), end: Double(($0 + 1) * 8), scene: 22) }
        for _ in 0..<50 {
            precondition(store.randomizeTimeline(render))
            let scenes = store.segments.map(\.scene)
            precondition(Set(scenes) == [10, 18] && zip(scenes, scenes.dropFirst()).allSatisfy { $0 != $1 })
            store.randomizeSegment(at: 0, render: render)
            precondition(library.eligibleScenes.contains(store.segments[0].scene))
        }
        library.toggleFavorite(18)
        precondition(store.randomizeTimeline(render) && store.segments.allSatisfy { $0.scene == 10 })
        library.toggleFavorite(10)
        precondition(library.eligibleScenes == installed && library.favoritesFallbackMessage != nil)
        precondition(store.randomizeTimeline(render) && store.segments.allSatisfy { installed.contains($0.scene) })
        store.isStudio = false; render.scene = 22; store.randomizeScene(render)
        precondition(installed.contains(render.scene), "Empty favorites must fall back to installed visuals")
        library.toggleFavorite(10)
        store.makeTimeline(SongSegmentation(boundaries: [0, 8, 16, 24], bpm: 120), render: render)
        precondition(store.segments.allSatisfy { $0.scene == 10 })
        let radioPlan = SongSegmentation(boundaries: (0...12).map { Double($0 * 8) }, bpm: 120)
        let schedule = RadioVisualSchedule.make(plan: radioPlan, pool: [10, 18], bars: 4,
            favorites: [10, 18], repeatFavorites: true)
        precondition(schedule.count == 12 && Set(schedule.map(\.scene)) == [10, 18])
        var off = library.pool; off.enabled = false; library.setPool(off)
        precondition(library.eligibleScenes == installed && library.isFavorite(10))
        precondition(library.randomizerGroup == .all)
        store.isStudio = false
        library.setRandomizerGroup(.category("Tunnels"))
        precondition(library.eligibleScenes == tunnels && library.filteredScenes() == tunnels)
        for _ in 0..<100 {
            store.randomizeScene(render)
            precondition(library.category(for: render.scene) == "Tunnels")
        }
        library.setRandomizerGroup(.favorites)
        precondition(library.randomizerGroup == .favorites && library.eligibleScenes == [10])
        store.randomizeScene(render)
        precondition(render.scene == 10 && library.filteredScenes() == [10])
        let saved = ProjectMPresets(defaults: defaults)
        precondition(saved.randomizerGroup == .favorites && saved.filteredScenes() == [10])
        library.setRandomizerGroup(.all)
        precondition(library.eligibleScenes == installed && library.filteredScenes() == installed)
        library.setPool(VisualizerPool(enabled: true, category: "Missing category", favoritesOnly: true))
        precondition(library.eligibleScenes.isEmpty && library.favoritesFallbackMessage == nil,
            "Favorites fallback must not escape an unavailable category")
        print("PASS shared dropdown: All default, category filters strip/Library/randomizer, favorites filters everything, persistence, All restores full catalog")
        print("PASS visualizer pool: category/favorites intersection, stable identities, no favorite pruning, persistence, empty favorites fallback, genuine empty categories, scoped Studio generation/randomizers, small-pool repeats and Radio schedule")
    }
}
