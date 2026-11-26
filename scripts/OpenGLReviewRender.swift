import AppKit
@preconcurrency import AVFoundation
import Foundation

/// One preset per process isolates shader/translator failures during review.
@main struct OpenGLReviewRender {
    @MainActor static func main() async {
        NSApplication.shared.setActivationPolicy(.accessory)
        do {
            let args = CommandLine.arguments
            guard args.count == 4, let index = Int(args[1]) else { throw ExportError("Usage: OpenGLReviewRender CATALOG_INDEX AUDIO OUTPUT") }
            let catalogURL = URL(fileURLWithPath: "Sources/PulseCanvas/Resources/ProjectM/catalog.json")
            let catalog = try JSONDecoder().decode([ProjectMPreset].self, from: Data(contentsOf: catalogURL))
            guard catalog.indices.contains(index), let scene = ProjectMPresets.shared.scene(for: catalog[index].id) else { throw ExportError("Preset is not in the bundled library") }
            let state = RenderState()
            state.scene = scene
            state.chaos = 1
            state.speed = 1
            state.brightness = 1
            state.zoom = 1
            state.rotation = 0
            state.motionBlur = 0
            state.strobeEnabled = false
            state.projectMFramesPerSecond = 30
            let key = "PulseCanvas.videoFormat.v1"
            let saved = UserDefaults.standard.data(forKey: key)
            defer {
                if let saved { UserDefaults.standard.set(saved, forKey: key) }
                else { UserDefaults.standard.removeObject(forKey: key) }
            }
            let exporter = SocialExportController()
            exporter.aspect = .wide; exporter.resolution = 720; exporter.fps = 30
            let destination = URL(fileURLWithPath: args[3])
            await exporter.export(audioURL: URL(fileURLWithPath: args[2]), render: state, to: destination)
            guard exporter.exportedURL == destination else { throw ExportError(exporter.status) }
            print("Rendered \(catalog[index].title) — \(catalog[index].id)")
        } catch {
            fputs("REVIEW ERROR: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
