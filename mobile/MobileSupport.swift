import SwiftUI
import UIKit

/// iPhone and iPad Settings rows, matching every one of our apps.
struct MobileSupportLinks: View {
    @ObservedObject var engagement: CreatorEngagement
    @State private var showingSupport = false
    @Environment(\.openURL) private var openURL
    var body: some View {
        Group {
            Button { visit(.review, url: PulseCanvasCommunity.review) } label: {
                row("Rate on the App Store", systemImage: "star")
            }.accessibilityIdentifier("settingsRatePulseCanvas")
            ShareLink(item: PulseCanvasCommunity.website) { row("Share PulseCanvas", systemImage: "square.and.arrow.up") }
                .simultaneousGesture(TapGesture().onEnded { engagement.recordClick(.share) })
                .accessibilityIdentifier("settingsSharePulseCanvas")
            Button { visit(.feedback, url: PulseCanvasCommunity.feedback) } label: {
                row("Send Feedback", systemImage: "bubble.left.and.bubble.right")
            }.accessibilityIdentifier("settingsFeedbackPulseCanvas")
            Button { visit(.apps, url: PulseCanvasCommunity.apps) } label: { row("More Free Apps from Project ATOM", systemImage: "arrow.up.right") }
                .accessibilityIdentifier("settingsAtomApps")
            Button { visit(.support, url: PulseCanvasCommunity.support) } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Get support", systemImage: "headphones")
                    Text("We read every note")
                        .font(.footnote).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
            }.accessibilityIdentifier("settingsTechnicalSupport")
            Button { showingSupport = true } label: { row("More Information & Support", systemImage: "heart") }
                .accessibilityIdentifier("settingsSupportPulseCanvasCard")
                .fullScreenCover(isPresented: $showingSupport) {
                    MobileSupportOverlay(engagement: engagement) { showingSupport = false }
                        .presentationBackground(.clear)
                }
        }
    }
    private func row(_ title: LocalizedStringKey, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
    }
    private func visit(_ action: CreatorEngagement.Action, url: URL) {
        engagement.recordClick(action)
        openURL(url)
    }
}

/// Dims the Settings sheet behind a themed card; compact widths dock it to the bottom.
private struct MobileSupportOverlay: View {
    @ObservedObject var engagement: CreatorEngagement
    let dismiss: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 600
            let heightFraction = dynamicTypeSize.isAccessibilitySize || geometry.size.height < 800 ? 0.92 : 0.83
            ZStack {
                Color.black.opacity(0.45).ignoresSafeArea()
                    .onTapGesture(perform: dismiss)
                    .accessibilityHidden(true)
                MobileSupportCard(engagement: engagement, dismiss: dismiss)
                    .frame(maxWidth: max(0, min(geometry.size.width - (compact ? 24 : 48), 520)),
                           maxHeight: max(0, min(geometry.size.height - 24, compact ? geometry.size.height * heightFraction : 720)))
                    .padding(.horizontal, compact ? 12 : 24).padding(.vertical, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: compact ? .bottom : .center)
            }
        }
    }
}

struct MobileSupportCard: View {
    @ObservedObject var engagement: CreatorEngagement
    let dismiss: () -> Void
    @Environment(\.openURL) private var openURL
    @State private var contentHeight: CGFloat?
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                logo.frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 10)).accessibilityHidden(true)
                Text("Free software.\nSupported by people.")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                Button(action: dismiss) { Image(systemName: "xmark").font(.subheadline.weight(.semibold)).frame(width: 44, height: 44) }
                    .background(MobileTheme.panel, in: Circle())
                    .accessibilityLabel("Close support message")
                    .accessibilityIdentifier("supportClose")
            }
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 14)
            ScrollView {
                VStack(spacing: 8) {
                    Button { visit(.review, url: PulseCanvasCommunity.review) } label: {
                        action("Rate on the App Store", subtitle: "A quick rating helps more people find it", icon: "star", kind: .review)
                    }.buttonStyle(.plain).accessibilityIdentifier("supportReview")
                    Button { visit(.feedback, url: PulseCanvasCommunity.feedback) } label: {
                        action("Send Feedback", subtitle: "Help shape what comes next", icon: "bubble.left.and.bubble.right", kind: .feedback)
                    }.buttonStyle(.plain).accessibilityIdentifier("supportFeedback")
                    ShareLink(item: PulseCanvasCommunity.website) {
                        action("Share PulseCanvas", subtitle: "Help another music lover find their next visual", icon: "square.and.arrow.up", kind: .share)
                    }.buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded { engagement.recordClick(.share) })
                        .accessibilityIdentifier("supportShare")
                    Button { visit(.support, url: PulseCanvasCommunity.support) } label: {
                        action("Get support", subtitle: "We read every note", icon: "headphones", kind: .support)
                    }.buttonStyle(.plain).accessibilityIdentifier("supportTicket")
                    Button { visit(.apps, url: PulseCanvasCommunity.apps) } label: {
                        action("More Free Apps from Project ATOM", subtitle: "Every one is a Project ATOM project", icon: "square.grid.2x2", kind: .apps)
                    }.buttonStyle(.plain).accessibilityIdentifier("supportApps")
                }
                .padding(.horizontal, 20).padding(.bottom, 12)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .frame(maxHeight: contentHeight)
            .scrollBounceBehavior(.basedOnSize)
            Rectangle().fill(MobileTheme.accent.opacity(0.4)).frame(height: 1).padding(.horizontal, 24)
            VStack(alignment: .leading, spacing: 10) {
                Text("Checkmarks show which buttons you’ve opened. Every feature stays free, with no account or subscription.")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: dismiss) { Text("Back to Settings").frame(maxWidth: .infinity) }
                    .buttonStyle(MobileButton(prominent: true))
                    .accessibilityIdentifier("supportDismiss")
            }
            .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 14)
        }
        .foregroundStyle(.white)
        .background(MobileTheme.background, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(MobileTheme.accent.opacity(0.5), lineWidth: 1))
        .compositingGroup()
        .shadow(color: .black.opacity(0.3), radius: 24, y: 12)
        .tint(MobileTheme.accent)
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pulseCanvasSupportCard")
    }
    private var logo: some View {
        Group {
            if let url = ["Resources/Onboarding", "Onboarding"].lazy
                .compactMap({ Bundle.module.url(forResource: "logo", withExtension: "png", subdirectory: $0) }).first,
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image).resizable().interpolation(.high).scaledToFit()
            } else {
                Image(systemName: "waveform").font(.title2).foregroundStyle(MobileTheme.accent)
            }
        }
    }
    private func visit(_ kind: CreatorEngagement.Action, url: URL) {
        engagement.recordClick(kind)
        openURL(url)
    }
    private func action(_ title: LocalizedStringKey, subtitle: LocalizedStringKey, icon: String,
                        kind: CreatorEngagement.Action) -> some View {
        let clicked = engagement.clickedActions.contains(kind)
        return HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(MobileTheme.accent).frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.body.weight(.semibold)).foregroundStyle(.white)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }.fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Image(systemName: clicked ? "checkmark.circle.fill" : "arrow.up.right")
                .font(clicked ? .body : .caption).foregroundStyle(clicked ? MobileTheme.accent : .secondary)
                .accessibilityHidden(true)
        }
        .accessibilityValue(clicked ? Text("Previously opened") : Text(""))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 8).frame(minHeight: 52)
        .background(MobileTheme.panel, in: RoundedRectangle(cornerRadius: 14))
        .contentShape(Rectangle())
    }
}
