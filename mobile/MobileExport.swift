import SwiftUI
import UIKit

struct MobileExport: View {
    @ObservedObject var editor: MobileEditor
    @ObservedObject var exporter: SocialExportController
    @ObservedObject var audio: AudioController
    @ObservedObject var radio: RadioController
    @State private var request: MobileVideoSaveRequest?
    @State private var saved = false
    @State private var renderStarted = false
    @State private var error: String?
    init(editor: MobileEditor) { self.editor = editor; exporter = editor.exporter; audio = editor.audio; radio = editor.radio }
    private var hasCurrentResult: Bool { renderStarted && exporter.exportedURL != nil }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !exporter.isExporting {
                    Picker("Canvas", selection: $exporter.aspect) { ForEach(SocialAspect.allCases) { Text($0.rawValue).tag($0) } }.accessibilityIdentifier("mobileExportCanvas")
                    Picker("Resolution", selection: $exporter.resolution) { Text("720p").tag(720); Text("1080p").tag(1080); Text("4K").tag(2160) }.pickerStyle(.segmented)
                    Picker("Frame rate", selection: $exporter.fps) { ForEach([24, 30, 60], id: \.self) { Text("\($0) fps").tag($0) } }.pickerStyle(.segmented)
                    Text(radio.isActive ? "Export the current Radio song with the visualizer you’re watching." : "Full soundtrack included. Higher resolutions take longer to render.").foregroundStyle(.secondary)
                }
                if exporter.isExporting || hasCurrentResult {
                    if let image = exporter.framePreview { Image(decorative: image, scale: 1).resizable().scaledToFit().frame(maxHeight: 250).clipShape(RoundedRectangle(cornerRadius: 14)) }
                    ProgressView(value: exporter.progress)
                    Text(saved ? "Video saved" : hasCurrentResult ? "Your video is ready" : exporter.status).font(.headline)
                    if let estimate = exporter.estimatedSecondsRemaining { Text("About \(MobileTransport.time(estimate)) remaining").foregroundStyle(.secondary) }
                }
                if let error { Text(error).foregroundStyle(.red) }
                if exporter.status.hasPrefix("Export failed") { Text(exporter.status).foregroundStyle(.red) }
            }.padding(24)
        }.safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 10) {
                if exporter.isExporting {
                    Button("Cancel export") { exporter.cancel() }.buttonStyle(MobileButton())
                } else {
                    if let url = exporter.exportedURL, hasCurrentResult {
                        Button { request = MobileVideoSaveRequest(url: url) } label: {
                            Label(saved ? "Save another copy" : "Save video", systemImage: "tray.and.arrow.down").frame(maxWidth: .infinity, minHeight: 52)
                        }.buttonStyle(MobileButton(prominent: true)).accessibilityIdentifier("saveMobileVideo")
                    }
                    Button { startExport() } label: {
                        Label(hasCurrentResult ? "Render another video" : "Render video", systemImage: "film").frame(maxWidth: .infinity, minHeight: 52)
                    }.buttonStyle(MobileButton(prominent: !hasCurrentResult))
                        .accessibilityIdentifier("renderMobileVideo")
                        .disabled(audio.selectedURL == nil || radio.isActive && !radio.canSeek)
                }
            }.padding(20).frame(maxWidth: .infinity).background(MobileTheme.background)
        }.interactiveDismissDisabled(exporter.isExporting)
        .fullScreenCover(item: $request) { item in
            MobileVideoSavePicker(url: item.url) { result in
                request = nil
                if let result {
                    switch result {
                    case .success:
                        saved = true
                        if let id = exporter.successfulSaveID { editor.engagement.videoSaved(id: id) }
                    case .failure(let failure): error = failure.localizedDescription
                    }
                }
            }
        }
    }
    private func startExport() {
        let radioExport = radio.isActive
        if radioExport { radio.pause() } else { audio.pause(); editor.studio.save(editor.render) }
        let audioURL = audio.selectedURL
        let render = radioExport ? radio.visualizer : editor.render
        let segments = !radioExport && editor.studio.isStudio ? editor.studio.segments : []
        saved = false; error = nil
        #if DEBUG
        // Repeated UI runs keep earlier Files exports; isolate their names too.
        let filename = ProcessInfo.processInfo.arguments.contains("-PCMobileQA")
            ? "PulseCanvas-QA-Video-\(UUID().uuidString).mp4" : "PulseCanvas Video.mp4"
        #else
        let filename = "PulseCanvas Video.mp4"
        #endif
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent("Mobile-video-\(UUID().uuidString)").appendingPathComponent(filename)
        do { try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true) }
        catch { self.error = error.localizedDescription; return }
        Task { renderStarted = true; await exporter.export(audioURL: audioURL, render: render, to: destination,
                                     segments: segments, appearances: radioExport ? [:] : editor.studio.presets) }
    }
}

private struct MobileVideoSaveRequest: Identifiable { let id = UUID(); let url: URL }
private struct MobileVideoSavePicker: UIViewControllerRepresentable {
    let url: URL
    let completion: (Result<URL, Error>?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        picker.delegate = context.coordinator; picker.shouldShowFileExtensions = true; return picker
    }
    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let completion: (Result<URL, Error>?) -> Void
        init(completion: @escaping (Result<URL, Error>?) -> Void) { self.completion = completion }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first { completion(.success(url)) } else { completion(.failure(CocoaError(.fileWriteUnknown))) }
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { completion(nil) }
    }
}

struct MobileAbout: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var engagement = CreatorEngagement()
    var body: some View {
        List {
            Section {
                Text("PulseCanvas Studio").font(.title2.bold())
                Text("Music into moving visuals. Free to use, with no account or subscription.")
                Text("© 2026 Protomota, LLC").foregroundStyle(.secondary)
            }
            Section("Onboarding") {
                Button("Welcome to PulseCanvas Studio", systemImage: "sparkles") {
                    NotificationCenter.default.post(name: .pulseCanvasOnboarding, object: nil)
                }.accessibilityIdentifier("settingsWelcomePulseCanvas")
            }
            Section("Support PulseCanvas") {
                Button("Rate on the App Store", systemImage: "heart.circle") { engagement.recordClick(.review); openURL(PulseCanvasCommunity.review) }
                #if STORE_BUILD
                PulseCanvasTipButton(onTipCompleted: { engagement.recordClick(.tip) }) {
                    Label("Tip the Developer", systemImage: "cup.and.saucer")
                }.accessibilityIdentifier("settingsTipPulseCanvas")
                #else
                if engagement.offersWebsiteTip { Button("Tip the Developer", systemImage: "cup.and.saucer") { engagement.recordClick(.tip); openURL(PulseCanvasCommunity.tips) } }
                #endif
                ShareLink(item: PulseCanvasCommunity.website) { Label("Share PulseCanvas", systemImage: "square.and.arrow.up") }
                Button("Send feedback", systemImage: "bubble.left.and.bubble.right") { engagement.recordClick(.feedback); openURL(PulseCanvasCommunity.feedback) }
            }
            Section("Legal & Credits") {
                Text("First-party source uses the PulseCanvas Source-Available Noncommercial License. Earlier MIT releases and third-party assets retain their separate terms. Native Metal effects only; no projectM engine or external preset pack is included.")
                Link("Source code on GitHub", destination: URL(string: "https://github.com/protomota/pulsecanvas")!)
                Link("Privacy policy", destination: URL(string: "https://pulsecanvas.si/privacy/")!)
                if let url = Bundle.main.url(forResource: "PulseCanvas-LICENSE", withExtension: "txt", subdirectory: "Legal"), let license = try? String(contentsOf: url, encoding: .utf8) {
                    DisclosureGroup("Application license") { Text(license).font(.caption).textSelection(.enabled) }
                }
            }
        }.task { await engagement.observeStorefront() }
    }
}
