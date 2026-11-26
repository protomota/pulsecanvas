import SwiftUI

/// An explicitly opened support page; automatic rating requests stay in StoreKit.
struct VisionInfoView: View {
    @ObservedObject var engagement: CreatorEngagement
    @ObservedObject var session: VisionSession
    let close: () -> Void
    let replayOnboarding: () -> Void
    @Environment(\.openURL) private var openURL
    @State private var page = Page.support
    @State private var didReset = false
    private let accent = Color(red: 0.95, green: 0.68, blue: 0.55)
    private enum Page { case support, backup, cloud, legal }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Label("PulseCanvas Studio", systemImage: "waveform").font(.title2.bold())
                Spacer()
                Button("Done", action: close).accessibilityIdentifier("closeVisionInfoButton")
            }
            Picker("Information", selection: $page) {
                Text("Ratings & Support").tag(Page.support)
                Text("Backup & Restore").tag(Page.backup)
                Text("iCloud").tag(Page.cloud)
                Text("Legal & Credits").tag(Page.legal)
            }.pickerStyle(.segmented)
            ScrollView {
                if page == .support { support }
                else if page == .backup {
                    UserBackupView(currentProject: {
                        let editor = session.editor
                        return try editor.project.portableData(duration: editor.transport.duration, scene: editor.selectedScene)
                    }, prepare: { session.suspend() }, openProject: { data in
                        do {
                            let project = try VisionProject.openPortable(data)
                            Task { await session.editor.replaceProject(project) }
                        } catch { session.editor.message = error.localizedDescription }
                    })
                        .disabled(session.editor.loading)
                }
                else if page == .cloud {
                    CloudSyncView(prepare: { session.suspend() }, openProject: { data in
                        do {
                            let project = try VisionProject.openPortable(data)
                            Task { await session.editor.replaceProject(project) }
                        } catch { session.editor.message = error.localizedDescription }
                    }).disabled(session.editor.loading)
                }
                else { legal }
            }.scrollBounceBehavior(.basedOnSize)
        }.padding(32).frame(width: 760, height: 730)
    }

    private var support: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button("Welcome to PulseCanvas Studio", systemImage: "sparkles") {
                replayOnboarding()
            }.accessibilityIdentifier("settingsWelcomePulseCanvas")
            Link(destination: PulseCanvasCommunity.support) {
                Label("Get App Help", systemImage: "questionmark.circle")
            }
            Text("Free software.\nSupported by people.").font(.largeTitle.bold())
            Text("PulseCanvas Studio is free, with every feature included. Your ratings, sharing and feedback help more people discover the app and help us keep building.")
                .font(.body).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                Button { visit(.review, url: PulseCanvasCommunity.review) } label: {
                    row("Rate on the App Store", detail: "Leave a rating and share your experience", icon: "star.bubble", action: .review)
                }.buttonStyle(.plain).accessibilityIdentifier("visionSupportReview")
                ShareLink(item: PulseCanvasCommunity.website) {
                    row("Share PulseCanvas", detail: "Help someone discover their next visual", icon: "square.and.arrow.up", action: .share)
                }.buttonStyle(.plain).accessibilityIdentifier("visionSupportShare")
                    .simultaneousGesture(TapGesture().onEnded { engagement.recordClick(.share); didReset = false })
                Button { visit(.feedback, url: PulseCanvasCommunity.feedback) } label: {
                    row("Send Feedback", detail: "Your ideas help shape what comes next", icon: "bubble.left.and.bubble.right", action: .feedback)
                }.buttonStyle(.plain).accessibilityIdentifier("visionSupportFeedback")
                Button { visit(.apps, url: PulseCanvasCommunity.apps) } label: {
                    row("More Free Apps by Protomota", detail: "Explore more free apps from our studio", icon: "square.grid.2x2", action: .apps)
                }.buttonStyle(.plain).accessibilityIdentifier("visionSupportApps")
            }
            Text("All features stay free, with no account or subscription.").font(.callout).foregroundStyle(.secondary)
            Divider()
            Text(didReset ? "Saved clicks reset." : "Checkmarks remember buttons you’ve clicked on this device, not completed reviews or shares.")
                .font(.caption).foregroundStyle(.secondary)
            Button("Reset saved clicks") { engagement.resetClickedActions(); didReset = true }
                .font(.callout).accessibilityIdentifier("visionSupportReset")
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var legal: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Copyright © 2026 Protomota, LLC").foregroundStyle(.secondary)
            Link("Source code on GitHub", destination: URL(string: "https://github.com/protomota/pulsecanvas")!)
            Text(Bundle.main.url(forResource: "PulseCanvas-LICENSE", withExtension: "txt", subdirectory: "Legal")
                .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? "License unavailable")
                .font(.body).textSelection(.enabled)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func visit(_ action: CreatorEngagement.Action, url: URL) {
        engagement.recordClick(action); didReset = false
        openURL(url)
    }

    private func row(_ title: LocalizedStringKey, detail: LocalizedStringKey, icon: String, action: CreatorEngagement.Action) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon).font(.title2)
                Spacer()
                Image(systemName: engagement.hasClicked(action) ? "checkmark.circle.fill" : "arrow.up.right")
                    .accessibilityLabel(engagement.hasClicked(action) ? "Previously clicked" : "Open")
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                Text(detail).font(.callout).opacity(0.8).lineLimit(2)
            }
        }.frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
            .padding(16)
            .foregroundStyle(action == .review ? Color(red: 0.20, green: 0.12, blue: 0.14) : Color.primary)
            .background(action == .review ? accent : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.12)))
            .contentShape(RoundedRectangle(cornerRadius: 20)).hoverEffect(.highlight)
    }
}
