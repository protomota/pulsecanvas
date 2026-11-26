import Foundation

@main struct CreatorEngagementSmoke {
    @MainActor static func main() {
        let suite = "PulseCanvasCreatorEngagementSmoke"
        let preferences = UserDefaults(suiteName: suite)!
        func fresh() { preferences.removePersistentDomain(forName: suite) }
        typealias E = CreatorEngagement
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let day: TimeInterval = 24 * 60 * 60

        // Milestone: the direct-download card waits for five saved videos or Radio sessions.
        fresh()
        var state = E(preferences: preferences, usesCustomReminders: true)
        let firstSave = UUID()
        state.videoSaved(id: firstSave)
        E(preferences: preferences, usesCustomReminders: true).videoSaved(id: firstSave) // Other window, same export.
        precondition(preferences.integer(forKey: E.saveCountKey) == 1)
        for _ in 0..<3 { state.videoSaved() }
        precondition(!state.supportReminderDue(now: start) && state.claimPrompt(isIdle: true, now: start) == nil)
        state.radioStarted() // Mac Radio sessions count like saved videos.
        precondition(state.completedActions == 5 && state.supportReminderDue(now: start) && state.lastMilestone == .radio)
        precondition(state.claimPrompt(isIdle: false, now: start) == nil, "Never prompt while busy")
        state.beginProcessing()
        precondition(state.claimPrompt(isIdle: true, now: start) == nil, "Never prompt while exporting")
        state.endProcessing()
        let otherWindow = E(preferences: preferences, usesCustomReminders: true)
        precondition(state.claimPrompt(isIdle: true, now: start) == .support)
        precondition(otherWindow.claimPrompt(isIdle: true, now: start) == nil, "Claimed once across windows")

        // Seven-day wait: more actions inside the week never bring it back early.
        for _ in 0..<20 { state.videoSaved() }
        precondition(!state.supportReminderDue(now: start.addingTimeInterval(6 * day + 23 * 3600)))
        precondition(state.claimPrompt(isIdle: true, now: start.addingTimeInterval(6 * day)) == nil)
        precondition(state.claimPrompt(isIdle: true, now: start.addingTimeInterval(7 * day)) == .support, "Returns after a week")

        // One click does not stop it; it returns until every box is checked.
        state.recordClick(.review)
        state.videoSaved()
        precondition(state.claimPrompt(isIdle: true, now: start.addingTimeInterval(14 * day)) == .support, "One click keeps reminders")
        precondition(!state.recordClick(.feedback) && !state.recordClick(.share) && !state.recordClick(.support))
        precondition(state.recordClick(.apps), "Fifth box finishes")
        precondition(state.hasClickedEveryCardAction)
        state.videoSaved()
        precondition(!state.supportReminderDue(now: start.addingTimeInterval(60 * day)))
        precondition(E(preferences: preferences, usesCustomReminders: true).hasClicked(.share), "Checkmarks persist")
        // Reset clears checks only and keeps the weekly wait.
        fresh()
        state = E(preferences: preferences, usesCustomReminders: true)
        for _ in 0..<5 { state.videoSaved() }
        precondition(state.claimPrompt(isIdle: true, now: start) == .support)
        for action in E.cardActions { state.recordClick(action) }
        state.resetClickedActions()
        precondition(state.clickedActions.isEmpty && !state.supportReminderDue(now: start.addingTimeInterval(day)))

        // Later returns after a week; Don't show again stops the card for good, across relaunches.
        fresh()
        state = E(preferences: preferences, usesCustomReminders: true)
        for _ in 0..<5 { state.videoSaved() }
        precondition(state.claimPrompt(isIdle: true, now: start) == .support)
        state.videoSaved() // Later
        precondition(state.claimPrompt(isIdle: true, now: start.addingTimeInterval(7 * day)) == .support, "Later returns")
        state.dismissSupportReminderForever()
        precondition(state.isSupportReminderDismissed)
        let relaunched = E(preferences: preferences, usesCustomReminders: true)
        for offset in [8, 30, 365] {
            relaunched.videoSaved()
            precondition(!relaunched.supportReminderDue(now: start.addingTimeInterval(Double(offset) * day)))
            precondition(relaunched.claimPrompt(isIdle: true, now: start.addingTimeInterval(Double(offset) * day)) == nil,
                         "Don't show again is permanent")
        }
        precondition(relaunched.isSupportReminderDismissed && relaunched.clickedActions.isEmpty, "Dismissal does not fake clicks")
        relaunched.resetClickedActions()
        precondition(relaunched.isSupportReminderDismissed, "Reset clicks keeps the dismissal")

        // Upgrades keep earlier marks; a retired tip mark is ignored and never finishes the card.
        fresh()
        preferences.set(["share", "review", "tip"], forKey: E.clicksKey)
        preferences.set(12, forKey: E.saveCountKey)
        state = E(preferences: preferences, usesCustomReminders: true)
        precondition(state.hasClicked(.share) && state.clickedActions.count == 2 && state.supportReminderDue(now: start))
        fresh()
        preferences.set(true, forKey: "PulseCanvas.engagement.firstVideoSaved.v1")
        precondition(E(preferences: preferences).completedActions == 1)

        // Review eligibility: App Store and iPhone/iPad ask Apple once at five, never a custom card.
        fresh()
        state = E(preferences: preferences, usesCustomReminders: false)
        for _ in 0..<4 { state.videoSaved() }
        precondition(!state.reviewDue && state.claimPrompt(isIdle: true) == nil)
        state.videoSaved()
        precondition(state.reviewDue && !state.supportReminderDue(now: start))
        precondition(state.claimPrompt(isIdle: true) == .review)
        precondition(preferences.bool(forKey: E.reviewKey))
        for _ in 0..<10 { state.videoSaved() }
        precondition(!state.reviewDue && E(preferences: preferences, usesCustomReminders: false).claimPrompt(isIdle: true) == nil)
        fresh()
        state = E(preferences: preferences, usesCustomReminders: false)
        state.recordClick(.review) // Share Your Experience
        for _ in 0..<6 { state.videoSaved() }
        precondition(!state.reviewDue && state.claimPrompt(isIdle: true) == nil)
        fresh()
        preferences.set(true, forKey: E.reviewKey) // An earlier build already asked.
        preferences.set(9, forKey: E.saveCountKey)
        precondition(E(preferences: preferences, usesCustomReminders: false).claimPrompt(isIdle: true) == nil)

        #if STORE_BUILD
        precondition(!E(preferences: preferences).usesCustomReminders)
        #else
        precondition(E(preferences: preferences).usesCustomReminders)
        #endif
        precondition(E(preferences: preferences, usesCustomReminders: true).promptDelay == .seconds(11))
        precondition(E(preferences: preferences, usesCustomReminders: false).promptDelay == .seconds(2))
        precondition(E.reminderInterval == 7 * day && E.milestone == 5 && E.cardActions.count == 5)

        precondition(E.cardActions == [.review, .feedback, .share, .support, .apps])
        precondition(PulseCanvasCommunity.feedback.absoluteString == "https://protomota.com/apps?app=pulsecanvas#feedback")
        precondition(PulseCanvasCommunity.support.absoluteString == "https://protomota.com/support?app=pulsecanvas")
        precondition(PulseCanvasCommunity.apps.absoluteString == "https://protomota.com/apps")
        fresh()
        print("PASS creator engagement: milestone 5, Later returns weekly, Don't show again is permanent, stops after all five boxes, no tips, one native review at 5")
    }
}
