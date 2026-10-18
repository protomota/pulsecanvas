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
    init(scene: Int) {
        let look = NativeEffects.all[NativeEffects.resolved(scene)].look
        zoom = look.zoom
        speed = look.speed; zoomSpeed = look.zoomSpeed; chaos = look.chaos
        brightness = look.brightness; size = look.size; detail = look.detail; fog = look.fog; palette = look.palette
    }
    var isValid: Bool {
        [zoom, speed, zoomSpeed, chaos, brightness, size, detail, fog].allSatisfy(\.isFinite)
            && (0.1...3).contains(zoom) && (0...3).contains(speed) && (0...3).contains(zoomSpeed) && (0...1).contains(chaos)
            && (0.1...3).contains(brightness) && (0.1...3).contains(size)
            && (0...1).contains(detail) && (0...1).contains(fog) && (0...4).contains(palette)
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

    func validated() throws -> Self {
        guard version == 1, (1...500).contains(clips.count), Set(clips.map(\.id)).count == clips.count,
              bpm.isFinite, (20...300).contains(bpm),
              clips.allSatisfy({ NativeEffects.all.indices.contains($0.scene) && (1...64).contains($0.bars) }),
              looks.allSatisfy({ NativeEffects.all.indices.contains($0.key) && $0.value.isValid }),
              audioFile.map({ !$0.contains("/") && !$0.contains("\\") && $0 != "." && $0 != ".." }) ?? true,
              beatBoundaries.map({ beats in
                  !beats.isEmpty && beats.count <= 100_000 && beats.first == 0
                    && beats.allSatisfy { $0.isFinite && (0...86_400).contains($0) }
                    && zip(beats, beats.dropFirst()).allSatisfy { $0 < $1 }
              }) ?? true else {
            throw CocoaError(.fileReadCorruptFile)
        }
        var result = self
        result.clips = clips.map { var clip = $0; clip.scene = NativeEffects.resolved(clip.scene); return clip }
        return result
    }

    func segments(duration: Double) -> [StudioSegment] {
        guard duration.isFinite, duration > 0 else { return [] }
        var start = 0.0
        var beat = 0
        return clips.compactMap { clip in
            guard start < duration else { return nil }
            beat += clip.bars * 4
            let end = min(duration, beatBoundaries.map { $0.indices.contains(beat) ? $0[beat] : duration }
                ?? (start + Double(clip.bars) * 240 / bpm))
            defer { start = end }
            return StudioSegment(start: start, end: end, scene: clip.scene, bars: clip.bars)
        }
    }
}

#if !os(tvOS)
extension UTType {
    static let pulseVision = UTType(exportedAs: "com.protomota.pulsecanvas.vision-project", conformingTo: .json)
}

struct VisionProjectDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pulseVision, .json] }
    var project: VisionProject
    init(project: VisionProject) { self.project = project }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents, data.count < 4_000_000 else { throw CocoaError(.fileReadCorruptFile) }
        project = try JSONDecoder().decode(VisionProject.self, from: data).validated()
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try JSONEncoder().encode(project.validated()))
    }
}

#endif
