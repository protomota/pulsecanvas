import SwiftUI

@main struct PulseCanvasVisionApp: App {
    @StateObject private var studio = VisionStudio()
    var body: some Scene {
        WindowGroup(id: "studio") {
            VisionStudioView(studio: studio)
                .tint(Color(red: 0.95, green: 0.68, blue: 0.55))
        }.defaultSize(width: 1400, height: 950)
        ImmersiveSpace(id: "visualizer-stage") {
            VisionImmersiveView(studio: studio)
        }.immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
