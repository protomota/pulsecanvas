import AppKit
import SwiftUI

@MainActor
struct ExportOverlayView: View {
    @ObservedObject var exporter: SocialExportController
    @State private var showSuccess = false
    private let accent = Color(red: 0.95, green: 0.68, blue: 0.55)

    var body: some View {
        ZStack {
            if exporter.isExporting {
                Color.black.opacity(0.82)
                VStack(spacing: 22) {
                    Text("Creating your video").font(.system(size: 26, weight: .semibold, design: .rounded))
                    if let preview = exporter.framePreview {
                        Image(decorative: preview, scale: 1).resizable().scaledToFit()
                            .frame(maxHeight: 240).clipShape(RoundedRectangle(cornerRadius: 10))
                            .accessibilityLabel("Current rendered frame")
                    } else {
                        ProgressView().controlSize(.large).frame(height: 120)
                    }
                    Text(exporter.status).font(.system(size: 17, weight: .medium)).monospacedDigit()
                    ProgressView(value: exporter.progress).progressViewStyle(.linear).tint(accent)
                        .scaleEffect(x: 1, y: 2).accessibilityLabel("Video export progress")
                    HStack {
                        if exporter.totalFrames > 0 {
                            Text("\(exporter.renderedFrames.formatted()) / \(exporter.totalFrames.formatted()) frames")
                        }
                        Spacer()
                        Text("\(Int(exporter.progress * 100))%").monospacedDigit()
                    }.font(.system(size: 13)).foregroundStyle(.secondary)
                    if let remaining = exporter.estimatedSecondsRemaining {
                        Text("About \(remainingTime(remaining)) remaining · \(exporter.framesPerSecond.formatted(.number.precision(.fractionLength(1)))) frames/s")
                            .font(.system(size: 14, weight: .medium)).monospacedDigit().foregroundStyle(accent)
                    } else if exporter.renderedFrames < exporter.totalFrames {
                        Text("Estimating time remaining…").font(.system(size: 14)).foregroundStyle(.secondary)
                    }
                    Button("Cancel export") { exporter.cancel() }
                        .buttonStyle(StudioButtonStyle(compact: true))
                        .disabled(exporter.status == "Cancelling…")
                }.padding(.horizontal, 60).padding(.vertical, 32)
            } else if showSuccess, let url = exporter.exportedURL {
                VStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 36)).foregroundStyle(.green)
                    Text("Video saved").font(.system(size: 20, weight: .semibold, design: .rounded))
                    Text(url.lastPathComponent).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(2)
                    Button { NSWorkspace.shared.activateFileViewerSelecting([url]) } label: {
                        Label("Show in Finder", systemImage: "folder")
                    }.buttonStyle(StudioButtonStyle(treatment: .primary, compact: true))
                }.padding(28).frame(width: 370)
                    .background(Color(red: 0.20, green: 0.17, blue: 0.22), in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.15)))
                    .overlay(alignment: .topTrailing) {
                        Button { withAnimation { showSuccess = false } } label: {
                            Image(systemName: "xmark").frame(width: 44, height: 44)
                        }.buttonStyle(.plain).accessibilityLabel("Dismiss export success")
                    }
                    .shadow(color: .black.opacity(0.4), radius: 24, y: 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: exporter.exportedURL) { _, url in withAnimation { showSuccess = url != nil } }
            .task(id: exporter.exportedURL) {
                guard exporter.exportedURL != nil else { return }
                do { try await Task.sleep(for: .seconds(10)) } catch { return }
                withAnimation { showSuccess = false }
            }
    }
    private func remainingTime(_ seconds: Double) -> String {
        let rounded = max(1, Int(ceil(seconds)))
        if rounded >= 3600 { return "\(rounded / 3600)h \((rounded % 3600) / 60)m" }
        if rounded >= 60 { return "\(rounded / 60)m \(rounded % 60)s" }
        return "\(rounded)s"
    }

}
