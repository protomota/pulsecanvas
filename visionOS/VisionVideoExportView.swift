import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

struct VisionMovie: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .mpeg4Movie) { SentTransferredFile($0.url) }
    }
}

struct VisionVideoExportView: View {
    @ObservedObject var studio: VisionStudio
    let close: () -> Void
    @StateObject private var exporter = SocialExportController()
    @State private var saving = false
    @State private var saved = false
    @State private var saveError: String?
    @State private var work: URL?
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Label("Export video", systemImage: "film").font(.title2.bold())
            if !exporter.isExporting && exporter.exportedURL == nil {
                Picker("Canvas", selection: $exporter.aspect) {
                    ForEach(SocialAspect.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Resolution", selection: $exporter.resolution) {
                    Text("720p").tag(720); Text("1080p").tag(1080); Text("4K").tag(2160)
                }.pickerStyle(.segmented)
                Picker("Frame rate", selection: $exporter.fps) {
                    ForEach([24, 30, 60], id: \.self) { Text("\($0) fps").tag($0) }
                }.pickerStyle(.segmented)
                let size = exporter.aspect.dimensions(resolution: exporter.resolution)
                Text("\(size.width) × \(size.height) · Full soundtrack included")
                    .foregroundStyle(.secondary)
            }
            if exporter.isExporting || exporter.exportedURL != nil {
                if let image = exporter.framePreview {
                    Image(decorative: image, scale: 1).resizable().scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 250).clipShape(RoundedRectangle(cornerRadius: 16))
                }
                ProgressView(value: exporter.progress)
                Text(saved ? "Video saved" : exporter.status).font(.headline)
                if let remaining = exporter.estimatedSecondsRemaining {
                    Text("About \(Duration.seconds(remaining).formatted(.time(pattern: .minuteSecond))) remaining")
                        .foregroundStyle(.secondary).monospacedDigit()
                }
            }
            if let saveError { Text(saveError).foregroundStyle(.red) }
            if !exporter.isExporting && exporter.exportedURL == nil && exporter.status.hasPrefix("Export failed") {
                Text(exporter.status).foregroundStyle(.red)
            }
            HStack {
                Button(exporter.isExporting ? "Cancel export" : "Done") {
                    if exporter.isExporting { exporter.cancel() } else { close() }
                }
                Spacer()
                if exporter.exportedURL != nil {
                    Button(saved ? "Save another copy" : "Save video") { saving = true }.buttonStyle(.borderedProminent)
                } else if !exporter.isExporting {
                    Button("Render video") { startExport() }.buttonStyle(.borderedProminent)
                        .disabled(studio.audioURL == nil)
                }
            }
        }.padding(32).frame(width: 660, height: 570)
            .interactiveDismissDisabled(exporter.isExporting)
            .fileExporter(isPresented: $saving, item: exporter.exportedURL.map(VisionMovie.init),
                contentTypes: [.mpeg4Movie], defaultFilename: "PulseCanvas Video") { result in
                switch result {
                case .success: saved = true; saveError = nil
                case .failure(let error): saveError = "Couldn't save video: \(error.localizedDescription)"
                }
            }
            .onAppear {
                exporter.aspect = studio.project.exportAspect.flatMap(SocialAspect.init(rawValue:)) ?? .wide
                exporter.resolution = studio.project.exportResolution ?? 1080
                exporter.fps = min(60, studio.project.exportFPS ?? 60)
            }
            .onDisappear { if let work { try? FileManager.default.removeItem(at: work) } }
    }
    private func startExport() {
        studio.suspend()
        studio.saveExportFormat(aspect: exporter.aspect.rawValue, resolution: exporter.resolution, fps: exporter.fps)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("Vision-video-\(UUID().uuidString)")
        do { try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) }
        catch { saveError = error.localizedDescription; return }
        work = folder; saveError = nil; saved = false
        let audio = studio.audioURL
        let cuts = studio.segments
        let looks = studio.project.looks.mapValues(\.preset)
        Task { await exporter.export(audioURL: audio, render: studio.render,
            to: folder.appendingPathComponent("PulseCanvas Video.mp4"), segments: cuts, appearances: looks) }
    }
}
