import Foundation

@main struct VisionTransportSmoke {
    @MainActor static func main() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("VisionStudio-test-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let studio = VisionStudio(directory: directory)
        studio.volume = 0
        await studio.importAudio(URL(fileURLWithPath: "Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3"))
        precondition(studio.message == nil && studio.transport.duration > 30 && !studio.loading)
        precondition(studio.project.clips.count > 1 && studio.project.beatBoundaries != nil)
        let first = studio.project.clips[0]
        studio.bars(2, clip: first.id)
        precondition(studio.project.clips[0].bars == 2)
        studio.assign(22); studio.updateLook { $0.chaos = 0.91; $0.palette = 3 }
        precondition(studio.render.scene == 22 && studio.render.chaos == 0.91 && studio.render.palette == 3)
        let count = studio.project.clips.count
        studio.addClip(); precondition(studio.project.clips.count == count + 1)
        studio.assign(22); precondition(studio.look.chaos == 0.91)
        studio.moveClip(1); studio.removeClip(); precondition(studio.project.clips.count == count)
        studio.seek(8); precondition(abs(studio.transport.seconds - 8) < 0.05)
        precondition(studio.render.audioBands.contains { $0 > 0 })
        studio.togglePlayback()
        try await Task.sleep(for: .milliseconds(350))
        precondition(studio.transport.playing && (studio.render.playbackTime ?? 0) > 8.1)
        studio.suspend(); precondition(!studio.transport.playing && studio.render.paused)
        let restored = VisionStudio(directory: directory)
        restored.volume = 0; await restored.start()
        precondition(restored.message == nil && restored.project.looks[22]?.chaos == 0.91)
        precondition(restored.project.clips.count == count && restored.transport.duration > 30)
        let filesBefore = Set(try FileManager.default.contentsOfDirectory(atPath: directory.path))
        let loaded = await studio.loadRadioAudio(URL(fileURLWithPath: "Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3"), title: "Cached Radio test")
        precondition(loaded && studio.project.audioTitle == "Cached Radio test" && studio.project.audioFile == nil)
        let filesAfter = Set(try FileManager.default.contentsOfDirectory(atPath: directory.path))
        precondition(filesAfter == filesBefore,
                     "Radio playback must not duplicate cached audio on each song")
        precondition(!studio.transport.playing && studio.render.audioBands.count == 32)
        print("PASS cached Radio audio: title, analysis, paused start, no duplicate audio copies")
        print("PASS Vision transport: actual soundtrack import/analysis, per-scene bars, shared appearance, add/move/remove, seek, playback clock/audio bands, pause and autosave restoration")
    }
}
