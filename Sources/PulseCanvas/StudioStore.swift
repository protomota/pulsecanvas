import Foundation
import SwiftUI

struct VisualPreset: Codable, Equatable {
    var isValid: Bool {
        [speed, brightness, particleSize, fog, rotation, zoom, motionBlur, strobeSensitivity, strobeStrength, chaos, liquidDetail, zoomSpeed].allSatisfy { $0.isFinite } && (0...4).contains(palette) && (0...1).contains(chaos) && (0...1).contains(liquidDetail) && (0...3).contains(zoomSpeed) && (1...12).contains(haloCount)
    }
    var speed: Float = 1
    var brightness: Float = 1
    var particleSize: Float = 1
    var palette: Int = 0
    var fog: Float = 0.5
    var rotation: Float = 0
    var zoom: Float = 1
    var motionBlur: Float = 0
    var strobeEnabled = false
    var strobeSensitivity: Float = 1
    var strobeStrength: Float = 1
    var chaos: Float = 0.5
    var liquidDetail: Float = 0.6
    var zoomSpeed: Float = 1.5
    var haloCount: Int = 6
}

// Projects saved before the Chaos control retain a balanced beat response.
extension VisualPreset {
    enum CodingKeys: String, CodingKey {
        case speed, brightness, particleSize, palette, fog, rotation, zoom, motionBlur
        case strobeEnabled, strobeSensitivity, strobeStrength, chaos, liquidDetail, zoomSpeed, haloCount
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(speed: try values.decode(Float.self, forKey: .speed),
                  brightness: try values.decode(Float.self, forKey: .brightness),
                  particleSize: try values.decode(Float.self, forKey: .particleSize),
                  palette: try values.decode(Int.self, forKey: .palette),
                  fog: try values.decode(Float.self, forKey: .fog),
                  rotation: try values.decode(Float.self, forKey: .rotation),
                  zoom: try values.decode(Float.self, forKey: .zoom),
                  motionBlur: try values.decode(Float.self, forKey: .motionBlur),
                  strobeEnabled: try values.decode(Bool.self, forKey: .strobeEnabled),
                  strobeSensitivity: try values.decode(Float.self, forKey: .strobeSensitivity),
                  strobeStrength: try values.decode(Float.self, forKey: .strobeStrength),
                  chaos: try values.decodeIfPresent(Float.self, forKey: .chaos) ?? 0.5,
                  liquidDetail: try values.decodeIfPresent(Float.self, forKey: .liquidDetail) ?? 0.6,
                  zoomSpeed: try values.decodeIfPresent(Float.self, forKey: .zoomSpeed) ?? 1.5,
                  haloCount: try values.decodeIfPresent(Int.self, forKey: .haloCount) ?? 6)
    }
}

@MainActor
extension VisualPreset {
    /// One default profile serves the editor, reset and Studio export. Existing
    /// saved appearances take precedence; changing defaults cannot overwrite them.
    static func defaults(for scene: Int) -> VisualPreset {
        if scene >= RenderState.nativeSceneNames.count { return VisualPreset(chaos: 1, zoomSpeed: 0) }
        var result = VisualPreset()
        if let look = NativeEffects.effect(scene)?.look {
            result.palette = look.palette; result.particleSize = look.size
            result.speed = look.speed; result.zoomSpeed = look.zoomSpeed
            result.brightness = look.brightness; result.fog = look.fog
            result.liquidDetail = look.detail; result.chaos = look.chaos; result.zoom = look.zoom
        }
        return result
    }
}

struct CreatorProject: Codable {
    var version = 1
    var soundtrack: URL?
    var scene: Int
    var appearance: VisualPreset
    var aspect: String
    var resolution: Int
    var fps: Int
    var timeline: [StudioSegment]? = nil
    var studioEnabled: Bool? = nil
    var visualPresets: [Int: VisualPreset]? = nil
    var barsPerSection: Int? = nil
    var effectIdentities: [Int: String]? = nil
    var bundledSoundtrack: String? = nil
    // Same-app access on this Mac; other Macs ask the user to locate the track.
    var soundtrackBookmark: Data? = nil
    var loopPlayback: Bool? = nil
}

@MainActor
final class StudioStore: ObservableObject {
    @Published var isStudio = false
    @Published private(set) var visualizerRevealRequest = 0
    func requestVisualizerReveal() { visualizerRevealRequest &+= 1 }
    @Published var segments: [StudioSegment] = []
    @Published var selectedSegment = 0
    @Published var detectedBPM: Double?
    @Published var barsPerSection = 4
    var beatsPerSection: Int { barsPerSection * 4 }
    @Published var presets: [Int: VisualPreset] = [:] { didSet { persist() } }
    #if STORE_BUILD
    private let key = "PulseCanvas.metalStudio.v1"
    #else
    private let key = "PulseCanvas.studio.v1"
    #endif
    private let library: ProjectMPresets
    private let defaults: UserDefaults
    private struct Saved: Codable { var presets: [Int: VisualPreset]; var identities: [Int: String]? = nil }
    init(defaults: UserDefaults = .standard, library: ProjectMPresets? = nil) {
        self.defaults = defaults; self.library = library ?? .shared
        #if STORE_BUILD
        let savedData = defaults.data(forKey: key) ?? defaults.data(forKey: "PulseCanvas.studio.v1")
        #else
        let savedData = defaults.data(forKey: key)
        #endif
        if let data = savedData, let saved = try? JSONDecoder().decode(Saved.self, from: data) {
            if defaults.data(forKey: key + ".beforeOriginalOnly") == nil {
                defaults.set(data, forKey: key + ".beforeOriginalOnly")
            }
            #if STORE_BUILD
            var nativePresets: [Int: VisualPreset] = [:]
            for scene in saved.presets.keys.sorted() where !self.library.isRetiredScene(scene, identities: saved.identities) {
                if let native = try? self.library.migratedScene(scene, identities: saved.identities), nativePresets[native] == nil {
                    nativePresets[native] = saved.presets[scene]
                }
            }
            presets = nativePresets
            #else
            if let migrated = try? Self.migratedPresets(saved.presets, identities: saved.identities, library: self.library) {
                presets = migrated
            } else {
                // Keep the complete original data when an unavailable import prevents
                // migration. Never reinterpret an old external index as a new native ID.
                defaults.set(data, forKey: key + ".unresolved")
                var restored: [Int: VisualPreset] = [:]
                for (scene, appearance) in saved.presets where !self.library.isRetiredScene(scene, identities: saved.identities) {
                    if let resolved = try? self.library.migratedScene(scene, identities: saved.identities), restored[resolved] == nil {
                        restored[resolved] = appearance
                    }
                }
                presets = restored
            }
            #endif
        }
    }
    static func migratedPresets(_ presets: [Int: VisualPreset], identities: [Int: String]?, library: ProjectMPresets) throws -> [Int: VisualPreset] {
        var result: [Int: VisualPreset] = [:]
        for (scene, appearance) in presets where !library.isRetiredScene(scene, identities: identities) {
            let resolved = try library.migratedScene(scene, identities: identities)
            guard result[resolved] == nil else { throw CocoaError(.fileReadCorruptFile) }
            result[resolved] = appearance
        }
        return result
    }
    func preset(_ render: RenderState) -> VisualPreset {
        VisualPreset(speed: render.speed, brightness: render.brightness, particleSize: render.particleSize,
                     palette: render.palette, fog: render.fog, rotation: render.rotation, zoom: render.zoom,
                     motionBlur: render.motionBlur, strobeEnabled: render.strobeEnabled, strobeSensitivity: render.strobeSensitivity, strobeStrength: render.strobeStrength, chaos: render.chaos, liquidDetail: render.liquidDetail, zoomSpeed: render.zoomSpeed, haloCount: render.haloCount)
    }
    func save(_ render: RenderState) {
        let appearance = preset(render)
        guard presets[render.scene] != appearance else { return }
        presets[render.scene] = appearance
    }
    func applyCommonSettings(chaos: Float?, zoomSpeed: Float?, motionSpeed: Float?,
                             strobeEnabled: Bool? = nil, strobeSensitivity: Float? = nil,
                             strobeStrength: Float? = nil, render: RenderState) {
        guard [chaos, zoomSpeed, motionSpeed, strobeSensitivity, strobeStrength].compactMap({ $0 }).allSatisfy({ $0.isFinite }) else { return }
        guard chaos != nil || zoomSpeed != nil || motionSpeed != nil || strobeEnabled != nil || strobeSensitivity != nil || strobeStrength != nil else { return }
        var updated = presets
        updated[render.scene] = preset(render)
        for scene in self.library.availableScenes {
            var appearance = updated[scene] ?? defaultPreset(for: scene)
            if let chaos { appearance.chaos = min(1, max(0, chaos)) }
            if let zoomSpeed { appearance.zoomSpeed = min(3, max(0, zoomSpeed)) }
            if let motionSpeed { appearance.speed = min(3, max(0.05, motionSpeed)) }
            if let strobeEnabled { appearance.strobeEnabled = strobeEnabled }
            if let strobeSensitivity { appearance.strobeSensitivity = min(4, max(0.25, strobeSensitivity)) }
            if let strobeStrength { appearance.strobeStrength = min(1, max(0.1, strobeStrength)) }
            updated[scene] = appearance
        }
        presets = updated
        apply(to: render)
    }
    func makeTimeline(_ plan: SongSegmentation, render: RenderState) {
        save(render)
        let eligible = self.library.eligibleScenes
        let sequence = self.library.pool.enabled ? eligible : NativeEffects.timelineOrder
        guard !sequence.isEmpty else { segments = []; selectedSegment = 0; return }
        let previous = segments
        segments = zip(plan.boundaries, plan.boundaries.dropFirst()).enumerated().map { index, pair in
            StudioSegment(start: pair.0, end: pair.1,
                scene: previous.first(where: { abs($0.start - pair.0) < 0.05 && (!self.library.pool.enabled || eligible.contains($0.scene)) })?.scene ?? sequence[index % sequence.count], bars: barsPerSection)
        }
        detectedBPM = plan.bpm; selectedSegment = 0
    }
    func barCount(for segment: StudioSegment) -> Int {
        if let bars = segment.bars { return bars }
        let bpm = detectedBPM.flatMap { $0.isFinite && $0 > 0 ? $0 : nil } ?? 120
        let count = ((segment.end - segment.start) * bpm / 240).rounded()
        return Int(max(1, min(Double(Int.max / 4), count)))
    }

    /// Ripple later cards along the one-bar grid, preserving their visualizer order.
    /// A nil index applies the length to every card and sets the cadence for new cards.
    @discardableResult
    func setBars(_ bars: Int, at index: Int? = nil, grid: SongSegmentation, render: RenderState) -> Bool {
        guard bars > 0, bars <= Int.max / 4, !segments.isEmpty,
              index.map({ segments.indices.contains($0) }) ?? true else { return false }
        if let index, barCount(for: segments[index]) == bars { return false }
        let changed = rebuildBars(from: index ?? 0, grid: grid, render: render) { sourceIndex, original in
            index == nil || sourceIndex == index ? bars : original.map(self.barCount(for:)) ?? self.barsPerSection
        }
        if changed && index == nil { barsPerSection = bars }
        return changed
    }

    @discardableResult
    func randomizeBars(grid: SongSegmentation, render: RenderState, chooseLength: () -> Int = { Int.random(in: 1...8) }) -> Bool {
        rebuildBars(from: 0, grid: grid, render: render) { _, _ in chooseLength() }
    }

    private func rebuildBars(from first: Int, grid: SongSegmentation, render: RenderState,
                             length: (Int, StudioSegment?) -> Int) -> Bool {
        guard segments.indices.contains(first), grid.boundaries.count >= 2, grid.boundaries.first == 0,
              grid.boundaries.allSatisfy({ $0.isFinite }),
              zip(grid.boundaries, grid.boundaries.dropFirst()).allSatisfy({ $0 < $1 }),
              abs((grid.boundaries.last ?? 0) - (segments.last?.end ?? 0)) < 0.05 else { return false }
        let previous = segments
        var rebuilt = Array(previous.prefix(first))
        let start = previous[first].start
        var cursor = grid.boundaries.indices.min(by: {abs(grid.boundaries[$0] - start) < abs(grid.boundaries[$1] - start)}) ?? 0
        let last = grid.boundaries.count - 1
        var time = start, sourceIndex = first
        while time < grid.boundaries[last], rebuilt.count < 10_000 {
            let original = sourceIndex < previous.count ? previous[sourceIndex] : nil
            let bars = length(sourceIndex, original)
            guard bars > 0, bars <= Int.max / 4 else { return false }
            let next = cursor + min(bars, last - cursor)
            let end = grid.boundaries[next]
            guard end > time else { return false }
            rebuilt.append(StudioSegment(start: time, end: end,
                scene: original?.scene ?? previous.last!.scene, bars: bars))
            time = end; cursor = next; sourceIndex += 1
        }
        guard time == grid.boundaries[last] else { return false }
        save(render)
        segments = rebuilt
        detectedBPM = grid.bpm
        selectedSegment = min(selectedSegment, segments.count - 1)
        follow(time: render.playbackTime ?? 0, render: render)
        return true
    }
    func follow(time: Double, render: RenderState) {
        guard isStudio, let index = StudioTimeline.index(at: time, in: segments) else { return }
        if selectedSegment != index { selectedSegment = index }
        let scene = segments[index].scene
        if render.scene != scene {
            save(render); render.scene = scene; apply(to: render)
            requestVisualizerReveal()
        }
    }
    func selectScene(_ scene: Int, render: RenderState) {
        save(render)
        if isStudio && segments.indices.contains(selectedSegment) { segments[selectedSegment].scene = scene }
        render.scene = scene; apply(to: render)
    }
    /// The browser stays open and playback continues; only the containing clip changes.
    @discardableResult
    func assignAtPlayhead(_ time: Double, render: RenderState) -> Int? {
        guard time.isFinite, let index = StudioTimeline.index(at: time, in: segments) else { return nil }
        save(render)
        segments[index].scene = render.scene
        selectedSegment = index
        return index
    }
    @discardableResult
    func randomizeTimeline(_ render: RenderState) -> Bool {
        let library = self.library
        guard !segments.isEmpty, let scenes = StudioTimeline.randomizedScenes(current: segments.map(\.scene),
            favorites: [], available: library.eligibleScenes, allowRepeats: library.pool.enabled) else { return false }
        save(render)
        for index in segments.indices { segments[index].scene = scenes[index] }
        if segments.indices.contains(selectedSegment) {
            render.scene = segments[selectedSegment].scene; apply(to: render)
            requestVisualizerReveal()
        }
        return true
    }
    func randomizeSegment(at index: Int, render: RenderState) {
        guard segments.indices.contains(index) else { return }
        save(render)
        let library = self.library, occupied = Set(segments.map(\.scene))
        var choices = library.eligibleScenes.filter { !occupied.contains($0) }
        if choices.isEmpty && library.pool.enabled {
            choices = library.eligibleScenes.filter { $0 != segments[index].scene }
        }
        guard let scene = choices.randomElement() else { return }
        segments[index].scene = scene
        if selectedSegment == index { render.scene = scene; apply(to: render) }
    }
    /// Roll a clip's shared appearance without selecting it or seeking the soundtrack.
    func randomizeVisuals(at index: Int, render: RenderState) {
        guard segments.indices.contains(index) else { return }
        let scene = segments[index].scene
        if scene == render.scene {
            randomize(render)
        } else {
            let target = RenderState()
            target.scene = scene
            apply(to: target)
            randomize(target)
        }
    }
    func randomizeScene(_ render: RenderState) {
        if isStudio, segments.indices.contains(selectedSegment) {
            randomizeSegment(at: selectedSegment, render: render)
            requestVisualizerReveal()
            return
        }
        let candidates = self.library.eligibleScenes.filter { $0 != render.scene }
        guard let scene = candidates.randomElement() else { return }
        selectScene(scene, render: render)
        requestVisualizerReveal()
    }
    func randomize(_ render: RenderState) {
        render.chaos = Float.random(in: 0.1...1)
        render.liquidDetail = Float.random(in: 0.15...1)
        render.zoomSpeed = Float.random(in: 0.5...2.5)
        render.haloCount = Int.random(in: 2...12)
        render.speed = Float.random(in: 0.35...2.4)
        render.brightness = Float.random(in: 0.7...1.8)
        render.particleSize = Float.random(in: 1...2.8)
        render.palette = Int.random(in: 0...4)
        render.fog = Float.random(in: 0.08...0.8)
        render.rotation = Float.random(in: -.pi...(.pi))
        render.zoom = Float.random(in: 0.6...1.55)
        render.motionBlur = Float.random(in: 0...0.45)
        render.strobeSensitivity = Float.random(in: 0.6...2.4)
        render.strobeStrength = Float.random(in: 0.35...1)
        // White flashes require the explicit toggle; never enable them randomly.
        save(render)
    }
    func apply(to render: RenderState) {
        apply(presets[render.scene] ?? defaultPreset(for: render.scene), to: render)
    }
    func reset(_ render: RenderState) {
        apply(defaultPreset(for: render.scene), to: render)
        save(render)
    }
    private func defaultPreset(for scene: Int) -> VisualPreset {
        VisualPreset.defaults(for: scene)
    }
    func apply(_ saved: VisualPreset, to render: RenderState) { saved.apply(to: render) }
    private func persist() {
        if let data = try? JSONEncoder().encode(Saved(presets: presets, identities: self.library.identities(for: Set(presets.keys)))) { defaults.set(data, forKey: key) }
    }
}

@MainActor
extension VisualPreset {
    func apply(to render: RenderState) {
        let saved = self
        render.chaos = saved.chaos
        render.liquidDetail = saved.liquidDetail
        render.zoomSpeed = saved.zoomSpeed
        render.haloCount = saved.haloCount
        render.speed = saved.speed; render.brightness = saved.brightness; render.particleSize = saved.particleSize
        render.palette = saved.palette; render.fog = saved.fog; render.rotation = saved.rotation
        render.zoom = saved.zoom; render.motionBlur = saved.motionBlur
        render.strobeEnabled = saved.strobeEnabled; render.strobeSensitivity = saved.strobeSensitivity; render.strobeStrength = saved.strobeStrength
    }
}

@MainActor
extension CreatorProject {
    func remapped(using library: ProjectMPresets) throws -> CreatorProject {
        var result = self
        result.scene = try library.migratedScene(scene, identities: effectIdentities)
        result.timeline = try timeline?.map { segment in
            var next = segment
            next.scene = try library.migratedScene(segment.scene, identities: effectIdentities)
            return next
        }
        if let visualPresets {
            result.visualPresets = try StudioStore.migratedPresets(visualPresets, identities: effectIdentities, library: library)
        }
        if library.isRetiredScene(scene, identities: effectIdentities) {
            result.appearance = result.visualPresets?[result.scene] ?? VisualPreset.defaults(for: result.scene)
        }
        result.effectIdentities = library.identities(for: Set(result.visualPresets?.keys.map { $0 } ?? []).union(result.timeline?.map(\.scene) ?? []).union([result.scene]))
        return result
    }
}
