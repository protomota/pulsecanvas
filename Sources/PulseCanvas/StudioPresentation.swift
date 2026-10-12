import AppKit
import SwiftUI

@MainActor
final class StudioPresentationController: NSObject, ObservableObject {
    enum Mode {
        case studio, visualizer
    }
    @Published private(set) var isPresented = false
    @Published private(set) var mode: Mode = .studio
    var followsStudioTimeline: Bool { !isPresented || mode == .studio }
    private weak var window: NSWindow?
    private var ownsFullScreen = false
    private var originalBackground: NSColor?
    private var keyboardMonitor: Any?

    var canPresentEditorSheet: Bool {
        NSApplication.shared.isActive && window?.isKeyWindow == true
            && window?.attachedSheet == nil && NSApplication.shared.modalWindow == nil
    }

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(enteredFullScreen(_:)), name: NSWindow.didEnterFullScreenNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(exitedFullScreen(_:)), name: NSWindow.didExitFullScreenNotification, object: nil)
    }

    func attach(_ window: NSWindow?) { self.window = window }

    @discardableResult
    func present(audio: AudioController, mode: Mode = .studio) -> Bool {
        guard let window, !isPresented else { return false }
        originalBackground = window.backgroundColor
        window.backgroundColor = .black
        ownsFullScreen = !window.styleMask.contains(.fullScreen)
        self.mode = mode
        isPresented = true
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate()
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self, weak audio] event in
            guard let self, self.isPresented, event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty else { return event }
            if event.isARepeat && (event.keyCode == 53 || event.keyCode == 49) { return nil }
            if event.keyCode == 53 { audio?.pause(); self.dismiss(); return nil }
            if event.keyCode == 49 { audio?.playPause(); return nil }
            return event
        }
        if ownsFullScreen { window.toggleFullScreen(nil) }
        return true
    }

    func dismiss() {
        guard isPresented else { return }
        stopMonitoringKeyboard()
        isPresented = false
        if ownsFullScreen && window?.styleMask.contains(.fullScreen) == true { window?.toggleFullScreen(nil) }
        else if !ownsFullScreen { restoreBackground() }
    }

    @objc private func enteredFullScreen(_ notification: Notification) {
        guard let source = notification.object as? NSWindow, source === window else { return }
        // Escape can arrive while the native entrance animation is still running.
        if ownsFullScreen && !isPresented { source.toggleFullScreen(nil) }
    }

    @objc private func exitedFullScreen(_ notification: Notification) {
        guard let source = notification.object as? NSWindow, source === window else { return }
        stopMonitoringKeyboard()
        restoreBackground()
        ownsFullScreen = false
        isPresented = false
    }
    private func stopMonitoringKeyboard() {
        if let keyboardMonitor { NSEvent.removeMonitor(keyboardMonitor) }
        keyboardMonitor = nil
    }

    private func restoreBackground() {
        if let originalBackground { window?.backgroundColor = originalBackground }
        originalBackground = nil
    }
}

@MainActor
struct StudioWindowReader: NSViewRepresentable {
    let attach: (NSWindow?) -> Void
    final class WindowView: NSView {
        var attach: ((NSWindow?) -> Void)?
        override func viewDidMoveToWindow() { super.viewDidMoveToWindow(); attach?(window) }
    }
    func makeNSView(context: Context) -> WindowView {
        let view = WindowView(); view.attach = attach; return view
    }
    func updateNSView(_ view: WindowView, context: Context) { view.attach = attach }
}

@MainActor
struct StudioPresentationView: View {
    @ObservedObject var render: RenderState
    @ObservedObject var audio: AudioController
    @ObservedObject var studio: StudioStore
    var mode: StudioPresentationController.Mode = .studio
    var aspect: SocialAspect = .wide
    let exit: () -> Void
    @AppStorage("PulseCanvas.presentationMatchAspect.v1") private var matchAspectRatio = false
    @State private var controlsVisible = true
    @State private var hideControls: Task<Void, Never>?

    var body: some View {
        GeometryReader { space in
            let width = matchAspectRatio ? min(space.size.width, space.size.height * aspect.aspectRatio) : space.size.width
            let height = matchAspectRatio ? width / aspect.aspectRatio : space.size.height
            ZStack(alignment: .bottom) {
                Color.black
                VisualizerView(state: render)
                    .frame(width: width, height: height)
                    .clipped()
                    .frame(width: space.size.width, height: space.size.height)
                if controlsVisible || !audio.isPlaying {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(RenderState.sceneNames[render.scene]).font(.headline)
                            Text(mode == .studio ? "Studio · Section \(studio.selectedSegment + 1) of \(studio.segments.count) · Esc to exit" : "Visualizer · Esc to exit")
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("Match aspect ratio", isOn: $matchAspectRatio)
                            .toggleStyle(.checkbox).controlSize(.large)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12).frame(minHeight: 44)
                            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 11))
                            .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(.white.opacity(0.13)))
                            .help("Fit the visualization to the project’s \(aspect.rawValue) aspect ratio, with black bars where needed.")
                        Button { audio.playPause(); revealControls() } label: {
                            Label(audio.isPlaying ? "Pause" : "Play", systemImage: audio.isPlaying ? "pause.fill" : "play.fill")
                        }.accessibilityLabel(audio.isPlaying ? "Pause presentation" : "Play presentation")
                        Button { audio.seek(fraction: 0); audio.playFullSoundtrack(); revealControls() } label: {
                            Label("Restart", systemImage: "backward.end.fill")
                        }.accessibilityLabel("Restart presentation")
                        Button(action: exit) { Label("Exit presentation", systemImage: "arrow.down.right.and.arrow.up.left") }
                    }.buttonStyle(StudioButtonStyle(compact: true))
                        .padding(18).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .padding(24).transition(.opacity)
                }
            }.contentShape(Rectangle())
                .onContinuousHover { phase in if case .active = phase { revealControls() } }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black)
            .ignoresSafeArea().preferredColorScheme(.dark)
            .onAppear { revealControls() }
            .onChange(of: audio.isPlaying) { _, _ in revealControls() }
            .onChange(of: matchAspectRatio) { _, _ in revealControls() }
            .onDisappear { hideControls?.cancel() }
    }

    private func revealControls() {
        hideControls?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { controlsVisible = true }
        hideControls = Task { @MainActor in
            do { try await Task.sleep(for: .seconds(3)) } catch { return }
            guard audio.isPlaying else { return }
            withAnimation(.easeOut(duration: 0.3)) { controlsVisible = false }
        }
    }
}
