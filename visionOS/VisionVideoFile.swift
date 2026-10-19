import Foundation
import CryptoKit

/// A completed movie outlives the render sheet, a canceled picker and app relaunch.
enum VisionVideoFile {
    static var directory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PulseCanvas-Completed-Video", isDirectory: true)
    }
    static func validate(_ url: URL) throws {
        guard url.isFileURL, url.pathExtension.lowercased() == "mp4" else { throw CocoaError(.fileReadCorruptFile) }
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard values.isRegularFile == true, (values.fileSize ?? 0) > 0 else { throw CocoaError(.fileReadCorruptFile) }
    }
    /// The same rendered file saved again is one export, including after reopening the sheet.
    static func saveIdentity(_ url: URL) throws -> UUID {
        var current = url
        current.removeAllCachedResourceValues()
        try validate(current)
        let values = try FileManager.default.attributesOfItem(atPath: current.path)
        // Atomic replacement may preserve the old modification date and byte count.
        // The local file identity still distinguishes a newly rendered replacement.
        let signature = "\(values[.systemNumber] ?? "")|\(values[.systemFileNumber] ?? "")|\(values[.size] ?? 0)|\(values[.modificationDate] ?? "")"
        let bytes = Array(SHA256.hash(data: Data(signature.utf8)).prefix(16))
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
    static func recover(in directory: URL = Self.directory) -> URL? {
        let url = directory.appendingPathComponent("PulseCanvas Video.mp4")
        do { try validate(url); return url } catch { return nil }
    }
    /// Build 4 finished the movie in this temporary folder before its picker crashed.
    /// Its final filename appears only after both encoding and audio muxing complete.
    static func recoverPreviousRender(in temporary: URL = FileManager.default.temporaryDirectory,
                                      cache: URL = Self.directory) -> URL? {
        if let existing = recover(in: cache) { return existing }
        let folders = (try? FileManager.default.contentsOfDirectory(at: temporary,
            includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)) ?? []
        let candidates = folders.filter { $0.lastPathComponent.hasPrefix("Vision-video-") }
            .map { $0.appendingPathComponent("PulseCanvas Video.mp4") }
            .filter { (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true }
            .sorted { ((try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
                > ((try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) }
        for url in candidates { if let retained = try? retain(url, in: cache) { return retained } }
        return nil
    }
    static func retain(_ source: URL, in directory: URL = Self.directory) throws -> URL {
        try validate(source)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appendingPathComponent("PulseCanvas Video.mp4")
        if source.standardizedFileURL == destination.standardizedFileURL { return destination }
        if FileManager.default.fileExists(atPath: destination.path) {
            _ = try FileManager.default.replaceItemAt(destination, withItemAt: source)
        } else { try FileManager.default.moveItem(at: source, to: destination) }
        return destination
    }
}
