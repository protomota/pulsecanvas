import AppKit
import Foundation
@preconcurrency import Metal

/// Developer gallery for native effects: stills, motion frame sequences, continuity,
/// Chaos isolation and timing. Build with scripts/native-gallery.sh.
@main struct NativeGallery {
    struct Failure: LocalizedError {
        let text: String
        var errorDescription: String? { text }
    }

    struct Options {
        var command = "stills"
        var scenes: [Int] = []
        var width = 640, height = 360
        var time = 12.3, start = 10.0, duration = 4.0
        var fps = 30
        var chaos: Float? = nil
        var zoomSpeed: Float? = nil
        var palette = -1
        var output = ".build/native-gallery"
        var silence = false
        var brightness: Float? = nil
        var fog: Float? = nil

        @MainActor init(_ arguments: [String]) throws {
            var index = 1
            if arguments.count > 1 { command = arguments[1]; index = 2 }
            while index < arguments.count {
                let key = arguments[index], value = index + 1 < arguments.count ? arguments[index + 1] : ""
                switch key {
                case "--scenes": scenes = Self.parseScenes(value).filter { !NativeEffects.isRetired($0) }
                case "--size":
                    let parts = value.split(separator: "x").compactMap { Int($0) }
                    guard parts.count == 2 else { throw Failure(text: "Size must be WIDTHxHEIGHT") }
                    width = parts[0]; height = parts[1]
                case "--time": time = Double(value) ?? time
                case "--start": start = Double(value) ?? start
                case "--duration": duration = Double(value) ?? duration
                case "--fps": fps = Int(value) ?? fps
                case "--chaos": chaos = Float(value)
                case "--zoom-speed": zoomSpeed = Float(value)
                case "--palette": palette = Int(value) ?? palette
                case "--out": output = value
                case "--silence": silence = true; index -= 1
                case "--brightness": brightness = Float(value)
                case "--fog": fog = Float(value)
                default: throw Failure(text: "Unknown option \(key)")
                }
                index += 2
            }
            if scenes.isEmpty { scenes = NativeEffects.activeIDs }
        }

        static func parseScenes(_ text: String) -> [Int] {
            text.split(separator: ",").flatMap { part -> [Int] in
                let bounds = part.split(separator: "-").compactMap { Int($0) }
                if bounds.count == 2 { return Array(bounds[0]...bounds[1]) }
                return bounds
            }
        }
    }

    @MainActor static func main() async {
        NSApplication.shared.setActivationPolicy(.accessory)
        do { try run(Options(CommandLine.arguments)) } catch {
            print("FAIL: \(error.localizedDescription)"); exit(1)
        }
    }

    static func pixels(_ texture: MTLTexture) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: texture.width * texture.height * 4)
        bytes.withUnsafeMutableBytes {
            texture.getBytes($0.baseAddress!, bytesPerRow: texture.width * 4,
                             from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0)
        }
        return bytes
    }

    static func png(_ bytes: [UInt8], width: Int, height: Int, to url: URL) throws {
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: width * 4, bitsPerPixel: 32)!
        for pixel in stride(from: 0, to: bytes.count, by: 4) {
            bitmap.bitmapData![pixel] = bytes[pixel + 2]
            bitmap.bitmapData![pixel + 1] = bytes[pixel + 1]
            bitmap.bitmapData![pixel + 2] = bytes[pixel]
            bitmap.bitmapData![pixel + 3] = 255
        }
        try bitmap.representation(using: .png, properties: [:])!.write(to: url)
    }

    /// Mean absolute channel difference, 0...255.
    static func difference(_ a: [UInt8], _ b: [UInt8]) -> Double {
        var total = 0
        for index in stride(from: 0, to: min(a.count, b.count), by: 4) {
            total += abs(Int(a[index]) - Int(b[index])) + abs(Int(a[index + 1]) - Int(b[index + 1])) + abs(Int(a[index + 2]) - Int(b[index + 2]))
        }
        return Double(total) / Double(a.count / 4 * 3)
    }

    struct Coverage { var cells: Int; var lit: Double; var mean: Double }
    static func coverage(_ bytes: [UInt8], width: Int, height: Int) -> Coverage {
        var cells = Set<Int>(), lit = 0, sum = 0
        for index in stride(from: 0, to: bytes.count, by: 4) {
            let value = max(bytes[index], max(bytes[index + 1], bytes[index + 2]))
            sum += Int(bytes[index]) + Int(bytes[index + 1]) + Int(bytes[index + 2])
            if value > 20 {
                lit += 1
                let x = (index / 4) % width, y = (index / 4) / width
                cells.insert((y * 4 / height) * 4 + x * 4 / width)
            }
        }
        let count = Double(width * height)
        return Coverage(cells: cells.count, lit: Double(lit) / count, mean: Double(sum) / (count * 3))
    }

    @MainActor static func configure(_ state: RenderState, scene: Int, options: Options) {
        state.scene = scene
        VisualPreset.defaults(for: scene).apply(to: state)
        if let chaos = options.chaos { state.chaos = chaos }
        if let zoomSpeed = options.zoomSpeed { state.zoomSpeed = zoomSpeed }
        if let brightness = options.brightness { state.brightness = brightness }
        if let fog = options.fog { state.fog = fog }
        state.motionBlur = 0
        state.strobeEnabled = false
        if options.palette >= 0 { state.palette = options.palette }
    }

    @MainActor static func render(_ renderer: VisualizerRenderer, analyzer: SoundtrackAnalyzer, time: Double, silence: Bool) throws -> [UInt8] {
        let features = silence ? AudioFeatures.silence : try analyzer.frame(at: time, clipStart: 0, clipEnd: 10_000)
        let texture = try renderer.renderOffscreen(time: time, audioBands: features.bands, audioPulse: features.pulse,
            audioMomentum: features.momentum, audioBeatMotionTime: features.beatMotionTime, audioEnvelopes: features.envelopes, audioSwell: features.swell)
        return pixels(texture)
    }

    @MainActor static func run(_ options: Options) throws {
        let root = URL(fileURLWithPath: options.output, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let analyzer = try SoundtrackAnalyzer(url: URL(fileURLWithPath: "Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3"))
        let names = RenderState.nativeSceneNames
        let state = RenderState()
        let renderer = VisualizerRenderer(state: state)
        let compileStart = ProcessInfo.processInfo.systemUptime
        try renderer.prepareOffscreen(width: options.width, height: options.height)
        print(String(format: "LIBRARY attach and native compile: %.0f ms", (ProcessInfo.processInfo.systemUptime - compileStart) * 1000))
        switch options.command {
        case "stills":
            for scene in options.scenes {
                configure(state, scene: scene, options: options)
                let bytes = try render(renderer, analyzer: analyzer, time: options.time, silence: options.silence)
                try png(bytes, width: options.width, height: options.height, to: root.appendingPathComponent(String(format: "%03d.png", scene)))
                let c = coverage(bytes, width: options.width, height: options.height)
                print(String(format: "STILL %3d %-22@ cells %2d lit %5.1f%% mean %5.1f", scene, names[scene] as NSString, c.cells, c.lit * 100, c.mean))
            }
        case "frames":
            for scene in options.scenes {
                configure(state, scene: scene, options: options)
                let folder = root.appendingPathComponent(String(format: "%03d", scene), isDirectory: true)
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                let count = Int(options.duration * Double(options.fps))
                for frame in 0..<count {
                    let time = options.start + Double(frame) / Double(options.fps)
                    let bytes = try render(renderer, analyzer: analyzer, time: time, silence: options.silence)
                    try png(bytes, width: options.width, height: options.height, to: folder.appendingPathComponent(String(format: "%05d.png", frame)))
                }
                print("FRAMES \(scene) \(names[scene]): \(count)")
            }
        case "audit":
            // Chaos isolation, element response and continuity at zero and full Chaos.
            var failures: [String] = []
            for scene in options.scenes {
                configure(state, scene: scene, options: options)
                state.chaos = 0
                let quietMusic = try render(renderer, analyzer: analyzer, time: options.time, silence: false)
                let quietSilence = try render(renderer, analyzer: analyzer, time: options.time, silence: true)
                let isolation = difference(quietMusic, quietSilence)
                state.chaos = 1
                // Same music clock, with and without the instantaneous levels: isolates
                // element response from the integrated clock.
                let features = try analyzer.frame(at: options.time, clipStart: 0, clipEnd: 10_000)
                let withLevels = pixels(try renderer.renderOffscreen(time: options.time, audioBands: features.bands, audioPulse: features.pulse,
                    audioMomentum: features.momentum, audioBeatMotionTime: features.beatMotionTime, audioEnvelopes: features.envelopes, audioSwell: features.swell))
                let withoutLevels = pixels(try renderer.renderOffscreen(time: options.time, audioBands: [Float](repeating: 0, count: 32), audioPulse: 0,
                    audioMomentum: 0, audioBeatMotionTime: features.beatMotionTime))
                let response = difference(withLevels, withoutLevels)
                var summaries: [String] = []
                var minimumMean = 255.0, minimumCells = 16
                for chaos in [Float(0), 1] {
                    state.chaos = chaos
                    var steps: [Double] = []
                    var previous: [UInt8]? = nil
                    for frame in 0..<Int(options.duration * Double(options.fps)) {
                        let bytes = try render(renderer, analyzer: analyzer, time: options.start + Double(frame) / Double(options.fps), silence: false)
                        let c = coverage(bytes, width: options.width, height: options.height)
                        minimumMean = min(minimumMean, c.mean); minimumCells = min(minimumCells, c.cells)
                        if let previous { steps.append(difference(previous, bytes)) }
                        previous = bytes
                    }
                    let sorted = steps.sorted()
                    let median = sorted.isEmpty ? 0 : sorted[sorted.count / 2]
                    let peak = sorted.last ?? 0
                    let at = steps.firstIndex(of: peak).map { $0 + 1 } ?? 0
                    summaries.append(String(format: "c%.0f step %5.2f/%6.2f x%4.1f @%3d", chaos, median, peak, peak / max(0.01, median), at))
                }
                print(String(format: "AUDIT %3d %-22@ zeroChaos %.3f  levels %6.2f  ", scene, names[scene] as NSString, isolation, response) + summaries.joined(separator: "  ") + String(format: "  minMean %5.1f cells %2d", minimumMean, minimumCells))
                if isolation > 0.001 { failures.append("\(names[scene]): music changes output at zero Chaos (\(isolation))") }
                if minimumMean < 4 { failures.append("\(names[scene]): near-black frame (mean \(minimumMean))") }
                if minimumCells < 14 { failures.append("\(names[scene]): sparse frame (\(minimumCells)/16 cells)") }
            }
            if !failures.isEmpty { throw Failure(text: failures.joined(separator: "\n")) }
        case "features":
            var time = options.start
            while time < options.start + options.duration {
                let f = try analyzer.frame(at: time, clipStart: 0, clipEnd: 10_000)
                func mean(_ r: Range<Int>) -> Float { r.map { f.bands[$0] }.reduce(0, +) / Float(r.count) }
                print(String(format: "t %6.2f low %.2f lowMid %.2f highMid %.2f high %.2f pulse %.2f momentum %.2f motion %.2f | envelopes %.2f %.2f %.2f %.2f swell %.2f",
                             time, mean(0..<6), mean(6..<14), mean(14..<23), mean(23..<32), f.pulse, f.momentum, f.beatMotionTime,
                             f.envelopes.x, f.envelopes.y, f.envelopes.z, f.envelopes.w, f.swell))
                time += 1 / Double(options.fps)
            }
        case "zoomcheck":
            // Mirrors scripts/ZoomSmoke.swift with numbers, to locate failures.
            for scene in options.scenes {
                state.scene = scene; state.chaos = 0; state.zoomSpeed = 0
                func frame(_ time: Double) throws -> [UInt8] { pixels(try renderer.renderOffscreen(time: time, audioBands: [Float](repeating: 0, count: 32))) }
                let flat = try frame(2.3), moving = try frame(2.7)
                state.zoomSpeed = 1; let travel = try frame(2.3)
                state.zoomSpeed = 3; let fast = try frame(2.3)
                state.zoomSpeed = 0; let restored = try frame(2.3)
                let a = difference(flat, moving), b = difference(flat, travel), d = difference(travel, fast)
                let ok = a > 0.05 * 255 / 255 && b > 0.5 && d > 0.5 && flat == restored
                print(String(format: "ZOOM %3d %-22@ animate %.3f travel %.3f fast %.3f restored %@ %@", scene, names[scene] as NSString, a, b, d, flat == restored ? "yes" : "NO", ok ? "" : "<-- FAIL"))
            }
        case "beatcheck":
            // Mirrors scripts/AudioSyncSmoke.swift: an attack must visibly change each scene.
            let frameFeatures = try analyzer.frame(at: 1.33, clipStart: 0, clipEnd: 4)
            for scene in options.scenes {
                state.scene = scene; state.zoom = 1; state.brightness = 1; state.strobeEnabled = false
                let idle = pixels(try renderer.renderOffscreen(time: 1.33, audioBands: frameFeatures.bands, audioPulse: 0))
                let beat = pixels(try renderer.renderOffscreen(time: 1.33, audioBands: frameFeatures.bands, audioPulse: 1, audioSwell: 1))
                let changed = zip(idle, beat).filter { abs(Int($0) - Int($1)) > 8 }.count
                if changed <= 400 { print("BEAT \(scene) \(names[scene]) changed \(changed) <-- weak") }
            }
        case "covercheck":
            // Mirrors scripts/CanvasCoverageSmoke.swift spans and occupancy.
            let settings: [(Double, Float, Float)] = [(2.3, 1, 0), (0, 0.6, 2.7), (8, 1.55, -2.7), (24, 1, 1.1)]
            for scene in options.scenes {
                state.scene = scene; state.speed = 1; state.brightness = 1; state.particleSize = 1; state.palette = 0
                for (time, zoom, rotation) in settings {
                    if [0, 1, 2, 5, 7].contains(scene) && time != 2.3 { continue }
                    state.zoom = zoom; state.rotation = rotation
                    let p = pixels(try renderer.renderOffscreen(time: time, audioBands: Array(repeating: 0.2, count: 32)))
                    var count = 0, minX = options.width, maxX = 0, minY = options.height, maxY = 0
                    var cells = Set<Int>()
                    for i in stride(from: 0, to: p.count, by: 4) where max(p[i], max(p[i+1], p[i+2])) > 16 {
                        let x = (i/4) % options.width, y = (i/4) / options.width
                        count += 1; minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
                        cells.insert((y * 4 / options.height) * 4 + x * 4 / options.width)
                    }
                    let w = Double(maxX - minX) / Double(options.width), h = Double(maxY - minY) / Double(options.height)
                    let lit = Double(count) / Double(options.width * options.height)
                    if w <= 0.95 || h <= 0.95 || lit <= 0.05 || cells.count < 14 {
                        print(String(format: "COVER %3d %-22@ t=%.1f zoom=%.2f rot=%.1f span %.2f x %.2f lit %.2f cells %d <-- FAIL", scene, names[scene] as NSString, time, zoom, rotation, w, h, lit, cells.count))
                    }
                }
                state.zoom = 1; state.rotation = 0
            }
        case "palcheck":
            // Accents can dominate a frame; verify each shared palette actually
            // changes the GPU output instead of requiring monochromatic ratios.
            let frameFeatures = try analyzer.frame(at: 1.33, clipStart: 0, clipEnd: 4)
            for scene in options.scenes {
                state.scene = scene; state.zoom = 1; state.brightness = 1; state.strobeEnabled = false
                var outputs = Set<Data>()
                for palette in VisualPalette.allCases {
                    state.palette = palette.rawValue
                    let image = pixels(try renderer.renderOffscreen(time: 1.33, audioBands: frameFeatures.bands))
                    outputs.insert(Data(image))
                }
                guard outputs.count == VisualPalette.allCases.count else {
                    throw Failure(text: "Palettes must produce distinct outputs for \(names[scene])")
                }
            }
            print("PASS: \(options.scenes.count * VisualPalette.allCases.count) distinct GPU palette outputs across \(options.scenes.count) effects")
        case "wrapcheck":
            // Isolated jumps: a frame step far larger than both neighbouring steps. Run at
            // zero Chaos and high Zoom speed so travel wraps are crossed many times.
            for scene in options.scenes {
                configure(state, scene: scene, options: options)
                state.chaos = 0
                if options.zoomSpeed == nil { state.zoomSpeed = 3 }
                var steps: [Double] = [], previous: [UInt8]? = nil
                let count = Int(options.duration * Double(options.fps))
                for frame in 0..<count {
                    let bytes = pixels(try renderer.renderOffscreen(time: options.start + Double(frame) / Double(options.fps), audioBands: [Float](repeating: 0, count: 32)))
                    if let previous { steps.append(difference(previous, bytes)) }
                    previous = bytes
                }
                var spikes: [String] = []
                for i in 1..<max(1, steps.count - 1) {
                    let local = max(steps[i - 1], steps[i + 1])
                    if steps[i] > local * 2.5 + 2 { spikes.append(String(format: "%.2fs:%.1f/%.1f", options.start + Double(i + 1) / Double(options.fps), steps[i], local)) }
                }
                if !spikes.isEmpty { print("WRAP \(scene) \(names[scene]) spikes \(spikes.count): " + spikes.prefix(4).joined(separator: " ")) }
            }
        case "musiccheck":
            // How much the soundtrack moves each design at its default look, over nine song
            // times. levels = instantaneous bands, attack swell and energy at the same music
            // clock; total = everything music adds over silence, including the music clock.
            // area = share of pixels the instantaneous levels change by more than 12/255.
            let silent = [Float](repeating: 0, count: 32)
            for scene in options.scenes {
                configure(state, scene: scene, options: options)
                var levels = 0.0, total = 0.0, area = 0.0
                let times = stride(from: 10.0, through: 90.0, by: 10.0).map { $0 + options.start - 10 }
                for time in times {
                    let f = try analyzer.frame(at: time, clipStart: 0, clipEnd: 10_000)
                    let full = pixels(try renderer.renderOffscreen(time: time, audioBands: f.bands, audioPulse: f.pulse, audioMomentum: f.momentum,
                        audioBeatMotionTime: f.beatMotionTime, audioEnvelopes: f.envelopes, audioSwell: f.swell))
                    let clockOnly = pixels(try renderer.renderOffscreen(time: time, audioBands: silent, audioBeatMotionTime: f.beatMotionTime))
                    let none = pixels(try renderer.renderOffscreen(time: time, audioBands: silent))
                    levels += difference(full, clockOnly); total += difference(full, none)
                    var changed = 0
                    for index in stride(from: 0, to: full.count, by: 4) where max(abs(Int(full[index]) - Int(clockOnly[index])), abs(Int(full[index + 1]) - Int(clockOnly[index + 1])), abs(Int(full[index + 2]) - Int(clockOnly[index + 2]))) > 12 { changed += 1 }
                    area += Double(changed) / Double(full.count / 4)
                }
                let n = Double(times.count)
                print(String(format: "MUSIC %3d %-22@ chaos %.2f  levels %6.2f  area %5.1f%%  total %6.2f", scene, names[scene] as NSString, state.chaos, levels / n, area / n * 100, total / n))
            }
        case "timing":
            for scene in options.scenes {
                configure(state, scene: scene, options: options)
                let first = ProcessInfo.processInfo.systemUptime
                _ = try renderer.renderOffscreen(time: 12, audioBands: [Float](repeating: 0.25, count: 32))
                let firstMs = (ProcessInfo.processInfo.systemUptime - first) * 1000
                let begin = ProcessInfo.processInfo.systemUptime
                let frames = 10
                for frame in 0..<frames {
                    _ = try renderer.renderOffscreen(time: 12 + Double(frame) / 60, audioBands: [Float](repeating: 0.3, count: 32), audioPulse: 0.5, audioMomentum: 0.6)
                }
                let ms = (ProcessInfo.processInfo.systemUptime - begin) * 1000 / Double(frames)
                print(String(format: "TIMING %3d %-22@ %dx%d %6.2f ms  (first frame incl. pipeline %6.1f ms)", scene, names[scene] as NSString, options.width, options.height, ms, firstMs))
            }
        default:
            throw Failure(text: "Unknown command \(options.command)")
        }
    }
}
