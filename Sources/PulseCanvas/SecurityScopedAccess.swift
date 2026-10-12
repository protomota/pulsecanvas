import Foundation

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
        return (try? URL(resolvingBookmarkData: bookmark,
                         options: [.withSecurityScope, .withoutUI],
                         relativeTo: nil, bookmarkDataIsStale: &stale)) ?? fallback
    }

    func readOnlyBookmark() throws -> Data {
        try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                             includingResourceValuesForKeys: nil, relativeTo: nil)
    }
}
