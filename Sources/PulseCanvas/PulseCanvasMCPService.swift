#if os(macOS) && DIRECT_BUILD && !STORE_BUILD
import AVFoundation
import Combine
import Foundation

@MainActor
final class PulseMCPService: ObservableObject {
    typealias Object = PulseMCP.Object
    private var access: PulseMCPAccess!
    private var audio: AudioController!
    private var studio: StudioStore!
    private var radio: RadioController!
    private var render: RenderState!
    private var exporter: SocialExportController!
    private var jobs: PulseMCPJobs!
    private let library = ProjectMPresets.shared
    private var preparing = false
    private var radioCatalog: (source: URL, catalog: RadioCatalog, url: URL, stationID: String)?

    func attach(access: PulseMCPAccess, audio: AudioController, studio: StudioStore, radio: RadioController,
                render: RenderState, exporter: SocialExportController) {
        guard self.access == nil else { return }
        self.access = access
        self.audio = audio
        self.studio = studio
        self.radio = radio
        self.render = render
        self.exporter = exporter
        jobs = PulseMCPJobs(access: access, exporter: exporter)
    }

    func call(_ name: String, _ args: Object) async -> Object {
        do {
            guard let tool = PulseMCP.tools.first(where: { $0.name == name }), PulseMCP.valid(args, schema: tool.input) else {
                throw PulseMCPError("INVALID_ARGUMENTS", "Use the published input schema.")
            }
            if name == "get_app_status" {
                return ["value": ["running": true, "enabled": access.enabled,
                                  "edition": PulseMCPAccess.edition, "version": PulseMCPAccess.version,
                                  "editing": access.enabled && access.editing, "playback": access.enabled && access.playback,
                                  "rendering": access.enabled && access.rendering,
                                  "pendingExports": access.enabled ? jobs.pendingCount : 0]]
            }
            guard access.enabled else {
                throw PulseMCPError("CONNECTION_DISABLED", "Enable local agent access in PulseCanvas Studio → Settings → Agent access.")
            }
            if let permission = tool.permission { try require(permission) }
            return ["value": try await execute(name, args)]
        } catch {
            return ["error": PulseMCPJobs.error(error, defaultCode: "OPERATION_FAILED").payload]
        }
    }

    private func execute(_ name: String, _ args: Object) async throws -> Object {
        switch name {
        case "get_capabilities": return capabilities()
        case "list_visualizers": return listVisualizers(args)
        case "get_visualizer": return visualizer(try scene(args.string("id")), detailed: true)
        case "list_favorites":
            let kind = args.string("kind")
            let items = kind == "visualizer"
                ? library.availableScenes.filter(library.isFavorite).map { visualizer($0) }
                : radio.favoriteSongs.map { song($0.track) }
            return ["kind": kind, "favorites": items]
        case "list_radio_songs":
            let tracks: [RadioTrack]
            if let current = radio.catalog, !radio.isPersonalMusic { tracks = current.tracks }
            else { tracks = try await radioFavoritesCatalog().catalog.tracks }
            return page(tracks.map { song($0) }, args: args, key: "songs")
        case "set_favorite": return try await setFavorite(args)
        case "get_playback_state": return try playback()
        case "load_song":
            try checkRevision(args)
            let source = try authorizedAudio(args.string("path"))
            let prepared = try await prepare(source, args: args, permission: "playback")
            try install(prepared)
            studio.segments = []; studio.detectedBPM = nil; studio.generationSeed = nil
            return try playback()
        case "set_playback_state":
            try checkStudio()
            guard audio.selectedURL != nil else { throw audioUnavailable() }
            switch args.string("state") {
            case "play":
                if !audio.isPlaying { audio.playFullSoundtrack() }
                guard audio.isPlaying else { throw PulseMCPError("PLAYBACK_FAILED", "PulseCanvas could not start the audio engine.") }
            case "pause": audio.pause()
            default: audio.stop()
            }
            return try playback()
        case "seek":
            try checkStudio()
            guard audio.selectedURL != nil, audio.duration > 0 else { throw audioUnavailable() }
            let position = args.double("seconds")
            guard position <= audio.duration else { throw PulseMCPError("INVALID_POSITION", "Seek within the reported soundtrack duration.") }
            audio.seek(fraction: position / audio.duration)
            return try playback()
        case "set_volume":
            let volume = Float(args.double("volume"))
            if radio.isActive { radio.volume = volume } else { audio.volume = volume }
            return try playback()
        case "get_project":
            try checkStudio()
            return try projectDetails(document(), duration: audio.duration)
        case "create_project":
            try checkStudio(); try checkRevision(args)
            studio.cloudProjectID = UUID().uuidString
            studio.generationSeed = nil; studio.isStudio = true
            studio.barsPerSection = args["barsPerScene"] as? Int ?? 4
            studio.segments = []; studio.selectedSegment = 0
            studio.detectedBPM = audio.segmentPlan(beatsPerSection: studio.beatsPerSection)?.bpm
            return try projectDetails(document(), duration: audio.duration)
        case "open_project": return try await openProject(args)
        case "save_project": return try saveProject(args)
        case "analyze_song":
            try checkStudio()
            guard let grid = audio.segmentPlan(beatsPerSection: args["beatsPerSection"] as? Int ?? 1) else { throw audioUnavailable() }
            var info: Object = ["boundariesSeconds": grid.boundaries]
            info["bpm"] = grid.bpm
            return info
        case "set_timeline":
            try checkStudio(); try checkRevision(args)
            let entries = args["segments"] as? [Object] ?? []
            let segments = try entries.map {
                StudioSegment(start: $0.double("startSeconds"), end: $0.double("endSeconds"),
                              scene: try scene($0.string("visualizerId")), bars: $0["bars"] as? Int)
            }
            try checkWholeSong(segments, duration: audio.duration)
            var appearances = studio.presets
            for index in Set(segments.map(\.scene)) where appearances[index] == nil {
                appearances[index] = library.favoriteAppearance(for: index) ?? .defaults(for: index)
            }
            studio.presets = appearances
            studio.isStudio = true; studio.segments = segments; studio.generationSeed = nil
            studio.follow(time: audio.playbackSeconds, render: render)
            return try projectDetails(document(), duration: audio.duration)
        case "set_visualizer":
            try checkStudio(); try checkRevision(args)
            let index = try scene(args.string("id"))
            if let section = args["section"] as? Int {
                guard studio.segments.indices.contains(section) else {
                    throw PulseMCPError("INVALID_TIMELINE", "Read the project and choose an existing section index.")
                }
                studio.assignScene(index, at: section, render: render)
                studio.generationSeed = nil
            } else {
                studio.selectScene(index, render: render)
            }
            return try projectDetails(document(), duration: audio.duration)
        case "set_visualizer_settings":
            try checkStudio(); try checkRevision(args)
            let index = try scene(args.string("id"))
            let changes = args["settings"] as? Object ?? [:]
            let controls = controls(for: index)
            guard changes.keys.allSatisfy({ controls[$0] != nil }) else {
                throw PulseMCPError("UNSUPPORTED_SETTING", "Read get_visualizer for controls that apply to this effect.")
            }
            let updated = try appearance(for: index, changes: changes)
            if studio.presets[index] != updated { studio.presets[index] = updated }
            if index == render.scene { updated.apply(to: render) }
            return try projectDetails(document(), duration: audio.duration)
        case "start_export", "render_preview": return try startExport(name, args)
        case "get_export_status": return ["job": jobs.details(try jobs.job(args.string("id")))]
        case "list_exports": return ["jobs": try jobs.recent(args["limit"] as? Int ?? 25).map(jobs.details)]
        case "cancel_export": return ["job": jobs.details(try jobs.cancel(args.string("id")))]
        case "create_music_video": return try await createMusicVideo(args)
        default: throw PulseMCPError("UNKNOWN_TOOL", "Use tools/list to discover the supported tools.")
        }
    }

    private func require(_ permission: String) throws {
        guard access.enabled, access.permits(permission) else {
            throw PulseMCPError("PERMISSION_REQUIRED", "Enable \(permission) access in PulseCanvas Studio → Settings → Agent access.")
        }
    }

    private func capabilities() -> Object {
        var result: Object = [
            "edition": PulseMCPAccess.edition, "resolutions": SocialExportController.supportedResolutions,
            "frameRates": SocialExportController.supportedFrameRates.filter { [24, 30, 60].contains($0) },
            "aspects": SocialAspect.allCases.map(\.agentName),
            "engines": library.entries.isEmpty ? ["metal"] : ["metal", "projectM"],
            "videoCodec": "h264", "audioCodec": "aac", "controls": PulseMCP.controlProperties,
            "maxPendingExports": PulseMCPJobs.maxPending
        ]
        result["inputFolder"] = access.scope(.input)?.url.path
        result["outputFolder"] = access.scope(.output)?.url.path
        return result
    }

    private func checkStudio() throws {
        guard !radio.isActive else {
            throw PulseMCPError("RADIO_ACTIVE", "Studio operations preserve the current Radio session. Load an authorized song to switch to Studio.")
        }
    }

    private func scene(_ id: String) throws -> Int {
        let index = id.hasPrefix("native:") ? Int(id.dropFirst(7)) : library.scene(for: id)
        guard let index, library.availableScenes.contains(index), library.identity(for: index) == id else {
            throw PulseMCPError("UNSUPPORTED_EFFECT", "The visualizer ID is unknown or unavailable in this edition. Read list_visualizers.")
        }
        return index
    }

    private func visualizer(_ index: Int, detailed: Bool = false) -> Object {
        var item: Object = ["id": library.identity(for: index), "name": library.sceneNames[index],
                            "category": library.category(for: index),
                            "engine": library.preset(for: index) == nil ? "metal" : "projectM",
                            "available": true, "favorite": library.isFavorite(index)]
        if detailed {
            if let data = try? JSONEncoder().encode(look(index)) {
                item["settings"] = try? JSONSerialization.jsonObject(with: data)
            }
            item["controls"] = controls(for: index)
        }
        return item
    }

    private func listVisualizers(_ args: Object) -> Object {
        let query = args["query"] as? String
        let engine = args["engine"] as? String
        let category = args["category"] as? String
        let hits = library.availableScenes.lazy.map { self.visualizer($0) }.filter {
            (engine == nil || $0.string("engine") == engine) &&
            (category == nil || $0.string("category").localizedCaseInsensitiveCompare(category!) == .orderedSame) &&
            (args["favoritesOnly"] as? Bool != true || $0["favorite"] as? Bool == true) &&
            (query == nil || $0.string("name").localizedCaseInsensitiveContains(query!) ||
                $0.string("id").localizedCaseInsensitiveContains(query!))
        }
        return page(Array(hits), args: args, key: "visualizers")
    }

    private func page(_ items: [Object], args: Object, key: String) -> Object {
        let offset = min(args["offset"] as? Int ?? 0, items.count)
        let end = min(offset + (args["limit"] as? Int ?? 50), items.count)
        var response: Object = [key: Array(items[offset..<end]), "total": items.count]
        if end < items.count { response["nextOffset"] = end }
        return response
    }

    private func song(_ track: RadioTrack) -> Object {
        ["id": track.id, "title": track.title, "genre": track.genre, "durationSeconds": track.duration,
         "favorite": radio.isFavoriteSong(track)]
    }

    private func setFavorite(_ args: Object) async throws -> Object {
        let id = args.string("id"), kind = args.string("kind"), desired = args["favorite"] as? Bool == true
        if kind == "visualizer" {
            let index = try scene(id)
            if library.isFavorite(index) != desired { library.toggleFavorite(index, appearance: look(index)) }
        } else {
            if desired, !radio.favoriteSongs.contains(where: { $0.id == id }),
               !radio.setFavoriteSong(id: id, favorite: true) {
                let resolved = try await radioFavoritesCatalog()
                guard let track = resolved.catalog.tracks.first(where: { $0.id == id }) else {
                    throw PulseMCPError("SONG_NOT_FOUND", "Read list_radio_songs to find an available Radio track ID.")
                }
                try require("editing")
                let song = FavoriteRadioSong(track: track, sourceURL: resolved.source, catalogURL: resolved.url,
                                             stationID: resolved.stationID, folderBookmark: radio.studioMusicFolderBookmark)
                guard radio.setFavoriteSong(id: id, favorite: true, candidate: song) else {
                    throw PulseMCPError("FAVORITE_NOT_SAVED", "Verify the Radio catalog and the saved favorites limit.")
                }
            } else if !desired {
                guard UUID(uuidString: id) != nil else {
                    throw PulseMCPError("SONG_NOT_FOUND", "Supply a Radio track ID from list_radio_songs or list_favorites.")
                }
                _ = radio.setFavoriteSong(id: id, favorite: false)
            }
        }
        return ["kind": kind, "id": id, "favorite": desired]
    }

    /// Resolve the app's configured Radio library without starting playback or
    /// changing the active station. Local libraries still require an input grant.
    private func radioFavoritesCatalog() async throws -> (source: URL, catalog: RadioCatalog, url: URL, stationID: String) {
        let configured = radio.studioMusicSource
        let authorized = configured.isFileURL ? try access.authorize(configured.path, in: [.input]) : nil
        let source = authorized?.url ?? configured
        defer { withExtendedLifetime(authorized?.scope) {} }
        if let radioCatalog, radioCatalog.source == source { return radioCatalog }
        do {
            let resolved = try await radio.studioMusicLibrary.completeCatalog(at: source)
            guard access.enabled, radio.studioMusicSource == configured else {
                throw PulseMCPError("RADIO_CATALOG_CHANGED", "The Radio source or agent access changed. Read the current catalog and retry.")
            }
            if source.isFileURL { _ = try access.authorize(resolved.url.path, in: [.input]) }
            let entry = (source: source, catalog: resolved.catalog, url: resolved.url, stationID: resolved.stationID)
            radioCatalog = entry
            return entry
        } catch let failure as PulseMCPError { throw failure }
        catch {
            throw PulseMCPError("RADIO_CATALOG_UNAVAILABLE", "The configured Radio catalog could not be loaded. Check the Radio source or connection.")
        }
    }

    private func controls(for index: Int) -> Object {
        var controls = PulseMCP.controlProperties
        if library.preset(for: index) != nil {
            // The preset supplies its own colors, particle sizes and depth.
            for key in ["palette", "particleSize", "fog"] { controls.removeValue(forKey: key) }
        }
        if NativeEffects.effect(index)?.detailLabel == nil { controls.removeValue(forKey: "liquidDetail") }
        if index != 28 { controls.removeValue(forKey: "haloCount") }
        return controls
    }

    private func look(_ index: Int) -> VisualPreset {
        if index == render.scene { return studio.preset(render) }
        return studio.presets[index] ?? library.favoriteAppearance(for: index) ?? .defaults(for: index)
    }

    private func appearance(for index: Int, changes: Object) throws -> VisualPreset {
        let data = try JSONEncoder().encode(look(index))
        let existing = try JSONSerialization.jsonObject(with: data) as? Object ?? [:]
        let merged = existing.merging(changes) { _, new in new }
        return try JSONDecoder().decode(VisualPreset.self, from: JSONSerialization.data(withJSONObject: merged))
    }

    private func audioUnavailable() -> PulseMCPError {
        PulseMCPError("AUDIO_UNAVAILABLE", "Load an existing local audio file from the authorized input folder.")
    }

    private func authorizedAudio(_ path: String) throws -> PulseMCPAccess.AuthorizedPath {
        do { return try access.authorize(path, in: [.input]) }
        catch let error as PulseMCPError where error.code == "FILE_UNAVAILABLE" {
            throw PulseMCPError("AUDIO_UNAVAILABLE", error.message)
        }
    }

    private func prepare(_ source: PulseMCPAccess.AuthorizedPath, args: Object, permission: String) async throws -> PreparedSoundtrack {
        guard !preparing else { throw PulseMCPError("PROJECT_BUSY", "Wait for the other song or project preparation to finish.") }
        preparing = true
        defer { preparing = false }
        let original = try PulseMCPJobs.sourceIdentity(source.url)
        defer { withExtendedLifetime(source.scope) {} }
        let preparation = Task.detached(priority: .userInitiated) { try PreparedSoundtrack(url: source.url) }
        let prepared: PreparedSoundtrack
        do {
            prepared = try await withTaskCancellationHandler { try await preparation.value } onCancel: { preparation.cancel() }
        } catch { throw PulseMCPJobs.error(error, defaultCode: "AUDIO_UNAVAILABLE") }
        let current = try PulseMCPJobs.sourceIdentity(source.url)
        guard current.bytes == original.bytes, current.modified == original.modified else {
            throw PulseMCPError("AUDIO_CHANGED", "The file changed during preparation. Retry with a stable local copy.")
        }
        try require(permission)
        _ = try authorizedAudio(source.url.path)
        try checkRevision(args)
        guard prepared.analyzer.duration > 0, prepared.analyzer.duration <= 86_400 else { throw audioUnavailable() }
        return prepared
    }

    private func install(_ prepared: PreparedSoundtrack) throws {
        radio.leave()
        guard audio.install(prepared) else { throw audioUnavailable() }
        studio.timelineSoundtrack = audio.selectedURL
    }

    private func document() -> CreatorProject {
        studio.document(audio: audio, render: render, exporter: exporter)
    }

    private func revision(_ project: CreatorProject) throws -> String {
        var stable = project
        if let scene = stable.timeline?.first?.scene, stable.studioEnabled == true {
            stable.scene = scene
            stable.appearance = stable.visualPresets?[scene] ?? .defaults(for: scene)
        }
        return UserBackup.hash(try stable.encoded())
    }

    private func checkRevision(_ args: Object) throws {
        guard try revision(document()) == args.string("expectedRevision") else {
            throw PulseMCPError("PROJECT_CONFLICT", "The Studio project changed. Read the current revision and review the new project before retrying.")
        }
    }

    private func projectDetails(_ project: CreatorProject, duration: Double) throws -> Object {
        let aspect = SocialAspect(rawValue: project.aspect) ?? .wide
        var result: Object = ["revision": try revision(project), "durationSeconds": min(duration, 86_400),
                              "visualizerId": library.identity(for: project.scene),
                              "studioEnabled": project.studioEnabled ?? false,
                              "timeline": timeline(project).map(\.payload),
                              "exportSettings": ["aspect": aspect.agentName, "resolution": project.resolution, "fps": project.fps]]
        result["id"] = project.cloudProjectID
        result["seed"] = project.generationSeed
        if let path = project.soundtrack?.path, (try? authorizedAudio(path)) != nil {
            result["soundtrackPath"] = path
        }
        result["barsPerScene"] = project.barsPerSection.flatMap { (1...128).contains($0) ? $0 : nil }
        return result
    }

    private func timeline(_ project: CreatorProject) -> [PulseMCPScene] {
        (project.timeline ?? []).map {
            PulseMCPScene(visualizerId: project.effectIdentities?[$0.scene] ?? library.identity(for: $0.scene),
                          startSeconds: $0.start, endSeconds: $0.end, bars: $0.bars)
        }
    }

    private func playback() throws -> Object {
        ["ready": audio.selectedURL != nil, "playing": audio.isPlaying, "positionSeconds": min(audio.playbackSeconds, 86_400),
         "durationSeconds": min(audio.duration, 86_400), "volume": audio.volume,
         "mode": radio.isActive ? "radio" : "studio", "title": audio.title, "revision": try revision(document())]
    }

    private func checkWholeSong(_ segments: [StudioSegment], duration: Double) throws {
        guard duration > 0, !segments.isEmpty,
              StudioTimeline.valid(segments, sceneCount: library.sceneNames.count),
              let end = segments.last?.end, abs(end - duration) <= 0.001 else {
            throw PulseMCPError("INVALID_TIMELINE", "Supply contiguous sections from zero through the exact soundtrack duration.")
        }
    }

    private func outputPath(_ path: String, extension expected: String) throws -> PulseMCPAccess.AuthorizedPath {
        let output = try access.authorize(path, in: [.output], writing: true)
        guard output.url.pathExtension.lowercased() == expected else {
            throw PulseMCPError("INVALID_PATH", "Use a .\(expected) filename in the authorized output folder.")
        }
        return output
    }

    private func openProject(_ args: Object) async throws -> Object {
        try checkRevision(args)
        let input = try access.authorize(args.string("path"), in: [.input, .output])
        defer { withExtendedLifetime(input.scope) {} }
        guard input.url.pathExtension.lowercased() == "pulsecanvas",
              let size = try input.url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size <= 8_000_000 else {
            throw PulseMCPError("INVALID_PROJECT", "Choose a PulseCanvas project file under 8 MB.")
        }
        let data = try Data(contentsOf: input.url)
        let saved = try JSONDecoder().decode(CreatorProject.self, from: data)
        let referenced = Set((saved.timeline ?? []).map(\.scene)).union([saved.scene])
        for index in referenced {
            if library.isRetiredScene(index, identities: saved.effectIdentities) {
                throw PulseMCPError("UNSUPPORTED_EFFECT", "This project uses a retired effect. Open it in Studio if you want to choose a replacement.")
            }
        }
        let project: CreatorProject
        do { project = try saved.remapped(using: library) }
        catch { throw PulseMCPError("UNSUPPORTED_EFFECT", error.localizedDescription) }
        let aspect = try project.checkedAspect()
        if let source = try BundledSoundtrack.resolve(identifier: project.bundledSoundtrack, externalURL: project.soundtrack) {
            try require("playback")
            let prepared = try await prepare(try authorizedAudio(source.path), args: args, permission: "editing")
            try require("playback")
            guard (project.timeline?.last?.end ?? 0) <= prepared.analyzer.duration + 0.05 else {
                throw PulseMCPError("INVALID_TIMELINE", "The project's timeline extends beyond its authorized soundtrack.")
            }
            try install(prepared)
        } else {
            guard (project.timeline?.last?.end ?? 0) == 0 else { throw audioUnavailable() }
            try require("playback")
            radio.leave(); audio.clear(); studio.timelineSoundtrack = nil
        }
        studio.applyDocument(project, aspect: aspect, audio: audio, render: render, exporter: exporter)
        try UserBackup.rememberProject(data, name: input.url.path)
        return try projectDetails(document(), duration: audio.duration)
    }

    private func signature(_ tool: String, _ args: Object) -> String {
        UserBackup.hash(Data((tool + "\n" + PulseMCP.jsonText(args)).utf8))
    }

    private func writeProject(_ project: CreatorProject, to url: URL, overwrite: Bool) throws {
        try PulseMCPJobs.checkDestination(url, overwrite: overwrite)
        let staging = url.deletingLastPathComponent().appendingPathComponent(".PulseCanvas-project-" + UUID().uuidString)
        let data = try project.encoded()
        if overwrite && FileManager.default.fileExists(atPath: url.path) {
            guard let current = project.cloudProjectID,
                  let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size <= 8_000_000,
                  let existing = try? JSONDecoder().decode(CreatorProject.self, from: Data(contentsOf: url)),
                  existing.cloudProjectID == current else {
                throw PulseMCPError("OUTPUT_EXISTS", "Use a new name. PulseCanvas can replace only another save of this project.")
            }
        }
        try data.write(to: staging, options: .withoutOverwriting)
        defer { try? FileManager.default.removeItem(at: staging) }
        try PulseMCPJobs.publish(staging, to: url, overwrite: overwrite)
        try UserBackup.rememberProject(data, name: url.path)
    }

    private func saveProject(_ args: Object) throws -> Object {
        let key = args.string("requestKey"), signature = signature("save_project", args)
        let target = try outputPath(args.string("path"), extension: "pulsecanvas")
        defer { withExtendedLifetime(target.scope) {} }
        if let receipt = try jobs.repeatSave(key: key, signature: signature) {
            guard FileManager.default.fileExists(atPath: target.url.path) else {
                throw PulseMCPError("PROJECT_NOT_FOUND", "The previously saved project is missing. Choose a destination and new request key.")
            }
            return ["path": receipt.path, "project": try projectDetails(receipt.project, duration: receipt.duration)]
        }
        try checkStudio(); try checkRevision(args)
        var document = document()
        if document.cloudProjectID == nil { document.cloudProjectID = UUID().uuidString }
        try writeProject(document, to: target.url, overwrite: args["overwrite"] as? Bool == true)
        try jobs.rememberSave(.init(key: key, signature: signature, path: target.url.path, project: document, duration: audio.duration))
        studio.cloudProjectID = document.cloudProjectID
        return ["path": target.url.path, "project": try projectDetails(document, duration: audio.duration)]
    }

    private func exportFormat(_ args: Object) throws -> PulseMCPJobs.Format {
        let aspect = args["aspect"] as? String ?? exporter.aspect.agentName
        let resolution = args["resolution"] as? Int ?? exporter.resolution
        let fps = args["fps"] as? Int ?? exporter.fps
        guard SocialExportController.supportedResolutions.contains(resolution),
              SocialExportController.supportedFrameRates.contains(fps), [24, 30, 60].contains(fps) else {
            throw PulseMCPError("UNSUPPORTED_FORMAT", "Choose a resolution and frame rate from get_capabilities.")
        }
        return .init(aspect: aspect, resolution: resolution, fps: fps)
    }

    private func startExport(_ tool: String, _ args: Object) throws -> Object {
        let key = args.string("requestKey"), signature = signature(tool, args)
        if let previous = try jobs.repeatJob(key: key, signature: signature) { return ["job": jobs.details(previous)] }
        try checkStudio(); try checkRevision(args)
        guard let soundtrack = audio.selectedURL, audio.duration > 0 else { throw audioUnavailable() }
        let source = try authorizedAudio(soundtrack.path)
        let target = try outputPath(args.string("path"), extension: "mp4")
        defer { withExtendedLifetime((source.scope, target.scope)) {} }
        let preview = tool == "render_preview" ? (args["previewSeconds"] as? Double ?? 5) : nil
        guard tool == "render_preview" || args["previewSeconds"] == nil else {
            throw PulseMCPError("INVALID_ARGUMENTS", "Use render_preview for a short clip.")
        }
        let project = document()
        if project.studioEnabled == true { try checkWholeSong(project.timeline ?? [], duration: audio.duration) }
        let job = try makeJob(args: args, signature: signature, project: project, source: source.url, destination: target.url,
                              format: exportFormat(args), projectPath: nil, preview: preview, duration: audio.duration, fallback: false)
        try jobs.submit(job)
        return ["job": jobs.details(job)]
    }

    private func makeJob(args: Object, signature: String, project: CreatorProject, source: URL, destination: URL,
                         format: PulseMCPJobs.Format, projectPath: String?, preview: Double?, duration: Double,
                         fallback: Bool) throws -> PulseMCPJobs.Job {
        let overwrite = args["overwrite"] as? Bool == true
        try jobs.checkCapacity(destination: destination)
        try jobs.checkOutput(destination, overwrite: overwrite)
        let identity = try PulseMCPJobs.sourceIdentity(source)
        _ = try scene(library.identity(for: project.scene))
        for entry in timeline(project) { _ = try scene(entry.visualizerId) }
        return .init(id: UUID().uuidString, signature: signature, requestKey: args.string("requestKey"),
                     destination: destination.path, projectPath: projectPath, sourcePath: source.path,
                     sourceBytes: identity.bytes, sourceModified: identity.modified, settings: format,
                     previewSeconds: preview, overwrite: overwrite, project: project,
                     timeline: timeline(project), duration: duration, usedFallback: fallback)
    }

    private func creationResult(_ job: PulseMCPJobs.Job) throws -> Object {
        guard let path = job.projectPath else {
            throw PulseMCPError("PROJECT_NOT_FOUND", "The job does not have an editable project.")
        }
        let saved = try? access.authorize(path, in: [.output])
        defer { withExtendedLifetime(saved?.scope) {} }
        guard saved != nil else {
            throw PulseMCPError(job.errorCode ?? "PROJECT_NOT_FOUND",
                                job.errorMessage ?? "The editable project is unavailable in the authorized folder.")
        }
        return ["projectPath": path, "project": try projectDetails(job.project, duration: job.duration),
                "job": jobs.details(job), "usedFallback": job.usedFallback]
    }

    private func createMusicVideo(_ args: Object) async throws -> Object {
        try require("editing"); try require("playback")
        let key = args.string("requestKey"), signature = signature("create_music_video", args)
        if let previous = try jobs.repeatJob(key: key, signature: signature) { return try creationResult(previous) }
        try checkRevision(args)
        let source = try authorizedAudio(args.string("songPath"))
        let projectPath = try outputPath(args.string("projectPath"), extension: "pulsecanvas")
        let output = try outputPath(args.string("outputPath"), extension: "mp4")
        defer { withExtendedLifetime((source.scope, projectPath.scope, output.scope)) {} }
        try jobs.checkCapacity(destination: output.url)
        try PulseMCPJobs.checkDestination(output.url, overwrite: false)
        try PulseMCPJobs.checkDestination(PulseMCPJobs.manifestURL(output.url), overwrite: false)
        try PulseMCPJobs.checkDestination(projectPath.url, overwrite: false)
        let format = try exportFormat(args)
        let isPreview = args["previewOnly"] as? Bool == true
        guard isPreview || args["previewSeconds"] == nil else {
            throw PulseMCPError("INVALID_ARGUMENTS", "Set previewOnly to true to use previewSeconds.")
        }
        let prepared = try await prepare(source, args: args, permission: "editing")
        try require("playback"); try require("rendering")
        _ = try outputPath(projectPath.url.path, extension: "pulsecanvas")
        _ = try outputPath(output.url.path, extension: "mp4")
        let bars = args["barsPerScene"] as? Int ?? 4
        let seed = args["seed"] as? String ?? UUID().uuidString
        var generator = PulseMCPSeed(seed)
        let requested = try (args["visualizerIds"] as? [String] ?? []).map(scene)
        var pool = requested.isEmpty ? library.availableScenes.filter(library.isFavorite) : requested
        let fallback = pool.isEmpty
        if fallback {
            switch args.string("fallback") {
            case "metal": pool = library.availableScenes.filter { library.preset(for: $0) == nil }
            case "available": pool = library.availableScenes
            default: throw PulseMCPError("EMPTY_STYLE_POOL", "Add a favorite, choose visualizer IDs, or request an explicit fallback.")
            }
        }
        pool = Set(pool).sorted { library.identity(for: $0) < library.identity(for: $1) }
        guard !pool.isEmpty else { throw PulseMCPError("EMPTY_STYLE_POOL", "Choose an installed visualizer.") }
        pool.shuffle(using: &generator)
        let grid = prepared.analyzer.segmentPlan(beatsPerSection: bars * 4)
        let duration = prepared.analyzer.duration
        let sections = StudioTimeline.sections(boundaries: grid.boundaries, bars: bars) { index, _ in pool[index % pool.count] }
        try checkWholeSong(sections, duration: duration)
        var appearances = studio.presets
        for index in Set(sections.map(\.scene)) {
            var settings = appearances[index] ?? library.favoriteAppearance(for: index) ?? .defaults(for: index)
            settings.strobeEnabled = args["strobeEnabled"] as? Bool == true
            appearances[index] = settings
        }
        let first = sections[0].scene
        guard let aspect = SocialAspect.allCases.first(where: { $0.agentName == format.aspect }) else {
            throw PulseMCPError("UNSUPPORTED_FORMAT", "Choose an aspect from get_capabilities.")
        }
        let bookmarked = try? prepared.access.readOnlyBookmark()
        let project = CreatorProject(soundtrack: source.url, scene: first, appearance: appearances[first]!,
            aspect: aspect.rawValue, resolution: format.resolution, fps: format.fps, timeline: sections,
            studioEnabled: true, visualPresets: appearances, barsPerSection: bars,
            effectIdentities: library.identities(for: Set(appearances.keys)), soundtrackBookmark: bookmarked,
            loopPlayback: false, cloudProjectID: UUID().uuidString, generationSeed: seed)
        let job = try makeJob(args: args, signature: signature, project: project, source: source.url, destination: output.url,
                              format: format, projectPath: projectPath.url.path,
                              preview: isPreview ? args["previewSeconds"] as? Double ?? 5 : nil, duration: duration, fallback: fallback)
        try jobs.submit(job)
        do {
            try writeProject(project, to: projectPath.url, overwrite: false)
            try install(prepared)
            studio.applyDocument(project, aspect: aspect, audio: audio, render: render, exporter: exporter)
        } catch {
            jobs.failPreparation(job, error: error)
            throw error
        }
        return try creationResult(job)
    }
}

private extension Dictionary where Key == String, Value == Any {
    func string(_ key: String) -> String { self[key] as? String ?? "" }
    func double(_ key: String) -> Double { self[key] as? Double ?? 0 }
}
#endif
