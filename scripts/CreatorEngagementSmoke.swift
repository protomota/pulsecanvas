import Foundation

@main struct CreatorEngagementSmoke {
    @MainActor static func main() {
        let suite = "PulseCanvasCreatorEngagementSmoke"
        let preferences = UserDefaults(suiteName: suite)!
        func fresh() { preferences.removePersistentDomain(forName: suite) }
        typealias E = CreatorEngagement

        // Milestone: five saved videos or Radio sessions, counted once per export across windows.
        fresh()
        var state = E(preferences: preferences)
        let firstSave = UUID()
        state.videoSaved(id: firstSave)
        E(preferences: preferences).videoSaved(id: firstSave) // Other window, same export.
        precondition(preferences.integer(forKey: E.saveCountKey) == 1)
        for _ in 0..<3 { state.videoSaved() }
        precondition(!state.reviewDue && state.claimPrompt(isIdle: true) == nil)
        state.radioStarted() // Mac Radio sessions count like saved videos.
        precondition(state.completedActions == 5 && state.reviewDue)
        precondition(state.claimPrompt(isIdle: false) == nil, "Never prompt while busy")
        state.beginProcessing()
        precondition(state.claimPrompt(isIdle: true) == nil, "Never prompt while exporting")
        state.endProcessing()
        let otherWindow = E(preferences: preferences)
        precondition(state.claimPrompt(isIdle: true) == .review)
        precondition(preferences.bool(forKey: E.reviewKey))
        precondition(otherWindow.claimPrompt(isIdle: true) == nil, "Claimed once across windows")
        for _ in 0..<10 { state.videoSaved() }
        precondition(!state.reviewDue && E(preferences: preferences).claimPrompt(isIdle: true) == nil, "Apple is asked once")

        // Card checkmarks persist and reset; nothing about them prompts.
        fresh()
        state = E(preferences: preferences)
        precondition(!state.recordClick(.feedback) && !state.recordClick(.share) && !state.recordClick(.support)
                     && !state.recordClick(.apps))
        precondition(state.recordClick(.review), "Fifth box finishes")
        precondition(state.hasClickedEveryCardAction && E(preferences: preferences).hasClicked(.share), "Checkmarks persist")
        state.resetClickedActions()
        precondition(state.clickedActions.isEmpty)

        // Upgrades keep earlier marks; a retired tip mark is ignored.
        fresh()
        preferences.set(["share", "review", "tip"], forKey: E.clicksKey)
        precondition(E(preferences: preferences).hasClicked(.share) && E(preferences: preferences).clickedActions.count == 2)
        fresh()
        preferences.set(true, forKey: "PulseCanvas.engagement.firstVideoSaved.v1")
        precondition(E(preferences: preferences).completedActions == 1)

        // Share Your Experience or an earlier build's request means Apple is never asked.
        fresh()
        state = E(preferences: preferences)
        state.recordClick(.review)
        for _ in 0..<6 { state.videoSaved() }
        precondition(!state.reviewDue && state.claimPrompt(isIdle: true) == nil)
        fresh()
        preferences.set(true, forKey: E.reviewKey)
        preferences.set(9, forKey: E.saveCountKey)
        precondition(E(preferences: preferences).claimPrompt(isIdle: true) == nil)

        precondition(E(preferences: preferences).promptDelay == .seconds(2))
        precondition(E.milestone == 5 && E.cardActions.count == 5)

        precondition(E.cardActions == [.review, .feedback, .share, .support, .apps])
        precondition(PulseCanvasCommunity.feedback.absoluteString == "https://projectatom.ai/apps?app=pulsecanvas#feedback")
        precondition(PulseCanvasCommunity.support.absoluteString == "https://projectatom.ai/apps?app=pulsecanvas#feedback")
        precondition(PulseCanvasCommunity.apps.absoluteString == "https://projectatom.ai/apps")
        fresh()
        print("PASS creator engagement: no automatic support card, card checkmarks persist, no tips, one native review at 5")
    }
}
