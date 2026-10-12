import AppKit
@preconcurrency import AVFoundation
import Foundation

@main
struct SocialExportSmoke {
    @MainActor static func main() async {
        NSApplication.shared.setActivationPolicy(.accessory)
        do { try await run() }
        catch { print("FAIL: \(error.localizedDescription)"); exit(1) }
    }
    static func require(_ condition: Bool, _ message: String) throws {
        if !condition { throw ExportError(message) }
    }
    @MainActor static func run() async throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".build/social-export-validation", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let soundtrack = root.appendingPathComponent("stereo-test.wav")
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
        var settings = format.settings
        settings[AVLinearPCMIsNonInterleaved] = false
        var file: AVAudioFile? = try AVAudioFile(forWriting: soundtrack, settings: settings)
        let pcm = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 88_200)!
        pcm.frameLength = 88_200
        for index in 0..<88_200 {
            let t = Double(index) / 44_100
            let sample: Float = t < 0.4 ? 0 : Float(0.45 * sin(2 * Double.pi * 200 * t))
            pcm.floatChannelData![0][index] = sample
            pcm.floatChannelData![1][index] = -sample // Prevent a mono-downmix shortcut passing.
        }
        try file?.write(from: pcm)
        file = nil
        let analyzer = try SoundtrackAnalyzer(url: soundtrack)
        let silence = try analyzer.frame(at: 0.15, clipStart: 0, clipEnd: 2).bands
        let tone = try analyzer.frame(at: 0.55, clipStart: 0, clipEnd: 2).bands
        try require((silence.max() ?? 1) < 0.01 && (tone.max() ?? 0) > 0.5, "FFT must react to actual opposite-phase stereo samples and distinguish silence")
        print("PASS: exact-timestamp FFT distinguishes silence and opposite-phase stereo tone")
        var detector = StrobeDetector()
        var bass = [Float](repeating: 0, count: 32)
        for index in 0..<8 { bass[index] = 1 }
        try require(detector.nextFrame(time: 0, bands: bass) == 0, "Bass must not trigger hi-hat strobe")
        var treble = [Float](repeating: 0, count: 32)
        for index in 24..<32 { treble[index] = 1 }
        try require(detector.nextFrame(time: 0.05, bands: treble) == 1, "Treble attack must trigger strobe")
        try require(detector.nextFrame(time: 0.09, bands: treble) == 0, "Strobe must remain brief and cannot retrigger sustained treble")
        print("PASS: optional hi-hat strobe responds to treble attacks, ignores bass, and releases")
        let state = RenderState()
        state.scene = 0
        let exporter = SocialExportController()
        for (index, aspect) in SocialAspect.allCases.enumerated() {
            exporter.aspect = aspect
            exporter.resolution = index == 4 ? 1080 : 720
            exporter.fps = [24, 30, 60, 24, 30][index]
            let target = root.appendingPathComponent("\(index)-\(exporter.fps).mp4")
            try? FileManager.default.removeItem(at: target)
            await exporter.export(audioURL: soundtrack, render: state, to: target)
            try require(exporter.exportedURL == target, exporter.status)
            let dimensions = aspect.dimensions(resolution: exporter.resolution)
            try await verify(target, width: dimensions.width, height: dimensions.height,
                             fps: exporter.fps, duration: 2, hasAudio: true)
            print("PASS: \(aspect.rawValue) \(dimensions.width)x\(dimensions.height) \(exporter.fps)fps: exact timeline, H.264, full soundtrack stereo AAC")
        }
        exporter.aspect = .square
        exporter.resolution = 720
        exporter.fps = 24
        let silent = root.appendingPathComponent("silent.mp4")
        try? FileManager.default.removeItem(at: silent)
        await exporter.export(audioURL: nil, render: state, to: silent)
        try require(exporter.exportedURL == silent, exporter.status)
        try await verify(silent, width: 720, height: 720, fps: 24, duration: 15, hasAudio: false)
        print("PASS: procedural silent clip has exact 360-frame timeline and no audio track")
        await exporter.export(audioURL: nil, render: state, to: silent)
        try require(exporter.exportedURL == silent, "Existing destination replacement failed: \(exporter.status)")
        try await verify(silent, width: 720, height: 720, fps: 24, duration: 15, hasAudio: false)
        print("PASS: completed export safely replaces an existing destination")
        let entire = root.appendingPathComponent("entire-track.mp4")
        try? FileManager.default.removeItem(at: entire)
        await exporter.export(audioURL: soundtrack, render: state, to: entire)
        try require(exporter.exportedURL == entire, exporter.status)
        try await verify(entire, width: 720, height: 720, fps: 24, duration: 2, hasAudio: true)
        print("PASS: entire soundtrack exports all 48 frames and full 2-second audio")
        let cancelled = entire
        let preserved = try Data(contentsOf: entire)
        let pending = Task { @MainActor in await exporter.export(audioURL: soundtrack, render: state, to: cancelled) }
        while !exporter.isExporting { await Task.yield() }
        while exporter.isExporting && exporter.progress < 0.1 { try await Task.sleep(for: .milliseconds(2)) }
        exporter.cancel()
        await pending.value
        let afterCancel = try Data(contentsOf: cancelled)
        try require(exporter.status == "Export cancelled" && afterCancel == preserved, "Cancellation must preserve existing output")
        print("PASS: cancellation preserves existing output and cleans up partial export")
        // Drive the real detector from PCM, then decode the compressed output.
        let hats = root.appendingPathComponent("treble-attacks.wav")
        let hatBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 26_460)!
        hatBuffer.frameLength = hatBuffer.frameCapacity
        for index in 0..<Int(hatBuffer.frameLength) {
            let t = Double(index) / 44_100
            var sample = 0.0
            for attack in [0.06, 0.18, 0.30, 0.42, 0.54] {
                let age = t - attack
                if age >= 0 && age < 0.025 {
                    for frequency in [4000.0, 5500, 7000, 8500, 11000, 14000] {
                        sample += 0.11 * sin(2 * Double.pi * frequency * age) * exp(-60 * age)
                    }
                }
            }
            hatBuffer.floatChannelData![0][index] = Float(sample)
            hatBuffer.floatChannelData![1][index] = Float(sample)
        }
        do { let writer = try AVAudioFile(forWriting: hats, settings: settings); try writer.write(from: hatBuffer) }
        state.scene = 19; state.particleSize = 1.6; state.strobeEnabled = true
        exporter.aspect = .phone; exporter.resolution = 720; exporter.fps = 60
        let hatVideo = root.appendingPathComponent("hat-strobe.mp4")
        await exporter.export(audioURL: hats, render: state, to: hatVideo)
        try require(exporter.exportedURL == hatVideo, exporter.status)
        let hatFrames = try whiteFrames(hatVideo)
        try require(hatFrames.white >= 3 && hatFrames.white < hatFrames.total / 2, "Real treble attacks must produce brief full white frames: \(hatFrames)")
        let bassVideo = root.appendingPathComponent("bass-no-strobe.mp4")
        await exporter.export(audioURL: soundtrack, render: state, to: bassVideo)
        try require(exporter.exportedURL == bassVideo, exporter.status)
        let bassFrames = try whiteFrames(bassVideo)
        try require(bassFrames.white == 0, "Pure bass must not cause white flashes")
        print("PASS: actual treble PCM -> MP4 yields \(hatFrames.white) brief white frames; bass PCM yields none")
        let kicks = root.appendingPathComponent("kick-attacks.wav")
        let kickBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 48_510)!
        kickBuffer.frameLength = kickBuffer.frameCapacity
        for index in 0..<Int(kickBuffer.frameLength) {
            let time = Double(index) / 44_100
            var value = 0.02 * sin(2 * Double.pi * 440 * time)
            for attack in [0.3, 0.8] {
                let age = time - attack
                if age >= 0 && age < 0.12 { value += 0.65 * exp(-age * 30) * sin(2 * Double.pi * 65 * age) }
            }
            kickBuffer.floatChannelData![0][index] = Float(value)
            kickBuffer.floatChannelData![1][index] = -Float(value)
        }
        do { let writer = try AVAudioFile(forWriting: kicks, settings: settings); try writer.write(from: kickBuffer) }
        state.strobeEnabled = false; state.palette = VisualPalette.blueHour.rawValue
        state.speed = 0; state.zoom = 1; state.brightness = 1; state.motionBlur = 0
        let pulseVideo = root.appendingPathComponent("beat-pulse.mp4")
        await exporter.export(audioURL: kicks, render: state, to: pulseVideo)
        try require(exporter.exportedURL == pulseVideo, exporter.status)
        let pulseFrames = try pixelSequence(pulseVideo)
        func frameChange(_ a: [UInt8], _ b: [UInt8]) -> Double {
            zip(a,b).reduce(0.0) { $0 + Double(abs(Int($1.0)-Int($1.1))) } / Double(a.count)
        }
        let firstKick = frameChange(pulseFrames[19],pulseFrames[36]), secondKick = frameChange(pulseFrames[49],pulseFrames[36])
        // Use settled tone before the kick, after the soundtrack onset has released.
        let quietChange = frameChange(pulseFrames[12],pulseFrames[36])
        try require(firstKick > 0.5 && secondKick > 0.5 && quietChange < min(firstKick,secondKick)*0.5,
                    "Decoded MP4 must deform on both actual kicks and release: \(firstKick), \(secondKick), quiet \(quietChange)")
        print("PASS: decoded MP4 deforms elements on both PCM kicks and releases, with procedural motion frozen and white strobe disabled")
        for scene in [22,23] {
            state.scene = scene; state.chaos = 1
            let movie = root.appendingPathComponent("organic-waves-\(scene).mp4")
            await exporter.export(audioURL: kicks, render: state, to: movie)
            try require(exporter.exportedURL == movie, exporter.status)
            let frames = try pixelSequence(movie)
            let kickChange = min(frameChange(frames[19],frames[36]),frameChange(frames[49],frames[36]))
            let releaseChange = frameChange(frames[12],frames[36])
            try require(kickChange > 0.5 && releaseChange < kickChange*0.5, "Surface waves must follow PCM kicks and relax: scene \(scene), hit \(kickChange), release \(releaseChange)")
            print("PASS: \(RenderState.sceneNames[scene]) local waves survive MP4, kick change \(kickChange), relaxed change \(releaseChange)")
        }
        state.speed = 1; state.chaos = 0
        let calmVideo = root.appendingPathComponent("chaos-low.mp4")
        await exporter.export(audioURL: kicks, render: state, to: calmVideo)
        try require(exporter.exportedURL == calmVideo && state.chaos == 0, exporter.status)
        let calmLevels = try frameBrightness(calmVideo)
        state.chaos = 1
        let chaoticVideo = root.appendingPathComponent("chaos-high.mp4")
        await exporter.export(audioURL: kicks, render: state, to: chaoticVideo)
        try require(exporter.exportedURL == chaoticVideo && state.chaos == 1, exporter.status)
        let chaoticLevels = try frameBrightness(chaoticVideo)
        let chaosDifference = zip(calmLevels, chaoticLevels).reduce(0.0) { $0 + abs($1.0-$1.1) } / Double(calmLevels.count)
        try require(chaosDifference > 0.25, "Decoded exports must preserve and respond to the Chaos setting: \(chaosDifference)")
        print("PASS: decoded low/high Chaos exports differ on real PCM beats while retaining the live setting, mean brightness difference \(chaosDifference)")
        state.scene = 18; state.palette = 4; state.zoom = 0.8
        exporter.aspect = .wide; exporter.resolution = 720; exporter.fps = 24
        let studioVideo = root.appendingPathComponent("studio-sequence.mp4")
        var blue = VisualPreset(); blue.palette = 3; blue.zoom = 1.37; blue.particleSize = 1.9
        var warm = VisualPreset(); warm.palette = 2; warm.zoom = 1.1
        // Compress a seven-bar fixture into two seconds for the decoded export check.
        let barsSuite = "PulseCanvas.ExportBars." + UUID().uuidString
        let barsDefaults = UserDefaults(suiteName: barsSuite)!
        defer { barsDefaults.removePersistentDomain(forName: barsSuite) }
        let barsStudio = StudioStore(defaults: barsDefaults), barsState = RenderState()
        barsStudio.isStudio = true
        barsStudio.segments = [StudioSegment(start: 0, end: 8.0 / 7, scene: 18, bars: 4), StudioSegment(start: 8.0 / 7, end: 2, scene: 20, bars: 4)]
        let barsGrid = SongSegmentation(boundaries: (0...7).map { Double($0) * 2 / 7 }, bpm: nil)
        try require(barsStudio.setBars(1, at: 1, grid: barsGrid, render: barsState), "Set one-bar middle section")
        try require(barsStudio.setBars(2, at: 2, grid: barsGrid, render: barsState), "Set two-bar final section")
        barsStudio.segments[2].scene = 18
        let sections = barsStudio.segments
        try require(sections.map(\.bars) == [4,1,2], "Export fixture must use individual card lengths")
        await exporter.export(audioURL: soundtrack, render: state, to: studioVideo, segments: sections, appearances: [18: blue, 20: warm])
        try require(exporter.exportedURL == studioVideo, exporter.status)
        try await verify(studioVideo, width: 1280, height: 720, fps: 24, duration: 2, hasAudio: true)
        let colors = try frameColors(studioVideo)
        for index in [5, 15, 27, 35, 40] { try require(colors[index].2 > colors[index].0 * 1.4, "Blue section must use shared Blue Hour appearance at frame \(index)") }
        for index in [28, 30, 34] { try require(colors[index].0 > colors[index].2 * 1.4, "Warm section must switch on its bar boundary at frame \(index)") }
        try require(state.scene == 18 && state.palette == 4 && state.zoom == 0.8, "Export cannot mutate live appearance")
        print("PASS: decoded Studio MP4 follows generated 4/1/2 per-card bar timing exactly, repeats shared blue appearance, applies first-section preset, retains live state and full audio")
        let fourKAudio = root.appendingPathComponent("4k-soundtrack.wav")
        let shortPCM = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8820)!
        shortPCM.frameLength = shortPCM.frameCapacity
        for i in 0..<Int(shortPCM.frameLength) {
            let sample = Float(0.2 * sin(Double(i) / 44100 * 2 * .pi * 200))
            shortPCM.floatChannelData![0][i] = sample; shortPCM.floatChannelData![1][i] = -sample
        }
        do { let writer = try AVAudioFile(forWriting: fourKAudio, settings: settings); try writer.write(from: shortPCM) }
        exporter.resolution = 2160; exporter.fps = 24
        for aspect in [SocialAspect.wide, .phone] {
            exporter.aspect = aspect
            let target = root.appendingPathComponent("4k-\(aspect == .wide ? "wide" : "phone").mp4")
            await exporter.export(audioURL: fourKAudio, render: state, to: target)
            try require(exporter.exportedURL == target, exporter.status)
            let size = aspect.dimensions(resolution: 2160)
            try await verify(target, width: size.width, height: size.height, fps: 24, duration: 0.2, hasAudio: true)
            print("PASS: 4K \(aspect.rawValue) \(size.width)x\(size.height) decodes every frame with full soundtrack")
        }
        let savedFormat = SocialExportController()
        try require(savedFormat.resolution == 2160 && savedFormat.aspect == .phone, "4K project settings persist")
        exporter.aspect = .wide; exporter.resolution = 720; exporter.fps = 24
        let spatialScenes = [4,10,12,22,23,24,25,26,27,28,29,30]
        let spatialSections = spatialScenes.enumerated().map { index, scene in
            StudioSegment(start: Double(index)*2/Double(spatialScenes.count), end: Double(index+1)*2/Double(spatialScenes.count), scene: scene)
        }
        let spatialPresets = Dictionary(uniqueKeysWithValues: spatialScenes.map { scene in
            var preset = VisualPreset(); preset.palette = VisualPalette.blueHour.rawValue; preset.chaos = 0.8
            return (scene,preset)
        })
        let spatialVideo = root.appendingPathComponent("spatial-studio.mp4")
        await exporter.export(audioURL: soundtrack, render: state, to: spatialVideo, segments: spatialSections, appearances: spatialPresets)
        try require(exporter.exportedURL == spatialVideo, exporter.status)
        try await verify(spatialVideo, width: 1280, height: 720, fps: 24, duration: 2, hasAudio: true)
        let spatialColors = try frameColors(spatialVideo)
        for index in spatialScenes.indices {
            let frame = Int((Double(index)+0.5)*48/Double(spatialScenes.count))
            try require(spatialColors[frame].2 > spatialColors[frame].0 * 1.8 && spatialColors[frame].2 > 1000, "Every spatial Studio section must render its shared blue preset")
        }
        print("PASS: decoded Studio export plays all \(spatialScenes.count) spatial designs with shared palettes and full audio")
        state.scene = 23
        var liquidPreset = VisualPreset(); liquidPreset.palette = VisualPalette.blueHour.rawValue; liquidPreset.chaos = 0.8
        liquidPreset.apply(to: state)
        var liquidFrames: [[(Double,Double,Double)]] = []
        for detail: Float in [0,1] {
            state.liquidDetail = detail
            let movie = root.appendingPathComponent("liquid-detail-\(Int(detail)).mp4")
            await exporter.export(audioURL: soundtrack, render: state, to: movie)
            try require(exporter.exportedURL == movie && state.liquidDetail == detail, "Liquid export must retain the live setting")
            liquidFrames.append(try frameColors(movie))
        }
        let liquidChange = zip(liquidFrames[0],liquidFrames[1]).reduce(0.0) { $0 + abs($1.0.0-$1.1.0) + abs($1.0.1-$1.1.1) + abs($1.0.2-$1.1.2) } / 48
        try require(liquidChange > 28_800, "Decoded low/high Liquid detail movies must visibly differ")
        state.liquidDetail = 0; liquidPreset.liquidDetail = 1
        let liquidStudio = root.appendingPathComponent("liquid-shared-preset.mp4")
        await exporter.export(audioURL: soundtrack, render: state, to: liquidStudio, segments: [StudioSegment(start: 0, end: 2, scene: 23)], appearances: [23:liquidPreset])
        try require(exporter.exportedURL == liquidStudio && state.liquidDetail == 0, "Studio must apply its shared liquid preset and retain the live setting")
        let sharedLiquid = try frameColors(liquidStudio)
        let sharedDifference = zip(sharedLiquid,liquidFrames[1]).reduce(0.0) { $0 + abs($1.0.0-$1.1.0) + abs($1.0.1-$1.1.1) + abs($1.0.2-$1.1.2) } / 48
        try require(sharedDifference < 14_400, "Shared Liquid detail must reproduce the matching single-visualizer export")
        print("PASS: decoded Liquid detail exports visibly differ; Studio shared detail matches single-visualizer output and preserves live state")
        for zoomScene in [18,22] {
            state.scene = zoomScene
            var zoomPreset = VisualPreset(); zoomPreset.palette = VisualPalette.blueHour.rawValue
            zoomPreset.apply(to: state)
            var zoomFrames: [[UInt8]] = []
            for speed: Float in [0,2.5] {
                state.zoomSpeed = speed
                let movie = root.appendingPathComponent("zoom-\(zoomScene)-\(speed).mp4")
                await exporter.export(audioURL: soundtrack, render: state, to: movie)
                try require(exporter.exportedURL == movie && state.zoomSpeed == speed, "Zoom export must retain the live setting")
                zoomFrames.append(try framePixels(movie))
            }
            let change = zip(zoomFrames[0],zoomFrames[1]).reduce(0.0) { $0 + Double(abs(Int($1.0)-Int($1.1))) } / Double(zoomFrames[0].count)
            try require(change > 3, "Decoded flat/forward zoom movies must visibly differ: scene \(zoomScene), mean pixel change \(change)")
            state.zoomSpeed = 0; zoomPreset.zoomSpeed = 2.5
            let studioZoom = root.appendingPathComponent("zoom-shared-\(zoomScene).mp4")
            await exporter.export(audioURL: soundtrack, render: state, to: studioZoom, segments: [StudioSegment(start: 0, end: 2, scene: zoomScene)], appearances: [zoomScene:zoomPreset])
            try require(exporter.exportedURL == studioZoom && state.zoomSpeed == 0, "Studio zoom must retain the live setting")
            let shared = try framePixels(studioZoom)
            let mismatch = zip(shared,zoomFrames[1]).reduce(0.0) { $0 + Double(abs(Int($1.0)-Int($1.1))) } / Double(shared.count)
            try require(mismatch < 2, "Shared zoom speed must reproduce direct export")
            print("PASS: scene \(zoomScene) decoded zoom mean pixel change \(change), shared preset mismatch \(mismatch)")
        }
        print("PASS: decoded flat/forward zoom differs for geometry and mesh tunnels; Studio reproduces shared zoom and retains live state")
        state.scene = 28
        var haloPreset = VisualPreset(); haloPreset.palette = VisualPalette.blueHour.rawValue
        haloPreset.apply(to: state)
        var haloFrames: [[UInt8]] = []
        for count in [2,12] {
            state.haloCount = count
            let movie = root.appendingPathComponent("halo-count-\(count).mp4")
            await exporter.export(audioURL: soundtrack, render: state, to: movie)
            try require(exporter.exportedURL == movie && state.haloCount == count, "Halo export must retain the live count")
            haloFrames.append(try framePixels(movie))
        }
        let haloChange = zip(haloFrames[0],haloFrames[1]).reduce(0.0) { $0 + Double(abs(Int($1.0)-Int($1.1))) } / Double(haloFrames[0].count)
        try require(haloChange > 3, "Decoded Halo count movies must visibly differ")
        state.haloCount = 2; haloPreset.haloCount = 12
        let haloStudio = root.appendingPathComponent("halo-shared-preset.mp4")
        await exporter.export(audioURL: soundtrack, render: state, to: haloStudio, segments: [StudioSegment(start: 0, end: 2, scene: 28)], appearances: [28:haloPreset])
        try require(exporter.exportedURL == haloStudio && state.haloCount == 2, "Studio halo count must retain the live setting")
        let sharedHalos = try framePixels(haloStudio)
        let haloMismatch = zip(sharedHalos,haloFrames[1]).reduce(0.0) { $0 + Double(abs(Int($1.0)-Int($1.1))) } / Double(sharedHalos.count)
        try require(haloMismatch < 2, "Shared Halo count must reproduce direct export")
        print("PASS: decoded Halo count changes geometry, mean pixel change \(haloChange); shared Studio preset mismatch \(haloMismatch), live count retained")
        state.scene = 22
        var blurPreset = VisualPreset(); blurPreset.palette = VisualPalette.blueHour.rawValue
        blurPreset.apply(to: state)
        var blurFrames: [[UInt8]] = []
        for strength: Float in [0, 0.9] {
            state.motionBlur = strength
            let movie = root.appendingPathComponent("content-blur-\(strength).mp4")
            await exporter.export(audioURL: soundtrack, render: state, to: movie)
            try require(exporter.exportedURL == movie && state.motionBlur == strength, "Content blur export must retain live setting")
            blurFrames.append(try framePixels(movie))
        }
        let blurChange = zip(blurFrames[0],blurFrames[1]).reduce(0.0) { $0 + Double(abs(Int($1.0)-Int($1.1))) } / Double(blurFrames[0].count)
        try require(blurChange > 0.5, "Whole-image softness must survive MP4 encoding")
        state.motionBlur = 0; blurPreset.motionBlur = 0.9
        let blurStudio = root.appendingPathComponent("content-blur-shared.mp4")
        await exporter.export(audioURL: soundtrack, render: state, to: blurStudio, segments: [StudioSegment(start: 0, end: 2, scene: 22)], appearances: [22:blurPreset])
        try require(exporter.exportedURL == blurStudio && state.motionBlur == 0, "Studio blur must retain live setting")
        let sharedBlur = try framePixels(blurStudio)
        let blurMismatch = zip(sharedBlur,blurFrames[1]).reduce(0.0) { $0 + Double(abs(Int($1.0)-Int($1.1))) } / Double(sharedBlur.count)
        try require(blurMismatch < 2, "Studio must reproduce shared content blur")
        print("PASS: decoded uniform blur visibly softens movie, mean pixel change \(blurChange); shared Studio mismatch \(blurMismatch), live blur retained")
        // Zero Chaos must export pure procedural motion, even with a soundtrack
        // and a saved Studio preset. Compare decoded output to true silent PCM.
        let silentPCM = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 88_200)!
        silentPCM.frameLength = silentPCM.frameCapacity
        for channel in 0..<Int(format.channelCount) {
            silentPCM.floatChannelData![channel].initialize(repeating: 0, count: Int(silentPCM.frameLength))
        }
        let silentTrack = root.appendingPathComponent("zero-chaos-silent.wav")
        do { let writer = try AVAudioFile(forWriting: silentTrack, settings: settings); try writer.write(from: silentPCM) }
        for scene in [18,22,25,30] {
            var calmPreset = VisualPreset(); calmPreset.chaos = 0; calmPreset.zoomSpeed = 1.5
            calmPreset.strobeEnabled = true
            calmPreset.apply(to: state); state.scene = scene
            var movies: [[UInt8]] = []
            for (label, track) in [("audio",soundtrack),("silent",silentTrack)] {
                let movie = root.appendingPathComponent("zero-chaos-\(scene)-\(label).mp4")
                await exporter.export(audioURL: track, render: state, to: movie)
                try require(exporter.exportedURL == movie && state.chaos == 0, "Zero-Chaos export must retain live settings")
                movies.append(try framePixels(movie))
            }
            let mismatch = zip(movies[0],movies[1]).reduce(0.0) { $0 + Double(abs(Int($1.0)-Int($1.1))) } / Double(movies[0].count)
            try require(mismatch < 0.2, "Zero-Chaos movie must ignore music: scene \(scene), decoded mismatch \(mismatch)")
            state.chaos = 1
            let sharedMovie = root.appendingPathComponent("zero-chaos-\(scene)-studio.mp4")
            await exporter.export(audioURL: soundtrack, render: state, to: sharedMovie,
                segments: [StudioSegment(start: 0, end: 2, scene: scene)], appearances: [scene:calmPreset])
            try require(exporter.exportedURL == sharedMovie && state.chaos == 1, "Studio zero Chaos must preserve the live setting")
            let shared = try framePixels(sharedMovie)
            let sharedMismatch = zip(shared,movies[0]).reduce(0.0) { $0 + Double(abs(Int($1.0)-Int($1.1))) } / Double(shared.count)
            try require(sharedMismatch < 0.2, "Studio must honor zero Chaos: scene \(scene), decoded mismatch \(sharedMismatch)")
            print("PASS: \(RenderState.sceneNames[scene]) zero-Chaos music/silence decoded mismatch \(mismatch), Studio mismatch \(sharedMismatch), live setting retained")
        }
        print("PASS: all offline social export checks")
    }

    static func pixelSequence(_ url: URL) throws -> [[UInt8]] {
        let asset = AVURLAsset(url: url)
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: asset.tracks(withMediaType: .video)[0], outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        reader.add(output); try require(reader.startReading(), "Cannot decode shape pulse movie")
        var frames: [[UInt8]] = []
        while let sample = output.copyNextSampleBuffer(), let image = CMSampleBufferGetImageBuffer(sample) {
            CVPixelBufferLockBaseAddress(image, .readOnly)
            let bytes = CVPixelBufferGetBaseAddress(image)!.assumingMemoryBound(to: UInt8.self)
            let width = CVPixelBufferGetWidth(image), height = CVPixelBufferGetHeight(image), row = CVPixelBufferGetBytesPerRow(image)
            var pixels: [UInt8] = []
            for y in stride(from: 0, to: height, by: 8) { for x in stride(from: 0, to: width, by: 8) {
                let i=y*row+x*4; pixels.append(contentsOf: [bytes[i],bytes[i+1],bytes[i+2]])
            } }
            CVPixelBufferUnlockBaseAddress(image, .readOnly); frames.append(pixels)
        }
        try require(reader.status == .completed && frames.count == 66, "Pulse movie must decode every frame")
        return frames
    }

    static func framePixels(_ url: URL) throws -> [UInt8] {
        let asset = AVURLAsset(url: url)
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: asset.tracks(withMediaType: .video)[0], outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        reader.add(output); try require(reader.startReading(), "Cannot decode zoom movie")
        var pixels: [UInt8] = [], frames = 0
        while let sample = output.copyNextSampleBuffer(), let image = CMSampleBufferGetImageBuffer(sample) {
            CVPixelBufferLockBaseAddress(image, .readOnly)
            let bytes = CVPixelBufferGetBaseAddress(image)!.assumingMemoryBound(to: UInt8.self)
            for y in stride(from: 0, to: CVPixelBufferGetHeight(image), by: 8) {
                for x in stride(from: 0, to: CVPixelBufferGetWidth(image), by: 8) {
                    let index = y * CVPixelBufferGetBytesPerRow(image) + x * 4
                    pixels.append(contentsOf: [bytes[index],bytes[index+1],bytes[index+2]])
                }
            }
            CVPixelBufferUnlockBaseAddress(image, .readOnly); frames += 1
        }
        try require(reader.status == .completed && frames == 48, "Zoom movie must decode every frame")
        return pixels
    }

    static func frameColors(_ url: URL) throws -> [(Double, Double, Double)] {
        let asset = AVURLAsset(url: url)
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: asset.tracks(withMediaType: .video)[0], outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        reader.add(output); try require(reader.startReading(), "Cannot decode Studio movie")
        var colors: [(Double, Double, Double)] = []
        while let sample = output.copyNextSampleBuffer(), let image = CMSampleBufferGetImageBuffer(sample) {
            CVPixelBufferLockBaseAddress(image, .readOnly)
            let bytes = CVPixelBufferGetBaseAddress(image)!.assumingMemoryBound(to: UInt8.self)
            var r = 0.0, g = 0.0, b = 0.0
            for y in stride(from: 0, to: CVPixelBufferGetHeight(image), by: 8) {
                for x in stride(from: 0, to: CVPixelBufferGetWidth(image), by: 8) {
                    let i = y * CVPixelBufferGetBytesPerRow(image) + x * 4
                    r += Double(bytes[i+2]); g += Double(bytes[i+1]); b += Double(bytes[i])
                }
            }
            CVPixelBufferUnlockBaseAddress(image, .readOnly); colors.append((r,g,b))
        }
        try require(reader.status == .completed && colors.count == 48, "Studio must decode every frame")
        return colors
    }

    static func frameBrightness(_ url: URL) throws -> [Double] {
        let asset = AVURLAsset(url: url)
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: asset.tracks(withMediaType: .video)[0], outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        reader.add(output)
        try require(reader.startReading(), "Cannot decode beat pulse movie")
        var levels: [Double] = []
        while let sample = output.copyNextSampleBuffer() {
            guard let image = CMSampleBufferGetImageBuffer(sample) else { continue }
            CVPixelBufferLockBaseAddress(image, .readOnly)
            let bytes = CVPixelBufferGetBaseAddress(image)!.assumingMemoryBound(to: UInt8.self)
            let width = CVPixelBufferGetWidth(image), height = CVPixelBufferGetHeight(image), row = CVPixelBufferGetBytesPerRow(image)
            var total = 0.0, count = 0
            for y in stride(from: 0, to: height, by: 8) {
                for x in stride(from: 0, to: width, by: 8) {
                    let index = y * row + x * 4
                    total += Double(bytes[index]) + Double(bytes[index+1]) + Double(bytes[index+2]); count += 1
                }
            }
            CVPixelBufferUnlockBaseAddress(image, .readOnly)
            levels.append(total / Double(max(1, count)))
        }
        try require(reader.status == .completed && levels.count == 66, "Beat clip must decode every frame")
        return levels
    }

    static func whiteFrames(_ url: URL) throws -> (white: Int, total: Int) {
        let asset = AVURLAsset(url: url)
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: asset.tracks(withMediaType: .video)[0], outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        reader.add(output)
        try require(reader.startReading(), "Cannot decode strobe movie")
        var white = 0, total = 0
        while let sample = output.copyNextSampleBuffer() {
            guard let image = CMSampleBufferGetImageBuffer(sample) else { continue }
            CVPixelBufferLockBaseAddress(image, .readOnly)
            let bytes = CVPixelBufferGetBaseAddress(image)!.assumingMemoryBound(to: UInt8.self)
            let width = CVPixelBufferGetWidth(image), height = CVPixelBufferGetHeight(image), row = CVPixelBufferGetBytesPerRow(image)
            var bright = 0
            for y in 0..<5 { for x in 0..<5 {
                let index = ((height * (y * 2 + 1)) / 10) * row + ((width * (x * 2 + 1)) / 10) * 4
                if min(bytes[index], bytes[index + 1], bytes[index + 2]) > 240 { bright += 1 }
            } }
            CVPixelBufferUnlockBaseAddress(image, .readOnly)
            if bright >= 24 { white += 1 }
            total += 1
        }
        return (white, total)
    }

    static func verify(_ url: URL, width: Int, height: Int, fps: Int, duration: Double, hasAudio: Bool) async throws {
        let asset = AVURLAsset(url: url)
        let actualDuration = try await asset.load(.duration).seconds
        try require(abs(actualDuration - duration) < 0.002, "Wrong movie duration \(actualDuration), expected \(duration)")
        let videos = try await asset.loadTracks(withMediaType: .video)
        let audios = try await asset.loadTracks(withMediaType: .audio)
        try require(videos.count == 1 && audios.count == (hasAudio ? 1 : 0), "Wrong video/audio track count")
        let video = videos[0]
        let size = try await video.load(.naturalSize)
        try require(Int(size.width) == width && Int(size.height) == height, "Wrong video dimensions \(size)")
        let descriptions = try await video.load(.formatDescriptions)
        try require(descriptions.first.map { CMFormatDescriptionGetMediaSubType($0) } == kCMVideoCodecType_H264, "Video must be H.264")
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: video, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        reader.add(output)
        try require(reader.startReading(), "Cannot read exported video")
        var times: [Double] = []
        while let sample = output.copyNextSampleBuffer() {
            if CMSampleBufferGetNumSamples(sample) > 0 { times.append(CMSampleBufferGetPresentationTimeStamp(sample).seconds) }
        }
        try require(reader.status == .completed, "Exported video reader failed")
        times.sort()
        let frameCount = Int(ceil(duration * Double(fps) - 0.00000001))
        try require(times.count == frameCount, "Dropped or duplicated frame: found \(times.count), expected \(frameCount)")
        for (index, time) in times.enumerated() {
            try require(abs(time - Double(index) / Double(fps)) < 0.0001, "Wrong frame timestamp \(time) at \(index)")
        }
        if hasAudio {
            let audio = audios[0]
            let descriptions = try await audio.load(.formatDescriptions)
            try require(descriptions.first.map { CMFormatDescriptionGetMediaSubType($0) } == kAudioFormatMPEG4AAC, "Soundtrack must be AAC")
            let range = try await audio.load(.timeRange)
            try require(abs(range.start.seconds) < 0.002 && abs(range.duration.seconds - duration) < 0.003, "Soundtrack trim or start time differs from video")
            let audioReader = try AVAssetReader(asset: asset)
            let pcm = AVAssetReaderTrackOutput(track: audio, outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM, AVLinearPCMIsFloatKey: true, AVLinearPCMBitDepthKey: 32, AVLinearPCMIsNonInterleaved: false])
            audioReader.add(pcm)
            try require(audioReader.startReading(), "Cannot decode exported soundtrack")
            var energy: Double = 0
            var count = 0
            while let sample = pcm.copyNextSampleBuffer() {
                guard let description = CMSampleBufferGetFormatDescription(sample),
                      let format = CMAudioFormatDescriptionGetStreamBasicDescription(description),
                      let block = CMSampleBufferGetDataBuffer(sample) else { throw ExportError("Missing decoded audio buffer") }
                try require(format.pointee.mChannelsPerFrame == 2, "Stereo soundtrack channels were lost")
                var length = 0
                var pointer: UnsafeMutablePointer<Int8>?
                try require(CMBlockBufferGetDataPointer(block, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &pointer) == noErr, "Cannot read soundtrack PCM")
                pointer!.withMemoryRebound(to: Float.self, capacity: length / 4) {
                    for index in 0..<length / 4 { energy += Double($0[index] * $0[index]); count += 1 }
                }
            }
            try require(count > 0 && sqrt(energy / Double(count)) > 0.1, "Trimmed export contains silence instead of selected tone")
        }
    }
}
