import Foundation

@main struct CreatorEngagementSmoke {
    @MainActor static func main() {
        let suite = "PulseCanvas.EngagementValidation.\(UUID().uuidString)"
        let preferences = UserDefaults(suiteName: suite)!
        defer { preferences.removePersistentDomain(forName: suite) }
        var state = CreatorEngagement(preferences: preferences)
        precondition(!state.pendingExportThanks && !state.presentExportThanks())
        state.videoSaved()
        precondition(!state.presentExportThanks())
        precondition(!state.pendingExportThanks && !state.showsThanks)
        state = CreatorEngagement(preferences: preferences)
        precondition(!state.pendingExportThanks)
        state.videoSaved()
        precondition(state.pendingExportThanks)
        state = CreatorEngagement(preferences: preferences)
        precondition(state.pendingExportThanks)
        let secondWindow = CreatorEngagement(preferences: preferences)
        precondition(state.presentExportThanks())
        precondition(!secondWindow.presentExportThanks())
        #if STORE_BUILD
        precondition(!state.showsThanks) // Apple rating request comes first, with no custom gate.
        #else
        precondition(state.showsThanks)
        #endif
        precondition(!secondWindow.showsThanks && !state.presentExportThanks())
        state.showsThanks = false
        state = CreatorEngagement(preferences: preferences)
        for _ in 0..<4 { state.videoSaved() }
        precondition(!state.presentExportThanks())
        precondition(!state.pendingExportThanks && !state.showsThanks)

        // Upgrade with one saved video but no prompt: wait for the next successful save.
        preferences.removePersistentDomain(forName: suite)
        preferences.set(true, forKey: "PulseCanvas.engagement.firstVideoSaved.v1")
        state = CreatorEngagement(preferences: preferences)
        precondition(!state.pendingExportThanks)
        state.videoSaved()
        precondition(state.pendingExportThanks)

        // Already-seen prompts must remain suppressed after upgrading.
        preferences.removePersistentDomain(forName: suite)
        preferences.set(true, forKey: "PulseCanvas.engagement.firstVideoSaved.v1")
        preferences.set(true, forKey: "PulseCanvas.engagement.firstExportThanksShown.v1")
        preferences.set(true, forKey: "PulseCanvas.engagement.firstExportReviewRequested.v1")
        state = CreatorEngagement(preferences: preferences)
        state.videoSaved()
        precondition(!state.pendingExportThanks && !state.presentExportThanks())
        for code in ["USA", "GBR", "CAN", "DEU", "JPN", "US", "", nil] as [String?] {
            precondition(DeveloperSupportPolicy.allowsWebsiteTip(storeBuild: true, countryCode: code) == (code == "USA"))
            precondition(DeveloperSupportPolicy.allowsWebsiteTip(storeBuild: false, countryCode: code))
        }
        precondition(PulseCanvasCommunity.tips.absoluteString == "https://pulsecanvas.si/tips")
        #if STORE_BUILD
        precondition(!state.offersWebsiteTip)
        #else
        precondition(state.offersWebsiteTip)
        #endif
        print("PASS: no first-export prompt; second successful save persists across relaunch; one immediate review attempt without a support gate; concurrent windows, later exports and upgrade history; storefront policy and tips URL")
    }
}
