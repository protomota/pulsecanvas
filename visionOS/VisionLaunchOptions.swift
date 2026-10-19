import Foundation

/// Launch hooks for UI tests and recorded demos. Every hook is opt-in through launch arguments, so an ordinary launch
/// (App Store, TestFlight, Xcode Run) behaves exactly as before.
///
///     -PCUITesting            fresh, isolated Studio and Radio storage in a temporary folder (no autosave restore,
///                             the bundled demo soundtrack, a new timeline); the user's own files are never touched
///     -PCAutoplay             start playback once the soundtrack is ready
///     -PCOpenImmersive        open the immersive viewing space once playback starts (implies -PCAutoplay)
///     -PCHideRoom YES|NO      set the "Hide room" switch before opening (default: the app's own default)
///     -PCRadio                start in Radio mode (needs the network)
///     -PCVisualizer <n|name>  put this visualizer on the first timeline card (index into NativeEffects.names, or a
///                             case-insensitive name)
///     -PCSeek <seconds>       seek the soundtrack before playing
///     -PCCaptureAudio <file>  debug UI-test capture only: import a local fixture through the real audio path
struct VisionLaunchOptions: Equatable {
    var uiTesting = false
    var autoplay = false
    var openImmersive = false
    var hideRoom: Bool?
    var radio = false
    var visualizer: String?
    var seek: Double?
    /// Debug-only recorded-demo sequence; applied only with isolated UI-test storage.
    var captureScenes: [Int] = []
    /// Optional short local soundtrack for an isolated debug capture of real export/save UI.
    var captureAudio: URL?

    static let current = VisionLaunchOptions(arguments: ProcessInfo.processInfo.arguments)

    init(arguments: [String]) {
        func value(_ flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
            let next = arguments[index + 1]
            return next.hasPrefix("-PC") ? nil : next
        }
        func flag(_ name: String) -> Bool {
            guard arguments.contains(name) else { return false }
            guard let next = value(name) else { return true }
            return !["NO", "no", "false", "0"].contains(next)
        }
        uiTesting = flag("-PCUITesting")
        openImmersive = flag("-PCOpenImmersive")
        autoplay = flag("-PCAutoplay") || openImmersive
        radio = flag("-PCRadio")
        if let room = value("-PCHideRoom") { hideRoom = !["NO", "no", "false", "0"].contains(room) }
        visualizer = value("-PCVisualizer")
        seek = value("-PCSeek").flatMap(Double.init)
        #if DEBUG
        if uiTesting { captureScenes = value("-PCCaptureScenes")?.split(separator: ",").compactMap { Int($0) } ?? [] }
        if uiTesting, let path = value("-PCCaptureAudio") {
            if path.hasPrefix("/") { captureAudio = URL(fileURLWithPath: path) }
            else if !path.isEmpty, path != ".", path != "..", !path.contains("/"), !path.contains("\\") {
                // Simulator installation can relocate the container between capture runs.
                captureAudio = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(path)
            }
        }
        #endif
    }

    /// The index of the requested visualizer in `names`, by number or by case-insensitive name.
    func visualizerIndex(in names: [String]) -> Int? {
        guard let visualizer else { return nil }
        if let index = Int(visualizer), names.indices.contains(index) { return index }
        return names.firstIndex { $0.compare(visualizer, options: .caseInsensitive) == .orderedSame }
    }

    /// A per-launch temporary folder for `-PCUITesting`, so tests start clean and never read or write user data.
    static func isolatedDirectory(_ name: String) -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PulseCanvasUITesting-\(ProcessInfo.processInfo.processIdentifier)", isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

extension VisionSession {
    /// The app's session: normal storage, or fresh isolated storage under `-PCUITesting`.
    static func forLaunch(_ launch: VisionLaunchOptions = .current) -> VisionSession {
        guard launch.uiTesting else { return VisionSession() }
        let defaults = UserDefaults(suiteName: "PulseCanvasUITesting-\(ProcessInfo.processInfo.processIdentifier)")!
        return VisionSession(editor: VisionStudio(directory: VisionLaunchOptions.isolatedDirectory("Studio")),
                             radio: VisionRadio(directory: VisionLaunchOptions.isolatedDirectory("Radio"), defaults: defaults))
    }
}

@MainActor extension VisionLaunchOptions {
    /// Use the actual Studio assignment/settings paths for reproducible simulator recordings.
    /// Ordinary launches and release builds never read or apply this capture-only sequence.
    func applyCaptureSequence(to studio: VisionStudio) {
        #if DEBUG
        guard uiTesting, !captureScenes.isEmpty, captureScenes.count <= 64,
              captureScenes.allSatisfy({ NativeEffects.activeIDs.contains($0) }) else { return }
        studio.applyCommonSettings(VisionCommonSettings(bars: 1, chaos: 0.85, zoomSpeed: 2,
                                                        motionSpeed: 1.3, strobeEnabled: false))
        for (index, clip) in studio.project.clips.enumerated() {
            studio.assign(captureScenes[index % captureScenes.count], to: clip.id)
        }
        for segment in studio.segments {
            NSLog("CAPTURE-SEGMENT %.3f %.3f %d %@", segment.start, segment.end, segment.scene, NativeEffects.names[segment.scene])
        }
        #endif
    }
}
