import SwiftUI

struct CreatorThanksView: View {
    let offersWebsiteTip: Bool
    var isExportMilestone = false
    let done: () -> Void
    @Environment(\.openURL) private var openURL
    private let peach = Color(red: 0.95, green: 0.68, blue: 0.55)

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "star.bubble")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(peach)
                    .frame(width: 66, height: 66)
                    .background(peach.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                VStack(alignment: .leading, spacing: 7) {
                    Text(isExportMilestone ? "YOUR SECOND VIDEO, SAVED" : "RATINGS & SUPPORT")
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
                Button { openURL(PulseCanvasCommunity.review) } label: {
                    action("Rate on the App Store", detail: "Leave a rating and share your experience", icon: "star.bubble", primary: true)
                }.buttonStyle(StudioButtonStyle(treatment: .primary))
                if offersWebsiteTip {
                    Button { openURL(PulseCanvasCommunity.tips) } label: {
                        action("Tip the Developer", detail: "Opens pulsecanvas.si/tips in your browser", icon: "heart.circle")
                    }.buttonStyle(StudioButtonStyle())
                }
                ShareLink(item: PulseCanvasCommunity.website) {
                    action("Share PulseCanvas", detail: "Help another music lover find their next visual", icon: "square.and.arrow.up")
                }.buttonStyle(StudioButtonStyle())
                Button { openURL(PulseCanvasCommunity.feedback) } label: {
                    action("Send feedback", detail: "Your ideas help shape what comes next", icon: "bubble.left.and.bubble.right")
                }.buttonStyle(StudioButtonStyle())

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

    private func action(_ title: String, detail: String, icon: String, primary: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 23)).foregroundStyle(primary ? Color(red: 0.22, green: 0.13, blue: 0.15) : peach).frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(detail).font(.system(size: 12, weight: .regular)).foregroundStyle(primary ? Color(red: 0.22, green: 0.13, blue: 0.15).opacity(0.8) : Color.secondary)
            }
            Spacer()
            Image(systemName: "arrow.up.right").font(.system(size: 11)).foregroundStyle(primary ? Color(red: 0.22, green: 0.13, blue: 0.15) : Color.secondary)
        }.padding(.vertical, 9).frame(maxWidth: .infinity, alignment: .leading)
    }
}
