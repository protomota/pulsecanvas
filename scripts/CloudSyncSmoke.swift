import Foundation

@main @MainActor struct CloudSyncSmoke {
    static var checks = 0
    static func require(_ value: @autoclosure () throws -> Bool, _ label: String) throws {
        guard try value() else { throw UserBackup.fail(label) }
        checks += 1
    }
    static func rejects(_ label: String, _ operation: () throws -> Void) throws {
        do { try operation() } catch { checks += 1; return }
        throw UserBackup.fail("Expected rejection: " + label)
    }
    static func main() throws {
        let favorite = Data("favorite look".utf8)
        var a = CloudSyncLedger(), b = CloudSyncLedger()
        let first = try a.edit(.visualFavorite, key: "native:22", payload: favorite)!
        let second = try b.edit(.visualFavorite, key: "native:12", payload: favorite)!
        try a.merge([second]); try b.merge([first])
        try require(Set(a.current) == Set(b.current), "Independent favorites converge")
        let deletion = try b.edit(.visualFavorite, key: "native:22", payload: nil)!
        try a.merge([deletion]); try a.merge([first])
        try require(a.current.first { $0.key == "native:22" }?.deleted == true, "Stale events cannot resurrect a deleted favorite")
        let unchanged = try CloudSyncLedger.encoded(a)
        try a.merge([])
        try require(try CloudSyncLedger.encoded(a) == unchanged, "An incomplete download is not an empty library")
        var scoped = CloudSyncLedger()
        try scoped.observe(["visualFavorite:projectm:one": favorite], scope: ["visualFavorite:projectm:one"])
        try scoped.observe([:], scope: ["visualFavorite:native:22"])
        try require(scoped.current.first?.deleted == false, "Unsupported edition preserves another edition's favorite")
        var local = CloudSyncLedger()
        try local.observe(["look:native:22":favorite], scope: ["look:native:22"])
        try local.observe([:], scope: ["look:native:22"])
        try require(local.current.first?.deleted == true, "Explicit local removal creates a tombstone")
        let restarted = try CloudSyncLedger.read(CloudSyncLedger.encoded(local))
        try require(restarted.pending == local.pending && restarted.heads == local.heads, "Offline queue survives restart")

        var left = CloudSyncLedger(), right = CloudSyncLedger()
        let original = try left.edit(.project, key: "shared", payload: Data("original".utf8))!
        try right.merge([original])
        let l = try left.edit(.project, key: "shared", payload: Data("left".utf8))!
        let r = try right.edit(.project, key: "shared", payload: Data("right".utf8))!
        try left.merge([r]); try right.merge([l])
        try require(Set(left.current) == Set(right.current), "Concurrent projects converge")
        try require(left.current.count == 2 && Set(left.current.map(\.payload)) == Set([l.payload,r.payload]), "Both project revisions kept")
        try left.merge(Array(right.events.values)); try right.merge(Array(left.events.values))
        try require(left.current.count == 2 && Set(left.current) == Set(right.current), "Conflict copies are stable and idempotent")
        _ = try CloudSyncLedger.read(CloudSyncLedger.encoded(left))
        checks += 1
        var fresh = CloudSyncLedger()
        try fresh.merge(Array(left.events.values).reversed())
        try require(Set(fresh.current) == Set(left.current), "A fresh device rebuilds the same conflict list")
        var editing = CloudSyncLedger()
        try editing.merge([original,l])
        // The downloaded head changed after the user began editing original.
        _ = try editing.editProject(key:"shared",payload:Data("offline edit".utf8),basedOn:original.event)
        try require(Set(editing.current.map(\.payload)) == Set([l.payload,Data("offline edit".utf8)]), "Cloud discovery cannot disguise a concurrent saved-file edit as a causal overwrite")
        var malformed = r; malformed.schema = 9
        let before = try CloudSyncLedger.encoded(fresh)
        try rejects("Malformed whole batch") { try fresh.merge([second,malformed]) }
        try require(try CloudSyncLedger.encoded(fresh) == before, "Malformed batch has no partial writes")
        var duplicate = r; duplicate.payload = favorite
        try rejects("Conflicting event IDs") { try fresh.merge([r,duplicate]) }
        var causal = CloudSyncLedger()
        let c1 = try causal.edit(.look, key: "native:1", payload: Data([1]))!
        let c2 = try causal.edit(.look, key: "native:1", payload: Data([2]))!
        let c3 = try causal.edit(.look, key: "native:1", payload: Data([3]))!
        var outOfOrder = CloudSyncLedger()
        try require(outOfOrder.readyChanges([c3]).isEmpty, "A child waits for its missing causal chain")
        try require(outOfOrder.readyChanges([c3,c1,c2]).count == 3, "Downloaded causal chains become ready together")
        try outOfOrder.merge([c3]); try outOfOrder.merge([c1,c2])
        try require(outOfOrder.current == [c3], "Out-of-order causal updates preserve latest edit")

        let fm = FileManager.default
        let root = URL(fileURLWithPath: "/Volumes/Expand/Codex Media/PulseCanvas Studio/Development/icloud-20261110/tmp")
            .appendingPathComponent("Smoke-" + UUID().uuidString)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }
        let source = root.appendingPathComponent("Test song.wav")
        var wav = Data("RIFF".utf8)
        func little<T: FixedWidthInteger>(_ value: T) { var v = value.littleEndian; withUnsafeBytes(of: &v) { wav.append(contentsOf: $0) } }
        little(UInt32(88_236)); wav.append(Data("WAVEfmt ".utf8)); little(UInt32(16)); little(UInt16(1)); little(UInt16(1))
        little(UInt32(44_100)); little(UInt32(88_200)); little(UInt16(2)); little(UInt16(16)); wav.append(Data("data".utf8)); little(UInt32(88_200))
        for i in 0..<44_100 { little(Int16(sin(Double(i) * 2 * .pi * 220 / 44_100) * 4000)) }
        try wav.write(to: source)
        var project: [String: Any] = ["version":1,"scene":22,"soundtrack":source.absoluteString,
            "soundtrackBookmark":Data("must not travel".utf8).base64EncodedString(),
            "appearance":["chaos":0.8,"speed":1.7],"effectIdentities":["22":"native:22"],
            "timeline":[["start":0,"end":1,"scene":22,"bars":1]],"loopPlayback":true]
        let initial = try JSONSerialization.data(withJSONObject: project)
        let bundle = try CloudProjectPackage.make(initial, filename:"Journey.pulsecanvas",key:"journey",in:root.appendingPathComponent("first"))
        try require(bundle.info.audio?.name == source.lastPathComponent, "Audio keeps original filename")
        try require(bundle.info.nativeOnly, "Native-only project identified")
        try require(bundle.info.isAvailableInEdition, "Every edition shows compatible native projects")
        var creatorsInfo = bundle.info
        creatorsInfo.nativeOnly = false
        let creatorsPayload = try CloudSyncLedger.encoded(creatorsInfo)
        var sharedProjects = CloudSyncLedger()
        let creatorsProject = try sharedProjects.edit(.project, key: "creators-project", payload: creatorsPayload)!
        var companion = CloudSyncLedger()
        try companion.merge([creatorsProject])
        let info = try JSONDecoder().decode(CloudProjectInfo.self, from: companion.current[0].payload)
        #if DIRECT_BUILD && !STORE_BUILD
        try require(info.isAvailableInEdition, "Creators can see the synced Creators project")
        #else
        try require(!info.isAvailableInEdition, "Metal editions hide the synced Creators project")
        #endif
        try require(companion.current == [creatorsProject], "Edition visibility leaves the Creators record intact")
        let metadata = try String(contentsOf:bundle.project,encoding:.utf8)
        try require(!metadata.contains("must not travel") && !metadata.contains("Bookmark") && !metadata.contains(root.path), "No bookmarks or original device paths uploaded")
        project["appearance"] = ["chaos":0.95,"speed":2.2]
        let updated = try CloudProjectPackage.make(JSONSerialization.data(withJSONObject:project),filename:"Journey.pulsecanvas",key:"journey",in:root.appendingPathComponent("second"))
        try require(bundle.info.audio?.asset == updated.info.audio?.asset && bundle.info.asset != updated.info.asset, "Settings edits deduplicate audio")
        try fm.removeItem(at:source)
        let output = root.appendingPathComponent("fresh-device")
        let restored = try CloudProjectPackage.open(bundle.info,key:"journey",project:bundle.project,audio:bundle.audio,destination:output)
        let decoded = try JSONSerialization.jsonObject(with:restored) as! [String:Any]
        let restoredAudio = URL(string:decoded["soundtrack"] as! String)!
        try require(try Data(contentsOf:restoredAudio) == wav && restoredAudio.lastPathComponent == "Test song.wav", "Fresh-device audio restore matches exact bytes and filename")
        try require(decoded["cloudProjectID"] as? String == "journey" && decoded["loopPlayback"] as? Bool == true, "Project identity and playback settings round trip")
        try require((decoded["timeline"] as? [[String:Any]])?.first?["bars"] as? Int == 1, "Timeline round trip")
        let repacked = try CloudProjectPackage.make(restored,filename:"Journey.pulsecanvas",key:"journey",in:root.appendingPathComponent("repacked"))
        try require(repacked.info.asset == bundle.info.asset && repacked.info.audio?.asset == bundle.info.audio?.asset, "Reopened projects produce identical cloud assets")
        let missing = root.appendingPathComponent("missing-device")
        try rejects("Missing audio") { _ = try CloudProjectPackage.open(bundle.info,key:"journey",project:bundle.project,audio:nil,destination:missing) }
        try require(!fm.fileExists(atPath:missing.path), "Missing download cannot partially restore")
        try Data([0,1,2]).write(to:bundle.audio!)
        try rejects("Damaged audio") { _ = try CloudProjectPackage.open(bundle.info,key:"journey",project:bundle.project,audio:bundle.audio,destination:missing) }
        var malicious = bundle.info; malicious.audio?.name = "../escape.wav"
        try rejects("Path traversal") { _ = try malicious.validated() }
        print("PASS: \(checks) iCloud ledger and project checks (isolated local files, no Apple Account transfer)")
    }
}

extension CloudSyncChange: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(event); hasher.combine(payload) }
}
