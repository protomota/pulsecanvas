import SwiftUI

@main struct PulseCanvasTVApp: App {
    @StateObject private var player = TVPlayer()
    var body: some Scene {
        WindowGroup { TVPlayerView(player: player)
                .preferredColorScheme(.dark)
                .modifier(PulseCanvasOnboardingPresentation(onReplay: { player.suspend() })) }
    }
}
