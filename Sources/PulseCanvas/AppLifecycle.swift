import AppKit

/// Closing the last editor or radio window ends playback and quits, even if an
/// auxiliary credits window remains open. Minimizing is not a close event.
@MainActor
final class AppLifecycle: NSObject, NSApplicationDelegate {
    private let primaryWindows = NSHashTable<NSWindow>.weakObjects()
    private weak var audio: AudioController?
    private weak var radio: RadioController?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification, object: nil)
    }

    func attach(audio: AudioController, radio: RadioController) {
        self.audio = audio; self.radio = radio
    }

    func track(_ window: NSWindow?) {
        if let window { primaryWindows.add(window) }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) { stopPlayback() }

    private func stopPlayback() { radio?.shutdown(); audio?.stop() }

    @objc private func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, primaryWindows.contains(window) else { return }
        primaryWindows.remove(window)
        guard primaryWindows.allObjects.isEmpty else { return }
        stopPlayback()
        // Finish the native close event before terminating the SwiftUI scene host.
        DispatchQueue.main.async { NSApplication.shared.terminate(nil) }
    }
}
