import Foundation
import ZIPFoundation

extension UserBackup {
    /// ZIP64-capable storage avoids base64-encoding an entire music folder in memory.
    /// manifest.json is versioned structured metadata; every file has size and SHA-256.
    static func writeZIP(_ archive: Archive, to url: URL, deterministic: Bool = false) throws {
        try validate(archive)
        var completed = false
        defer { if !completed { try? FileManager.default.removeItem(at: url) } }
        let zip = try ZIPFoundation.Archive(url: url, accessMode: .create)
        let date = deterministic ? Calendar(identifier: .gregorian).date(from: DateComponents(year: 2000, month: 1, day: 1))! : Date()
        for file in archive.files {
            try zip.addEntry(with: file.path, type: .file, uncompressedSize: Int64(file.data.count), modificationDate: date) { offset, size in
                file.data.subdata(in: Int(offset)..<Int(offset) + size)
            }
        }
        var metadata = archive
        for index in metadata.files.indices { metadata.files[index].data = Data() }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let manifest = try encoder.encode(metadata)
        try zip.addEntry(with: "manifest.json", type: .file, uncompressedSize: Int64(manifest.count), modificationDate: date) { offset, size in
            manifest.subdata(in: Int(offset)..<Int(offset) + size)
        }
        completed = true
    }

    static func readZIP(_ url: URL, workspace: URL) throws -> Archive {
        let zip = try ZIPFoundation.Archive(url: url, accessMode: .read)
        var entries: [Entry] = []
        for entry in zip {
            guard entries.count < 20_001 else { throw fail(String(localized: "Too many backup files.")) }
            entries.append(entry)
        }
        guard entries.count <= 20_001, Set(entries.map { $0.path.lowercased() }).count == entries.count,
              entries.allSatisfy({ $0.type == .file && !$0.isCompressed && $0.compressedSize == $0.uncompressedSize
                  && ($0.path == "manifest.json" || safePath($0.path)) }),
              let manifestEntry = zip["manifest.json"], manifestEntry.uncompressedSize < 32_000_000 else { throw fail(String(localized: "Invalid backup ZIP contents.")) }
        var manifest = Data()
        let crc = try zip.extract(manifestEntry) { chunk in manifest.append(chunk) }
        guard crc == manifestEntry.checksum else { throw fail(String(localized: "Damaged backup manifest.")) }
        var archive = try JSONDecoder().decode(Archive.self, from: manifest)
        guard archive.format == format, archive.version == 1, archive.files.count + 1 == entries.count,
              Set(archive.files.map { $0.path.lowercased() }).count == archive.files.count else { throw fail(String(localized: "Choose a supported PulseCanvas backup ZIP.")) }
        var total = 0
        for file in archive.files {
            guard safePath(file.path), file.data.isEmpty, file.byteCount >= 0, file.byteCount <= maximumSourceBytes,
                  let entry = zip[file.path], entry.uncompressedSize == UInt64(file.byteCount) else { throw fail(String(localized: "A backup file is missing or has an invalid size.")) }
            total += file.byteCount
            guard total <= maximumSourceBytes else { throw fail(String(localized: "This backup exceeds 100 GB.")) }
        }
        // Check parent/file conflicts before creating any paths. Only our own fresh
        // private workspace is used; never extract directly into the user's data.
        let paths = Set(archive.files.map { $0.path.lowercased() })
        for path in paths {
            var parts = path.split(separator: "/"); parts.removeLast()
            while parts.count > 1 {
                guard !paths.contains(parts.joined(separator: "/")) else { throw fail(String(localized: "Conflicting backup paths.")) }
                parts.removeLast()
            }
        }
        guard !FileManager.default.fileExists(atPath: workspace.path) else { throw fail(String(localized: "The backup workspace is already in use.")) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        var complete = false
        defer { if !complete { try? FileManager.default.removeItem(at: workspace) } }
        for index in archive.files.indices {
            let file = archive.files[index], destination = workspace.appendingPathComponent(file.path)
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            let entry = zip[file.path]!
            let checksum = try zip.extract(entry, to: destination)
            guard checksum == entry.checksum else { throw fail(String(localized: "A backup file is damaged.")) }
            archive.files[index].data = try Data(contentsOf: destination, options: .alwaysMapped)
        }
        try validate(archive)
        complete = true
        return archive
    }
}
