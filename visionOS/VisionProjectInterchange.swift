import Foundation

@MainActor extension VisionProject {
    /// Use the Mac's actual Codable model and stable effect identities, not a parallel schema.
    static func openPortable(_ data: Data, library: ProjectMPresets = .shared) throws -> VisionProject {
        if let legacy = try? JSONDecoder().decode(VisionProject.self, from: data) { return try legacy.validated() }
        let source = try JSONDecoder().decode(CreatorProject.self, from: data).remapped(using: library)
        guard source.version == 1, source.appearance.isValid,
              [720, 1080, 2160].contains(source.resolution), [24, 30, 60, 120].contains(source.fps),
              SocialAspect(rawValue: source.aspect) != nil,
              StudioTimeline.valid(source.timeline ?? [], sceneCount: NativeEffects.all.count),
              source.visualPresets?.allSatisfy({ NativeEffects.all.indices.contains($0.key) && $0.value.isValid }) ?? true,
              source.bundledSoundtrack == nil || source.bundledSoundtrack == "pulsecanvas",
              source.soundtrack.map(\.isFileURL) ?? true else { throw CocoaError(.fileReadCorruptFile) }
        var project = VisionProject()
        project.macProject = try JSONEncoder().encode(source)
        project.exportAspect = source.aspect; project.exportResolution = source.resolution; project.exportFPS = source.fps
        project.loopPlayback = source.loopPlayback ?? true
        project.looks = (source.visualPresets ?? [:]).mapValues(VisionLook.init)
        project.looks[source.scene] = VisionLook(source.appearance)
        if let cuts = source.timeline, !cuts.isEmpty {
            project.clips = cuts.map { VisionClip(scene: $0.scene, bars: $0.bars ?? source.barsPerSection ?? 4) }
            project.importedTimeline = cuts
        } else { project.clips = [VisionClip(scene: source.scene, bars: source.barsPerSection ?? 4)] }
        if source.bundledSoundtrack == nil {
            // A Mac sandbox bookmark cannot grant access on another device.
            project.externalAudioURL = source.soundtrack ?? URL(fileURLWithPath: "/Missing soundtrack")
            project.audioTitle = source.soundtrack?.deletingPathExtension().lastPathComponent ?? "Soundtrack"
        }
        return try project.validated()
    }

    func portableData(duration: Double, scene: Int) throws -> Data {
        let valid = try validated()
        let saved = macProject.flatMap { try? JSONDecoder().decode(CreatorProject.self, from: $0) }
        let appearance = valid.looks[scene] ?? VisionLook(scene: scene)
        let project = CreatorProject(soundtrack: externalAudioURL, scene: scene,
            appearance: appearance.preset, aspect: exportAspect ?? saved?.aspect ?? SocialAspect.wide.rawValue,
            resolution: exportResolution ?? saved?.resolution ?? 1080, fps: exportFPS ?? saved?.fps ?? 60,
            timeline: valid.segments(duration: duration), studioEnabled: true,
            visualPresets: valid.looks.mapValues(\.preset), barsPerSection: valid.clips.first?.bars ?? 4,
            effectIdentities: Dictionary(uniqueKeysWithValues: Set(valid.looks.keys).union(valid.clips.map(\.scene)).union([scene])
                .map { ($0, "native:\($0)") }),
            bundledSoundtrack: externalAudioURL == nil ? "pulsecanvas" : nil, loopPlayback: loopPlayback)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(project)
    }
}
