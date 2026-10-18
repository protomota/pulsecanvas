import SwiftUI
import UniformTypeIdentifiers

struct VisionVideoExportView: View {
    @ObservedObject var studio: VisionStudio
    let close: () -> Void
    @StateObject private var exporter = SocialExportController()
    @State private var saveRequest: VisionVideoSaveRequest?
    @State private var readyURL: URL?
    @State private var saved = false
    @State private var saveError: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Label("Export video", systemImage: "film").font(.title2.bold())
            if !exporter.isExporting && readyURL == nil {
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
            if exporter.isExporting || readyURL != nil {
                if let image = exporter.framePreview {
                    Image(decorative: image, scale: 1).resizable().scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 250).clipShape(RoundedRectangle(cornerRadius: 16))
                }
                ProgressView(value: readyURL == nil ? exporter.progress : 1)
                Text(saved ? "Video saved" : readyURL != nil ? "Video ready to save" : exporter.status).font(.headline)
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
                if let readyURL {
                    Button("Render another video") { self.readyURL = nil; saved = false }
                    Button(saved ? "Save another copy" : "Save video", systemImage: "tray.and.arrow.down") {
                        do { saveRequest = try VisionVideoSaveRequest(url: readyURL) }
                        catch { saveError = "The rendered video is unavailable: \(error.localizedDescription)" }
                    }.buttonStyle(.borderedProminent)
                } else if !exporter.isExporting {
                    Button("Render video") { startExport() }.buttonStyle(.borderedProminent)
                        .disabled(studio.audioURL == nil)
                }
            }
        }.padding(32).frame(width: 660, height: 570)
            .interactiveDismissDisabled(exporter.isExporting)
            .sheet(item: $saveRequest) { request in
                VisionVideoSavePicker(request: request) { result in
                    saveRequest = nil
                    if let result {
                        switch result {
                        case .success: saved = true; saveError = nil
                        case .failure(let error): saveError = "Couldn't save video: \(error.localizedDescription)"
                        }
                    }
                }
            }
            .onAppear {
                readyURL = VisionVideoFile.recoverPreviousRender()
                exporter.aspect = studio.project.exportAspect.flatMap(SocialAspect.init(rawValue:)) ?? .wide
                exporter.resolution = studio.project.exportResolution ?? 1080
                exporter.fps = min(60, studio.project.exportFPS ?? 60)
            }
    }
    private func startExport() {
        studio.suspend()
        studio.saveExportFormat(aspect: exporter.aspect.rawValue, resolution: exporter.resolution, fps: exporter.fps)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("Vision-video-\(UUID().uuidString)")
        do { try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) }
        catch { saveError = error.localizedDescription; return }
        saveError = nil; saved = false; readyURL = nil
        let audio = studio.audioURL
        let cuts = studio.segments
        let looks = studio.project.looks.mapValues(\.preset)
        Task {
            var keepCompletedFile = false
            defer { if !keepCompletedFile { try? FileManager.default.removeItem(at: folder) } }
            await exporter.export(audioURL: audio, render: studio.render,
                to: folder.appendingPathComponent("PulseCanvas Video.mp4"), segments: cuts, appearances: looks)
            if let url = exporter.exportedURL {
                do { readyURL = try VisionVideoFile.retain(url) }
                catch {
                    readyURL = url; keepCompletedFile = true
                    saveError = "The video can be saved, but couldn't be cached for later: \(error.localizedDescription)"
                }
            }
        }
    }
}
