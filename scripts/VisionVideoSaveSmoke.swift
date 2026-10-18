import Foundation

@main struct VisionVideoSaveSmoke {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("Vision-save-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let cache = root.appendingPathComponent("Cache")
        let work = root.appendingPathComponent("Work")
        try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
        let source = work.appendingPathComponent("PulseCanvas Video.mp4")
        let bytes = Data(repeating: 0x71, count: 2_000_000)
        try bytes.write(to: source)
        let retained = try VisionVideoFile.retain(source, in: cache)
        try FileManager.default.removeItem(at: work)
        // The original render workspace can disappear while the picker is open.
        precondition(VisionVideoFile.recover(in: cache) == retained && (try? Data(contentsOf: retained)) == bytes)
        let sameFile = try VisionVideoFile.retain(retained, in: cache)
        precondition(sameFile == retained)
        let replacement = root.appendingPathComponent("Replacement.mp4")
        let second = Data(repeating: 0x62, count: 300_000)
        try second.write(to: replacement)
        _ = try VisionVideoFile.retain(replacement, in: cache)
        precondition((try? Data(contentsOf: retained)) == second)
        let empty = root.appendingPathComponent("Empty.mp4"); try Data().write(to: empty)
        do { _ = try VisionVideoFile.retain(empty, in: cache); fatalError("Empty movie accepted") } catch {}
        precondition((try? Data(contentsOf: retained)) == second, "Failed render must not replace the last completed movie")
        do { try VisionVideoFile.validate(root.appendingPathComponent("Missing.mp4")); fatalError("Missing movie accepted") } catch {}
        do { try VisionVideoFile.validate(root); fatalError("Directory accepted") } catch {}
        let legacy = root.appendingPathComponent("Legacy")
        let oldWork = legacy.appendingPathComponent("Vision-video-previous-build")
        try FileManager.default.createDirectory(at: oldWork, withIntermediateDirectories: true)
        try bytes.write(to: oldWork.appendingPathComponent("PulseCanvas Video.mp4"))
        let unrelated = legacy.appendingPathComponent("Unrelated.mp4"); try second.write(to: unrelated)
        let recoveredCache = root.appendingPathComponent("Recovered")
        let recovered = VisionVideoFile.recoverPreviousRender(in: legacy, cache: recoveredCache)!
        precondition((try? Data(contentsOf: recovered)) == bytes)
        precondition(FileManager.default.fileExists(atPath: unrelated.path))
        precondition(VisionVideoFile.recoverPreviousRender(in: legacy, cache: recoveredCache) == recovered)
        print("PASS save handoff: on-disk movie survives workspace dismissal, cancellation/retry and recovery; replacement is atomic; missing/empty inputs preserve completed movie; build-4 recovery is scoped")
    }
}
