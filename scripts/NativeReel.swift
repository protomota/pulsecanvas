import AppKit
@preconcurrency import AVFoundation
import Foundation

/// Exports a labeled-ready motion reel through the real Studio exporter: one section per
/// design over a continuous excerpt of the bundled soundtrack.
///   native-reel.sh --scenes 31-99 --seconds 3 --start 20 --aspect wide --resolution 720 --fps 30 --out reel.mp4 [--chaos 0]
@main struct NativeReel {
    @MainActor static func main() async {
        NSApplication.shared.setActivationPolicy(.accessory)
        do { try await run(CommandLine.arguments) } catch { print("FAIL: \(error.localizedDescription)"); exit(1) }
    }

    /// Writes a looping excerpt; the file is closed when this returns, finalizing its header.
    static func writeExcerpt(from source: URL, start: Double, duration: Double, to target: URL) throws {
        let input = try AVAudioFile(forReading: source)
        let rate = input.processingFormat.sampleRate
        let songLength = Double(input.length) / rate
        var settings = input.processingFormat.settings
        settings[AVLinearPCMIsNonInterleaved] = false
        let writer = try AVAudioFile(forWriting: target, settings: settings)
        var remaining = duration, position = start
        while remaining > 0.001 {
            let chunk = min(remaining, songLength - position)
            input.framePosition = AVAudioFramePosition(position * rate)
            let count = AVAudioFrameCount(chunk * rate)
            let buffer = AVAudioPCMBuffer(pcmFormat: input.processingFormat, frameCapacity: count)!
            try input.read(into: buffer, frameCount: count)
            try writer.write(from: buffer)
            remaining -= chunk; position = 0
        }
    }

    @MainActor static func run(_ arguments: [String]) async throws {
        var scenes: [Int] = [], seconds = 3.0, start = 20.0, resolution = 720, fps = 30
        var aspect = SocialAspect.wide, output = ".build/reels/reel.mp4"
        var chaos: Float? = nil, zoomSpeed: Float? = nil
        var variedOrder = false
        var index = 1
        while index + 1 < arguments.count {
            let key = arguments[index], value = arguments[index + 1]
            switch key {
            case "--scenes":
                scenes = value.split(separator: ",").flatMap { part -> [Int] in
                    let bounds = part.split(separator: "-").compactMap { Int($0) }
                    return bounds.count == 2 ? Array(bounds[0]...bounds[1]) : bounds
                }.filter { !NativeEffects.isRetired($0) }
            case "--seconds": seconds = Double(value) ?? seconds
            case "--start": start = Double(value) ?? start
            case "--resolution": resolution = Int(value) ?? resolution
            case "--fps": fps = Int(value) ?? fps
            case "--aspect": aspect = ["wide": .wide, "landscape": .landscape, "portrait": .portrait, "phone": .phone, "square": .square][value] ?? .wide
            case "--order": variedOrder = value == "varied"
            case "--chaos": chaos = Float(value)
            case "--zoom-speed": zoomSpeed = Float(value)
            case "--out": output = value
            default: throw ExportError("Unknown option \(key)")
            }
            index += 2
        }
        if scenes.isEmpty { scenes = NativeEffects.activeIDs }
        if variedOrder {
            // Reorder the demonstration only; render every effect's real defaults.
            var pending = scenes, ordered: [Int] = [], previous = -1
            while !pending.isEmpty {
                let index = pending.firstIndex { VisualPreset.defaults(for: $0).palette != previous } ?? 0
                let scene = pending.remove(at: index)
                ordered.append(scene); previous = VisualPreset.defaults(for: scene).palette
            }
            scenes = ordered
        }
        let destination = URL(fileURLWithPath: output)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        let duration = seconds * Double(scenes.count)
        let audio = destination.deletingPathExtension().appendingPathExtension("wav")
        try writeExcerpt(from: URL(fileURLWithPath: "Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3"), start: start, duration: duration, to: audio)
        let segments = scenes.enumerated().map { StudioSegment(start: Double($0.offset) * seconds, end: Double($0.offset + 1) * seconds, scene: $0.element) }
        var appearances: [Int: VisualPreset] = [:]
        for scene in scenes {
            var look = VisualPreset.defaults(for: scene)
            if let chaos { look.chaos = chaos }
            if let zoomSpeed { look.zoomSpeed = zoomSpeed }
            appearances[scene] = look
        }
        let preferencesKey = "PulseCanvas.videoFormat.v1"
        let savedFormat = UserDefaults.standard.data(forKey: preferencesKey)
        defer {
            if let savedFormat { UserDefaults.standard.set(savedFormat, forKey: preferencesKey) }
            else { UserDefaults.standard.removeObject(forKey: preferencesKey) }
        }
        let exporter = SocialExportController()
        exporter.aspect = aspect; exporter.resolution = resolution; exporter.fps = fps
        let began = ProcessInfo.processInfo.systemUptime
        await exporter.export(audioURL: audio, render: RenderState(), to: destination, segments: segments, appearances: appearances)
        guard exporter.exportedURL == destination else { throw ExportError(exporter.status) }
        let labels: [[String: Any]] = segments.map {
            let look = appearances[$0.scene]!
            return ["start": $0.start, "end": $0.end, "scene": $0.scene,
                    "palette": VisualPalette(rawValue: look.palette)!.title, "chaos": look.chaos,
                    "zoomSpeed": look.zoomSpeed, "speed": look.speed]
        }
        try JSONSerialization.data(withJSONObject: ["names": RenderState.nativeSceneNames, "segments": labels]).write(to: destination.deletingPathExtension().appendingPathExtension("json"))
        try? FileManager.default.removeItem(at: audio)
        print(String(format: "REEL %@: %d sections, %.0f s, %@ %dp %d fps, exported in %.1f s", destination.lastPathComponent, scenes.count, duration, aspect.rawValue, resolution, fps, ProcessInfo.processInfo.systemUptime - began))
    }
}
