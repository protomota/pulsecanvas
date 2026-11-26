import Foundation

extension Notification.Name {
    static let pulseCanvasUserDataChanged = Notification.Name("PulseCanvas.userDataChanged")
    static let pulseCanvasCloudDataApplied = Notification.Name("PulseCanvas.cloudDataApplied")
}

/// Restores use an immutable storage generation. The pointer and restored settings
/// are activated together before any playback or library models are created.
enum UserDataStorage {
    // Local UI builds can use a private Info.plist key to keep QA out of real files.
    // The shipping plists never contain this key, and Release ignores it.
    private static var testRoot: URL? {
        #if DEBUG
        if let path = Bundle.main.object(forInfoDictionaryKey: "PulseCanvasUserDataTestRoot") as? String {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        #endif
        return nil
    }
    static var defaultSupport: URL {
        if let testRoot { return testRoot.appendingPathComponent("Support", isDirectory: true) }
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PulseCanvas", isDirectory: true)
    }
    static var backupRoot: URL { defaultSupport.deletingLastPathComponent().appendingPathComponent("PulseCanvasBackups", isDirectory: true) }
    static var defaultDocuments: URL {
        if let testRoot { return testRoot.appendingPathComponent("Documents", isDirectory: true) }
        #if os(macOS)
        return defaultSupport.appendingPathComponent("Documents", isDirectory: true)
        #else
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        #endif
    }
    static func root(_ name: String) -> URL {
        if let value = UserDefaults.standard.string(forKey: "PulseCanvas.backup.active.v1"), let id = UUID(uuidString: value) {
            return backupRoot.appendingPathComponent("Restores/\(id.uuidString)/\(name)", isDirectory: true)
        }
        return name == "Documents" ? defaultDocuments
            : defaultSupport
    }
    static var documents: URL { root("Documents") }
    static var support: URL { root("Support") }
}

/// Retain a balanced sandbox lease for the complete lifetime of an audio read
/// or asynchronous export. Non-sandboxed development URLs need no lease.
final class SecurityScopedAccess {
    let url: URL
    private let didStart: Bool

    init(url: URL) {
        self.url = url
        didStart = url.startAccessingSecurityScopedResource()
    }

    deinit {
        if didStart { url.stopAccessingSecurityScopedResource() }
    }

    static func resolve(bookmark: Data?, fallback: URL) -> URL {
        guard let bookmark else { return fallback }
        var stale = false
        // A stale bookmark can still resolve. The audio controller refreshes
        // the bookmark while the resolved resource is accessible.
        #if os(macOS)
        let options: URL.BookmarkResolutionOptions = [.withSecurityScope, .withoutUI]
        #else
        let options: URL.BookmarkResolutionOptions = [.withoutUI]
        #endif
        return (try? URL(resolvingBookmarkData: bookmark, options: options,
                         relativeTo: nil, bookmarkDataIsStale: &stale)) ?? fallback
    }

    func readOnlyBookmark() throws -> Data {
        #if os(macOS)
        let options: URL.BookmarkCreationOptions = [.withSecurityScope, .securityScopeAllowOnlyReadAccess]
        #else
        let options: URL.BookmarkCreationOptions = []
        #endif
        return try url.bookmarkData(options: options,
                             includingResourceValuesForKeys: nil, relativeTo: nil)
    }
}
