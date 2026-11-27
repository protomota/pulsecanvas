import AppKit
import SwiftUI

/// Free ways to help PulseCanvas grow: rate, share, send feedback. Opens only from Settings or Help.
struct CreatorThanksView: View {
    @ObservedObject var engagement: CreatorEngagement
    /// Where the dismiss button returns the person.
    var returnsToSettings = false
    let done: () -> Void
    @Environment(\.openURL) private var openURL
    @State private var shareAnchor = NSView()
    @State private var didReset = false
    private let peach = Color(red: 0.95, green: 0.68, blue: 0.55)
    private let background = Color(red: 0.115, green: 0.095, blue: 0.14)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable().interpolation(.high).frame(width: 66, height: 66)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 7) {
                    Text("RATINGS & SUPPORT")
                        .font(.system(size: 12, weight: .bold)).tracking(1.4).foregroundStyle(peach)
                    Text("Free software.\nSupported by people.")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button(action: done) { Image(systemName: "xmark") }
                    .buttonStyle(StudioButtonStyle(treatment: .quiet, circular: true))
                    .accessibilityLabel("Close support message")
                    .accessibilityIdentifier("supportClose")
            }.padding(.bottom, 22)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 10) {
                        Button { visit(.review, url: PulseCanvasCommunity.review) } label: {
                            action("Rate on the App Store", detail: "A quick rating helps more people find it", icon: "star", kind: .review)
                        }.buttonStyle(StudioButtonStyle()).accessibilityIdentifier("supportReview")
                        Button { visit(.feedback, url: PulseCanvasCommunity.feedback) } label: {
                            action("Send Feedback", detail: "Help shape what comes next", icon: "bubble.left.and.bubble.right", kind: .feedback)
                        }.buttonStyle(StudioButtonStyle()).accessibilityIdentifier("supportFeedback")
                        Button {
                            engagement.recordClick(.share); didReset = false
                            CommunitySharePresenter.shared.present(from: shareAnchor, dismiss: done)
                        } label: {
                            action("Share PulseCanvas", detail: "Help another music lover find their next visual", icon: "square.and.arrow.up", kind: .share)
                        }.buttonStyle(StudioButtonStyle()).background(CommunityShareAnchor(view: shareAnchor))
                            .accessibilityIdentifier("supportShare")
                        Button { visit(.support, url: PulseCanvasCommunity.support) } label: {
                            action("Get support", detail: "We read every note", icon: "headphones", kind: .support)
                        }.buttonStyle(StudioButtonStyle()).accessibilityIdentifier("supportTicket")
                        Button { visit(.apps, url: PulseCanvasCommunity.apps) } label: {
                            action("More Free Apps from Project ATOM", detail: "Every one is a Project ATOM project", icon: "square.grid.2x2", kind: .apps)
                        }.buttonStyle(StudioButtonStyle()).accessibilityIdentifier("supportApps")
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(status)
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Button("Reset saved clicks") {
                            engagement.resetClickedActions(); didReset = true
                        }.buttonStyle(StudioButtonStyle(compact: true))
                            .accessibilityIdentifier("supportReset")
                            .help("Clear local action checkmarks. Your music, projects and favorites stay intact.")
                    }
                }.padding(.trailing, 2)
            }.scrollBounceBehavior(.basedOnSize)
            VStack(alignment: .leading, spacing: 14) {
                Text("Every feature stays free. No account, no subscription.")
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                HStack(spacing: 18) {
                    Spacer(minLength: 0)
                    Button(action: done) {
                        Text(returnsToSettings ? "Back to Settings" : "Back to Studio")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .buttonStyle(StudioButtonStyle(treatment: .primary))
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("supportDismiss")
                }
            }.padding(.top, 22)
        }
        .padding(30).frame(width: 600, height: 700)
        .background(background)
        .tint(peach)
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .contain).accessibilityIdentifier("pulseCanvasSupportCard")
    }

    private var status: String {
        if didReset { return String(localized: "Saved clicks reset.") }
        return String(localized: "Checkmarks show which buttons you’ve opened.")
    }

    private func visit(_ kind: CreatorEngagement.Action, url: URL) {
        engagement.recordClick(kind); didReset = false
        openURL(url)
    }

    private func action(_ title: LocalizedStringKey, detail: LocalizedStringKey, icon: String,
                        kind: CreatorEngagement.Action? = nil) -> some View {
        let clicked = kind.map { engagement.clickedActions.contains($0) } ?? false
        return HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 22)).foregroundStyle(peach).frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(detail).font(.system(size: 12.5, weight: .regular)).foregroundStyle(.secondary)
            }.fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Image(systemName: clicked ? "checkmark.circle.fill" : "arrow.up.right")
                .font(.system(size: 14)).foregroundStyle(peach)
                .accessibilityHidden(true)
        }.padding(.vertical, 8).frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityValue(clicked ? Text("Previously clicked") : Text(""))
    }
}

private struct CommunityShareAnchor: NSViewRepresentable {
    let view: NSView
    func makeNSView(context: Context) -> NSView { view }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

/// Retain sharing outside the card so its picker survives the sheet closing.
@MainActor private final class CommunitySharePresenter: NSObject, NSSharingServicePickerDelegate {
    static let shared = CommunitySharePresenter()
    private var picker: NSSharingServicePicker?
    private var presentation: Task<Void, Never>?
    func present(from anchor: NSView, dismiss: () -> Void) {
        let parent = anchor.window?.sheetParent ?? NSApp.mainWindow
        dismiss()
        presentation?.cancel()
        presentation = Task { @MainActor in
            guard let parent else { return }
            // Let SwiftUI detach the dismissed sheet before anchoring the share picker.
            for _ in 0..<30 where parent.attachedSheet != nil {
                do { try await Task.sleep(for: .milliseconds(50)) } catch { return }
            }
            guard !Task.isCancelled, parent.isVisible, parent.attachedSheet == nil,
                  let content = parent.contentView else { return }
            let picker = NSSharingServicePicker(items: [PulseCanvasCommunity.website])
            self.picker = picker
            picker.delegate = self
            picker.show(relativeTo: NSRect(x: content.bounds.midX, y: content.bounds.midY, width: 1, height: 1),
                        of: content, preferredEdge: .minY)
        }
    }
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
        picker = nil
    }
}

/// Mac Settings rows, matching every one of our apps.
struct PulseCanvasSupportLinks: View {
    @ObservedObject var engagement: CreatorEngagement
    @State private var showingSupport = false
    @Environment(\.openURL) private var openURL
    var body: some View {
        Button {
            engagement.recordClick(.review)
            openURL(PulseCanvasCommunity.review)
        } label: { Label("Rate on the App Store", systemImage: "star") }
            .accessibilityIdentifier("settingsRatePulseCanvas")
        Button { showingSupport = true } label: { Label("Rate, share, or send feedback", systemImage: "heart") }
            .accessibilityIdentifier("settingsSupportPulseCanvasCard")
            .sheet(isPresented: $showingSupport) {
                CreatorThanksView(engagement: engagement, returnsToSettings: true) { showingSupport = false }
            }
        Button { engagement.recordClick(.support); openURL(PulseCanvasCommunity.support) } label: {
            VStack(alignment: .leading, spacing: 2) {
                Label("Get support", systemImage: "headphones")
                Text("We read every note")
                    .font(.callout).foregroundStyle(.secondary).padding(.leading, 28)
            }
        }.accessibilityIdentifier("settingsTechnicalSupport")
        Link(destination: PulseCanvasCommunity.apps) {
            Label("More Free Apps from Project ATOM", systemImage: "arrow.up.right")
        }.accessibilityIdentifier("settingsAtomApps")
        Text("A Project ATOM project").font(.callout).foregroundStyle(.secondary)
            .accessibilityIdentifier("settingsAtomCredit")
    }
}
