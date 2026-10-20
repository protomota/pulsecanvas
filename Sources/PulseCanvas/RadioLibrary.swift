import CryptoKit
import Foundation
import Combine

struct RadioStation: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let description: String
    let catalog: String

    func resolvedURL(relativeTo directoryURL: URL) throws -> URL {
        guard let url = URL(string: catalog, relativeTo: directoryURL)?.absoluteURL else { throw RadioError.invalidCatalog }
        if directoryURL.isFileURL {
            guard url.isFileURL, url.resolvingSymlinksInPath().path.hasPrefix(directoryURL.deletingLastPathComponent().resolvingSymlinksInPath().path + "/") else { throw RadioError.invalidCatalog }
        } else {
            guard url.scheme == "https", url.host != nil, url.user == nil, url.password == nil else { throw RadioError.invalidCatalog }
        }
        return url
    }
}

struct RadioStationDirectory: Codable, Sendable {
    let version: Int
    let stations: [RadioStation]

    static func decode(_ data: Data, from url: URL) throws -> Self {
        guard data.count <= 2_000_000 else { throw RadioError.invalidCatalog }
        let directory = try JSONDecoder().decode(Self.self, from: data)
        guard directory.version == 1, (1...100).contains(directory.stations.count),
              Set(directory.stations.map(\.id)).count == directory.stations.count else { throw RadioError.invalidCatalog }
        for station in directory.stations {
            guard !station.id.isEmpty, station.id.count <= 80, !station.title.isEmpty else { throw RadioError.invalidCatalog }
            _ = try station.resolvedURL(relativeTo: url)
        }
        return directory
    }
}

struct RadioTrack: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let genre: String
    let duration: Double
    let audio: String
    let sha256: String
    let byteCount: Int

    func resolvedURL(relativeTo catalogURL: URL) throws -> URL {
        guard let url = URL(string: audio, relativeTo: catalogURL)?.absoluteURL else { throw RadioError.invalidCatalog }
        if catalogURL.isFileURL {
            let directory = catalogURL.deletingLastPathComponent().resolvingSymlinksInPath().path + "/"
            guard url.isFileURL, url.resolvingSymlinksInPath().path.hasPrefix(directory) else { throw RadioError.invalidCatalog }
        } else {
            guard url.scheme == "https", url.host != nil, url.user == nil, url.password == nil else { throw RadioError.invalidCatalog }
        }
        return url
    }
}

struct RadioCatalog: Codable, Sendable {
    let version: Int
    let title: String
    let tracks: [RadioTrack]

    static func decode(_ data: Data, from url: URL) throws -> RadioCatalog {
        guard data.count <= 2_000_000 else { throw RadioError.invalidCatalog }
        let catalog = try JSONDecoder().decode(Self.self, from: data)
        guard catalog.version == 1, !catalog.title.isEmpty,
              catalog.tracks.count <= 500, Set(catalog.tracks.map(\.id)).count == catalog.tracks.count else { throw RadioError.invalidCatalog }
        for track in catalog.tracks {
            guard UUID(uuidString: track.id) != nil, !track.title.isEmpty,
                  track.duration.isFinite, track.duration > 0, track.duration <= 7200,
                  (1...100_000_000).contains(track.byteCount), track.sha256.count == 64,
                  track.sha256.allSatisfy({ $0.isHexDigit && $0.isASCII }) else { throw RadioError.invalidCatalog }
            _ = try track.resolvedURL(relativeTo: url)
        }
        return catalog
    }
}

/// Keep enough source information to replay a favorite after changing stations
/// or relaunching. Song identities are independent of visualizer favorites.
struct FavoriteRadioSong: Codable, Identifiable, Sendable, Equatable {
    let track: RadioTrack
    let sourceURL: URL
    let catalogURL: URL
    let stationID: String
    let folderBookmark: Data?
    var id: String { track.id }

    var isValid: Bool {
        guard sourceURL.isFileURL || (sourceURL.scheme == "https" && sourceURL.host != nil && sourceURL.user == nil && sourceURL.password == nil),
              sourceURL.isFileURL == catalogURL.isFileURL,
              let data = try? JSONEncoder().encode(RadioCatalog(version: 1, title: "Favorite", tracks: [track])) else { return false }
        return (try? RadioCatalog.decode(data, from: catalogURL)) != nil
    }
}

enum RadioError: LocalizedError {
    case invalidCatalog, download, integrity, allUnavailable
    var errorDescription: String? {
        switch self {
        case .invalidCatalog: return "This radio catalog is invalid. Choose a version 1 catalog with HTTPS audio URLs."
        case .download: return "The radio library could not be downloaded. Check your connection and catalog URL."
        case .integrity: return "A radio track did not match the catalog. Refresh the library and try again."
        case .allUnavailable: return "None of the radio tracks could be played. Check the library and try again."
        }
    }
}

/// Content-addressed files remain available offline and never contain R2 credentials.
actor RadioLibrary {
    private let directory: URL
    init(directory: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("PulseCanvas/Radio/Audio", isDirectory: true)) { self.directory = directory }

    func catalog(at url: URL) async throws -> RadioCatalog {
        try RadioCatalog.decode(await document(at: url), from: url)
    }

    func stations(at url: URL) async throws -> RadioStationDirectory {
        try RadioStationDirectory.decode(await document(at: url), from: url)
    }

    /// Only a complete library can prove a song was removed. Genre subsets and
    /// failed requests must never delete favorites from other stations.
    func completeCatalog(at source: URL) async throws -> (catalog: RadioCatalog, url: URL, stationID: String) {
        if source.lastPathComponent == "stations.json" {
            let directory = try await stations(at: source)
            guard let all = directory.stations.first(where: { $0.id == "all-music" })
                    ?? (directory.stations.count == 1 ? directory.stations.first : nil) else { throw RadioError.invalidCatalog }
            let url = try all.resolvedURL(relativeTo: source)
            return (try await catalog(at: url), url, all.id)
        }
        return (try await catalog(at: source), source, "all-music")
    }

    private func document(at url: URL) async throws -> Data {
        let data: Data
        if url.isFileURL { data = try Data(contentsOf: url) }
        else {
            guard url.scheme == "https", url.host != nil, url.user == nil, url.password == nil else { throw RadioError.invalidCatalog }
            let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 30)
            let (body, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200,
                  response.url?.scheme == "https" else { throw RadioError.download }
            data = body
        }
        try Task.checkCancellation()
        guard data.count <= 2_000_000 else { throw RadioError.invalidCatalog }
        return data
    }

    func localAudio(for track: RadioTrack, catalogURL: URL) async throws -> URL {
        let source = try track.resolvedURL(relativeTo: catalogURL)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appendingPathComponent(track.sha256.lowercased() + ".m4a")
        if let data = try? Data(contentsOf: destination), valid(data, track: track) { return destination }
        let temporary: URL
        if source.isFileURL { temporary = source }
        else {
            let request = URLRequest(url: source, timeoutInterval: 90)
            let (downloaded, response) = try await URLSession.shared.download(for: request)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200,
                  response.url?.scheme == "https" else {
                try? FileManager.default.removeItem(at: downloaded)
                throw RadioError.download
            }
            temporary = downloaded
        }
        defer { if !source.isFileURL { try? FileManager.default.removeItem(at: temporary) } }
        try Task.checkCancellation()
        guard try temporary.resourceValues(forKeys: [.fileSizeKey]).fileSize == track.byteCount else { throw RadioError.integrity }
        let data = try Data(contentsOf: temporary, options: .mappedIfSafe)
        guard valid(data, track: track) else { throw RadioError.integrity }
        try data.write(to: destination, options: .atomic)
        return destination
    }

    private func valid(_ data: Data, track: RadioTrack) -> Bool {
        data.count == track.byteCount && SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() == track.sha256.lowercased()
    }
}

/// Browsing Studio music never switches Radio's station or starts its player.
@MainActor final class StudioMusicCatalog: ObservableObject {
    @Published private(set) var tracks: [RadioTrack] = []
    @Published private(set) var loading = false
    @Published private(set) var error: String?
    private let library: RadioLibrary
    private let source: URL
    private var catalogURL: URL?
    private let access: SecurityScopedAccess?

    init(source: URL, folderBookmark: Data? = nil, library: RadioLibrary = RadioLibrary()) {
        self.library = library
        let folder = SecurityScopedAccess.resolve(bookmark: folderBookmark, fallback: source.deletingLastPathComponent())
        self.source = source.isFileURL ? folder.appendingPathComponent(source.lastPathComponent) : source
        access = source.isFileURL ? SecurityScopedAccess(url: folder) : nil
    }

    func load() async {
        guard !loading else { return }
        loading = true; error = nil
        defer { loading = false }
        do {
            let complete = try await library.completeCatalog(at: source)
            try Task.checkCancellation()
            tracks = complete.catalog.tracks.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
            catalogURL = complete.url
        } catch is CancellationError { }
        catch { self.error = error.localizedDescription }
    }

    func matching(search: String, favoritesOnly: Bool, favoriteIDs: Set<String>) -> [RadioTrack] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return tracks.filter { track in
            (!favoritesOnly || favoriteIDs.contains(track.id)) &&
                (query.isEmpty || track.title.localizedStandardContains(query) || track.genre.localizedStandardContains(query))
        }
    }

    func audio(for track: RadioTrack) async throws -> URL {
        guard tracks.contains(track), let catalogURL else { throw RadioError.invalidCatalog }
        return try await library.localAudio(for: track, catalogURL: catalogURL)
    }
}

/// A Studio project owns its soundtrack copy, independent of Radio cache cleanup.
enum StudioMusicStorage {
    static func copy(_ source: URL, title: String, into directory: URL) throws -> URL {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " -_()"))
        let name = String(title.components(separatedBy: allowed.inverted).joined(separator: " ").prefix(100))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let folder = directory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let destination = folder.appendingPathComponent(name.isEmpty ? "Soundtrack" : name).appendingPathExtension(source.pathExtension)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: source, to: destination)
            return destination
        } catch { try? FileManager.default.removeItem(at: folder); throw error }
    }
}

/// Shuffle deals every track once before starting another round.
struct RadioQueue {
    private var remaining: [Int] = []
    mutating func reset() { remaining = [] }
    mutating func next(count: Int, current: Int?, shuffle: Bool, prioritized: Set<Int> = []) -> Int? {
        guard count > 0 else { return nil }
        if !shuffle { return current.map { ($0 + 1) % count } ?? 0 }
        // A manually selected song can still be in the bag. Count it as heard.
        if remaining.count == 1, remaining.last == current, count > 1 { remaining = [] }
        if remaining.isEmpty {
            let favorites = (0..<count).filter { prioritized.contains($0) }.shuffled()
            let others = (0..<count).filter { !prioritized.contains($0) }.shuffled()
            remaining = others + favorites
        }
        if count > 1, remaining.last == current,
           let alternate = remaining.indices.reversed().first(where: { remaining[$0] != current && prioritized.contains(remaining[$0]) == prioritized.contains(current ?? -1) })
                ?? remaining.indices.reversed().first(where: { remaining[$0] != current }) {
            remaining.swapAt(alternate, remaining.count - 1)
        }
        return remaining.popLast()
    }
}

/// Deal favorites once per song, then fill with non-favorites. Studio is independent.
enum RadioVisualSchedule {
    static func make(plan: SongSegmentation, pool: [Int], bars: Int,
                     favorites: Set<Int> = [], played: Set<Int> = [], previous: Int? = nil, repeatFavorites: Bool = false) -> [StudioSegment] {
        guard !pool.isEmpty else { return [] }
        let available = Array(Set(pool)).sorted()
        var preferred = available.filter { favorites.contains($0) && !played.contains($0) }.shuffled()
        let fillers = repeatFavorites ? available : available.filter { !favorites.contains($0) }
        var bag: [Int] = [], previous = previous, result: [StudioSegment] = []
        for (start, end) in zip(plan.boundaries, plan.boundaries.dropFirst()) {
            let scene: Int
            if preferred.last == previous,
               let alternate = preferred.firstIndex(where: { $0 != previous }) {
                preferred.swapAt(alternate, preferred.count - 1)
            }
            // A lone favorite can be the outgoing song's last visual. Open with
            // a different design, then deal that favorite later in the song.
            if let favorite = preferred.last, favorite != previous || available.count == 1 {
                scene = preferred.removeLast()
            }
            else {
                // If the entire gallery is favorited, hold the last design once
                // its unique choices run out rather than repeating favorites.
                guard !fillers.isEmpty else {
                    if let last = result.popLast() { result.append(StudioSegment(start: last.start, end: end, scene: last.scene, bars: last.bars)) }
                    continue
                }
                if bag.isEmpty {
                    bag = fillers.shuffled()
                    if bag.count > 1, bag.last == previous { bag.swapAt(0, bag.count - 1) }
                }
                scene = bag.removeLast()
            }
            result.append(StudioSegment(start: start, end: end, scene: scene, bars: bars))
            previous = scene
        }
        return result
    }
}
