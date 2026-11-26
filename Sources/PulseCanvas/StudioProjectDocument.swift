#if os(macOS)
import Foundation

@MainActor
extension StudioStore {
    func document(audio: AudioController, render: RenderState, exporter: SocialExportController,
                  library suppliedLibrary: ProjectMPresets? = nil) -> CreatorProject {
        let library = suppliedLibrary ?? .shared
        var appearances = presets
        appearances[render.scene] = preset(render)
        let bundled = BundledSoundtrack.identifier(for: audio.selectedURL)
        return CreatorProject(soundtrack: bundled == nil ? audio.selectedURL : nil,
                              scene: render.scene, appearance: preset(render), aspect: exporter.aspect.rawValue,
                              resolution: exporter.resolution, fps: exporter.fps, timeline: segments,
                              studioEnabled: isStudio, visualPresets: appearances, barsPerSection: barsPerSection,
                              effectIdentities: library.identities(for: Set(appearances.keys).union(segments.map(\.scene))),
                              bundledSoundtrack: bundled, soundtrackBookmark: audio.soundtrackBookmark,
                              loopPlayback: audio.loopEnabled, cloudProjectID: cloudProjectID, generationSeed: generationSeed)
    }

    func applyDocument(_ project: CreatorProject, aspect: SocialAspect, audio: AudioController,
                       render: RenderState, exporter: SocialExportController) {
        cloudProjectID = project.cloudProjectID
        generationSeed = project.generationSeed
        if let appearances = project.visualPresets { presets = appearances }
        segments = project.timeline ?? []
        isStudio = project.studioEnabled ?? false
        render.scene = project.scene
        apply(project.appearance, to: render)
        selectedSegment = 0
        barsPerSection = project.barsPerSection ?? 4
        detectedBPM = audio.segmentPlan(beatsPerSection: beatsPerSection)?.bpm
        exporter.aspect = aspect
        exporter.resolution = project.resolution
        exporter.fps = project.fps
        if let loop = project.loopPlayback { audio.loopEnabled = loop }
        follow(time: audio.playbackSeconds, render: render)
    }
}

@MainActor
extension CreatorProject {
    func checkedAspect() throws -> SocialAspect {
        guard version == 1, RenderState.sceneNames.indices.contains(scene), appearance.isValid,
              SocialExportController.supportedResolutions.contains(resolution),
              SocialExportController.supportedFrameRates.contains(fps),
              let aspect = SocialAspect(rawValue: aspect),
              barsPerSection.map({ (1...(Int.max / 4)).contains($0) }) ?? true,
              StudioTimeline.valid(timeline ?? [], sceneCount: RenderState.sceneNames.count),
              visualPresets?.allSatisfy({ RenderState.sceneNames.indices.contains($0.key) && $0.value.isValid }) ?? true
        else { throw CocoaError(.fileReadCorruptFile) }
        return aspect
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}
#endif
