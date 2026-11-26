import AppKit
import SwiftUI

/// Test-only: renders the real Mac Settings support rows and the reminder card offscreen
/// (no screen capture or UI automation) so proof PNGs can be made with the Mac locked.
@main
struct SupportProofRender {
    @MainActor static func main() throws {
        let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".")
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.prohibited)
        NSApp.appearance = NSAppearance(named: .darkAqua)
        // The card shows the app icon; a bare executable has none, so use the generated one.
        if let icon = NSImage(contentsOfFile: ".build/AppIcon.iconset/icon_512x512@2x.png") { NSApp.applicationIconImage = icon }
        let preferences = UserDefaults(suiteName: "PulseCanvas.supportProof.\(UUID().uuidString)")!
        let engagement = CreatorEngagement(preferences: preferences, usesCustomReminders: true)
        engagement.recordClick(.review)
        engagement.recordClick(.feedback)

        let settings = Form {
            Section("Onboarding") {
                Button("Welcome to PulseCanvas Studio", systemImage: "sparkles") {}
                Text("See the onboarding again, from the beginning.").font(.callout).foregroundStyle(.secondary)
            }
            Section("Support PulseCanvas") { PulseCanvasSupportLinks(engagement: engagement) }
            Section("Your data") { Button("Backup & Restore…", systemImage: "externaldrive") {} }
        }.formStyle(.grouped).frame(width: 560, height: 520)
        try render(settings, to: output.appendingPathComponent("mac-settings-support.png"))

        let card = CreatorThanksView(engagement: engagement, isAutomatic: true) {}
        try render(card, to: output.appendingPathComponent("mac-reminder-card.png"))
    }

    @MainActor static func render<Content: View>(_ view: Content, to url: URL) throws {
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(origin: .zero, size: host.fittingSize)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        window.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(1.5))
        host.layoutSubtreeIfNeeded()
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { throw CocoaError(.fileWriteUnknown) }
        host.cacheDisplay(in: host.bounds, to: rep)
        try rep.representation(using: .png, properties: [:])!.write(to: url)
        print("Rendered \(url.path) at \(Int(host.bounds.width))x\(Int(host.bounds.height)) pt")
    }
}
