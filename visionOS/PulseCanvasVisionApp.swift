import SwiftUI

@main struct PulseCanvasVisionApp: App {
    @StateObject private var session = VisionSession.forLaunch()
    var body: some Scene {
        WindowGroup(id: "studio") {
            VisionStudioView(studio: session.activeStudio, session: session)
                .tint(Color(red: 0.95, green: 0.68, blue: 0.55))
        }.defaultSize(width: 1400, height: 950)
        ImmersiveSpace(id: "visualizer-stage") {
            VisionImmersiveView(studio: session.activeStudio, session: session)
        }.immersionStyle(selection: Binding(get: { session.fullImmersion ? .full : .mixed }, set: { _ in }), in: .mixed, .full)
    }
}
