import AppKit
import Foundation

@main struct UpdaterSmoke {
    @MainActor static func main() async throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        app.finishLaunching()
        let updater = AppUpdater()
        let expected = Bundle.main.object(forInfoDictionaryKey: "UpdaterExpectedVersion") as? String
        let checksEnabled = Bundle.main.object(forInfoDictionaryKey: "SUEnableAutomaticChecks") as? Bool ?? false
        for _ in 0..<500 {
            if let expected, updater.availableVersion == expected { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        precondition(updater.automaticChecks == checksEnabled)
        precondition(updater.availableVersion == expected,
                     "Unexpected update availability: \(updater.availableVersion ?? "none")")
        if expected != nil { precondition(updater.canCheck, "The available update must be actionable") }
        print("PASS real Sparkle probe: \(expected ?? "no update"), automatic checks \(checksEnabled)")
    }
}
