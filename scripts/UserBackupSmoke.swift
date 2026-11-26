import Foundation
import ZIPFoundation

@main struct UserBackupSmoke {
    static func require(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
        if try !condition() { throw UserBackup.fail(message) }
    }
    static func main() throws {
        let fm = FileManager.default
        let root = URL(fileURLWithPath: "/Volumes/Expand/Codex Media/PulseCanvas Studio/Development/user-backup-20261110/tmp", isDirectory: true)
            .appendingPathComponent("PulseCanvasBackupSmoke-\(UUID().uuidString)")
        defer { try? fm.removeItem(at: root) }
        let sourceSuite = "PulseCanvas.Backup.Source.\(UUID().uuidString)"
        let targetSuite = "PulseCanvas.Backup.Target.\(UUID().uuidString)"
        let source = UserDefaults(suiteName: sourceSuite)!, target = UserDefaults(suiteName: targetSuite)!
        defer { source.removePersistentDomain(forName: sourceSuite); target.removePersistentDomain(forName: targetSuite) }
        func storage(_ name: String, domain: String) -> UserBackup.Storage {
            let base = root.appendingPathComponent(name)
            return .init(documents: base.appendingPathComponent("Documents"), support: base.appendingPathComponent("Support"),
                         backups: base.appendingPathComponent("Backups"), domain: domain)
        }
        let input = storage("input", domain: sourceSuite), output = storage("output", domain: targetSuite)
        let firstRun = try UserBackup.collect(currentProject: nil, platform: "macOS", defaults: source, storage: output)
        try require(firstRun.files.isEmpty, "First-run empty backup failed")
        try fm.createDirectory(at: input.documents, withIntermediateDirectories: true)
        try fm.createDirectory(at: input.support.appendingPathComponent("PersonalRadio/album"), withIntermediateDirectories: true)
        let audioURL = root.appendingPathComponent("original.wav")
        // Real one-second 16-bit mono PCM WAV, with a changing waveform.
        var audio = Data("RIFF".utf8)
        func little<T: FixedWidthInteger>(_ value: T) { var v = value.littleEndian; withUnsafeBytes(of: &v) { audio.append(contentsOf: $0) } }
        little(UInt32(88_236)); audio.append(Data("WAVEfmt ".utf8)); little(UInt32(16)); little(UInt16(1)); little(UInt16(1))
        little(UInt32(44_100)); little(UInt32(88_200)); little(UInt16(2)); little(UInt16(16)); audio.append(Data("data".utf8)); little(UInt32(88_200))
        for i in 0..<44_100 { little(Int16(sin(Double(i) * 2 * .pi * 220 / 44_100) * 4_000)) }
        try audio.write(to: audioURL)
        let look: [String: Any] = ["speed": 1.7, "chaos": 0.82, "palette": 3, "zoom": 1.2, "brightness": 1.2,
            "particleSize": 1.0, "fog": 0.5, "rotation": 0.0, "motionBlur": 0.0, "strobeEnabled": false,
            "strobeSensitivity": 1.0, "strobeStrength": 1.0, "liquidDetail": 0.6, "zoomSpeed": 1.5, "haloCount": 6]
        let project: [String: Any] = ["version": 1, "scene": 22, "soundtrack": audioURL.absoluteString, "soundtrackBookmark": Data("authorization-must-not-travel".utf8).base64EncodedString(),
            "appearance": look, "aspect": "16:9 · Wide", "resolution": 1080, "fps": 60,
            "timeline": [["start": 0, "end": 1, "scene": 22, "bars": 1]], "effectIdentities": ["22": "native:22"], "loopPlayback": true]
        let projectData = try JSONSerialization.data(withJSONObject: project)
        try projectData.write(to: input.documents.appendingPathComponent("Studio-autosave.pulsecanvas"))
        let catalogURL = input.support.appendingPathComponent("PersonalRadio/album/catalog.json")
        let catalog = Data("{\"version\":1,\"title\":\"My album\",\"tracks\":[]}".utf8)
        try catalog.write(to: catalogURL)
        try audio.write(to: catalogURL.deletingLastPathComponent().appendingPathComponent("song.wav"))
        source.set(["native:22", "native:12"], forKey: "PulseCanvas.metalEffectFavorites.v1")
        source.set(try JSONSerialization.data(withJSONObject: ["native:22": look]), forKey: "PulseCanvas.metalEffectFavorites.v1.appearances")
        let song = ["track": ["id": UUID().uuidString, "title": "Saved radio song", "genre": "Electronic", "duration": 1.0,
                              "audio": "song.wav", "sha256": UserBackup.hash(audio), "byteCount": audio.count],
                    "sourceURL": "https://radio.pulsecanvas.si/stations.json", "catalogURL": "https://radio.pulsecanvas.si/catalog.json",
                    "stationID": "electronic", "folderBookmark": Data("authorization-must-not-travel".utf8).base64EncodedString()] as [String: Any]
        source.set(try JSONSerialization.data(withJSONObject: [song]), forKey: "PulseCanvas.radio.favoriteSongs.v1")
        source.set(try JSONSerialization.data(withJSONObject: ["presets": ["22": look], "identities": ["22": "native:22"]]), forKey: "PulseCanvas.metalStudio.v1")
        source.set(try JSONSerialization.data(withJSONObject: ["enabled": true, "collection": "native", "category": "Tunnels", "favoritesOnly": false]), forKey: "PulseCanvas.metalVisualizerPool.v1")
        source.set(try JSONSerialization.data(withJSONObject: ["aspect": "16:9 · Wide", "resolution": 1080, "fps": 60]), forKey: "PulseCanvas.videoFormat.v1")
        source.set("electronic", forKey: "PulseCanvas.radio.station")
        source.set(true, forKey: "PulseCanvas.radio.favoriteSongsOnly.v1")
        source.set(["feedback"], forKey: "PulseCanvas.engagement.clickedActions.v1")
        source.set(true, forKey: "PulseCanvas.onboarding.completed.v1")
        source.set(catalogURL, forKey: "PulseCanvas.radio.personalCatalog.v1")
        source.set(true, forKey: "PulseCanvas.radio.personalActive.v1")
        source.set(0.42, forKey: "PulseCanvas.radio.volume")
        source.set("DO-NOT-EXPORT", forKey: "APIKey")
        source.set(true, forKey: "nativeTips.hasSupportedDevelopment.v1")
        let data = try UserBackup.export(currentProject: projectData, platform: "macOS", defaults: source, storage: input)
        let jsonArchive = try UserBackup.decode(data)
        let zipURL = root.appendingPathComponent("backup.zip")
        try UserBackup.writeZIP(jsonArchive, to: zipURL)
        let archive = try UserBackup.readZIP(zipURL, workspace: root.appendingPathComponent("Unpacked"))
        try require(archive.files.map(\.sha256) == jsonArchive.files.map(\.sha256), "ZIP lost files or metadata")
        let preferences = try UserBackup.preferenceValues(archive)
        try require(preferences["APIKey"] == nil && preferences["nativeTips.hasSupportedDevelopment.v1"] == nil, "Export leaked private settings")
        try require(archive.files.count == 5, "Incomplete file collection: \(archive.files.map(\.path))")
        try require(!String(decoding: data, as: UTF8.self).contains("DO-NOT-EXPORT"), "Credential leaked")
        let exportedProject = try JSONSerialization.jsonObject(with: archive.files.first { $0.path.hasSuffix("Backup-current.pulsecanvas") }!.data) as! [String: Any]
        try require(exportedProject["soundtrackBookmark"] == nil, "Project authorization bookmark leaked")
        // Destroy only this test's source workspace. Restore must stand on its own.
        try fm.removeItem(at: root.appendingPathComponent("input")); try fm.removeItem(at: audioURL)
        target.set("KEEP-LOCAL-SECRET", forKey: "APIKey")
        target.set(["old"], forKey: "PulseCanvas.metalEffectFavorites.v1")
        let before = target.persistentDomain(forName: targetSuite)! as NSDictionary
        try require(try UserBackup.stageRestore(archive, defaults: target, storage: output), "Restore wasn't staged")
        try require(before == target.persistentDomain(forName: targetSuite)! as NSDictionary, "Staging changed live preferences")
        try UserBackup.activatePendingRestore(defaults: target, storage: output)
        try require(target.stringArray(forKey: "PulseCanvas.metalEffectFavorites.v1") == ["native:22", "native:12"], "Favorites were lost or duplicated")
        try require(target.double(forKey: "PulseCanvas.radio.volume") == 0.42, "Preference changed")
        try require(target.string(forKey: "APIKey") == "KEEP-LOCAL-SECRET", "Restore changed a credential")
        for (key, expected) in preferences where key != "PulseCanvas.radio.personalCatalog.v1" {
            guard let actual = target.object(forKey: key) else { throw UserBackup.fail("Restored preference missing: \(key)") }
            try require(NSDictionary(dictionary: ["value": actual]).isEqual(to: ["value": expected]), "Restored favorite/settings metadata changed: \(key)")
        }
        let restoredRoot = output.root("Documents", defaults: target)
        let restored = try JSONSerialization.jsonObject(with: Data(contentsOf: restoredRoot.appendingPathComponent("Backup-current.pulsecanvas"))) as! [String: Any]
        let restoredAudio = URL(string: restored["soundtrack"] as! String)!
        try require(restoredAudio.lastPathComponent == audioURL.lastPathComponent, "Restore changed the soundtrack filename/title")
        try require(try Data(contentsOf: restoredAudio) == audio, "Restored soundtrack missing or changed")
        try require(restored["appearance"] as! NSDictionary == look as NSDictionary, "Look settings changed")
        try require(restored["effectIdentities"] as! [String: String] == ["22": "native:22"], "Effect identity mapping changed")
        let restoredCatalog = target.url(forKey: "PulseCanvas.radio.personalCatalog.v1")!
        try require(try Data(contentsOf: restoredCatalog) == catalog, "Personal playlist relationship broken")
        try require(try Data(contentsOf: restoredCatalog.deletingLastPathComponent().appendingPathComponent("song.wav")) == audio, "Personal music wasn't restored")
        try require(!(try UserBackup.stageRestore(archive, defaults: target, storage: output)), "Same backup duplicated")
        let again = try UserBackup.export(currentProject: nil, platform: "macOS", defaults: target, storage: output)
        try UserBackup.validate(UserBackup.decode(again))
        let domainBeforeBad = target.persistentDomain(forName: targetSuite)! as NSDictionary
        func rejects(_ changed: UserBackup.Archive, _ name: String) throws {
            do { _ = try UserBackup.stageRestore(changed, defaults: target, storage: output); throw UserBackup.fail("Accepted malformed backup: \(name)") }
            catch let error as UserBackup.Failure where error.message.hasPrefix("Accepted") { throw error }
            catch { }
            try require(domainBeforeBad == target.persistentDomain(forName: targetSuite)! as NSDictionary, "Bad restore modified preferences")
        }
        var bad = archive; bad.version = 999; try rejects(bad, "version")
        bad = archive; bad.files[0].data.append(0); try rejects(bad, "checksum")
        bad = archive; bad.files[0].path = "Documents/../../escape"; try rejects(bad, "traversal")
        bad = archive; bad.files.append(bad.files[0]); try rejects(bad, "duplicate")
        bad = archive; bad.files.removeAll { $0.originalURL == audioURL.absoluteString }; try rejects(bad, "missing soundtrack")
        bad = archive; bad.preferences = try PropertyListSerialization.data(fromPropertyList: ["APIKey": "bad"], format: .binary, options: 0); try rejects(bad, "unknown preference")
        bad = archive; bad.preferences = try PropertyListSerialization.data(fromPropertyList: ["PulseCanvas.radio.volume": "invalid"], format: .binary, options: 0); try rejects(bad, "preference type")
        let invalidZip = root.appendingPathComponent("invalid.zip")
        let zip = try ZIPFoundation.Archive(url: invalidZip, accessMode: .create)
        try zip.addEntry(with: "../escape", type: .file, uncompressedSize: Int64(1)) { _, _ in Data([0]) }
        do {
            _ = try UserBackup.readZIP(invalidZip, workspace: root.appendingPathComponent("BadUnpack"))
            throw UserBackup.fail("Accepted ZIP traversal")
        } catch let error as UserBackup.Failure where error.message == "Accepted ZIP traversal" { throw error }
        catch { }
        do { _ = try UserBackup.decode(Data("broken".utf8)); throw UserBackup.fail("Accepted malformed JSON") }
        catch is DecodingError { }
        let damagedURL = root.appendingPathComponent("damaged.zip")
        var damaged = try Data(contentsOf: zipURL)
        let position = damaged.range(of: archive.files[0].data.prefix(16))!.lowerBound + 3
        damaged[position] ^= 1
        try damaged.write(to: damagedURL)
        do {
            _ = try UserBackup.readZIP(damagedURL, workspace: root.appendingPathComponent("DamagedUnpack"))
            throw UserBackup.fail("Accepted damaged ZIP")
        } catch let error as UserBackup.Failure where error.message == "Accepted damaged ZIP" { throw error }
        catch { }
        // Exercise a real ZIP above the previous JSON payload ceiling without a
        // huge base64 allocation. The file is generated and removed on Expand.
        let largeURL = restoredRoot.appendingPathComponent("large.wav")
        fm.createFile(atPath: largeURL.path, contents: audio.prefix(44))
        let large = try FileHandle(forWritingTo: largeURL)
        try large.seekToEnd()
        let block = Data(repeating: 0, count: 1_048_576)
        for _ in 0..<300 { try large.write(contentsOf: block) }
        try large.close()
        let largeArchive = try UserBackup.collect(currentProject: nil, platform: "macOS", defaults: target, storage: output)
        let largeZIP = root.appendingPathComponent("large.zip")
        try UserBackup.writeZIP(largeArchive, to: largeZIP)
        let largeRestored = try UserBackup.readZIP(largeZIP, workspace: root.appendingPathComponent("LargeUnpack"))
        let largeFile = largeRestored.files.first { $0.path == "Documents/large.wav" }!
        try require(largeFile.data.count == 300 * 1_048_576 + 44 && largeFile.sha256 == UserBackup.hash(try Data(contentsOf: largeURL, options: .alwaysMapped)), "Large ZIP round trip changed bytes")
        print("PASS: JSON + ZIP export → clean workspace → restore; favorites, looks, timeline, identities, personal playlist/audio and preferences; original source removed; re-export; duplicate import; secret/bookmark exclusions; invalid-archive checks; malformed JSON, ZIP traversal and damaged ZIP CRC; live data unchanged before activation; 300 MiB ZIP round trip.")
    }
}
