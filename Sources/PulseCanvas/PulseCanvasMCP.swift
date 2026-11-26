#if os(macOS) && DIRECT_BUILD && !STORE_BUILD
import CoreFoundation
import Darwin
import Foundation

struct PulseMCPError: LocalizedError {
    let code: String
    let message: String
    init(_ code: String, _ message: String) { self.code = code; self.message = message }
    var errorDescription: String? { message }
    var payload: [String: Any] { ["code": code, "message": message] }
}

enum PulseMCP {
    typealias Object = [String: Any]
    static let argument = "--mcp"
    static let maxMessage = 2_000_000
    private static let versions = ["2025-11-25", "2025-06-18", "2025-03-26", "2024-11-05"]

    struct Tool {
        let name: String
        let description: String
        let input: Object
        let output: Object
        let permission: String?
        var schema: Object {
            ["name": name, "description": description, "inputSchema": input, "outputSchema": output,
             "annotations": ["readOnlyHint": permission == nil]]
        }
    }

    static func object(_ properties: Object, required: [String] = [], open: Bool = false) -> Object {
        ["type": "object", "properties": properties, "required": required, "additionalProperties": open]
    }

    static func text(_ values: [String]? = nil, limit: Int = 4096) -> Object {
        var schema: Object = ["type": "string", "minLength": 1, "maxLength": limit]
        if let values { schema["enum"] = values }
        return schema
    }
    static func number(_ min: Double, _ max: Double, integer: Bool = false) -> Object {
        ["type": integer ? "integer" : "number", "minimum": min, "maximum": max]
    }
    static func array(_ items: Object, max: Int = 10_000) -> Object {
        ["type": "array", "items": items, "maxItems": max]
    }
    static let boolean = ["type": "boolean"]
    static let resolutions = [720, 1080, 2160]
    static let aspectNames = ["wide", "landscape", "portrait", "phone", "square"]
    static var format: Object {
        ["aspect": text(aspectNames), "resolution": ["type": "integer", "enum": resolutions],
         "fps": ["type": "integer", "enum": [24, 30, 60]]]
    }
    static let id = text(limit: 256)
    static let path = text()
    static let revision = text(limit: 64)
    static let requestKey = text(limit: 128)
    static let seconds = number(0, 86_400)
    static let bars = number(1, 128, integer: true)
    static let timelineEntry = object(
        ["visualizerId": id, "startSeconds": seconds, "endSeconds": seconds, "bars": bars],
        required: ["visualizerId", "startSeconds", "endSeconds"])
    static let playback = object(
        ["ready": boolean, "playing": boolean, "positionSeconds": seconds, "durationSeconds": seconds,
         "volume": number(0, 1), "mode": text(["studio", "radio"]), "title": text(), "revision": revision],
        required: ["ready", "playing", "positionSeconds", "durationSeconds", "volume", "mode", "title", "revision"])
    static let visualizer = object(
        ["id": id, "name": text(), "category": text(), "engine": text(["metal", "projectM"]),
         "available": boolean, "favorite": boolean, "settings": ["type": "object"], "controls": ["type": "object"]],
        required: ["id", "name", "category", "engine", "available", "favorite"])
    static let project = object(
        ["id": id, "revision": revision, "soundtrackPath": path, "durationSeconds": seconds, "seed": id,
         "barsPerScene": bars, "visualizerId": id, "timeline": array(timelineEntry),
         "exportSettings": object(format.merging(["fps": ["type": "integer", "enum": [24, 30, 60, 120]]]) { _, actual in actual }, required: ["aspect", "resolution", "fps"]), "studioEnabled": boolean],
        required: ["revision", "durationSeconds", "visualizerId", "timeline", "exportSettings", "studioEnabled"])
    static let job = object(
        ["id": id, "phase": text(["queued", "preparing", "rendering", "muxing", "validating", "completed", "failed", "cancelled"]),
         "progress": number(0, 1), "framesRendered": ["type": "integer"], "totalFrames": ["type": "integer"],
         "etaSeconds": ["type": "number"], "destination": path, "projectPath": path, "manifestPath": path,
         "previewOnly": boolean, "error": object(["code": text(), "message": text()], required: ["code", "message"]),
         "artifact": object(["path": path, "durationSeconds": seconds, "width": ["type": "integer"],
            "height": ["type": "integer"], "fps": ["type": "number"], "expectedFrames": ["type": "integer"],
            "videoCodec": text(), "audioCodec": text(), "bytes": ["type": "integer"]],
            required: ["path", "durationSeconds", "width", "height", "fps", "expectedFrames", "videoCodec", "audioCodec", "bytes"])],
        required: ["id", "phase", "progress", "framesRendered", "totalFrames", "destination", "previewOnly"])
    static let visualRanges: [String: ClosedRange<Double>] = [
        "speed": 0.05...3, "zoomSpeed": 0...3, "chaos": 0...1, "brightness": 0.1...3,
        "liquidDetail": 0...1, "particleSize": 0.3...6, "fog": 0...1, "zoom": 0.3...2,
        "rotation": -3.14...3.14, "motionBlur": 0...0.9, "strobeSensitivity": 0.25...4,
        "strobeStrength": 0.1...1, "haloCount": 1...12, "palette": 0...4
    ]
    static let controlProperties: Object = {
        var properties: Object = visualRanges.mapValues { number($0.lowerBound, $0.upperBound) }
        for key in ["haloCount", "palette"] {
            let range = visualRanges[key]!
            properties[key] = number(range.lowerBound, range.upperBound, integer: true)
        }
        properties["strobeEnabled"] = boolean
        return properties
    }()

    static let tools: [Tool] = {
        func tool(_ name: String, _ description: String, _ input: Object = [:], _ required: [String] = [],
                  output: Object, permission: String? = nil) -> Tool {
            Tool(name: name, description: description, input: object(input, required: required), output: output, permission: permission)
        }
        let jobResult = object(["job": job], required: ["job"])
        let kind = text(["visualizer", "radioSong"])
        let projectChange = ["expectedRevision": revision]
        let start = format.merging(["path": path, "expectedRevision": revision, "requestKey": requestKey,
                                    "overwrite": boolean, "previewSeconds": number(0.5, 30)]) { first, _ in first }
        let generate = format.merging(["songPath": path, "projectPath": path, "outputPath": path, "barsPerScene": bars,
                                      "expectedRevision": revision, "requestKey": requestKey, "seed": id,
                                      "fallback": text(["metal", "available", "error"]), "visualizerIds": array(id, max: 500),
                                      "strobeEnabled": boolean, "previewOnly": boolean,
                                      "previewSeconds": number(0.5, 30)]) { first, _ in first }
        return [
            tool("get_app_status", "Check whether the Mac app is running and agent access is enabled.",
                 output: object(["running": boolean, "enabled": boolean, "edition": text(), "version": text(),
                                 "playback": boolean, "editing": boolean, "rendering": boolean, "pendingExports": ["type": "integer"]],
                                required: ["running", "enabled", "edition", "version", "playback", "editing", "rendering", "pendingExports"])),
            tool("get_capabilities", "Read current permissions, supported export formats, and effect controls.",
                 output: object(["edition": text(), "resolutions": array(["type": "integer"]), "frameRates": array(["type": "integer"]),
                    "aspects": array(text()), "engines": array(text()), "inputFolder": path, "outputFolder": path,
                    "videoCodec": text(), "audioCodec": text(), "controls": ["type": "object"], "maxPendingExports": ["type": "integer"]],
                    required: ["edition", "resolutions", "frameRates", "aspects", "engines", "videoCodec", "audioCodec", "controls", "maxPendingExports"])),
            tool("list_visualizers", "Find installed effects by stable ID, name, category, engine or favorite state.",
                 ["query": text(limit: 256), "engine": text(["metal", "projectM"]), "category": text(limit: 256),
                  "favoritesOnly": boolean, "offset": number(0, 100_000, integer: true), "limit": number(1, 200, integer: true)],
                 output: object(["visualizers": array(visualizer, max: 200), "total": ["type": "integer"], "nextOffset": ["type": "integer"]],
                                required: ["visualizers", "total"])),
            tool("get_visualizer", "Read one installed visualizer and its saved appearance.", ["id": id], ["id"], output: visualizer),
            tool("list_favorites", "List saved visualizers or radio songs by stable ID.", ["kind": kind], ["kind"],
                 output: object(["kind": kind, "favorites": array(["type": "object"])], required: ["kind", "favorites"])),
            tool("list_radio_songs", "List tracks in the current or configured Radio catalog without starting playback.",
                 ["offset": number(0, 500, integer: true), "limit": number(1, 200, integer: true)],
                 output: object(["songs": array(["type": "object"], max: 200), "total": ["type": "integer"], "nextOffset": ["type": "integer"]],
                                required: ["songs", "total"])),
            tool("set_favorite", "Set or remove a saved favorite explicitly. Repeating the same request preserves the current saved look.",
                 ["kind": kind, "id": id, "favorite": boolean], ["kind", "id", "favorite"],
                 output: object(["kind": kind, "id": id, "favorite": boolean], required: ["kind", "id", "favorite"]), permission: "editing"),
            tool("load_song", "Prepare an existing local song and select it for Studio.",
                 ["path": path, "expectedRevision": revision], ["path", "expectedRevision"], output: playback, permission: "playback"),
            tool("get_playback_state", "Read the current transport position in seconds, duration, volume, and project revision.", output: playback),
            tool("set_playback_state", "Play, pause, or stop explicitly.",
                 ["state": text(["play", "pause", "stop"])], ["state"], output: playback, permission: "playback"),
            tool("seek", "Seek Studio audio to a position in seconds.", ["seconds": seconds], ["seconds"], output: playback, permission: "playback"),
            tool("set_volume", "Set transport volume from zero to one.", ["volume": number(0, 1)], ["volume"], output: playback, permission: "playback"),
            tool("get_project", "Read the editable Studio project and concurrency revision.", output: project),
            tool("create_project", "Start a new editable project using the loaded song and current visualizer.",
                 projectChange.merging(["barsPerScene": bars]) { first, _ in first }, ["expectedRevision"], output: project, permission: "editing"),
            tool("open_project", "Open an existing PulseCanvas project and its authorized soundtrack.",
                 ["path": path, "expectedRevision": revision], ["path", "expectedRevision"], output: project, permission: "editing"),
            tool("save_project", "Save the editable project to an authorized .pulsecanvas path.",
                 ["path": path, "overwrite": boolean, "expectedRevision": revision, "requestKey": requestKey],
                 ["path", "expectedRevision", "requestKey"], output: object(["path": path, "project": project], required: ["path", "project"]),
                 permission: "editing"),
            tool("analyze_song", "Read detected BPM and beat or bar grid boundaries on the loaded song.",
                 ["beatsPerSection": number(1, 512, integer: true)], output: object(
                    ["bpm": ["type": "number"], "boundariesSeconds": array(seconds, max: 500_000)],
                    required: ["boundariesSeconds"])),
            tool("set_timeline", "Replace the entire contiguous full-song timeline using stable visualizer IDs.",
                 ["segments": array(timelineEntry), "expectedRevision": revision], ["segments", "expectedRevision"],
                 output: project, permission: "editing"),
            tool("set_visualizer", "Select a visualizer in the editor, or assign it to an existing timeline section.",
                 ["id": id, "expectedRevision": revision, "section": number(0, 9999, integer: true)], ["id", "expectedRevision"],
                 output: project, permission: "editing"),
            tool("set_visualizer_settings", "Update applicable appearance controls for an installed visualizer.",
                 ["id": id, "settings": object(controlProperties), "expectedRevision": revision], ["id", "settings", "expectedRevision"],
                 output: project, permission: "editing"),
            tool("start_export", "Queue a full-song MP4 using a snapshot of the current Studio project.", start,
                 ["path", "expectedRevision", "requestKey"], output: jobResult, permission: "rendering"),
            tool("render_preview", "Queue a short MP4 using the same renderer and settings as the full export.", start,
                 ["path", "expectedRevision", "requestKey"], output: jobResult, permission: "rendering"),
            tool("get_export_status", "Read an export's progress, failure, or validated media artifact.", ["id": id], ["id"], output: jobResult),
            tool("list_exports", "Read current and recent retained export jobs.", ["limit": number(1, 100, integer: true)],
                 output: object(["jobs": array(job, max: 100)], required: ["jobs"])),
            tool("cancel_export", "Cancel a queued or running export by its durable job ID.", ["id": id], ["id"], output: jobResult, permission: "rendering"),
            tool("create_music_video", "Analyze an authorized song, save a beat-aligned project, and queue an export. Explicit fallback and strobe choices are required.",
                 generate, ["songPath", "projectPath", "outputPath", "fallback", "strobeEnabled", "expectedRevision", "requestKey"],
                 output: object(["projectPath": path, "project": project, "job": job, "usedFallback": boolean],
                                required: ["projectPath", "project", "job", "usedFallback"]), permission: "rendering")
        ]
    }()

    static func valid(_ value: Any, schema: Object) -> Bool {
        switch schema["type"] as? String {
        case "object":
            guard let dictionary = value as? Object else { return false }
            let fields = schema["properties"] as? [String: Object] ?? [:]
            if let required = schema["required"] as? [String], !required.allSatisfy({ dictionary[$0] != nil }) { return false }
            return dictionary.allSatisfy { key, value in
                fields[key].map { valid(value, schema: $0) } ?? (schema["additionalProperties"] as? Bool != false)
            }
        case "array":
            guard let array = value as? [Any], let items = schema["items"] as? Object,
                  array.count <= (schema["maxItems"] as? Int ?? Int.max) else { return false }
            return array.allSatisfy { valid($0, schema: items) }
        case "string":
            guard let string = value as? String, string.count >= (schema["minLength"] as? Int ?? 0),
                  string.count <= (schema["maxLength"] as? Int ?? Int.max),
                  !string.utf8.contains(0) else { return false }
            return (schema["enum"] as? [String])?.contains(string) ?? true
        case "boolean":
            return (value as? NSNumber).map { CFGetTypeID($0) == CFBooleanGetTypeID() } ?? false
        case "number", "integer":
            guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return false }
            let amount = number.doubleValue
            guard amount.isFinite, amount >= (schema["minimum"] as? Double ?? -.infinity),
                  amount <= (schema["maximum"] as? Double ?? .infinity),
                  schema["type"] as? String != "integer" || amount.rounded() == amount else { return false }
            return (schema["enum"] as? [Int])?.contains(number.intValue) ?? true
        default: return false
        }
    }

    static func run() {
        var initialized = false
        while let line = readLine(strippingNewline: true) {
            guard line.utf8.count <= maxMessage,
                  let message = (try? JSONSerialization.jsonObject(with: Data(line.utf8))) as? Object else {
                send(["jsonrpc": "2.0", "id": NSNull(), "error": ["code": -32700, "message": "Invalid JSON-RPC message"]])
                continue
            }
            let id = message["id"] ?? NSNull()
            func respond(_ result: Object) { send(["jsonrpc": "2.0", "id": id, "result": result]) }
            func error(_ code: Int, _ reason: String) { send(["jsonrpc": "2.0", "id": id, "error": ["code": code, "message": reason]]) }
            guard message["jsonrpc"] as? String == "2.0", let method = message["method"] as? String else {
                error(-32600, "Invalid request"); continue
            }
            guard message["id"] != nil else { continue }
            let params = message["params"] as? Object ?? [:]
            switch method {
            case "initialize":
                guard !initialized, let version = params["protocolVersion"] as? String else {
                    error(-32602, "Expected one initialize request with a protocol version"); continue
                }
                initialized = true
                respond(["protocolVersion": versions.contains(version) ? version : versions[0],
                         "capabilities": ["tools": ["listChanged": false]],
                         "serverInfo": ["name": "pulsecanvas", "title": "PulseCanvas Studio",
                                        "version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development"],
                         "instructions": "Open PulseCanvas Studio on this Mac and enable Settings → Agent access. Read get_app_status and get_capabilities before changing data."])
            case "ping": respond([:])
            case "tools/list" where initialized: respond(["tools": tools.map(\.schema)])
            case "tools/call" where initialized:
                guard let name = params["name"] as? String, let tool = tools.first(where: { $0.name == name }) else {
                    error(-32602, "Unknown PulseCanvas tool"); continue
                }
                let arguments = params["arguments"] ?? Object()
                guard let args = arguments as? Object, valid(args, schema: tool.input) else {
                    error(-32602, "Arguments do not match the tool input schema"); continue
                }
                let result = PulseMCPMailbox.call(name, args)
                if let failure = result["error"] as? Object {
                    respond(["isError": true, "content": [["type": "text", "text": jsonText(failure)]]])
                } else if let value = result["value"] as? Object, valid(value, schema: tool.output) {
                    respond(["structuredContent": value, "content": [["type": "text", "text": jsonText(value)]]])
                } else {
                    respond(["isError": true, "content": [["type": "text", "text": "INVALID_RESPONSE: PulseCanvas returned unexpected data."]]])
                }
            default: error(-32601, "Method not available")
            }
        }
    }

    static func jsonText(_ object: Object) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes]) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }
    private static func send(_ object: Object) {
        FileHandle.standardOutput.write(Data((jsonText(object) + "\n").utf8))
    }
}

/// Both processes are the app's executable. A per-user directory lets the sandboxed
/// build use the same local transport without network server entitlements.
enum PulseMCPMailbox {
    typealias Object = PulseMCP.Object
    static var configuredRoot: URL {
        UserDataStorage.defaultSupport.appendingPathComponent("AgentConnection", isDirectory: true)
    }
    private static let unavailable = PulseMCPError("APP_UNAVAILABLE", "Open PulseCanvas Studio on this Mac, then retry.")
    private static let lifetime: TimeInterval = 180

    static func root() throws -> URL {
        let directory = configuredRoot
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        var info = stat()
        guard lstat(directory.path, &info) == 0, info.st_uid == geteuid(),
              info.st_mode & S_IFMT == S_IFDIR, info.st_mode & 0o077 == 0 else {
            throw PulseMCPError("CONNECTION_DIRECTORY", "PulseCanvas needs a private AgentConnection directory.")
        }
        return directory
    }

    static func lock(_ root: URL) throws -> Int32 {
        let fd = Darwin.open(root.appendingPathComponent("host.lock").path, O_RDWR | O_CREAT | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard fd >= 0 else { throw unavailable }
        return fd
    }

    static func call(_ name: String, _ arguments: Object) -> Object {
        do {
            let root = try root()
            let fd = try lock(root)
            defer { close(fd) }
            func hostIsRunning() -> Bool {
                if flock(fd, LOCK_EX | LOCK_NB) == 0 { flock(fd, LOCK_UN); return false }
                return errno == EWOULDBLOCK
            }
            guard hostIsRunning() else {
                if name == "get_app_status" { return ["value": PulseMCPAccess.offlineStatus] }
                throw unavailable
            }
            let id = UUID().uuidString
            let request = root.appendingPathComponent(id + ".request")
            let response = root.appendingPathComponent(id + ".response")
            let deadline = Date().addingTimeInterval(lifetime)
            let message: Object = ["name": name, "arguments": arguments, "deadline": deadline.timeIntervalSince1970]
            let data = try JSONSerialization.data(withJSONObject: message)
            guard data.count <= PulseMCP.maxMessage else {
                throw PulseMCPError("INVALID_ARGUMENTS", "Tool arguments exceed the size limit.")
            }
            try data.write(to: request, options: .atomic)
            defer {
                try? FileManager.default.removeItem(at: request)
                try? FileManager.default.removeItem(at: response)
            }
            while deadline.timeIntervalSinceNow > 0 {
                if let data = try? Data(contentsOf: response), let result = try? JSONSerialization.jsonObject(with: data) as? Object {
                    return result
                }
                guard hostIsRunning() else { throw unavailable }
                Thread.sleep(forTimeInterval: 0.05)
            }
            throw PulseMCPError("CONNECTION_TIMEOUT", "PulseCanvas did not reply. Reuse the same request key when retrying an operation that writes a file.")
        } catch let error as PulseMCPError { return ["error": error.payload] }
        catch { return ["error": unavailable.payload] }
    }

    @MainActor
    final class Host {
        private var timer: Timer?
        private var fd: Int32 = -1
        private var directory: URL?
        private var inFlight = Set<UUID>()
        private var lastSweep = Date.distantPast

        func start(handler: @escaping @MainActor (String, Object) async -> Object) {
            guard timer == nil else { return }
            do {
                let directory = try root()
                let fd = try lock(directory)
                guard flock(fd, LOCK_EX | LOCK_NB) == 0 else {
                    close(fd)
                    return
                }
                self.fd = fd
                self.directory = directory
                let timer = Timer(timeInterval: 0.125, repeats: true) { [weak self] _ in
                    MainActor.assumeIsolated { self?.consume(handler) }
                }
                self.timer = timer
                RunLoop.main.add(timer, forMode: .common)
            } catch {
                NSLog("PulseCanvas could not open its local agent connection.")
            }
        }

        var isRunning: Bool { fd >= 0 }

        private func consume(_ handler: @escaping @MainActor (String, Object) async -> Object) {
            guard inFlight.count < 16, let directory,
                  let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey, .fileSizeKey], options: [.skipsHiddenFiles])
            else { return }
            let now = Date()
            let sweep = now.timeIntervalSince(lastSweep) > 60
            if sweep { lastSweep = now }
            for file in files {
                guard let id = UUID(uuidString: file.deletingPathExtension().lastPathComponent), !inFlight.contains(id),
                      let properties = try? file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .contentModificationDateKey, .fileSizeKey]),
                      properties.isRegularFile == true, properties.isSymbolicLink != true else { continue }
                if sweep, let date = properties.contentModificationDate, now.timeIntervalSince(date) > lifetime + 10 {
                    if ["request", "response"].contains(file.pathExtension) { try? FileManager.default.removeItem(at: file) }
                    continue
                }
                guard file.pathExtension == "request", inFlight.count < 16,
                      (properties.fileSize ?? Int.max) <= PulseMCP.maxMessage,
                      let data = try? Data(contentsOf: file), let message = try? JSONSerialization.jsonObject(with: data) as? Object,
                      let name = message["name"] as? String, let args = message["arguments"] as? Object,
                      let deadline = message["deadline"] as? Double,
                      deadline > now.timeIntervalSince1970, deadline <= now.timeIntervalSince1970 + lifetime
                else { continue }
                inFlight.insert(id)
                Task {
                    let result = await handler(name, args)
                    defer { inFlight.remove(id) }
                    guard Date().timeIntervalSince1970 < deadline, FileManager.default.fileExists(atPath: file.path),
                          let response = try? JSONSerialization.data(withJSONObject: result) else { return }
                    let target = file.deletingPathExtension().appendingPathExtension("response")
                    // The bridge owns its request until it has read the reply. Keep
                    // this ID claimed until the request is removed by that bridge.
                    try? response.write(to: target, options: .atomic)
                    try? FileManager.default.removeItem(at: file)
                }
            }
        }

        deinit { timer?.invalidate(); if fd >= 0 { close(fd) } }
    }
}
#endif
