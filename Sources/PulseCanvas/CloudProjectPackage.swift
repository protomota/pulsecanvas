import Foundation

struct CloudAudioInfo: Codable, Sendable {
    var asset: String
    var name: String
    var bytes: Int
    func validated() throws -> Self {
        guard asset.count == 70, asset.hasSuffix(".audio"),
              asset.dropLast(6).allSatisfy({ $0.isHexDigit && $0.isASCII }),
              !name.isEmpty, name.count < 256, !name.contains("/"), name != ".", name != "..", !name.contains("\0"),
              bytes > 0, bytes <= UserBackup.maximumSourceBytes else { throw CocoaError(.fileReadCorruptFile) }
        return self
    }
}

struct CloudProjectInfo: Codable, Sendable {
    var title: String
    var asset: String
    var bytes: Int
    var nativeOnly: Bool
    var audio: CloudAudioInfo?
    var isAvailableInEdition: Bool {
        #if DIRECT_BUILD && !STORE_BUILD
        true
        #else
        nativeOnly
        #endif
    }
    func validated() throws -> Self {
        guard !title.isEmpty, title.count <= 500, asset.count == 69, asset.hasSuffix(".json"),
              asset.dropLast(5).allSatisfy({ $0.isHexDigit && $0.isASCII }),
              bytes > 0, bytes < 8_000_000 else { throw CocoaError(.fileReadCorruptFile) }
        if let audio { _ = try audio.validated() }
        return self
    }
}

enum CloudProjectPackage {
    static func fingerprint(_ data: Data) throws -> String {
        var stamp = data
        if let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           object["bundledSoundtrack"] == nil, let text = object["soundtrack"] as? String, let source = URL(string: text) {
            let bookmark = (object["soundtrackBookmark"] as? String).flatMap { Data(base64Encoded: $0) }
            let resolved = SecurityScopedAccess.resolve(bookmark: bookmark, fallback: source)
            let lease = SecurityScopedAccess(url: resolved)
            let values = try resolved.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            stamp.append(Data("\(values.fileSize ?? -1)|\(values.contentModificationDate?.timeIntervalSince1970 ?? 0)".utf8))
            withExtendedLifetime(lease) {}
        }
        return CloudSyncLedger.digest(stamp)
    }
    static func key(for data: Data, filename: String) throws -> String {
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let id = object?["cloudProjectID"] as? String, !id.isEmpty, id.count <= 100 { return id }
        return CloudSyncLedger.digest(Data(filename.utf8))
    }
    static func make(_ data: Data, filename: String, key: String, in workspace: URL) throws -> (info: CloudProjectInfo, project: URL, audio: URL?) {
        guard data.count < 8_000_000, var object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              object["version"] as? Int == 1, object["appearance"] is [String: Any] else { throw CocoaError(.fileReadCorruptFile) }
        object["cloudProjectID"] = key
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        var audioInfo: CloudAudioInfo?, audioFile: URL?
        var lease: SecurityScopedAccess?
        if object["bundledSoundtrack"] == nil, let text = object["soundtrack"] as? String, let source = URL(string: text) {
            guard source.isFileURL else { throw CocoaError(.fileReadCorruptFile) }
            let bookmark = (object["soundtrackBookmark"] as? String).flatMap { Data(base64Encoded: $0) }
            let resolved = SecurityScopedAccess.resolve(bookmark: bookmark, fallback: source)
            lease = SecurityScopedAccess(url: resolved)
            let values = try resolved.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])
            guard values.isRegularFile == true, values.isSymbolicLink != true,
                  (values.fileSize ?? Int.max) <= UserBackup.maximumSourceBytes else { throw CocoaError(.fileReadCorruptFile) }
            let staged = workspace.appendingPathComponent(UUID().uuidString)
            try FileManager.default.copyItem(at: resolved, to: staged)
            let audioAsset = try hashFile(staged) + ".audio"
            let destination = workspace.appendingPathComponent(audioAsset)
            try FileManager.default.moveItem(at: staged, to: destination)
            audioFile = destination
            audioInfo = try CloudAudioInfo(asset: audioAsset, name: resolved.lastPathComponent,
                bytes: destination.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0).validated()
            let portable = URL(fileURLWithPath: "/PulseCanvasCloud/" + source.lastPathComponent)
            object["soundtrack"] = portable.absoluteString
        }
        object = try UserBackup.sanitized(object) as! [String: Any]
        let projectData = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        let destination = workspace.appendingPathComponent(CloudSyncLedger.digest(projectData) + ".json")
        try projectData.write(to: destination, options: .atomic)
        withExtendedLifetime(lease) {}
        var title = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
        if title.count > 17, title.prefix(16).allSatisfy(\.isHexDigit), title.dropFirst(16).hasPrefix("-") { title = String(title.dropFirst(17)) }
        let identities = object["effectIdentities"] as? [String: String] ?? [:]
        let nativeOnly = !identities.isEmpty && identities.values.allSatisfy { $0.hasPrefix("native:") }
        return (try CloudProjectInfo(title: String(title.prefix(500)), asset: destination.lastPathComponent,
            bytes: projectData.count, nativeOnly: nativeOnly, audio: audioInfo).validated(), destination, audioFile)
    }
    static func hashFile(_ url: URL) throws -> String {
        UserBackup.hash(try Data(contentsOf: url, options: .alwaysMapped))
    }
    static func open(_ info: CloudProjectInfo, key: String, project: URL, audio: URL?, destination: URL) throws -> Data {
        _ = try info.validated()
        guard try project.resourceValues(forKeys: [.fileSizeKey]).fileSize == info.bytes,
              try hashFile(project) + ".json" == info.asset,
              var object = try JSONSerialization.jsonObject(with: Data(contentsOf: project)) as? [String: Any],
              object["version"] as? Int == 1, object["appearance"] is [String: Any] else { throw CocoaError(.fileReadCorruptFile) }
        // Check every downloaded asset before writing local files.
        if let expected = info.audio {
            guard let audio, try audio.resourceValues(forKeys: [.fileSizeKey]).fileSize == expected.bytes,
                  try hashFile(audio) + ".audio" == expected.asset else { throw CocoaError(.fileReadCorruptFile) }
        }
        object = try UserBackup.sanitized(object) as! [String: Any]
        if let expected = info.audio, let audio {
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
            let localAudio = destination.appendingPathComponent(expected.name)
            try FileManager.default.copyItem(at: audio, to: localAudio)
            object["soundtrack"] = localAudio.absoluteString
        }
        object["cloudProjectID"] = key
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }
}
