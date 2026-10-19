import AVFoundation
import SwiftUI

@main struct PulseCanvasMobileApp: App {
    @StateObject private var editor = MobileEditor()
    var body: some Scene {
        WindowGroup { MobileWorkspace(editor: editor).preferredColorScheme(.dark) }
    }
}
