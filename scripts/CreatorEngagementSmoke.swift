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
        precondition(!state.pendingExportThanks) // Any one action finishes the reminder.
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
        precondition(!state.pendingExportThanks)
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

        // The fourth Radio session asks once, sharing the one Apple request with exports.
        preferences.removePersistentDomain(forName: suite)
        state = CreatorEngagement(preferences: preferences)
        for _ in 1..<CreatorEngagement.radioMilestone { state.radioStarted() }
        precondition(!state.pendingRadioThanks && !state.presentRadioThanks())
        state.radioStarted()
        precondition(state.pendingRadioThanks)
        let otherRadioWindow = CreatorEngagement(preferences: preferences)
        #if STORE_BUILD
        precondition(state.presentRadioThanks() && !state.showsThanks)
        precondition(preferences.bool(forKey: "PulseCanvas.engagement.firstExportReviewRequested.v1"))
        state.videoSaved(); state.videoSaved()
        precondition(!state.presentExportThanks()) // Radio already made the Apple request.
        #else
        precondition(!state.presentRadioThanks() && state.showsThanks && state.thanksMilestone == .radio)
        state.showsThanks = false
        #endif
        precondition(!otherRadioWindow.presentRadioThanks() && !otherRadioWindow.showsThanks)
        state.radioStarted()
        state = CreatorEngagement(preferences: preferences)
        #if STORE_BUILD
        precondition(!state.pendingRadioThanks && !state.presentRadioThanks()) // One Apple request.
        #else
        precondition(state.pendingRadioThanks)
        _ = state.presentRadioThanks()
        precondition(state.showsThanks)
        state.showsThanks = false
        #endif
        #if !STORE_BUILD
        state.videoSaved(); state.videoSaved()
        _ = state.presentExportThanks()
        precondition(state.showsThanks && state.thanksMilestone == .export)
        #endif
        // An earlier Apple request (Store) or every action clicked (direct) skips the Radio ask.
        preferences.removePersistentDomain(forName: suite)
        state = CreatorEngagement(preferences: preferences)
        #if STORE_BUILD
        state.videoSaved(); state.videoSaved()
        precondition(state.presentExportThanks())
        #else
        for action in state.availableActions { state.recordClick(action) }
        #endif
        for _ in 0..<CreatorEngagement.radioMilestone { state.radioStarted() }
        precondition(!state.pendingRadioThanks && !state.presentRadioThanks())
        #if !STORE_BUILD
        for action in CreatorEngagement.Action.allCases {
            preferences.removePersistentDomain(forName: suite)
            state = CreatorEngagement(preferences: preferences)
            state.videoSaved(); state.videoSaved(); _ = state.presentExportThanks()
            precondition(state.showsThanks)
            state.recordClick(action)
            precondition(!state.showsThanks && state.hasClicked(action))
            state = CreatorEngagement(preferences: preferences)
            state.videoSaved()
            for _ in 0..<6 { state.radioStarted() }
            precondition(!state.pendingExportThanks && !state.pendingRadioThanks)
            precondition(!state.presentExportThanks() && !state.presentRadioThanks())
            // Manual About/More Information access stays available after acknowledgment.
            state.showsThanks = true; precondition(state.showsThanks)
        }
        #endif
        print("PASS: second-save eligibility, deduplicated exports, relaunch and concurrent windows; per-action clicks, completion, reset and upgrade; any one of Rate/Tip/Share/Feedback dismisses and persists; direct reminders repeat on later exports/Radio sessions until a click; Apple request stays ungated and one-time; hidden tips excluded; Radio reminders deduplicate each session and share the one Apple request")
    }
}
