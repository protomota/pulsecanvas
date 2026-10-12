import AppKit
@preconcurrency import AVFoundation
import Combine

@main struct ExportFeedbackSmoke {
    @MainActor static func main() async throws {
        _ = NSApplication.shared
        let root = URL(fileURLWithPath: ".build/export-feedback-validation")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let audio = root.appendingPathComponent("tone.wav")
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 44_100)!
        buffer.frameLength = 44_100
        for i in 0..<44_100 {
            let sample = Float(sin(Double(i) * 2 * .pi * 440 / 44_100) * 0.2)
            buffer.floatChannelData![0][i] = sample; buffer.floatChannelData![1][i] = sample
        }
        var settings = format.settings; settings[AVLinearPCMIsNonInterleaved] = false
        var file: AVAudioFile? = try AVAudioFile(forWriting: audio, settings: settings)
        try file?.write(from: buffer)
        file = nil
        let state = RenderState(); state.scene = 22
        let exporter = SocialExportController()
        exporter.fps = 24
        var previews = 0, counts: [Int] = [], statuses: [String] = []
        let previewObserver = exporter.$framePreview.sink { image in
            if let image { precondition(max(image.width, image.height) <= 480 && min(image.width, image.height) > 0); previews += 1 }
        }
        let countObserver = exporter.$renderedFrames.sink { counts.append($0) }
        let statusObserver = exporter.$status.sink { statuses.append($0) }
        for (aspect, resolution) in [(SocialAspect.wide,720),(.phone,2160),(.wide,2160)] {
            exporter.aspect = aspect; exporter.resolution = resolution
            previews = 0; counts = []; statuses = []
            if aspect == .wide && resolution == 2160 { state.scene = 23 }
            let began = ProcessInfo.processInfo.systemUptime
            var estimates: [Double] = []
            let estimateObserver = exporter.$estimatedSecondsRemaining.sink { if let value = $0 { precondition(value.isFinite && value > 0); estimates.append(value) } }
            let output = root.appendingPathComponent("\(resolution).mp4")
            await exporter.export(audioURL: audio, render: state, to: output)
            precondition(exporter.exportedURL == output && !exporter.isExporting && exporter.progress == 1)
            precondition(exporter.renderedFrames == 24 && exporter.totalFrames == 24 && previews >= 1)
            precondition(counts.first == 0 && counts.last == 24 && zip(counts,counts.dropFirst()).allSatisfy { $0 <= $1 })
            precondition(statuses.contains("Preparing export…") && statuses.contains("Finishing video…") && statuses.contains("Adding soundtrack…"))
            let duration = try await AVURLAsset(url: output).load(.duration).seconds
            precondition(abs(duration - 1) < 0.01)
            estimateObserver.cancel()
            precondition(exporter.estimatedSecondsRemaining == nil)
            print("TIMING: \(resolution) \(aspect.rawValue) scene \(state.scene): \(ProcessInfo.processInfo.systemUptime - began)s, \(estimates.count) estimates")
            print("PASS: \(resolution) \(aspect.rawValue) exposes actual small frame previews, exact 24-frame progress, finishing/audio stages, saved success and complete video")
        }
        let existing = root.appendingPathComponent("cancelled.mp4")
        let contents = Data("preserve existing file".utf8)
        try contents.write(to: existing)
        exporter.resolution = 720
        var requestedCancel = false
        let cancellationObserver = exporter.$progress.sink { progress in
            if exporter.isExporting && progress > 0.02 && !requestedCancel { requestedCancel = true; exporter.cancel() }
        }
        await exporter.export(audioURL: nil, render: state, to: existing)
        let retained = try Data(contentsOf: existing)
        precondition(requestedCancel && exporter.exportedURL == nil && exporter.status == "Export cancelled" && !exporter.isExporting && retained == contents)
        precondition(exporter.totalFrames == 360 && exporter.renderedFrames < 360)
        cancellationObserver.cancel()
        await exporter.export(audioURL: root.appendingPathComponent("missing.wav"), render: state, to: root.appendingPathComponent("failed.mp4"))
        precondition(exporter.exportedURL == nil && exporter.renderedFrames == 0 && exporter.totalFrames == 0 && exporter.framePreview == nil && exporter.status.hasPrefix("Export failed:"))
        withExtendedLifetime([previewObserver,countObserver,statusObserver]) {}
        print("PASS: cancelled/failed exports reset feedback and never signal success; cancellation preserves the destination")
    }
}
