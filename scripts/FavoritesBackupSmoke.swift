import Foundation

@main struct FavoritesBackupSmoke {
    @MainActor static func main() throws {
        let suite = "PulseCanvas.FavoritesBackupTest." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer {
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: directory)
        }
        #if STORE_BUILD
        let key = "PulseCanvas.metalEffectFavorites.v1"
        #else
        let key = "PulseCanvas.effectFavorites.v1"
        #endif
        let first = NativeEffects.activeIDs[0], second = NativeEffects.activeIDs[1]
        let library = ProjectMPresets(defaults: defaults, favoritesBackupDirectory: directory)
        library.toggleFavorite(first, appearance: VisualPreset(speed: 1.37, palette: 3, strobeEnabled: true, chaos: 0.82))
        let data = try library.exportFavorites()
        let backup = try FavoritesBackup.read(data)
        precondition(backup.favorites.map(\.id) == ["native:\(first)"])
        precondition(backup.favorites.first?.name == NativeEffects.names[first])
        let firstLook = library.favoriteAppearance(for: first)!
        precondition(firstLook.speed == 1.37 && firstLook.palette == 3 && firstLook.strobeEnabled)
        precondition(backup.favorites.first?.appearance == firstLook && backup.version == 2)
        let restoreSuite = suite + ".Restore", restoreDefaults = UserDefaults(suiteName: suite + ".Restore")!
        defer { restoreDefaults.removePersistentDomain(forName: restoreSuite) }
        let imported = ProjectMPresets(defaults: restoreDefaults)
        let importedReport = try imported.importFavorites(data)
        precondition(importedReport.added == 1 && imported.favoriteAppearance(for: first) == firstLook)
        let fresh = ProjectMPresets(defaults: defaults, favoritesBackupDirectory: directory)
        precondition(fresh.appearanceForSelection(first) == firstLook)
        let legacyData = Data(String(decoding: data, as: UTF8.self).replacingOccurrences(of: "\"version\" : 2", with: "\"version\" : 1").utf8)
        let legacy = try FavoritesBackup.read(legacyData)
        precondition(legacy.favorites.first?.id == "native:\(first)")
        library.toggleFavorite(second)
        let merged = try library.importFavorites(data)
        precondition(merged.added == 0 && merged.unavailable == 0)
        precondition(library.isFavorite(first) && library.isFavorite(second), "Import replaced newer favorites")

        // A backup cannot restore removed effects or silently favorite replacements.
        let retired = NativeEffects.all.indices.first(where: NativeEffects.isRetired)!
        let incoming = try FavoritesBackup(ids: ["native:\(second)", "native:\(retired)", "native:99999", "projectm:Future Pack/example.milk"], name: { _ in "Old display name" }).encoded()
        let report = try library.importFavorites(incoming)
        precondition(report.added == 0 && report.unavailable == 3)
        let saved = library.favoriteIDs
        defaults.set(Array(saved) + ["native:\(retired)", "native:99999", "projectm:Removed.milk"], forKey: key)
        let reload = ProjectMPresets(defaults: defaults, favoritesBackupDirectory: directory)
        precondition(reload.favoriteIDs == saved, "Removed favorites survived a relaunch")
        precondition(Set(defaults.stringArray(forKey: key)!) == saved, "Cleanup was not persisted")
        reload.toggleFavorite(-1); reload.toggleFavorite(retired); reload.toggleFavorite(99999)
        precondition(reload.favoriteIDs == saved, "Invalid or retired scenes can be favorited")
        let roundTrip = try FavoritesBackup.read(reload.exportFavorites())
        precondition(Set(roundTrip.favorites.map(\.id)) == saved)
        for invalid in [Data("{}".utf8), Data("not json".utf8), data.replacingVersion()] {
            do { _ = try library.importFavorites(invalid); preconditionFailure("Invalid backup accepted") }
            catch { precondition(library.favoriteIDs == saved, "Failed import changed favorites") }
        }
        defaults.removeObject(forKey: key)
        let recovered = ProjectMPresets(defaults: defaults, favoritesBackupDirectory: directory)
        precondition(recovered.favoriteIDs == saved, "Automatic backup did not recover missing preferences")
        defaults.set([String](), forKey: key)
        let empty = ProjectMPresets(defaults: defaults, favoritesBackupDirectory: directory)
        precondition(empty.favoriteIDs.isEmpty, "Deliberately empty favorites restored unexpectedly")
        precondition(empty.favoritesBackupError == nil)
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        precondition(files.count == 2, "Expected edition latest and daily backups")
        for file in files {
            let snapshot = try FavoritesBackup.read(Data(contentsOf: file))
            precondition(Set(snapshot.favorites.map(\.id)) == saved)
        }
        let blocked = directory.appendingPathComponent("not-a-folder")
        try Data().write(to: blocked)
        let failing = ProjectMPresets(defaults: defaults, favoritesBackupDirectory: blocked)
        failing.toggleFavorite(first)
        precondition(failing.isFavorite(first) && failing.favoritesBackupError != nil, "Backup failure lost favorites or went unreported")
        print("PASS: favorites round-trip, additive restore, removed/retired cleanup, invalid-scene guards, persisted cleanup, automatic recovery, daily snapshots, and failure reporting")
    }
}

private extension Data {
    func replacingVersion() -> Data { Data(String(decoding: self, as: UTF8.self).replacingOccurrences(of: "\"version\" : 2", with: "\"version\" : 99").utf8) }
}
