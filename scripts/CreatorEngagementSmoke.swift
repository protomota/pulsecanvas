import Foundation

@main struct CreatorEngagementSmoke {
    @MainActor static func main() {
        let suite = "PulseCanvas.EngagementValidation.\(UUID().uuidString)"
        let preferences = UserDefaults(suiteName: suite)!
        defer { preferences.removePersistentDomain(forName: suite) }
        var state = CreatorEngagement(preferences: preferences)
        precondition(!state.pendingExportThanks && !state.presentExportThanks())
        let firstSave = UUID()
        state.videoSaved(id: firstSave)
        // Multiple editor windows must count one completed export only once.
        CreatorEngagement(preferences: preferences).videoSaved(id: firstSave)
        precondition(preferences.integer(forKey: "PulseCanvas.engagement.successfulVideoSaves.v1") == 1)
        precondition(!state.pendingExportThanks && !state.showsThanks)
        state = CreatorEngagement(preferences: preferences)
        let secondSave = UUID()
        state.videoSaved(id: secondSave)
        let otherWindow = CreatorEngagement(preferences: preferences)
        otherWindow.videoSaved(id: secondSave)
        precondition(preferences.integer(forKey: "PulseCanvas.engagement.successfulVideoSaves.v1") == 2)
        state = CreatorEngagement(preferences: preferences)
        precondition(state.pendingExportThanks)
        let secondWindow = CreatorEngagement(preferences: preferences)
        #if STORE_BUILD
        precondition(state.presentExportThanks())
        precondition(!state.showsThanks)
        #else
        precondition(!state.presentExportThanks()) // Direct builds never request StoreKit.
        precondition(state.showsThanks)
        #endif
        precondition(!secondWindow.presentExportThanks() && !secondWindow.showsThanks)
        precondition(!state.presentExportThanks())
        state.showsThanks = false
        state = CreatorEngagement(preferences: preferences)
        precondition(!state.pendingExportThanks) // Dismissal doesn't loop the same export.
        state.videoSaved()
        #if STORE_BUILD
        precondition(!state.pendingExportThanks && !state.presentExportThanks())
        #else
        precondition(state.pendingExportThanks)
        _ = state.presentExportThanks()
        precondition(state.showsThanks)
        state.showsThanks = false
        #endif
        state.recordClick(.review)
        precondition(CreatorEngagement(preferences: preferences).hasClicked(.review))
        precondition(!state.hasClicked(.tip) && !state.hasClicked(.share) && !state.hasClicked(.feedback))
        state.videoSaved()
        #if !STORE_BUILD
        precondition(state.pendingExportThanks) // One action doesn't finish all four.
        #endif
        for action in state.availableActions { state.recordClick(action) }
        state = CreatorEngagement(preferences: preferences)
        precondition(state.availableActions.allSatisfy(state.hasClicked))
        for _ in 0..<4 { state.videoSaved() }
        precondition(!state.pendingExportThanks && !state.presentExportThanks())

        // Reset preserves exports, Apple's review history, and unrelated user data.
        let savedCount = preferences.integer(forKey: "PulseCanvas.engagement.successfulVideoSaves.v1")
        preferences.set("keep-project", forKey: "PulseCanvas.studio.v1")
        state.resetClickedActions()
        precondition(state.clickedActions.isEmpty && !state.pendingExportThanks)
        state = CreatorEngagement(preferences: preferences)
        precondition(state.clickedActions.isEmpty && !state.pendingExportThanks)
        precondition(preferences.integer(forKey: "PulseCanvas.engagement.successfulVideoSaves.v1") == savedCount)
        precondition(preferences.string(forKey: "PulseCanvas.studio.v1") == "keep-project")
        state.videoSaved()
        #if STORE_BUILD
        precondition(!state.pendingExportThanks)
        precondition(preferences.bool(forKey: "PulseCanvas.engagement.firstExportReviewRequested.v1"))
        #else
        precondition(state.pendingExportThanks)
        #endif

        // An explicitly clicked review link before export prevents the Apple request.
        preferences.removePersistentDomain(forName: suite)
        state = CreatorEngagement(preferences: preferences)
        state.recordClick(.review)
        state.videoSaved(); state.videoSaved()
        #if STORE_BUILD
        precondition(!state.pendingExportThanks && !state.presentExportThanks())
        #else
        precondition(state.pendingExportThanks)
        #endif

        // Migrate old save milestones without inventing click/completion history.
        preferences.removePersistentDomain(forName: suite)
        preferences.set(true, forKey: "PulseCanvas.engagement.firstVideoSaved.v1")
        state = CreatorEngagement(preferences: preferences)
        precondition(!state.pendingExportThanks)
        state.videoSaved()
        precondition(state.pendingExportThanks)
        preferences.set(true, forKey: "PulseCanvas.engagement.firstExportThanksShown.v1")
        preferences.set(true, forKey: "PulseCanvas.engagement.firstExportReviewRequested.v1")
        state = CreatorEngagement(preferences: preferences)
        precondition(state.clickedActions.isEmpty)
        #if STORE_BUILD
        precondition(!state.pendingExportThanks && !state.presentExportThanks())
        #else
        precondition(state.pendingExportThanks)
        #endif
        for code in ["USA", "GBR", "CAN", "DEU", "JPN", "US", "", nil] as [String?] {
            precondition(DeveloperSupportPolicy.allowsWebsiteTip(storeBuild: true, countryCode: code) == (code == "USA"))
            precondition(DeveloperSupportPolicy.allowsWebsiteTip(storeBuild: false, countryCode: code))
        }
        precondition(PulseCanvasCommunity.tips.absoluteString == "https://pulsecanvas.si/tips")
        #if STORE_BUILD
        precondition(!state.offersWebsiteTip && !state.availableActions.contains(.tip))
        #else
        precondition(state.offersWebsiteTip && state.availableActions.count == 4)
        #endif
        print("PASS: second-save eligibility, deduplicated exports, relaunch and concurrent windows; per-action clicks, completion, reset and upgrade; direct reminders repeat only on later exports; Apple request stays ungated and one-time; hidden tips excluded")
    }
}
