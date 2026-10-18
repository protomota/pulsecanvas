import Foundation

@main struct VisionProjectSmoke {
    static func main() throws {
        let scenes = NativeEffects.activeIDs
        precondition(scenes.count == 336)
        for scene in scenes {
            precondition(VisionLook(scene: scene).isValid, "Invalid defaults: \(scene)")
            precondition(NativeEffects.category(for: scene) != "Other native")
        }
        var project = VisionProject()
        project.clips = [VisionClip(scene: scenes[0], bars: 4), VisionClip(scene: scenes[1], bars: 1),
                         VisionClip(scene: scenes[0], bars: 2)]
        project.looks[scenes[0]] = VisionLook(scene: scenes[0])
        project.looks[scenes[0]]?.chaos = 0.82
        project.beatBoundaries = (0...48).map { Double($0) * 0.5 }
        let saved = try JSONEncoder().encode(project.validated())
        let loaded = try JSONDecoder().decode(VisionProject.self, from: saved).validated()
        precondition(loaded.clips == project.clips && loaded.looks == project.looks)
        precondition(loaded.loopPlayback)
        var legacy = try JSONSerialization.jsonObject(with: saved) as! [String: Any]
        legacy.removeValue(forKey: "loopPlayback")
        let migrated = try JSONDecoder().decode(VisionProject.self, from: JSONSerialization.data(withJSONObject: legacy)).validated()
        precondition(migrated.loopPlayback && migrated.clips == project.clips && migrated.looks == project.looks)
        project.loopPlayback = false
        let nonlooping = try JSONDecoder().decode(VisionProject.self, from: JSONEncoder().encode(project))
        precondition(!nonlooping.loopPlayback)
        let segments = loaded.segments(duration: 24)
        precondition(segments.map(\.start) == [0, 8, 10] && segments.map(\.end) == [8, 10, 14])
        precondition(StudioTimeline.valid(segments, sceneCount: NativeEffects.all.count))
        precondition(segments[0].scene == segments[2].scene && loaded.looks[segments[2].scene]?.chaos == 0.82)
        project.beatBoundaries = nil; project.bpm = 120
        precondition(project.segments(duration: 11).map(\.end) == [8, 10, 11])
        for bpm in [120.0, 150, 180] {
            var timed = project
            timed.bpm = bpm
            timed.barBoundaries = (0...24).map { Double($0) * 240 / bpm }
            timed.clips = [VisionClip(scene: scenes[0], bars: 4), VisionClip(scene: scenes[1], bars: 1)]
            let ids = timed.clips.map(\.id)
            timed.fitTimeline(duration: 24 * 240 / bpm)
            precondition(abs(timed.segments(duration: 24 * 240 / bpm)[0].end - 960 / bpm) < 0.00001)
            precondition(Array(timed.clips.prefix(2)).map(\.id) == ids)
            for i in timed.clips.indices { timed.clips[i].bars = 1 }
            timed.fitTimeline(duration: 24 * 240 / bpm)
            let cuts = timed.segments(duration: 24 * 240 / bpm)
            precondition(cuts.count == 24 && cuts.last?.end == 24 * 240 / bpm)
            precondition(cuts.allSatisfy { abs(($0.end - $0.start) - 240 / bpm) < 0.00001 })
            precondition(Set(timed.clips.map(\.id)).count == timed.clips.count)
        }
        var oldLook = try JSONSerialization.jsonObject(with: JSONEncoder().encode(VisionLook(scene: scenes[0]))) as! [String: Any]
        for key in ["strobeEnabled", "strobeSensitivity", "strobeStrength", "rotation", "motionBlur", "haloCount"] { oldLook.removeValue(forKey: key) }
        let migratedLook = try JSONDecoder().decode(VisionLook.self, from: JSONSerialization.data(withJSONObject: oldLook))
        precondition(!migratedLook.strobeEnabled && migratedLook.strobeSensitivity == 1 && migratedLook.isValid)
        print("PASS 120/150/180 BPM: four bars = 16 beats, one-bar retiming fills song, unique card IDs and appearance migration")
        var padded = project
        padded.barBoundaries = [0, 2, 4, 6, 8, 10]
        padded.clips = [VisionClip(scene: scenes[0], bars: 1), VisionClip(scene: scenes[1], bars: 1)]
        padded.fitTimeline(duration: 10.05)
        precondition(padded.segments(duration: 10.05).last?.end == 10.05
            && StudioTimeline.valid(padded.segments(duration: 10.05), sceneCount: NativeEffects.all.count))
        func rejects(_ mutate: (inout VisionProject) -> Void) {
            var invalid = project; mutate(&invalid)
            do { _ = try invalid.validated(); fatalError("Invalid project accepted") } catch {}
        }
        rejects { $0.version = 99 }
        rejects { $0.clips = [] }
        rejects { $0.clips[1].id = $0.clips[0].id }
        rejects { $0.clips[0].bars = 0 }
        rejects { $0.clips[0].scene = Int.max }
        rejects { $0.audioFile = "../private.mp3" }
        rejects { $0.bpm = .nan }
        rejects { $0.beatBoundaries = [0, 1, 0.5] }
        rejects { $0.beatBoundaries = [1, 2] }
        rejects { $0.barBoundaries = [0] }
        rejects { $0.looks[scenes[0]]?.speed = .infinity }
        rejects { $0.looks[scenes[0]]?.palette = 99 }
        for retired in NativeEffects.all.indices where !scenes.contains(retired) {
            var legacy = project; legacy.clips[0].scene = retired
            let result = try legacy.validated()
            precondition(scenes.contains(result.clips[0].scene))
        }
        print("PASS Vision project: 336 defaults/categories, JSON round-trip, shared looks, mixed bar lengths, beat grid, clipping, invalid files and retired IDs")
    }
}
