#if DIRECT_BUILD && canImport(Sparkle) && !LOCAL_BUILD
import Combine
import Sparkle
import SwiftUI

/// The direct-download edition retains Sparkle for the lifetime of the app.
/// App Store updates are delivered exclusively by Apple.
@MainActor final class AppUpdater: NSObject, ObservableObject, SPUUpdaterDelegate, SPUStandardUserDriverDelegate {
    private var controller: SPUStandardUpdaterController!
    private var observation: NSKeyValueObservation?
    private var activation: AnyCancellable?
    private var probeTimer: Timer?
    private var lastProbe: Date?
    private var started = false
    @Published private(set) var availableVersion: String?
    @Published private(set) var canCheck = false
    @Published var automaticChecks = false {
        didSet {
            guard started else { return }
            controller.updater.automaticallyChecksForUpdates = automaticChecks
            if automaticChecks { lastProbe = nil; probeIfNeeded() }
        }
    }
    override init() {
        super.init()
        controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: self, userDriverDelegate: self)
        automaticChecks = controller.updater.automaticallyChecksForUpdates
        observation = controller.updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] updater, _ in
            let ready = updater.canCheckForUpdates
            Task { @MainActor in
                self?.canCheck = ready
                if ready { self?.probeIfNeeded() }
            }
        }
        controller.startUpdater()
        started = true
        activation = NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification).sink { [weak self] _ in
            Task { @MainActor in self?.probeIfNeeded() }
        }
        probeTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.probeIfNeeded() }
        }
        probeIfNeeded()
    }
    deinit { probeTimer?.invalidate() }

    private func probeIfNeeded() {
        guard started, automaticChecks, availableVersion == nil,
              controller.updater.canCheckForUpdates, !controller.updater.sessionInProgress,
              lastProbe.map({ Date().timeIntervalSince($0) >= 900 }) ?? true else { return }
        lastProbe = Date()
        controller.updater.checkForUpdateInformation()
    }
    func checkForUpdates() {
        guard controller.updater.canCheckForUpdates else { return }
        controller.checkForUpdates(nil)
    }

    nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        let version = item.displayVersionString
        Task { @MainActor [weak self] in self?.availableVersion = version }
    }
    nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: any Error) {
        Task { @MainActor [weak self] in self?.availableVersion = nil }
    }
    nonisolated func updater(_ updater: SPUUpdater, userDidMake choice: SPUUserUpdateChoice,
                             forUpdate updateItem: SUAppcastItem, state: SPUUserUpdateState) {
        if choice == .skip {
            Task { @MainActor [weak self] in self?.availableVersion = nil }
        }
    }
    nonisolated var supportsGentleScheduledUpdateReminders: Bool { true }
    nonisolated func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool { false }
    nonisolated func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool,
                                                              forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        let version = update.displayVersionString
        Task { @MainActor [weak self] in self?.availableVersion = version }
    }
}

struct AppUpdateButton: View {
    @ObservedObject var updater: AppUpdater
    var body: some View {
        if let version = updater.availableVersion {
            Button { updater.checkForUpdates() } label: {
                Image(systemName: "tray.and.arrow.down.fill").font(.system(size: 17, weight: .semibold))
            }
            .buttonStyle(StudioButtonStyle(treatment: .primary, circular: true))
            .disabled(!updater.canCheck)
            .help("Update \(version) is available. Click to install.")
            .accessibilityLabel("Install update \(version)")
        }
    }
}
#endif
