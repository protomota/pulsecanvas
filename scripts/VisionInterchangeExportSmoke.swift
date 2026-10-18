import Foundation
@preconcurrency import AVFoundation
import Metal

@main struct VisionInterchangeExportSmoke {
    @MainActor static func main() async throws {
        let root = URL(fileURLWithPath: ProcessInfo.processInfo.environment["PULSECANVAS_VALIDATION_OUTPUT"]
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("PulseCanvas-Vision-export-validation").path)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let scenes = Array(NativeEffects.activeIDs.prefix(3))
        var native = VisionProject()
        native.clips = [VisionClip(scene: scenes[0], bars: 1), VisionClip(scene: scenes[1], bars: 2),
                        VisionClip(scene: scenes[2], bars: 1)]
        native.barBoundaries = [0, 1, 2, 3, 4]
        native.loopPlayback = false
        native.looks[scenes[0]] = VisionLook(scene: scenes[0])
        native.looks[scenes[0]]!.chaos = 0.87
        native.looks[scenes[0]]!.motionBlur = 0.2
        native.looks[scenes[0]]!.rotation = 0.7
        native.looks[scenes[0]]!.haloCount = 9
        native.looks[scenes[0]]!.strobeSensitivity = 1.6
        let data = try native.portableData(duration: 4, scene: scenes[0])
        let mac = try JSONDecoder().decode(CreatorProject.self, from: data).remapped(using: .shared)
        precondition(mac.version == 1 && mac.bundledSoundtrack == "pulsecanvas" && mac.fps == 60)
        precondition(mac.loopPlayback == false)
        precondition(mac.timeline?.map(\.end) == [1, 3, 4] && mac.timeline?.map(\.bars) == [1, 2, 1])
        precondition(StudioTimeline.valid(mac.timeline!, sceneCount: RenderState.sceneNames.count))
        precondition(mac.visualPresets?[scenes[0]] == native.looks[scenes[0]]!.preset)
        let reopened = try VisionProject.openPortable(data)
        precondition(reopened.clips.map(\.scene) == native.clips.map(\.scene))
        precondition(reopened.looks[scenes[0]] == native.looks[scenes[0]])
        precondition(!reopened.loopPlayback)
        precondition(reopened.segments(duration: 4).map(\.end) == [1, 3, 4])
        let again = try JSONDecoder().decode(CreatorProject.self, from: reopened.portableData(duration: 4, scene: scenes[0]))
        precondition(again.appearance == mac.appearance && again.aspect == mac.aspect && again.fps == mac.fps)
        var external = mac
        external.bundledSoundtrack = nil; external.soundtrack = URL(fileURLWithPath: "/Users/example/Music/Track.wav")
        let imported = try VisionProject.openPortable(JSONEncoder().encode(external))
        precondition(imported.externalAudioURL == external.soundtrack && imported.audioFile == nil)
        var bad = mac; bad.effectIdentities = [scenes[0]: "community:unsupported"]
        do { _ = try VisionProject.openPortable(JSONEncoder().encode(bad)); fatalError("External effect accepted") } catch {}
        try data.write(to: root.appendingPathComponent("Vision-to-Mac.pulsecanvas"))
        try JSONEncoder().encode(again).write(to: root.appendingPathComponent("Mac-to-Vision-to-Mac.pulsecanvas"))
        print("PASS shared Mac Codable project: native IDs, exact mixed-bar cuts, all appearance fields, export format, bundled/external audio references and unsupported-effect rejection")

        let audio = root.appendingPathComponent("four-second-drums.wav")
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 176_400)!
        buffer.frameLength = buffer.frameCapacity
        for i in 0..<Int(buffer.frameLength) {
            let t = Double(i) / 44_100, beat = t.truncatingRemainder(dividingBy: 0.4)
            let sample = Float(sin(2 * .pi * 100 * t) * exp(-beat * 25) * 0.6)
            buffer.floatChannelData![0][i] = sample; buffer.floatChannelData![1][i] = sample
        }
        var file: AVAudioFile? = try AVAudioFile(forWriting: audio, settings: format.settings)
        try file?.write(from: buffer); file = nil
        let state = RenderState(); state.scene = scenes[0]
        let exporter = SocialExportController(scratchDirectory: root)
        exporter.aspect = .wide; exporter.fps = 60
        for resolution in [1080, 2160] {
        exporter.resolution = resolution
        let width = resolution * 16 / 9
        let target = root.appendingPathComponent("Vision-\(resolution)p60.mp4")
        await exporter.export(audioURL: audio, render: state, to: target,
            segments: native.segments(duration: 4), appearances: native.looks.mapValues(\.preset))
        precondition(exporter.exportedURL == target, exporter.status)
        let asset = AVURLAsset(url: target)
        let video = try await asset.loadTracks(withMediaType: .video).first!
        let sound = try await asset.loadTracks(withMediaType: .audio).first!
        let size = try await video.load(.naturalSize), fps = try await video.load(.nominalFrameRate)
        let duration = try await asset.load(.duration).seconds
        precondition(size == CGSize(width: width, height: resolution) && fps == 60 && abs(duration - 4) < 0.04)
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: video, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        reader.add(output); precondition(reader.startReading())
        var frames = 0, times: [Double] = [], nonblack = Set<Int>()
        while let sample = output.copyNextSampleBuffer() {
            times.append(CMSampleBufferGetPresentationTimeStamp(sample).seconds)
            if let pixels = CMSampleBufferGetImageBuffer(sample) {
                CVPixelBufferLockBaseAddress(pixels, .readOnly)
                let bytes = CVPixelBufferGetBaseAddress(pixels)!.assumingMemoryBound(to: UInt8.self)
                let stride = CVPixelBufferGetBytesPerRow(pixels)
                var sum = 0
                for y in Swift.stride(from: 0, to: resolution, by: 24) {
                    for x in Swift.stride(from: 0, to: width, by: 24) {
                        let offset = y * stride + x * 4; sum += Int(bytes[offset]) + Int(bytes[offset+1]) + Int(bytes[offset+2])
                    }
                }
                if sum > 300 { nonblack.insert(min(2, frames < 60 ? 0 : frames < 180 ? 1 : 2)) }
                CVPixelBufferUnlockBaseAddress(pixels, .readOnly)
            }
            frames += 1
        }
        precondition(reader.status == .completed && frames == 240 && nonblack == Set([0, 1, 2]))
        precondition(zip(times, times.dropFirst()).allSatisfy { abs($1 - $0 - 1.0/60) < 0.00001 })
        let audioRange = try await sound.load(.timeRange)
        precondition(abs(audioRange.duration.seconds - 4) < 0.06)
        print("PASS actual decoded export: \(width)×\(resolution) H.264, 240 exact 60-fps frames, nonblack output across three sections, full-length AAC soundtrack")
        }
    }
}
