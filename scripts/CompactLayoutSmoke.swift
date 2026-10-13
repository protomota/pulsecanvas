import AppKit
import MetalKit
import SwiftUI

@main struct CompactLayoutSmoke {
    @MainActor static func main() {
        _ = NSApplication.shared
        let defaults = UserDefaults(suiteName: "PulseCanvas.layout-test.\(UUID().uuidString)")!
        let studio = StudioStore(defaults: defaults)
        studio.isStudio = true
        studio.segments = (0..<32).map { StudioSegment(start: Double($0 * 8), end: Double(($0 + 1) * 8), scene: $0 % 31, bars: 4) }
        studio.detectedBPM = 128
        let render = RenderState()
        let audio = AudioController()
        let exporter = SocialExportController()
        // The standalone test has its own defaults domain; retain its format too.
        let previousFormat = UserDefaults.standard.data(forKey: "PulseCanvas.videoFormat.v1")
        defer {
            if let previousFormat { UserDefaults.standard.set(previousFormat, forKey: "PulseCanvas.videoFormat.v1") }
            else { UserDefaults.standard.removeObject(forKey: "PulseCanvas.videoFormat.v1") }
        }
        let host = NSHostingView(rootView: CreatorView(render: render, audio: audio, studio: studio,
            exporter: exporter, presentation: StudioPresentationController()).preferredColorScheme(.dark))
        for height in stride(from: 180, through: 600, by: 1) {
            let layout = CanvasPreviewLayout(size: CGSize(width: 900, height: height), aspectRatio: 16.0 / 9)
            let next = CanvasPreviewLayout(size: CGSize(width: 900, height: height + 1), aspectRatio: 16.0 / 9)
            precondition(next.preview.height >= layout.preview.height, "Resizing larger must not collapse the image")
        }
        var previousHeights: [String: CGFloat] = [:]
        for studioMode in [true, false] {
            studio.isStudio = studioMode
            let modeName = studioMode ? "Studio" : "Visualizers"
            for size in [CGSize(width: 1080, height: 740), CGSize(width: 1440, height: 740), CGSize(width: 1440, height: 800), CGSize(width: 1440, height: 859), CGSize(width: 1440, height: 860), CGSize(width: 1440, height: 940)] {
                for aspect in SocialAspect.allCases {
                    exporter.aspect = aspect
                    host.frame = CGRect(origin: .zero, size: size)
                    host.layoutSubtreeIfNeeded()
                    RunLoop.main.run(until: Date().addingTimeInterval(0.1))
                    host.layoutSubtreeIfNeeded()
                    let metalViews = descendants(host).compactMap { $0 as? MTKView }
                    precondition(metalViews.count == 1, "Resize must retain one renderer")
                    let preview = metalViews[0].convert(metalViews[0].bounds, to: host)
                    precondition(preview.height >= 200, "Studio preview collapsed: \(preview)")
                    precondition(abs(preview.width / preview.height - aspect.aspectRatio) < 0.01, "Preview aspect changed")
                    precondition(host.bounds.contains(preview), "Preview escaped the window")
                    let key = "\(modeName)/\(size.width)/\(aspect.rawValue)"
                    if let previousHeight = previousHeights[key] { precondition(preview.height + 1 >= previousHeight, "Growing the window shrank the preview: \(key), window \(size.height), \(previousHeight) → \(preview.height)") }
                    previousHeights[key] = preview.height
                    print("PASS \(modeName) \(Int(size.width))×\(Int(size.height)) \(aspect.rawValue): preview \(Int(preview.width))×\(Int(preview.height))")
                    if studioMode && size.width == 1080 && aspect == .wide, let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) {
                        host.cacheDisplay(in: host.bounds, to: bitmap)
                        try! bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: ".build/validation/compact-studio-chrome.png"))
                    }
                }
            }
        }
        print("PASS compact editor: all canvas shapes retain visible previews with transport and presentation controls; one renderer survives resizing")
        let aspectPreference = "PulseCanvas.presentationMatchAspect.v1"
        let previousAspectPreference = UserDefaults.standard.object(forKey: aspectPreference)
        defer {
            if let previousAspectPreference { UserDefaults.standard.set(previousAspectPreference, forKey: aspectPreference) }
            else { UserDefaults.standard.removeObject(forKey: aspectPreference) }
        }
        for scene in [10, 31] {
            render.scene = scene
            for mode in [StudioPresentationController.Mode.studio, .visualizer] {
                for aspect in SocialAspect.allCases {
                    let presentationHost = NSHostingView(rootView: StudioPresentationView(
                        render: render, audio: audio, studio: studio, mode: mode, aspect: aspect, exit: {}))
                    for size in [CGSize(width: 1440, height: 900), CGSize(width: 900, height: 1440)] {
                        presentationHost.frame = CGRect(origin: .zero, size: size)
                        var retainedRenderer: MTKView?
                        for fit in [false, true, false] {
                            UserDefaults.standard.set(fit, forKey: aspectPreference)
                            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
                            presentationHost.layoutSubtreeIfNeeded()
                            let views = descendants(presentationHost).compactMap { $0 as? MTKView }
                            precondition(views.count == 1, "Presentation must retain one renderer")
                            if let retainedRenderer { precondition(views[0] === retainedRenderer, "Toggling aspect must resize the current renderer without restarting it") }
                            retainedRenderer = views[0]
                            let frame = views[0].convert(views[0].bounds, to: presentationHost)
                            precondition(abs(frame.midX - size.width / 2) < 1 && abs(frame.midY - size.height / 2) < 1, "Presentation must stay centered")
                            precondition(frame.minX >= -1 && frame.minY >= -1 && frame.maxX <= size.width + 1 && frame.maxY <= size.height + 1)
                            if fit {
                                precondition(abs(frame.width / frame.height - aspect.aspectRatio) < 0.01, "Presentation must match the project aspect ratio")
                                precondition(abs(frame.width - size.width) < 1 || abs(frame.height - size.height) < 1, "Fitted presentation must use the largest uncropped frame")
                            } else {
                                precondition(abs(frame.width - size.width) < 1 && abs(frame.height - size.height) < 1, "Unchecked presentation must fill the display")
                            }
                        }
                    }
                }
            }
        }
        print("PASS presentation aspect: all five project shapes, both presentation modes, native/ProjectM renderers and wide/tall displays; centered fit, full-screen fill and renderer continuity verified")
    }

    @MainActor static func descendants(_ view: NSView) -> [NSView] {
        view.subviews.flatMap { [$0] + descendants($0) }
    }
}
