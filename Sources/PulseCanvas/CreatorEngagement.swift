import Combine
import Foundation
import StoreKit

/// Saved videos and Radio sessions belong to the installation, independently of song/project settings.
/// Direct-download Mac builds show a styled support card after five completed actions. Later brings it
/// back after a week; Don't show again, or clicking every card action, stops it for good. App Store
/// builds make one native review request at five.
@MainActor
final class CreatorEngagement: ObservableObject {
    static let shared = CreatorEngagement()
    enum Action: String, CaseIterable { case review, share, feedback, support, apps }
    enum Milestone { case export, radio }
    enum Prompt { case review, support }
    static let milestone = 5
    static let reminderInterval: TimeInterval = 7 * 24 * 60 * 60
    /// The five card actions. The card keeps returning until every one has been clicked.
    static let cardActions: Set<Action> = [.review, .feedback, .share, .support, .apps]
    @Published private(set) var clickedActions: Set<Action>
    @Published private(set) var completedActions: Int
    /// What the automatic card celebrates: the most recent counted action.
    @Published private(set) var lastMilestone = Milestone.export
    @Published private(set) var processingCount = 0
    let usesCustomReminders: Bool
    private let preferences: UserDefaults
    private var lastPromptActionCount = -1
    static let saveCountKey = "PulseCanvas.engagement.successfulVideoSaves.v1"
    static let radioSessionsKey = "PulseCanvas.engagement.radioSessions.v1"
    static let clicksKey = "PulseCanvas.engagement.clickedActions.v1"
    /// Shared with the earlier one-time Store request so upgrades never ask twice.
    static let reviewKey = "PulseCanvas.engagement.firstExportReviewRequested.v1"
    static let presentedAtKey = "PulseCanvas.engagement.supportPresentedAt.v1"
    static let dismissedKey = "PulseCanvas.engagement.supportDismissedForever.v1"
    private static let legacySavedKey = "PulseCanvas.engagement.firstVideoSaved.v1"
    private static let lastSaveKey = "PulseCanvas.engagement.lastSuccessfulSaveID.v1"

    init(preferences: UserDefaults = .standard, usesCustomReminders: Bool? = nil) {
        self.preferences = preferences
        #if os(macOS) && !STORE_BUILD
        self.usesCustomReminders = usesCustomReminders ?? true
        #else
        self.usesCustomReminders = usesCustomReminders ?? false
        #endif
        // Count a saved video from the earliest milestone implementation as one export.
        if preferences.object(forKey: Self.saveCountKey) == nil, preferences.bool(forKey: Self.legacySavedKey) {
            preferences.set(1, forKey: Self.saveCountKey)
        }
        // Earlier clicks stay checked; only all five clicks stop the card.
        clickedActions = Set((preferences.stringArray(forKey: Self.clicksKey) ?? []).compactMap(Action.init(rawValue:)))
        completedActions = 0
        completedActions = storedCount
    }

    private var storedCount: Int {
        min(1_000_000_000, max(0, preferences.integer(forKey: Self.saveCountKey)))
            + min(1_000_000_000, max(0, preferences.integer(forKey: Self.radioSessionsKey)))
    }

    /// Counts one successful saved video. All editor windows observe the same export, so an ID counts once.
    func videoSaved(id: UUID = UUID()) {
        guard preferences.string(forKey: Self.lastSaveKey) != id.uuidString else {
            completedActions = storedCount
            return
        }
        preferences.set(id.uuidString, forKey: Self.lastSaveKey)
        let count = min(1_000_000_000, max(0, preferences.integer(forKey: Self.saveCountKey))) + 1
        preferences.set(count, forKey: Self.saveCountKey)
        lastMilestone = .export
        completedActions = storedCount
    }

    func radioStarted() {
        let count = min(1_000_000_000, max(0, preferences.integer(forKey: Self.radioSessionsKey))) + 1
        preferences.set(count, forKey: Self.radioSessionsKey)
        lastMilestone = .radio
        completedActions = storedCount
    }

    func beginProcessing() { processingCount += 1 }
    func endProcessing() { processingCount = max(0, processingCount - 1) }

    private var storedClicks: Set<Action> {
        Set((preferences.stringArray(forKey: Self.clicksKey) ?? []).compactMap(Action.init(rawValue:)))
    }

    func hasClicked(_ action: Action) -> Bool { storedClicks.contains(action) }

    /// True once every card action has a checkmark.
    var hasClickedEveryCardAction: Bool { Self.cardActions.isSubset(of: storedClicks) }

    /// Records a click, not a completed review or share. Returns true when every card action is checked.
    @discardableResult
    func recordClick(_ action: Action) -> Bool {
        var clicks = storedClicks
        clicks.insert(action)
        preferences.set(clicks.map(\.rawValue).sorted(), forKey: Self.clicksKey)
        clickedActions = clicks
        return hasClickedEveryCardAction
    }

    /// Clears the checkmarks only; the weekly wait is unchanged.
    func resetClickedActions() {
        preferences.removeObject(forKey: Self.clicksKey)
        clickedActions = []
    }

    /// True after Don't show again on the automatic card.
    var isSupportReminderDismissed: Bool { preferences.bool(forKey: Self.dismissedKey) }

    /// Don't show again: the automatic card never returns. Settings and Help still open it.
    func dismissSupportReminderForever() { preferences.set(true, forKey: Self.dismissedKey) }

    /// The direct-download card is due: five actions, not dismissed, a box still unchecked,
    /// a week since it last showed.
    func supportReminderDue(now: Date = .now) -> Bool {
        guard usesCustomReminders, storedCount >= Self.milestone, !isSupportReminderDismissed,
              !hasClickedEveryCardAction else { return false }
        let last = preferences.double(forKey: Self.presentedAtKey)
        return last == 0 || now.timeIntervalSince1970 - last >= Self.reminderInterval
    }

    /// App Store builds ask Apple once, after five actions, unless Share Your Experience was clicked.
    var reviewDue: Bool {
        !usesCustomReminders && storedCount >= Self.milestone && !preferences.bool(forKey: Self.reviewKey) && !hasClicked(.review)
    }

    var mayPrompt: Bool { usesCustomReminders ? supportReminderDue() : reviewDue }

    /// Claim before presenting so several windows cannot prompt for the same action.
    func claimPrompt(isIdle: Bool, now: Date = .now) -> Prompt? {
        let count = storedCount
        completedActions = count
        guard isIdle, processingCount == 0, count != lastPromptActionCount else { return nil }
        if usesCustomReminders {
            guard supportReminderDue(now: now) else { return nil }
            preferences.set(now.timeIntervalSince1970, forKey: Self.presentedAtKey)
            lastPromptActionCount = count
            return .support
        }
        guard reviewDue else { return nil }
        preferences.set(true, forKey: Self.reviewKey)
        lastPromptActionCount = count
        return .review
    }

    /// Idle time before an automatic prompt: the card waits longer than Apple's sheet.
    var promptDelay: Duration { .seconds(usesCustomReminders ? 11 : 2) }

    /// Apple's rating sheet only rates a production App Store install, never TestFlight or Xcode.
    static func isProductionAppStoreInstall() async -> Bool {
        guard case .verified(let transaction) = try? await AppTransaction.shared else { return false }
        return transaction.environment == .production
    }
}

enum PulseCanvasCommunity {
    static let website = URL(string: "https://pulsecanvas.ai/")!
    static let support = URL(string: "https://discord.gg/FMfeU8cypS")!
    static let feedback = URL(string: "https://projectatom.ai/apps?app=pulsecanvas#feedback")!
    static let review = URL(string: "https://apps.apple.com/app/id6821642700?action=write-review")!
    static let apps = URL(string: "https://projectatom.ai/apps")!
}
