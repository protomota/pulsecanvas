import AppKit
import MetalKit
import Foundation

@MainActor
private final class LiveRendererCheck: NSObject {
    let app: NSApplication
    let window: NSWindow
    let state: RenderState
    let output: VisualizerRenderer
    var completed = 0
    var failures = 0
    let scenes = NativeEffects.activeIDs
    var count: Int { scenes.count }

    init(app: NSApplication, window: NSWindow, state: RenderState) throws {
        self.app = app; self.window = window; self.state = state
        output = VisualizerRenderer(state: state)
        super.init()
        try output.prepareOffscreen(width: 400, height: 300)
    }

    @objc func check(_ timer: Timer) {
        // Leave the live MTKView drawing between checks. Read pixels through the
        // same offscreen path used by MP4 export, without capture hooks in the app.
        let liveError = state.errorMessage
        do {
            let texture = try output.renderOffscreen(time: 4.2, audioBands: state.audioBands)
            var pixels = [UInt8](repeating: 0, count: texture.width * texture.height * 4)
            texture.getBytes(&pixels, bytesPerRow: texture.width * 4, from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0)
            var lit = 0; var maxRGB = 0
            for p in stride(from: 0, to: pixels.count, by: 4) {
                let v = max(Int(pixels[p]), max(Int(pixels[p+1]), Int(pixels[p+2])))
                if v > 12 { lit += 1 }; maxRGB = max(maxRGB, v)
            }
            let ok = lit > 50 && maxRGB > 30 && liveError == nil && state.errorMessage == nil
            if !ok { failures += 1 }
            print("\(ok ? "PASS" : "FAIL") scene \(state.scene) \(RenderState.sceneNames[state.scene]), blur \(state.motionBlur): \(lit) lit pixels, max \(maxRGB), live error \(liveError ?? "none")")
        } catch { failures += 1; print("FAIL: \(error)") }
        completed += 1
        if completed >= count * 2 {
            timer.invalidate()
            print("Completed \(completed) live preview/error and offline GPU checks, failures=\(failures)")
            window.orderOut(nil); app.stop(nil)
            let exitCode: Int32 = failures == 0 ? 0 : 1
            DispatchQueue.main.async { exit(exitCode) }
        } else {
            state.scene = scenes[completed % count]
            state.motionBlur = completed >= count ? 0.75 : 0
        }
    }
}

@main struct RendererSmokeTest {
    @MainActor static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let state = RenderState()
        state.audioBands = (0..<32).map { Float($0 % 8) / 10 }
        let renderer = VisualizerRenderer(state: state)
        let view = MTKView(frame: NSRect(x: 0, y: 0, width: 400, height: 300), device: MTLCreateSystemDefaultDevice())
        view.colorPixelFormat = .bgra8Unorm; view.framebufferOnly = false
        view.preferredFramesPerSecond = 60; view.delegate = renderer
        let window = NSWindow(contentRect: view.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.title = "Visual renderer validation"; window.contentView = view
        let check = try LiveRendererCheck(app: app, window: window, state: state)
        renderer.attach(view)
        if let error = state.errorMessage { print("FAIL: \(error)"); exit(1) }
        window.orderFront(nil)
        Timer.scheduledTimer(timeInterval: 0.2, target: check, selector: #selector(LiveRendererCheck.check(_:)), userInfo: nil, repeats: true)
        app.run()
        _ = renderer
    }
}
