import Foundation

enum BundledSoundtrack {
    static let identifier = "pulsecanvas"

    static var url: URL? {
        let candidates = [
            Bundle.module.url(forResource: "PulseCanvas", withExtension: "mp3", subdirectory: "Resources/Audio"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3")
        ]
        return candidates.compactMap { $0 }.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    static func identifier(for soundtrack: URL?) -> String? {
        guard let soundtrack, let bundled = url,
              soundtrack.standardizedFileURL == bundled.standardizedFileURL else { return nil }
        return identifier
    }

    /// A bundled track uses a stable project reference, independent of where
    /// the application is installed on this or another Mac.
    static func resolve(identifier: String?, externalURL: URL?) throws -> URL? {
        guard let identifier else { return externalURL }
        guard identifier == Self.identifier else { throw CocoaError(.fileReadCorruptFile) }
        guard let url else { throw CocoaError(.fileReadNoSuchFile) }
        return url
    }
}
