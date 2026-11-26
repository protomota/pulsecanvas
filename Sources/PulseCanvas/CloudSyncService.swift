import Combine
import Foundation

@MainActor final class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()
    nonisolated static let containerID = "iCloud.com.protomota.pulsecanvas"
    static let enabledKey = "PulseCanvas.iCloud.enabled.v1"
    @Published private(set) var enabled: Bool
    @Published private(set) var busy = false
    @Published private(set) var status = String(localized: "iCloud sync is off. Your data stays on this device.")
    @Published private(set) var projects: [CloudSyncChange] = []
    @Published private(set) var lastSync: Date?
    private struct DiskState: Codable {
        var ledger = CloudSyncLedger()
        var account: String?
        var projectHashes: [String: String] = [:]
        var projectBases: [String: String] = [:]
        var needsApplication = false
    }
    private var state = DiskState()
    private var root: URL?
    private var query: NSMetadataQuery?
    private var observers: [NSObjectProtocol] = []
    private var queryObservers: [NSObjectProtocol] = []
    private var localTask: Task<Void, Never>?
    private var periodic: Task<Void, Never>?
    private var started = false
    private var applying = false
    private var generation = UUID()
    private var again = false
    private var confirmedAccountMerge = false
    private var connecting = false
    private var projectFailures: [String] = []
    private var invalidHistory = false
    private let defaults: UserDefaults
    private let support: URL
    private var stateURL: URL { support.appendingPathComponent("CloudSync/state.json") }
    private var workRoot: URL { support.appendingPathComponent("CloudSync/Work", isDirectory: true) }
    private var changesFolder: URL? { root?.appendingPathComponent("PulseCanvasData/Changes", isDirectory: true) }
    private var assetsFolder: URL? { root?.appendingPathComponent("Documents/Projects", isDirectory: true) }
    private var audioFolder: URL? { root?.appendingPathComponent("Documents/Audio", isDirectory: true) }

    init(defaults: UserDefaults = .standard, support: URL? = nil) {
        self.defaults = defaults
        self.support = support ?? UserDataStorage.support
        enabled = defaults.bool(forKey: Self.enabledKey)
        if FileManager.default.fileExists(atPath: stateURL.path) {
            do {
                let saved = try JSONDecoder().decode(DiskState.self, from: Data(contentsOf: stateURL))
                _ = try CloudSyncLedger.read(CloudSyncLedger.encoded(saved.ledger))
                try saved.ledger.events.values.forEach(CloudSyncAppData.validate)
                state = saved
            } catch {
                invalidHistory = true
                enabled = false
                defaults.set(false, forKey: Self.enabledKey)
                status = String(localized: "iCloud sync history couldn't be read. Sync is off; local data and the original history were kept.")
            }
        }
    }
    func start() {
        guard !started else { return }; started = true
        observers.append(NotificationCenter.default.addObserver(forName: .pulseCanvasUserDataChanged, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.localChanged() }
        })
        observers.append(NotificationCenter.default.addObserver(forName: .NSUbiquityIdentityDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.setEnabled(false)
                self?.status = String(localized: "Your Apple Account changed. Local data was kept. Confirm iCloud sync again to use the current account.")
            }
        })
        if enabled { connect() }
    }
    func setEnabled(_ value: Bool) {
        guard !value || !invalidHistory else {
            status = String(localized: "Sync history needs recovery before enabling iCloud. Local files and the unreadable history are preserved.")
            return
        }
        confirmedAccountMerge = value
        enabled = value; defaults.set(value, forKey: Self.enabledKey)
        generation = UUID(); localTask?.cancel(); periodic?.cancel(); query?.stop(); query = nil; root = nil
        queryObservers.forEach { NotificationCenter.default.removeObserver($0) }; queryObservers = []
        connecting = false
        if value { start(); connect() }
        else { status = String(localized: "iCloud sync is off. Local files and existing iCloud copies are kept."); projects = [] }
    }
    private func connect() {
        guard enabled, root == nil, !connecting else { return }
        connecting = true
        status = String(localized: "Connecting to iCloud Drive…")
        let ticket = generation
        Task {
            defer { if generation == ticket { connecting = false } }
            let result = await Task.detached { () -> (URL?, Data?) in
                let token = FileManager.default.ubiquityIdentityToken
                let identity = token.flatMap { try? NSKeyedArchiver.archivedData(withRootObject: $0, requiringSecureCoding: true) }
                return (FileManager.default.url(forUbiquityContainerIdentifier: Self.containerID), identity)
            }.value
            guard enabled, generation == ticket else { return }
            guard let url = result.0, let identity = result.1 else {
                status = String(localized: "iCloud Drive is unavailable. Sign in to iCloud and use an iCloud-enabled signed build. Your local data is safe.")
                return
            }
            let account = CloudSyncLedger.digest(identity)
            if state.account != account {
                if state.account != nil && !confirmedAccountMerge {
                    setEnabled(false)
                    status = String(localized: "Your Apple Account changed. Confirm iCloud sync again before merging local data with this account.")
                    return
                }
                // Never upload the previous account's event history into a new one.
                // Enabling the toggle explicitly confirms merging current local choices.
                if state.account != nil {
                    let archive = stateURL.deletingLastPathComponent().appendingPathComponent("PreviousAccount-" + UUID().uuidString + ".json")
                    do { try CloudSyncLedger.encoded(state).write(to: archive, options: .atomic) }
                    catch { status = String(localized: "Couldn't preserve the previous account's sync history. Local data was kept."); return }
                }
                state = DiskState(); state.account = account
            }
            confirmedAccountMerge = false
            root = url
            do {
                try FileManager.default.createDirectory(at: changesFolder!, withIntermediateDirectories: true)
                try FileManager.default.createDirectory(at: assetsFolder!, withIntermediateDirectories: true)
                try FileManager.default.createDirectory(at: audioFolder!, withIntermediateDirectories: true)
                try save()
                try watch()
                startPeriodicChecks()
            } catch { root = nil; query?.stop(); query = nil; status = String(localized: "Couldn't prepare iCloud sync: \(error.localizedDescription)") }
        }
    }
    private func startPeriodicChecks() {
        periodic?.cancel()
        periodic = Task { [weak self] in
            while !Task.isCancelled {
                self?.syncNow()
                do { try await Task.sleep(for: .seconds(30)) } catch { return }
            }
        }
    }
    private func watch() throws {
        guard let changesFolder, let assetsFolder else { return }
        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDataScope, NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(format: "%K BEGINSWITH %@ OR %K BEGINSWITH %@", NSMetadataItemPathKey,
            changesFolder.path + "/", NSMetadataItemPathKey, assetsFolder.path + "/")
        for name in [Notification.Name.NSMetadataQueryDidFinishGathering, .NSMetadataQueryDidUpdate] {
            queryObservers.append(NotificationCenter.default.addObserver(forName: name, object: query, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.syncNow() }
            })
        }
        self.query = query
        guard query.start() else { throw CocoaError(.fileReadUnknown) }
    }
    private func localChanged() {
        guard !applying, enabled else { return }
        localTask?.cancel()
        localTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(2)) } catch { return }
            self?.syncNow()
        }
    }
    private func save() throws {
        try FileManager.default.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try CloudSyncLedger.encoded(state).write(to: stateURL, options: .atomic)
    }
    private func observeLocal() throws {
        let snapshot = try CloudSyncAppData.snapshot(defaults: defaults)
        var scope = snapshot.scope
        for identity in state.ledger.baseline.keys where identity.hasPrefix("songFavorite:") {
            if let event = state.ledger.heads[identity], let change = state.ledger.events[event], CloudSyncAppData.canDeleteSong(change) {
                scope.insert(identity)
            }
        }
        try state.ledger.observe(snapshot.values, scope: scope)
    }
    func syncNow() {
        guard enabled else { return }
        guard root != nil else { connect(); return }
        if busy { again = true; return }
        busy = true; status = String(localized: "Syncing with iCloud Drive…")
        let ticket = generation
        Task {
            defer {
                busy = false
                if again { again = false; if enabled { syncNow() } }
            }
            do {
                try observeLocal(); try save()
                query?.disableUpdates()
                let items = query?.results as? [NSMetadataItem] ?? []
                query?.enableUpdates()
                let urls = items.compactMap { $0.value(forAttribute: NSMetadataItemURLKey) as? URL }
                    .filter { $0.deletingLastPathComponent().resolvingSymlinksInPath() == changesFolder?.resolvingSymlinksInPath() }
                    .filter { UUID(uuidString: $0.deletingPathExtension().lastPathComponent) != nil && state.ledger.events[$0.deletingPathExtension().lastPathComponent] == nil }
                let incoming = try await Task.detached {
                    try urls.compactMap { url -> CloudSyncChange? in
                        guard try Self.downloaded(url) else { return nil }
                        let data = try Self.coordinatedRead(url)
                        guard data.count < 3_000_000 else { throw CocoaError(.fileReadCorruptFile) }
                        let change = try JSONDecoder().decode(CloudSyncChange.self, from: data)
                        guard change.event == url.deletingPathExtension().lastPathComponent else { throw CocoaError(.fileReadCorruptFile) }
                        return change
                    }
                }.value
                guard enabled, generation == ticket else { return }
                try incoming.forEach(CloudSyncAppData.validate)
                // Capture edits made while downloads were in flight before applying
                // remote heads, so an async fetch cannot overwrite an unseen local edit.
                try observeLocal()
                let ready = state.ledger.readyChanges(incoming)
                try state.ledger.merge(ready)
                state.needsApplication = state.needsApplication || !ready.isEmpty
                try save() // durable before changing the app's live choices
                if state.needsApplication {
                    applying = true
                    defer { applying = false }
                    try CloudSyncAppData.apply(state.ledger.current.filter { $0.kind != .project }, defaults: defaults)
                    state.ledger.baseline = try CloudSyncAppData.snapshot(defaults: defaults).values
                    state.needsApplication = false
                    try save()
                }
                try await uploadProjects(ticket: ticket)
                guard enabled, generation == ticket, let folder = changesFolder else { return }
                let pending = state.ledger.pending.compactMap { state.ledger.events[$0] }
                for change in pending {
                    guard enabled, generation == ticket else { return }
                    let data = try CloudSyncLedger.encoded(change)
                    let destination = folder.appendingPathComponent(change.event + ".json")
                    try await Task.detached { try Self.writeImmutable(data, to: destination) }.value
                    state.ledger.pending.remove(change.event)
                }
                // One checkpoint per batch. A crash replays immutable writes safely
                // without rewriting the entire history for every favorite.
                try save()
                projects = state.ledger.current.filter { change in
                    guard change.kind == .project, !change.deleted,
                          let info = try? JSONDecoder().decode(CloudProjectInfo.self, from: change.payload) else { return false }
                    return info.isAvailableInEdition
                }.sorted { $0.order > $1.order }
                lastSync = Date()
                status = projectFailures.isEmpty ? "Changes saved to iCloud Drive. Apple transfers them when a connection is available."
                    : "Other changes saved. \(projectFailures.count) project(s) need attention: \(projectFailures[0])"
                if ready.count < incoming.count { status += " Waiting for earlier changes to finish downloading." }
            } catch {
                status = String(localized: "Sync needs attention: \(error.localizedDescription). Local data was kept; Sync now retries.")
            }
        }
    }

    private func uploadProjects(ticket: UUID) async throws {
        guard let folder = assetsFolder, let audioFolder else { return }
        projectFailures = []
        for url in UserBackup.savedProjects() where url.deletingLastPathComponent().lastPathComponent == "Projects" {
            guard enabled, generation == ticket else { return }
            let work = workRoot.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: work) }
            do {
            guard (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? Int.max) < 8_000_000 else { throw CocoaError(.fileReadCorruptFile) }
            let fingerprint = try Data(contentsOf: url)
            let digest = try CloudProjectPackage.fingerprint(fingerprint)
            if state.projectHashes[url.lastPathComponent] == digest { continue }
            let key = try CloudProjectPackage.key(for: fingerprint, filename: url.lastPathComponent)
            let result = try await Task.detached {
                try CloudProjectPackage.make(fingerprint, filename: url.lastPathComponent, key: key, in: work)
            }.value
            guard enabled, generation == ticket else { return }
            let destination = folder.appendingPathComponent(result.info.asset)
            try await Task.detached {
                if let audio = result.audio, let info = result.info.audio {
                    try Self.copyImmutable(audio, to: audioFolder.appendingPathComponent(info.asset))
                }
                try Self.copyImmutable(result.project, to: destination)
            }.value
            guard enabled, generation == ticket else { return }
            let revision = try state.ledger.editProject(key: key, payload: CloudSyncLedger.encoded(result.info), basedOn: state.projectBases[key])
            state.projectBases[key] = revision?.event ?? state.ledger.heads["project:" + key]
            state.projectHashes[url.lastPathComponent] = digest; try save()
            } catch { projectFailures.append("\(url.lastPathComponent): \(error.localizedDescription)") }
        }
    }
    func openProject(_ change: CloudSyncChange) async throws -> Data {
        guard enabled, let folder = assetsFolder else { throw CocoaError(.fileReadNoPermission) }
        let info = try JSONDecoder().decode(CloudProjectInfo.self, from: change.payload).validated()
        guard projects.contains(change), info.isAvailableInEdition else { throw CocoaError(.fileReadNoPermission) }
        let source = folder.appendingPathComponent(info.asset)
        let audio = info.audio.flatMap { audioFolder?.appendingPathComponent($0.asset) }
        let destination = support.appendingPathComponent("CloudProjects/" + UUID().uuidString, isDirectory: true)
        guard try Self.downloaded(source), try audio.map({ try Self.downloaded($0) }) ?? true else {
            status = String(localized: "Downloading this project from iCloud. Try Open again when the download finishes.")
            throw CocoaError(.fileReadUnknown)
        }
        let data = try await Task.detached {
            try CloudProjectPackage.open(info, key: change.key, project: source, audio: audio, destination: destination)
        }.value
        try UserBackup.rememberProject(data, name: info.title + ".pulsecanvas")
        state.projectBases[change.key] = change.event
        try save()
        return data
    }
    func removeProject(_ change: CloudSyncChange) {
        guard enabled, projects.contains(change) else { return }
        do {
            _ = try state.ledger.edit(.project, key: change.key, payload: nil)
            try save(); syncNow()
        } catch { status = String(localized: "Couldn't remove the cloud project: \(error.localizedDescription)") }
    }

    nonisolated static func downloaded(_ url: URL) throws -> Bool {
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.startDownloadingUbiquitousItem(at: url)
            return false
        }
        let values = try url.resourceValues(forKeys: [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey])
        if values.isUbiquitousItem == true && values.ubiquitousItemDownloadingStatus != .current && values.ubiquitousItemDownloadingStatus != .downloaded {
            try FileManager.default.startDownloadingUbiquitousItem(at: url); return false
        }
        return true
    }
    nonisolated static func coordinatedRead(_ url: URL) throws -> Data {
        var error: NSError?, result: Result<Data, Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: .withoutChanges, error: &error) { location in
            result = Result { try Data(contentsOf: location) }
        }
        if let error { throw error }
        guard let result else { throw CocoaError(.fileReadUnknown) }
        return try result.get()
    }
    nonisolated static func writeImmutable(_ data: Data, to url: URL) throws {
        var error: NSError?, failure: Error?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: &error) { location in
            do {
                if FileManager.default.fileExists(atPath: location.path) {
                    guard try Data(contentsOf: location) == data else { throw CocoaError(.fileWriteFileExists) }
                } else { try data.write(to: location, options: .atomic) }
            } catch { failure = error }
        }
        if let error { throw error }; if let failure { throw failure }
    }
    nonisolated static func copyImmutable(_ source: URL, to url: URL) throws {
        var error: NSError?, failure: Error?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: &error) { location in
            do {
                if !FileManager.default.fileExists(atPath: location.path) { try FileManager.default.copyItem(at: source, to: location) }
                guard try CloudProjectPackage.hashFile(location) == location.deletingPathExtension().lastPathComponent else { throw CocoaError(.fileReadCorruptFile) }
            } catch { failure = error }
        }
        if let error { throw error }; if let failure { throw failure }
    }
}
