import AppKit
import SwiftUI

struct CreatorThanksView: View {
    @ObservedObject var engagement: CreatorEngagement
    var milestone: CreatorEngagement.Milestone? = nil
    let done: () -> Void
    @Environment(\.openURL) private var openURL
    @State private var shareAnchor = NSView()
    @State private var didReset = false
    private var offersWebsiteTip: Bool { engagement.offersWebsiteTip }
    private let peach = Color(red: 0.95, green: 0.68, blue: 0.55)
    private var heading: String {
        switch milestone {
        case .export: "YOUR VIDEO, SAVED"
        case .radio: "THANKS FOR LISTENING"
        case nil: "RATINGS & SUPPORT"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "star.bubble")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(peach)
                    .frame(width: 66, height: 66)
                    .background(peach.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                VStack(alignment: .leading, spacing: 7) {
                    Text(heading)
                        .font(.system(size: 11, weight: .bold)).tracking(1.4).foregroundStyle(peach)
                    Text("Free software.\nSupported by people.")
                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Your App Store rating makes a difference.")
                    .font(.system(size: 16, weight: .semibold))
                Text("Protomota Software believes software should be free. We're giving our apps away, including PulseCanvas Studio—with every feature included. Your ratings and reviews help more people discover the app. Rate us on the Mac App Store\(offersWebsiteTip ? ", tip the developer," : "") and share PulseCanvas to help us keep building. Thank you for your support.")
                    .font(.system(size: 14)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(spacing: 10) {
                Button { visit(.review, url: PulseCanvasCommunity.review) } label: {
                    action("Rate on the App Store", detail: "Leave a rating and share your experience", icon: "star.bubble", kind: .review, primary: true)
                }.buttonStyle(StudioButtonStyle(treatment: .primary))
                if offersWebsiteTip {
                    Button { visit(.tip, url: PulseCanvasCommunity.tips) } label: {
                        action("Tip the Developer", detail: "Opens pulsecanvas.si/tips in your browser", icon: "heart.circle", kind: .tip)
                    }.buttonStyle(StudioButtonStyle())
                }
                Button {
                    let anchor = shareAnchor.window?.sheetParent?.contentView ?? NSApp.mainWindow?.contentView ?? shareAnchor
                    engagement.recordClick(.share)
                    didReset = false
                    done()
                    CommunitySharePresenter.shared.show(from: anchor)
                } label: {
                    action("Share PulseCanvas", detail: "Help another music lover find their next visual", icon: "square.and.arrow.up", kind: .share)
                }.buttonStyle(StudioButtonStyle()).background(CommunityShareAnchor(view: shareAnchor))
                Button { visit(.feedback, url: PulseCanvasCommunity.feedback) } label: {
                    action("Send feedback", detail: "Your ideas help shape what comes next", icon: "bubble.left.and.bubble.right", kind: .feedback)
                }.buttonStyle(StudioButtonStyle())

            }
            VStack(alignment: .leading, spacing: 8) {
                Text(didReset ? "Saved clicks reset." : "Checkmarks remember buttons you've clicked on this Mac, not completed reviews, tips or shares.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Button("Reset saved clicks") {
                    engagement.resetClickedActions()
                    didReset = true
                }.buttonStyle(StudioButtonStyle(compact: true))
                    .help("Clear local action checkmarks. Your music, projects and favorites stay intact. Apple's review limits are unchanged.")
            }
            HStack(spacing: 18) {
                Text("All features stay free. Thank you for your support.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Button("Back to Studio", action: done)
                    .buttonStyle(StudioButtonStyle(treatment: .primary))
                    .keyboardShortcut(.defaultAction)
            }
        }.padding(30).frame(width: 540)
            .background(Color(red: 0.115, green: 0.095, blue: 0.14))
            .tint(peach)
            .onExitCommand(perform: done)
    }

    private func visit(_ kind: CreatorEngagement.Action, url: URL) {
        engagement.recordClick(kind)
        didReset = false
        openURL(url)
        done()
    }

    private func action(_ title: String, detail: String, icon: String, kind: CreatorEngagement.Action, primary: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 23)).foregroundStyle(primary ? Color(red: 0.22, green: 0.13, blue: 0.15) : peach).frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(detail).font(.system(size: 12, weight: .regular)).foregroundStyle(primary ? Color(red: 0.22, green: 0.13, blue: 0.15).opacity(0.8) : Color.secondary)
            }
            Spacer()
            Image(systemName: engagement.hasClicked(kind) ? "checkmark.circle.fill" : "arrow.up.right")
                .font(.system(size: 13)).foregroundStyle(primary ? Color(red: 0.22, green: 0.13, blue: 0.15) : peach)
                .accessibilityLabel(engagement.hasClicked(kind) ? "Previously clicked" : "Open")
        }.padding(.vertical, 9).frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CommunityShareAnchor: NSViewRepresentable {
    let view: NSView
    func makeNSView(context: Context) -> NSView { view }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

/// Keep the native share picker alive after the reminder sheet is dismissed.
@MainActor private final class CommunitySharePresenter: NSObject, NSSharingServicePickerDelegate {
    static let shared = CommunitySharePresenter()
    private var picker: NSSharingServicePicker?
    func show(from anchor: NSView) {
        DispatchQueue.main.async { [self] in
            let picker = NSSharingServicePicker(items: [PulseCanvasCommunity.website])
            self.picker = picker
            picker.delegate = self
            picker.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: .minY)
        }
    }
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
        picker = nil
    }
}
