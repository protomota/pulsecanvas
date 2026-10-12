import Combine
import Foundation
import StoreKit

/// Export milestones belong to the installation, independently of song/project settings.
@MainActor
final class CreatorEngagement: ObservableObject {
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

    init(preferences: UserDefaults = .standard) {
        self.preferences = preferences
        // Count a saved video from the earlier milestone implementation as one export.
        // Keep dismissal/review history so an update never repeats a prompt already shown.
        if preferences.object(forKey: saveCountKey) == nil, preferences.bool(forKey: legacySavedKey) {
            preferences.set(1, forKey: saveCountKey)
        }
        pendingExportThanks = preferences.integer(forKey: saveCountKey) >= 2 && !preferences.bool(forKey: shownKey)
    }

    func videoSaved() {
        let count = min(2, min(2, max(0, preferences.integer(forKey: saveCountKey))) + 1)
        preferences.set(count, forKey: saveCountKey)
        pendingExportThanks = count >= 2 && !preferences.bool(forKey: shownKey)
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

    /// Request a review at the export milestone, without a custom pre-prompt or support gate.
    /// Apple controls whether the StoreKit rating sheet actually appears.
    func presentExportThanks() -> Bool {
        guard pendingExportThanks, !showsThanks, preferences.integer(forKey: saveCountKey) >= 2 else { return false }
        pendingExportThanks = false
        guard !preferences.bool(forKey: shownKey) else { return false }
        preferences.set(true, forKey: shownKey)
        #if !STORE_BUILD
        showsThanks = true
        #endif
        guard !preferences.bool(forKey: reviewKey) else { return false }
        preferences.set(true, forKey: reviewKey)
        return true
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
