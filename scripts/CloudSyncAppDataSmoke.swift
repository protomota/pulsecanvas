import Foundation

@main @MainActor struct CloudSyncAppDataSmoke {
    static func main() throws {
        let suite = "PulseCanvas.CloudSmoke." + UUID().uuidString
        let source = UserDefaults(suiteName: suite + ".source")!, target = UserDefaults(suiteName: suite + ".target")!
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer {
            source.removePersistentDomain(forName: suite + ".source"); target.removePersistentDomain(forName: suite + ".target")
            try? FileManager.default.removeItem(at: root)
        }
        let a = ProjectMPresets(defaults: source, favoritesBackupDirectory: root.appendingPathComponent("a"))
        let b = ProjectMPresets(defaults: target, favoritesBackupDirectory: root.appendingPathComponent("b"))
        let scene = NativeEffects.activeIDs[0]
        let look = VisualPreset(speed: 1.37, palette: 3, chaos: 0.82)
        precondition(a.favorite(scene, appearance: look))
        #if STORE_BUILD
        let looksKey = "PulseCanvas.metalStudio.v1"
        #else
        let looksKey = "PulseCanvas.studio.v1"
        #endif
        source.set(try CloudSyncLedger.encoded(CloudSyncAppData.SavedLooks(presets:[scene:look])), forKey: looksKey)
        let track = RadioTrack(id:UUID().uuidString,title:"Cloud song",genre:"Electronic",duration:1,audio:"song.mp3",sha256:String(repeating:"a",count:64),byteCount:5000)
        let song = FavoriteRadioSong(track:track,sourceURL:URL(string:"https://radio.pulsecanvas.si/stations.json")!,
            catalogURL:URL(string:"https://radio.pulsecanvas.si/catalog.json")!,stationID:"electronic",folderBookmark:Data([1,2,3]))
        source.set(try CloudSyncLedger.encoded([song]),forKey:"PulseCanvas.radio.favoriteSongs.v1")
        target.set(0.27,forKey:"PulseCanvas.audio.volume")
        let studio = StudioStore(defaults:target,library:b)
        let radio = RadioController(defaults:target,presets:b)
        var ledger = CloudSyncLedger()
        let snapshot = try CloudSyncAppData.snapshot(defaults:source,library:a)
        try ledger.observe(snapshot.values,scope:snapshot.scope)
        try CloudSyncAppData.apply(ledger.current,defaults:target,library:b)
        studio.reloadCloudPresets(); radio.reloadCloudFavorites()
        precondition(b.isFavorite(scene) && b.favoriteAppearance(for:scene) == look)
        precondition(studio.presets[scene] == look && radio.favoriteSongs.first?.id == track.id)
        precondition(radio.favoriteSongs.first?.folderBookmark == nil)
        precondition(target.double(forKey:"PulseCanvas.audio.volume") == 0.27)
        let rest = try CloudSyncAppData.snapshot(defaults:target,library:b)
        precondition(snapshot.values == rest.values, "Saved appearance and song metadata converge across real app models")
        a.toggleFavorite(scene)
        source.set(try CloudSyncLedger.encoded([FavoriteRadioSong]()),forKey:"PulseCanvas.radio.favoriteSongs.v1")
        source.set(try CloudSyncLedger.encoded(CloudSyncAppData.SavedLooks(presets:[:])),forKey:looksKey)
        let removed = try CloudSyncAppData.snapshot(defaults:source,library:a)
        var scope = removed.scope
        scope.insert("songFavorite:" + track.id)
        try ledger.observe(removed.values,scope:scope)
        try CloudSyncAppData.apply(ledger.current,defaults:target,library:b)
        studio.reloadCloudPresets(); radio.reloadCloudFavorites()
        precondition(!b.isFavorite(scene) && radio.favoriteSongs.isEmpty && studio.presets[scene] == nil)
        var invalid = CloudSyncChange(device:UUID().uuidString,sequence:1,kind:.look,key:"native:\(scene)",deleted:false,payload:Data("{}".utf8))
        let original = target.data(forKey:looksKey)
        do { try CloudSyncAppData.apply([invalid],defaults:target,library:b); preconditionFailure("Invalid look accepted") } catch {}
        precondition(target.data(forKey:looksKey) == original)
        invalid.kind = .visualFavorite
        invalid.key = "native:99999"
        invalid.payload = try CloudSyncLedger.encoded(FavoritesBackup.Favorite(id:invalid.key,name:"Unavailable",appearance:look))
        try CloudSyncAppData.apply([invalid],defaults:target,library:b)
        precondition(!b.isFavorite(99999))
        let files = root.appendingPathComponent("coordinated")
        try FileManager.default.createDirectory(at:files,withIntermediateDirectories:true)
        let event = files.appendingPathComponent("event.json")
        let bytes = Data("coordinated event".utf8)
        try CloudSyncService.writeImmutable(bytes,to:event)
        try CloudSyncService.writeImmutable(bytes,to:event)
        let read = try CloudSyncService.coordinatedRead(event)
        let downloaded = try CloudSyncService.downloaded(event)
        precondition(read == bytes && downloaded)
        do { try CloudSyncService.writeImmutable(Data([0]),to:event); preconditionFailure("Immutable event overwritten") } catch {}
        let afterCollision = try CloudSyncService.coordinatedRead(event)
        precondition(afterCollision == bytes)
        let copied = files.appendingPathComponent(CloudSyncLedger.digest(bytes) + ".audio")
        try CloudSyncService.copyImmutable(event,to:copied)
        try CloudSyncService.copyImmutable(event,to:copied)
        let copiedBytes = try Data(contentsOf:copied)
        precondition(copiedBytes == bytes)
        let history = root.appendingPathComponent("CloudSync/state.json")
        try FileManager.default.createDirectory(at:history.deletingLastPathComponent(),withIntermediateDirectories:true)
        try Data("bad history".utf8).write(to:history)
        target.set(true,forKey:CloudSyncService.enabledKey)
        let recovery = CloudSyncService(defaults:target,support:root)
        precondition(!recovery.enabled && !target.bool(forKey:CloudSyncService.enabledKey))
        recovery.setEnabled(true)
        let preserved = try Data(contentsOf:history)
        precondition(!recovery.enabled && preserved == Data("bad history".utf8))
        print("PASS: coordinated immutable transport, idempotent copy, collision rejection and fail-closed corrupt sync history")
        print("PASS: real favorites, saved-look and Radio models sync, reload, delete and reject malformed payloads; device-only volume unchanged")
    }
}
