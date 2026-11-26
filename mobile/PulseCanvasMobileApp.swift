import AVFoundation
import SwiftUI

@main struct PulseCanvasMobileApp: App {
    @StateObject private var editor = { _ = UserBackup.startupError; return MobileEditor() }()
    var body: some Scene {
        WindowGroup { MobileWorkspace(editor: editor)
                .preferredColorScheme(.dark)
                .modifier(PulseCanvasOnboardingPresentation(onReplay: { editor.audio.pause() }))
                // Prepare while the welcome pages are visible; immediate Skip is
                // also safe because both tasks keep their work off the UI thread.
                .task { await editor.start() }
                .task { CloudSyncService.shared.start() }
                .onReceive(NotificationCenter.default.publisher(for: .pulseCanvasCloudDataApplied)) { _ in
                    editor.studio.reloadCloudPresets(); editor.radio.reloadCloudFavorites()
                    if !editor.audio.isPlaying { editor.studio.apply(to: editor.render) }
                }
                .task { try? await VisualizerRenderer.prepareLiveAssets() } }
    }
}
