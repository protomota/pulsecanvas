import AVFoundation
import SwiftUI

@main struct PulseCanvasMobileApp: App {
    @StateObject private var editor = MobileEditor()
    var body: some Scene {
        WindowGroup { MobileWorkspace(editor: editor)
                .preferredColorScheme(.dark)
                .modifier(PulseCanvasOnboardingPresentation(onReplay: { editor.audio.pause() }))
                // Prepare while the welcome pages are visible; immediate Skip is
                // also safe because both tasks keep their work off the UI thread.
                .task { await editor.start() }
                .task { try? await VisualizerRenderer.prepareLiveAssets() } }
    }
}
