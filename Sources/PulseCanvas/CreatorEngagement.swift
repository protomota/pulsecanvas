import Combine
import Foundation
import StoreKit

/// Export milestones belong to the installation, independently of song/project settings.
@MainActor
final class CreatorEngagement: ObservableObject {
    enum Action: String, CaseIterable { case review, tip, share, feedback }
    @Published private(set) var clickedActions: Set<Action>
    @Published private(set) var pendingExportThanks: Bool
    @Published var showsThanks = false
    #if STORE_BUILD
    @Published private(set) var offersWebsiteTip = false
    #else
    @Published private(set) var offersWebsiteTip = true
    #endif
    private let preferences: UserDefaults
    private let saveCountKey = "PulseCanvas.engagement.successfulVideoSaves.v1"
    private let legacySavedKey = "PulseCanvas.engagement.firstVideoSaved.v1"
    private let shownKey = "PulseCanvas.engagement.firstExportThanksShown.v1"
    private let reviewKey = "PulseCanvas.engagement.firstExportReviewRequested.v1"
    private let clicksKey = "PulseCanvas.engagement.clickedActions.v1"
    private let presentedSaveKey = "PulseCanvas.engagement.thanksPresentedSave.v2"
    private let lastSaveKey = "PulseCanvas.engagement.lastSuccessfulSaveID.v1"

    init(preferences: UserDefaults = .standard) {
        self.preferences = preferences
        clickedActions = Set((preferences.stringArray(forKey: clicksKey) ?? []).compactMap(Action.init(rawValue:)))
        // Count a saved video from the earlier milestone implementation as one export.
        // An old dismissal or StoreKit request is not evidence that an action was clicked.
        if preferences.object(forKey: saveCountKey) == nil, preferences.bool(forKey: legacySavedKey) {
            preferences.set(1, forKey: saveCountKey)
        }
        pendingExportThanks = false
        refreshPending()
    }

    func videoSaved(id: UUID = UUID()) {
        // All editor windows observe the same export. Count its success only once.
        guard preferences.string(forKey: lastSaveKey) != id.uuidString else {
            refreshPending()
            return
        }
        preferences.set(id.uuidString, forKey: lastSaveKey)
        let count = min(1_000_000_000, max(0, preferences.integer(forKey: saveCountKey))) + 1
        preferences.set(count, forKey: saveCountKey)
        refreshPending()
    }

    var availableActions: [Action] {
        offersWebsiteTip ? Action.allCases : [.review, .share, .feedback]
    }

    func hasClicked(_ action: Action) -> Bool { storedClicks.contains(action) }

    func recordClick(_ action: Action) {
        var clicks = storedClicks
        clicks.insert(action)
        preferences.set(clicks.map(\.rawValue).sorted(), forKey: clicksKey)
        clickedActions = clicks
        refreshPending()
    }

    /// Resets only local button clicks. Apple controls its own rating-sheet history.
    func resetClickedActions() {
        preferences.removeObject(forKey: clicksKey)
        clickedActions = []
        // Resume reminders after the next save, not immediately on closing this screen.
        preferences.set(preferences.integer(forKey: saveCountKey), forKey: presentedSaveKey)
        refreshPending()
    }

    private var storedClicks: Set<Action> {
        Set((preferences.stringArray(forKey: clicksKey) ?? []).compactMap(Action.init(rawValue:)))
    }

    private func refreshPending() {
        let count = preferences.integer(forKey: saveCountKey)
        #if STORE_BUILD
        pendingExportThanks = count >= 2 && !preferences.bool(forKey: shownKey) && !hasClicked(.review)
        #else
        pendingExportThanks = count >= 2 && count > preferences.integer(forKey: presentedSaveKey)
            && !availableActions.allSatisfy(hasClicked)
        #endif
    }

    func observeStorefront() async {
        #if STORE_BUILD
        offersWebsiteTip = DeveloperSupportPolicy.allowsWebsiteTip(storeBuild: true, countryCode: await Storefront.current?.countryCode)
        for await storefront in Storefront.updates {
            guard !Task.isCancelled else { return }
            offersWebsiteTip = DeveloperSupportPolicy.allowsWebsiteTip(storeBuild: true, countryCode: storefront.countryCode)
        }
        #endif
    }

    /// Store builds make one ungated Apple review request; direct builds repeat their
    /// styled reminder on later saves until all available buttons have been clicked.
    func presentExportThanks() -> Bool {
        guard pendingExportThanks, !showsThanks, preferences.integer(forKey: saveCountKey) >= 2 else { return false }
        pendingExportThanks = false
        #if STORE_BUILD
        guard !preferences.bool(forKey: shownKey) else { return false }
        preferences.set(true, forKey: shownKey)
        guard !preferences.bool(forKey: reviewKey) else { return false }
        preferences.set(true, forKey: reviewKey)
        return true
        #else
        let count = preferences.integer(forKey: saveCountKey)
        guard count > preferences.integer(forKey: presentedSaveKey), !availableActions.allSatisfy(hasClicked) else { return false }
        preferences.set(count, forKey: presentedSaveKey)
        showsThanks = true
        return false
        #endif
    }

}

enum PulseCanvasCommunity {
    static let website = URL(string: "https://pulsecanvas.si/")!
    static let tips = URL(string: "https://pulsecanvas.si/tips")!
    static let feedback = URL(string: "https://pulsecanvas.si/support/")!
    static let review = URL(string: "https://apps.apple.com/app/id6821642700?action=write-review")!
}

enum DeveloperSupportPolicy {
    /// Use the actual Apple storefront, not the Mac's language, locale, or location.
    /// No external-purchase entitlement is configured for this worldwide Mac release.
    static func allowsWebsiteTip(storeBuild: Bool, countryCode: String?) -> Bool {
        !storeBuild || countryCode == "USA"
    }
}
