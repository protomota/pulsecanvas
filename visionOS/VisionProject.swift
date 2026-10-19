import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct VisionLook: Codable, Equatable {
    var zoom: Float
    var speed: Float
    var zoomSpeed: Float
    var chaos: Float
    var brightness: Float
    var size: Float
    var detail: Float
    var fog: Float
    var palette: Int
    var rotation: Float = 0
    var motionBlur: Float = 0
    var haloCount = 6
    var strobeEnabled = false
    var strobeSensitivity: Float = 1
    var strobeStrength: Float = 1
    init(scene: Int) {
        let look = NativeEffects.all[NativeEffects.resolved(scene)].look
        zoom = look.zoom
        speed = look.speed; zoomSpeed = look.zoomSpeed; chaos = look.chaos
        brightness = look.brightness; size = look.size; detail = look.detail; fog = look.fog; palette = look.palette
    }
    var isValid: Bool {
        [zoom, speed, zoomSpeed, chaos, brightness, size, detail, fog, rotation, motionBlur, strobeSensitivity, strobeStrength].allSatisfy(\.isFinite)
            && (0.1...3).contains(zoom) && (0...3).contains(speed) && (0...3).contains(zoomSpeed) && (0...1).contains(chaos)
            && (0.1...3).contains(brightness) && (0.1...6).contains(size)
            && (0...1).contains(detail) && (0...1).contains(fog) && (0...4).contains(palette)
            && (0.25...4).contains(strobeSensitivity) && (0.1...1).contains(strobeStrength)
            && (1...12).contains(haloCount) && (0...1).contains(motionBlur)
    }

    private enum CodingKeys: String, CodingKey {
        case zoom, speed, zoomSpeed, chaos, brightness, size, detail, fog, palette
        case strobeEnabled, strobeSensitivity, strobeStrength
        case rotation, motionBlur, haloCount
    }
    init(from decoder: Decoder) throws {
        let v = try decoder.container(keyedBy: CodingKeys.self)
        zoom = try v.decode(Float.self, forKey: .zoom); speed = try v.decode(Float.self, forKey: .speed)
        zoomSpeed = try v.decode(Float.self, forKey: .zoomSpeed); chaos = try v.decode(Float.self, forKey: .chaos)
        brightness = try v.decode(Float.self, forKey: .brightness); size = try v.decode(Float.self, forKey: .size)
        detail = try v.decode(Float.self, forKey: .detail); fog = try v.decode(Float.self, forKey: .fog)
        palette = try v.decode(Int.self, forKey: .palette)
        strobeEnabled = try v.decodeIfPresent(Bool.self, forKey: .strobeEnabled) ?? false
        strobeSensitivity = try v.decodeIfPresent(Float.self, forKey: .strobeSensitivity) ?? 1
        strobeStrength = try v.decodeIfPresent(Float.self, forKey: .strobeStrength) ?? 1
        rotation = try v.decodeIfPresent(Float.self, forKey: .rotation) ?? 0
        motionBlur = try v.decodeIfPresent(Float.self, forKey: .motionBlur) ?? 0
        haloCount = try v.decodeIfPresent(Int.self, forKey: .haloCount) ?? 6
    }
}

struct VisionClip: Codable, Identifiable, Equatable {
    var id = UUID()
    var scene: Int
    var bars = 4
}

struct VisionProject: Codable {
    var version = 1
    var clips: [VisionClip] = [VisionClip(scene: NativeEffects.defaultScene)]
    /// The same native ID shares one appearance across every clip.
    var looks: [Int: VisionLook] = [:]
    var audioFile: String? = nil
    var audioTitle = "Demo soundtrack"
    var bpm = 120.0
    var beatBoundaries: [Double]? = nil
    /// Same four-beat bar grid used by Mac Studio; old beat grids remain decodable.
    var barBoundaries: [Double]? = nil
    var externalAudioURL: URL? = nil
    /// Preserve exact Mac cuts and fields not exposed in Vision's editor.
    var importedTimeline: [StudioSegment]? = nil
    var macProject: Data? = nil
    var exportAspect: String? = nil
    var exportResolution: Int? = nil
    var exportFPS: Int? = nil
    var loopPlayback = true

    init() {}

    private enum CodingKeys: String, CodingKey {
        case version, clips, looks, audioFile, audioTitle, bpm, beatBoundaries, barBoundaries, loopPlayback
        case externalAudioURL, importedTimeline, macProject
        case exportAspect, exportResolution, exportFPS
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decode(Int.self, forKey: .version)
        clips = try values.decode([VisionClip].self, forKey: .clips)
        looks = try values.decode([Int: VisionLook].self, forKey: .looks)
        audioFile = try values.decodeIfPresent(String.self, forKey: .audioFile)
        audioTitle = try values.decode(String.self, forKey: .audioTitle)
        bpm = try values.decode(Double.self, forKey: .bpm)
        beatBoundaries = try values.decodeIfPresent([Double].self, forKey: .beatBoundaries)
        barBoundaries = try values.decodeIfPresent([Double].self, forKey: .barBoundaries)
        externalAudioURL = try values.decodeIfPresent(URL.self, forKey: .externalAudioURL)
        importedTimeline = try values.decodeIfPresent([StudioSegment].self, forKey: .importedTimeline)
        macProject = try values.decodeIfPresent(Data.self, forKey: .macProject)
        exportAspect = try values.decodeIfPresent(String.self, forKey: .exportAspect)
        exportResolution = try values.decodeIfPresent(Int.self, forKey: .exportResolution)
        exportFPS = try values.decodeIfPresent(Int.self, forKey: .exportFPS)
        // Existing Studio projects gain looping without losing their scenes or looks.
        loopPlayback = try values.decodeIfPresent(Bool.self, forKey: .loopPlayback) ?? true
    }

    func validated() throws -> Self {
        guard version == 1, (1...10_000).contains(clips.count), Set(clips.map(\.id)).count == clips.count,
              bpm.isFinite, (20...300).contains(bpm),
              clips.allSatisfy({ NativeEffects.all.indices.contains($0.scene) && (1...64).contains($0.bars) }),
              looks.allSatisfy({ NativeEffects.all.indices.contains($0.key) && $0.value.isValid }),
              importedTimeline.map({ $0.count == clips.count && StudioTimeline.valid($0, sceneCount: NativeEffects.all.count) }) ?? true,
              externalAudioURL.map(\.isFileURL) ?? true,
              exportResolution.map({ [720, 1080, 2160].contains($0) }) ?? true,
              exportFPS.map({ [24, 30, 60, 120].contains($0) }) ?? true,
              audioFile.map({ !$0.contains("/") && !$0.contains("\\") && $0 != "." && $0 != ".." }) ?? true,
              [beatBoundaries, barBoundaries].allSatisfy({ $0.map({ beats in
                  beats.count >= 2 && beats.count <= 100_000 && beats.first == 0
                    && beats.allSatisfy { $0.isFinite && (0...86_400).contains($0) }
                    && zip(beats, beats.dropFirst()).allSatisfy { $0 < $1 }
              }) ?? true }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        var result = self
        result.clips = clips.map { var clip = $0; clip.scene = NativeEffects.resolved(clip.scene); return clip }
        return result
    }

    func segments(duration: Double) -> [StudioSegment] {
        guard duration.isFinite, duration > 0 else { return [] }
        if let importedTimeline {
            return zip(importedTimeline, clips).compactMap { cut, clip in
                guard cut.start < duration else { return nil }
                return StudioSegment(start: cut.start, end: min(duration, cut.end), scene: clip.scene, bars: clip.bars)
            }
        }
        var start = 0.0
        var bar = 0
        return clips.compactMap { clip in
            guard start < duration else { return nil }
            bar += clip.bars
            let end = sectionEnd(bar: bar, start: start, bars: clip.bars, duration: duration)
            defer { start = end }
            return StudioSegment(start: start, end: end, scene: clip.scene, bars: clip.bars)
        }
    }

    /// Fill the song after bar edits, retaining existing cards and IDs in order.
    mutating func fitTimeline(duration: Double) {
        guard duration.isFinite, duration > 0, !clips.isEmpty else { return }
        let previous = clips
        var result: [VisionClip] = [], cursor = 0, time = 0.0
        while time < duration, result.count < 10_000 {
            let i = result.count
            let clip = i < previous.count ? previous[i]
                : VisionClip(scene: previous[i % previous.count].scene, bars: previous.last!.bars)
            cursor += clip.bars
            let end = sectionEnd(bar: cursor, start: time, bars: clip.bars, duration: duration)
            guard end > time else { break }
            result.append(clip); time = end
        }
        if time == duration { clips = result }
    }
    /// Rebuild every cut on the bar grid, retaining card identities and visualizer order where possible.
    /// Work in a temporary array so an invalid length or capacity failure cannot leave a partial edit.
    @discardableResult mutating func randomizeBars(duration: Double, chooseLength: () -> Int) -> Bool {
        guard duration.isFinite, duration > 0, !clips.isEmpty else { return false }
        let previous = clips
        var result: [VisionClip] = [], cursor = 0, time = 0.0
        while time < duration, result.count < 10_000 {
            let index = result.count
            let bars = chooseLength()
            guard (1...8).contains(bars) else { return false }
            var clip = index < previous.count ? previous[index] : VisionClip(scene: previous[index % previous.count].scene)
            clip.bars = bars
            cursor += bars
            let end = sectionEnd(bar: cursor, start: time, bars: bars, duration: duration)
            guard end > time else { return false }
            result.append(clip); time = end
        }
        guard time == duration else { return false }
        clips = result; importedTimeline = nil
        return true
    }
    private func sectionEnd(bar: Int, start: Double, bars: Int, duration: Double) -> Double {
        // The audio player and analyzer can disagree slightly about decoder padding.
        // The terminal cut always uses the player's duration, without zero-length tail cards.
        if let grid = barBoundaries { return bar >= grid.count - 1 ? duration : min(duration, grid[bar]) }
        if let grid = beatBoundaries { return bar * 4 >= grid.count - 1 ? duration : min(duration, grid[bar * 4]) }
        return min(duration, start + Double(bars) * 240 / bpm)
    }
}

struct VisionCommonSettings {
    var bars: Int? = nil
    var chaos: Float? = nil
    var zoomSpeed: Float? = nil
    var motionSpeed: Float? = nil
    var strobeEnabled: Bool? = nil
    var strobeSensitivity: Float? = nil
    var strobeStrength: Float? = nil
    var isValid: Bool {
        (bars.map { (1...64).contains($0) } ?? true)
            && (chaos.map { $0.isFinite && (0...1).contains($0) } ?? true)
            && ([zoomSpeed, motionSpeed].allSatisfy { $0.map { $0.isFinite && (0...3).contains($0) } ?? true })
            && (strobeSensitivity.map { $0.isFinite && (0.25...4).contains($0) } ?? true)
            && (strobeStrength.map { $0.isFinite && (0.1...1).contains($0) } ?? true)
    }
}

#if !os(tvOS)
extension UTType {
    static let pulseVision = UTType(exportedAs: "com.protomota.pulsecanvas.vision-project", conformingTo: .json)
    static let pulseCanvas = UTType(exportedAs: "com.protomota.pulsecanvas.project", conformingTo: .json)
}

struct VisionProjectDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pulseCanvas, .pulseVision, .json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents, data.count < 4_000_000 else { throw CocoaError(.fileReadCorruptFile) }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

#endif
