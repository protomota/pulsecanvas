import CryptoKit
import Foundation

extension Notification.Name {
    static let pulseCanvasOpenBackupProject = Notification.Name("PulseCanvas.openBackupProject")
}

/// A portable, versioned JSON document, including the audio needed to reopen projects.
/// Only explicitly owned settings and storage are included; never defaults wholesale.
enum UserBackup {
    static let startupError: String? = {
        do { try activatePendingRestore(); return nil }
        catch { return "Restore could not finish: \(error.localizedDescription) Your previous data is still in use." }
    }()
    static let format = "PulseCanvas User Backup"
    static let maximumBytes = 512_000_000
    static let maximumSourceBytes = 100_000_000_000
    static let activeKey = "PulseCanvas.backup.active.v1"
    static let preferenceKeys: Set<String> = [
        "PulseCanvas.effectFavorites.v1", "PulseCanvas.effectFavorites.v1.appearances",
        "PulseCanvas.metalEffectFavorites.v1", "PulseCanvas.metalEffectFavorites.v1.appearances",
        "PulseCanvas.studio.v1", "PulseCanvas.metalStudio.v1",
        "PulseCanvas.visualizerPool.v1", "PulseCanvas.metalVisualizerPool.v1",
        "PulseCanvas.radio.favoriteSongs.v1", "PulseCanvas.radio.favoriteSongsOnly.v1",
        "PulseCanvas.radio.station", "PulseCanvas.radio.bars", "PulseCanvas.radio.volume",
        "PulseCanvas.radio.catalogURL", "PulseCanvas.radio.personalCatalog.v1", "PulseCanvas.radio.personalActive.v1",
        "PulseCanvas.videoFormat.v1", "PulseCanvas.presentationMatchAspect.v1", "PulseCanvas.onboarding.completed.v1",
        "PulseCanvas.engagement.successfulVideoSaves.v1", "PulseCanvas.engagement.firstVideoSaved.v1",
        "PulseCanvas.engagement.firstExportThanksShown.v1", "PulseCanvas.engagement.firstExportReviewRequested.v1",
        "PulseCanvas.engagement.clickedActions.v1", "PulseCanvas.engagement.thanksPresentedSave.v2",
        "PulseCanvas.engagement.lastSuccessfulSaveID.v1", "PulseCanvas.engagement.radioSessions.v1",
        "PulseCanvas.engagement.radioThanksShown.v1", "PulseCanvas.engagement.thanksPresentedRadioSession.v2",
        "PulseCanvas.engagement.supportPresentedAt.v1", "PulseCanvas.engagement.supportOptedOut.v1"
    ]

    struct File: Codable, Sendable {
        var path: String
        var originalURL: String
        var sha256: String
        var data: Data
        var byteCount: Int
        init(path: String, originalURL: String, sha256: String, data: Data) {
            self.path = path; self.originalURL = originalURL; self.sha256 = sha256; self.data = data; byteCount = data.count
        }
    }
    struct Archive: Codable, Sendable {
        var format = UserBackup.format
        var version = 1
        var id = UUID()
        var created = Date()
        var platform: String
        var preferences: Data
        var files: [File]
    }
    struct Failure: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }
    struct Storage: Sendable {
        var documents: URL
        var support: URL
        var backups: URL
        var domain: String
        static var standard: Storage {
            return Storage(documents: UserDataStorage.defaultDocuments,
                support: UserDataStorage.defaultSupport, backups: UserDataStorage.backupRoot,
                domain: Bundle.main.bundleIdentifier ?? "PulseCanvas")
        }
        func root(_ name: String, defaults: UserDefaults) -> URL {
            if let text = defaults.string(forKey: activeKey), let id = UUID(uuidString: text) {
                return backups.appendingPathComponent("Restores/\(id.uuidString)/\(name)", isDirectory: true)
            }
            return name == "Documents" ? documents : support
        }
    }

    static var documents: URL { Storage.standard.root("Documents", defaults: .standard) }
    static var support: URL { Storage.standard.root("Support", defaults: .standard) }

    static func savedProjects() -> [URL] {
        let root = documents.resolvingSymlinksInPath()
        guard let iterator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else { return [] }
        return iterator.compactMap { $0 as? URL }.filter { isProject($0.path) && (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    static func hash(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
    static func fail(_ message: String) -> Failure { Failure(message: message) }

    /// Saved external project files are also retained internally for future backups.
    @discardableResult
    static func rememberProject(_ data: Data, name: String) throws -> Data {
        let folder = documents.appendingPathComponent("Projects", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let filename = String(hash(Data(name.utf8)).prefix(16)) + "-" + URL(fileURLWithPath: name).deletingPathExtension().lastPathComponent + ".pulsecanvas"
        var destination = folder.appendingPathComponent(filename)
        var portable = data
        if var object = try JSONSerialization.jsonObject(with: data) as? [String: Any], object["appearance"] != nil {
            if object["cloudProjectID"] == nil { object["cloudProjectID"] = hash(Data(filename.utf8)) }
            if let id = object["cloudProjectID"] as? String,
               let existing = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil).first(where: { url in
                   guard let saved = try? Data(contentsOf: url),
                         let value = try? JSONSerialization.jsonObject(with: saved) as? [String: Any] else { return false }
                   return value["cloudProjectID"] as? String == id
               }) { destination = existing }
            portable = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        }
        try portable.write(to: destination, options: .atomic)
        NotificationCenter.default.post(name: .pulseCanvasUserDataChanged, object: nil)
        return portable
    }

    static func export(currentProject: Data?, additionalProjects: [URL] = [], platform: String,
                       defaults: UserDefaults = .standard, storage: Storage = .standard) throws -> Data {
        let archive = try collect(currentProject: currentProject, additionalProjects: additionalProjects, platform: platform, defaults: defaults, storage: storage)
        guard archive.files.reduce(0, { $0 + $1.byteCount }) < maximumBytes / 2 else { throw fail(String(localized: "Use ZIP export for this music library.")) }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(archive)
        guard data.count < maximumBytes else { throw fail(String(localized: "Use ZIP export for this music library.")) }
        return data
    }

    static func collect(currentProject: Data?, additionalProjects: [URL] = [], platform: String,
                        defaults: UserDefaults = .standard, storage: Storage = .standard) throws -> Archive {
        let fm = FileManager.default
        var files: [File] = []
        var sources = Set<String>()
        var total = 0
        func add(_ data: Data, at path: String, source: String) throws {
            guard safePath(path), !files.contains(where: { $0.path == path }) else { throw fail(String(localized: "Duplicate or invalid backup path.")) }
            total += data.count
            guard total <= maximumSourceBytes, files.count < 20_000 else {
                throw fail(String(localized: "This backup exceeds 100 GB or 20,000 files. Nothing was exported."))
            }
            files.append(File(path: path, originalURL: source, sha256: hash(data), data: data))
            if !source.isEmpty { sources.insert(source) }
        }
        func addURL(_ url: URL, at path: String) throws {
            let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])
            guard values.isRegularFile == true, values.isSymbolicLink != true,
                  (values.fileSize ?? maximumSourceBytes + 1) <= maximumSourceBytes else { throw fail(String(localized: "Cannot back up \(url.lastPathComponent). It is missing, too large, or a symbolic link.")) }
            try add(Data(contentsOf: url, options: .mappedIfSafe), at: path, source: url.absoluteString)
        }
        let roots = ["Documents": storage.root("Documents", defaults: defaults), "Support": storage.root("Support", defaults: defaults)]
        for name in roots.keys.sorted() {
            let root = roots[name]!.resolvingSymlinksInPath()
            guard fm.fileExists(atPath: root.path) else { continue }
            var readError: Error?
            guard let iterator = fm.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles], errorHandler: { _, error in readError = error; return false }) else {
                if fm.fileExists(atPath: root.path) { throw fail(String(localized: "Could not read saved app data.")) }
                continue
            }
            for case let url as URL in iterator {
                let relative = String(url.path.dropFirst(root.path.count + 1))
                let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
                if values.isSymbolicLink == true { throw fail(String(localized: "A saved data folder contains a symbolic link: \(relative)")) }
                guard values.isRegularFile == true else { continue }
                let component = relative.split(separator: "/").first.map(String.init) ?? ""
                let owned = name == "Support"
                    ? ["PersonalRadio", "StudioMusic", "ProjectM", "ImportedRadio", "CloudProjects"].contains(component)
                    : ["Projects", "StudioMusic"].contains(component) || ["pulsecanvas", "pulsevision", "mp3", "m4a", "wav", "aiff", "aif", "aac", "caf", "flac"].contains(url.pathExtension.lowercased()) || relative == "Studio-autosave.json"
                if owned { try addURL(url, at: name + "/" + relative) }
            }
            if let readError { throw readError }
        }
        if let currentProject {
            files.removeAll { $0.path == "Documents/Backup-current.pulsecanvas" }
            try add(currentProject, at: "Documents/Backup-current.pulsecanvas", source: "")
        }
        for url in additionalProjects {
            let access = SecurityScopedAccess(url: url)
            try addURL(url, at: "Documents/Projects/\(UUID().uuidString)-\(url.deletingPathExtension().lastPathComponent).pulsecanvas")
            withExtendedLifetime(access) {}
        }
        // Older Creators libraries may refer to local catalogs rather than an
        // app-managed PersonalRadio copy. Retain the catalog's relative structure.
        var catalogs: [(URL, Data?)] = []
        if let text = defaults.string(forKey: "PulseCanvas.radio.catalogURL"), let url = URL(string: text), url.isFileURL {
            catalogs.append((url, defaults.data(forKey: "PulseCanvas.radio.folderBookmark")))
        }
        if let data = defaults.data(forKey: "PulseCanvas.radio.favoriteSongs.v1"),
           let songs = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for song in songs {
                let bookmark = (song["folderBookmark"] as? String).flatMap { Data(base64Encoded: $0) }
                for key in ["sourceURL", "catalogURL"] {
                    if let text = song[key] as? String, let url = URL(string: text), url.isFileURL { catalogs.append((url, bookmark)) }
                }
            }
        }
        for (catalog, bookmark) in catalogs where !sources.contains(catalog.absoluteString) {
            let directory = SecurityScopedAccess.resolve(bookmark: bookmark, fallback: catalog.deletingLastPathComponent())
            let access = SecurityScopedAccess(url: directory)
            let base = catalog.deletingLastPathComponent().standardizedFileURL
            let prefix = "Support/ImportedRadio/" + String(hash(Data(base.absoluteString.utf8)).prefix(16)) + "/"
            var queue = [catalog]
            while !queue.isEmpty {
                let reference = queue.removeLast()
                if sources.contains(reference.absoluteString) { continue }
                guard reference.standardizedFileURL.path.hasPrefix(base.path + "/") else { throw fail(String(localized: "A local music catalog refers outside its folder.")) }
                let relative = String(reference.standardizedFileURL.path.dropFirst(base.path.count + 1))
                let resolved = directory.appendingPathComponent(relative)
                try addURL(resolved, at: prefix + relative)
                files[files.count - 1].originalURL = reference.absoluteString; sources.insert(reference.absoluteString)
                if reference.pathExtension.lowercased() == "json" {
                    guard files.last!.data.count < 2_000_000,
                          let json = try JSONSerialization.jsonObject(with: files.last!.data) as? [String: Any], json["version"] as? Int == 1 else { throw fail(String(localized: "Invalid local music catalog.")) }
                    let records = (json["tracks"] as? [[String: Any]] ?? []) + (json["stations"] as? [[String: Any]] ?? [])
                    guard records.count <= 500 else { throw fail(String(localized: "Too many entries in a local music catalog.")) }
                    for record in records {
                        guard let path = record["audio"] as? String ?? record["catalog"] as? String,
                              let url = URL(string: path, relativeTo: reference)?.absoluteURL, url.isFileURL else { throw fail(String(localized: "Invalid local music file reference.")) }
                        queue.append(url)
                    }
                }
            }
            withExtendedLifetime(access) {}
        }
        // Follow project soundtrack references, including files outside the sandbox.
        // Capture each external source once; references are rewritten on restore.
        for file in files where isProject(file.path) {
            let object = try JSONSerialization.jsonObject(with: file.data)
            for url in referencedFiles(object) where !sources.contains(url.absoluteString) {
                let bookmark = (object as? [String: Any])?["soundtrackBookmark"] as? String
                let resolved = SecurityScopedAccess.resolve(bookmark: bookmark.flatMap { Data(base64Encoded: $0) }, fallback: url)
                let access = SecurityScopedAccess(url: resolved)
                // Keep the original filename: the player derives its title from
                // it. A unique parent separates different songs with equal names.
                try addURL(resolved, at: "Documents/BackupAudio/\(UUID().uuidString)/\(url.lastPathComponent)")
                files[files.count - 1].originalURL = url.absoluteString; sources.insert(url.absoluteString)
                withExtendedLifetime(access) {}
            }
        }
        for index in files.indices where isProject(files[index].path) {
            let data = try JSONSerialization.data(withJSONObject: sanitized(JSONSerialization.jsonObject(with: files[index].data)), options: [.sortedKeys])
            files[index].data = data; files[index].sha256 = hash(data); files[index].byteCount = data.count
        }
        var preferences: [String: Any] = [:]
        for key in preferenceKeys {
            if let value = defaults.object(forKey: key) {
                // UserDefaults stores URLs as bookmark data; export a plain URL instead.
                if key == "PulseCanvas.radio.personalCatalog.v1", let url = defaults.url(forKey: key) {
                    preferences[key] = url.absoluteString
                } else { preferences[key] = try sanitized(value) }
            }
        }
        let plist = try PropertyListSerialization.data(fromPropertyList: preferences, format: .binary, options: 0)
        let archive = Archive(platform: platform, preferences: plist, files: files)
        try validate(archive)
        return archive
    }

    static func read(_ url: URL) throws -> Archive {
        guard (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? maximumBytes) < maximumBytes else { throw fail(String(localized: "This backup is too large.")) }
        return try decode(Data(contentsOf: url, options: .mappedIfSafe))
    }
    static func decode(_ data: Data) throws -> Archive {
        guard data.count < maximumBytes else { throw fail(String(localized: "This backup is too large.")) }
        let archive = try JSONDecoder().decode(Archive.self, from: data)
        try validate(archive)
        return archive
    }
    static func validate(_ archive: Archive) throws {
        guard archive.format == format, archive.version == 1, archive.files.count <= 20_000,
              ["macOS", "iOS", "visionOS"].contains(archive.platform),
              archive.preferences.count < 32_000_000 else { throw fail(String(localized: "Choose a supported PulseCanvas user backup.")) }
        let values = try preferenceValues(archive)
        guard Set(values.keys).isSubset(of: preferenceKeys) else { throw fail(String(localized: "This backup includes unsupported settings.")) }
        try validatePreferences(values)
        var paths = Set<String>(), total = 0
        for file in archive.files {
            total += file.data.count
            guard total <= maximumSourceBytes, file.byteCount == file.data.count, safePath(file.path), paths.insert(file.path.lowercased()).inserted,
                  hash(file.data) == file.sha256 else { throw fail(String(localized: "The backup contains a damaged or duplicate file.")) }
            if !file.originalURL.isEmpty {
                guard let url = URL(string: file.originalURL), url.isFileURL, url.user == nil, url.password == nil else { throw fail(String(localized: "Invalid original file location.")) }
            }
            if isProject(file.path) {
                let object = try JSONSerialization.jsonObject(with: file.data)
                guard let project = object as? [String: Any], project["version"] as? Int == 1,
                      project["scene"] is NSNumber || project["clips"] is [Any] else { throw fail(String(localized: "A project in the backup is invalid.")) }
            }
        }
        // A file must never also be the parent of another entry.
        for path in paths {
            var components = path.split(separator: "/"); components.removeLast()
            while components.count > 1 {
                guard !paths.contains(components.joined(separator: "/")) else { throw fail(String(localized: "Conflicting backup paths.")) }
                components.removeLast()
            }
        }
        let sources = Set(archive.files.map(\.originalURL))
        for file in archive.files where isProject(file.path) {
            for url in referencedFiles(try JSONSerialization.jsonObject(with: file.data)) {
                guard sources.contains(url.absoluteString) else { throw fail(String(localized: "A project’s soundtrack is missing from this backup.")) }
            }
        }
    }

    static func safePath(_ path: String) -> Bool {
        let parts = path.split(separator: "/", omittingEmptySubsequences: false)
        return path.utf8.count < 1024 && parts.count >= 2 && ["Documents", "Support"].contains(String(parts[0]))
            && parts.allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." && !$0.contains("\\") && !$0.contains("\0") }
    }
    static func preferenceValues(_ archive: Archive) throws -> [String: Any] {
        guard let values = try PropertyListSerialization.propertyList(from: archive.preferences, options: [], format: nil) as? [String: Any] else { throw fail(String(localized: "Invalid saved settings.")) }
        return values
    }
    static func validatePreferences(_ values: [String: Any]) throws {
        for (key, value) in values {
            if key.contains("Favorites.v1") && !key.hasSuffix("appearances") || key.hasSuffix("clickedActions.v1") {
                guard let strings = value as? [String], strings.count <= 100_000,
                      strings.allSatisfy({ !$0.isEmpty && $0.count < 1024 }), Set(strings).count == strings.count else { throw fail(String(localized: "Invalid saved favorites or actions.")) }
            } else if key.hasSuffix(".appearances") || key.contains("Studio.v1") || key == "PulseCanvas.studio.v1"
                        || key.contains("Pool.v1") || key.hasSuffix("favoriteSongs.v1") || key.hasSuffix("videoFormat.v1") {
                guard let data = value as? Data, data.count < 16_000_000 else { throw fail(String(localized: "Invalid saved settings data.")) }
                let json = try JSONSerialization.jsonObject(with: data)
                guard json is [String: Any] || key.hasSuffix("favoriteSongs.v1") && json is [Any] else { throw fail(String(localized: "Invalid saved settings data.")) }
            } else if key.hasSuffix("catalogURL") || key.hasSuffix("personalCatalog.v1") {
                guard let string = value as? String, let url = URL(string: string),
                      url.isFileURL || url.scheme == "https" && url.host != nil,
                      url.user == nil, url.password == nil, url.query == nil else { throw fail(String(localized: "Invalid saved music location.")) }
            } else if key.hasSuffix("station") || key.hasSuffix("lastSuccessfulSaveID.v1") {
                guard let string = value as? String, string.count < 1024 else { throw fail(String(localized: "Invalid saved selection.")) }
            } else {
                guard let number = value as? NSNumber, number.doubleValue.isFinite,
                      (0...1_000_000_000).contains(number.doubleValue) else { throw fail(String(localized: "Invalid saved preference.")) }
            }
        }
    }
    static func isProject(_ path: String) -> Bool {
        ["pulsecanvas", "pulsevision"].contains(URL(fileURLWithPath: path).pathExtension.lowercased()) || path.hasSuffix("/Studio-autosave.json")
    }
    static func referencedFiles(_ object: Any) -> [URL] {
        if let dictionary = object as? [String: Any] {
            return dictionary.flatMap { key, value -> [URL] in
                if ["soundtrack", "externalAudioURL"].contains(key), let string = value as? String, let url = URL(string: string), url.isFileURL { return [url] }
                if key == "macProject", let string = value as? String, let data = Data(base64Encoded: string),
                   let json = try? JSONSerialization.jsonObject(with: data) { return referencedFiles(json) }
                return referencedFiles(value)
            }
        }
        return (object as? [Any])?.flatMap(referencedFiles) ?? []
    }
    static func sanitized(_ object: Any, urls: [String: String] = [:]) throws -> Any {
        if let dictionary = object as? [String: Any] {
            let excluded: Set<String> = ["soundtrackbookmark", "folderbookmark", "password", "token", "apikey", "secret", "authorization", "session"]
            return try dictionary.filter { !excluded.contains($0.key.lowercased()) }.mapValues { try sanitized($0, urls: urls) }
        }
        if let array = object as? [Any] { return try array.map { try sanitized($0, urls: urls) } }
        if let string = object as? String {
            if let replacement = urls[string] { return replacement }
            // Vision's retained Mac project is JSON encoded as base64.
            if let data = Data(base64Encoded: string), let json = try? JSONSerialization.jsonObject(with: data) {
                return try JSONSerialization.data(withJSONObject: sanitized(json, urls: urls), options: [.sortedKeys]).base64EncodedString()
            }
        }
        if let data = object as? Data, let json = try? JSONSerialization.jsonObject(with: data) {
            return try JSONSerialization.data(withJSONObject: sanitized(json, urls: urls), options: [.sortedKeys])
        }
        return object
    }

    /// Stage a complete immutable restore, then atomically publish a small pending marker.
    /// Live models keep their current files/preferences until the next cold launch.
    static func stageRestore(_ archive: Archive, defaults: UserDefaults = .standard, storage: Storage = .standard) throws -> Bool {
        try validate(archive)
        if defaults.string(forKey: activeKey) == archive.id.uuidString { return false }
        let fm = FileManager.default
        let root = storage.backups.appendingPathComponent("Restores/\(archive.id.uuidString)", isDirectory: true)
        let staging = storage.backups.appendingPathComponent("Staging-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: staging, withIntermediateDirectories: true)
        try fm.createDirectory(at: root.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: staging) }
        var mapping: [String: String] = [:]
        for file in archive.files where !file.originalURL.isEmpty { mapping[file.originalURL] = root.appendingPathComponent(file.path).absoluteString }
        for file in archive.files {
            var data = file.data
            if isProject(file.path) {
                data = try JSONSerialization.data(withJSONObject: sanitized(JSONSerialization.jsonObject(with: data), urls: mapping), options: [.sortedKeys])
            }
            let destination = staging.appendingPathComponent(file.path)
            try fm.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: destination, options: .atomic)
        }
        var preferences = try preferenceValues(archive)
        preferences = try sanitized(preferences, urls: mapping) as! [String: Any]
        let data = try PropertyListSerialization.data(fromPropertyList: preferences, format: .binary, options: 0)
        try data.write(to: staging.appendingPathComponent("preferences.plist"), options: .atomic)
        // An identical pending import is idempotent; a different import never merges into it.
        var metadata = archive
        for index in metadata.files.indices { metadata.files[index].data = Data() }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let fingerprint = hash(try encoder.encode(metadata))
        try Data(fingerprint.utf8).write(to: staging.appendingPathComponent("fingerprint"), options: .atomic)
        if fm.fileExists(atPath: root.path) {
            guard try Data(contentsOf: root.appendingPathComponent("fingerprint")) == Data(fingerprint.utf8) else { throw fail(String(localized: "A different backup uses this identity. Nothing restored.")) }
        } else { try fm.moveItem(at: staging, to: root) }
        let marker = try JSONEncoder().encode(archive.id)
        try marker.write(to: storage.backups.appendingPathComponent("pending.json"), options: .atomic)
        return true
    }

    /// Run before any app models are constructed. One persistent-domain write commits
    /// the settings and new storage generation together; old user files remain intact.
    static func activatePendingRestore(defaults: UserDefaults = .standard, storage: Storage = .standard) throws {
        let pending = storage.backups.appendingPathComponent("pending.json")
        guard FileManager.default.fileExists(atPath: pending.path) else { return }
        let id = try JSONDecoder().decode(UUID.self, from: Data(contentsOf: pending))
        if defaults.string(forKey: activeKey) == id.uuidString {
            try? FileManager.default.removeItem(at: pending)
            return
        }
        let root = storage.backups.appendingPathComponent("Restores/\(id.uuidString)")
        let plist = try Data(contentsOf: root.appendingPathComponent("preferences.plist"))
        guard var values = try PropertyListSerialization.propertyList(from: plist, options: [], format: nil) as? [String: Any],
              Set(values.keys).isSubset(of: preferenceKeys) else { throw fail(String(localized: "The pending restore is invalid. Your previous data has been kept.")) }
        let personalKey = "PulseCanvas.radio.personalCatalog.v1"
        let personalURL = (values.removeValue(forKey: personalKey) as? String).flatMap(URL.init(string:))
        // Match the URL representation UserDefaults.url(forKey:) expects, without
        // importing another machine's security-scoped authorization bookmarks.
        if let personalURL { values[personalKey] = try NSKeyedArchiver.archivedData(withRootObject: personalURL, requiringSecureCoding: true) }
        var domain = defaults.persistentDomain(forName: storage.domain) ?? [:]
        for key in preferenceKeys { domain.removeValue(forKey: key) }
        domain.removeValue(forKey: "PulseCanvas.radio.folderBookmark")
        // Restoring an old snapshot must not silently publish it to other devices.
        domain["PulseCanvas.iCloud.enabled.v1"] = false
        domain.merge(values) { _, restored in restored }
        domain[activeKey] = id.uuidString
        let previous = defaults.persistentDomain(forName: storage.domain) ?? [:]
        defaults.setPersistentDomain(domain, forName: storage.domain)
        guard defaults.synchronize() else {
            defaults.setPersistentDomain(previous, forName: storage.domain)
            defaults.synchronize()
            throw fail(String(localized: "The restore settings couldn't be saved. Your previous data is still in use."))
        }
        try? FileManager.default.removeItem(at: pending)
    }
}
