#if DIRECT_BUILD && canImport(Sparkle)
import Combine
import Sparkle
import SwiftUI

/// The direct-download edition retains Sparkle for the lifetime of the app.
/// App Store updates are delivered exclusively by Apple.
@MainActor final class AppUpdater: ObservableObject {
    private let controller: SPUStandardUpdaterController
    private var observation: NSKeyValueObservation?
    @Published private(set) var canCheck = false
    @Published var automaticChecks: Bool {
        didSet { controller.updater.automaticallyChecksForUpdates = automaticChecks }
    }
    init() {
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        automaticChecks = controller.updater.automaticallyChecksForUpdates
        observation = controller.updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] updater, _ in
            let ready = updater.canCheckForUpdates
            Task { @MainActor in self?.canCheck = ready }
        }
    }
    func checkForUpdates() { controller.checkForUpdates(nil) }
}
#endif
