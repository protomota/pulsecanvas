#if os(macOS) && DIRECT_BUILD && !STORE_BUILD
import AppKit
import SwiftUI

@MainActor
final class PulseMCPAccess: ObservableObject {
    @AppStorage("PulseCanvas.agent.enabled") var enabled = false
    @AppStorage("PulseCanvas.agent.playback") var playback = false
    @AppStorage("PulseCanvas.agent.editing") var editing = false
    @AppStorage("PulseCanvas.agent.rendering") var rendering = false
    @AppStorage("PulseCanvas.agent.inputBookmark") private var inputBookmark = Data()
    @AppStorage("PulseCanvas.agent.outputBookmark") private var outputBookmark = Data()

    @Published private(set) var lastConnection: Date?
    @Published private(set) var hostRunning = false
    let host = PulseMCPMailbox.Host()

    nonisolated static var edition: String {
        #if STORE_BUILD
        "app-store"
        #elseif LOCAL_BUILD
        "direct-local"
        #else
        "direct"
        #endif
    }
    nonisolated static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development"
    }
    nonisolated static var offlineStatus: PulseMCP.Object {
        ["running": false, "enabled": false, "edition": edition, "version": version,
         "playback": false, "editing": false, "rendering": false, "pendingExports": 0]
    }

    func host(_ service: PulseMCPService) {
        host.start { [weak self, weak service] name, arguments in
            guard let self, let service else { return ["error": PulseMCPError("APP_UNAVAILABLE", "Open PulseCanvas Studio.").payload] }
            if name == "get_app_status" || enabled { lastConnection = Date() }
            return await service.call(name, arguments)
        }
        hostRunning = host.isRunning
    }

    func permits(_ permission: String) -> Bool {
        switch permission {
        case "playback": playback
        case "editing": editing
        case "rendering": rendering
        default: false
        }
    }

    enum Folder: String { case input, output }

    func grant(_ folder: Folder, url: URL) throws {
        let options: URL.BookmarkCreationOptions = folder == .input
            ? [.withSecurityScope, .securityScopeAllowOnlyReadAccess] : [.withSecurityScope]
        let bookmark = try url.bookmarkData(options: options, includingResourceValuesForKeys: nil, relativeTo: nil)
        switch folder {
        case .input: inputBookmark = bookmark
        case .output: outputBookmark = bookmark
        }
        objectWillChange.send()
    }

    func revoke(_ folder: Folder) {
        switch folder {
        case .input: inputBookmark = Data()
        case .output: outputBookmark = Data()
        }
        objectWillChange.send()
    }

    func scope(_ folder: Folder) -> SecurityScopedAccess? {
        let data = folder == .input ? inputBookmark : outputBookmark
        guard !data.isEmpty else { return nil }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI, .withoutMounting],
                                 relativeTo: nil, bookmarkDataIsStale: &stale), !stale else { return nil }
        let access = SecurityScopedAccess(url: url)
        guard (try? access.url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { return nil }
        return access
    }

    struct AuthorizedPath {
        let url: URL
        let scope: SecurityScopedAccess
    }

    func authorize(_ path: String, in folders: [Folder], writing: Bool = false) throws -> AuthorizedPath {
        guard path.hasPrefix("/"), !path.utf8.contains(0) else {
            throw PulseMCPError("INVALID_PATH", "Use an absolute local file path.")
        }
        let url = URL(fileURLWithPath: path).standardizedFileURL
        for folder in folders {
            guard let grant = scope(folder) else { continue }
            let root = grant.url.resolvingSymlinksInPath().path
            let parent = url.deletingLastPathComponent().resolvingSymlinksInPath()
            let prefix = root == "/" ? "/" : root + "/"
            guard parent.path == root || parent.path.hasPrefix(prefix) else { continue }
            let candidate = parent.appendingPathComponent(url.lastPathComponent, isDirectory: false)
            let resolved = candidate.resolvingSymlinksInPath()
            guard resolved.path.hasPrefix(prefix), !writing || candidate.path == resolved.path else { continue }
            if writing {
                guard (try? parent.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else {
                    throw PulseMCPError("OUTPUT_UNAVAILABLE", "Choose an existing directory in the authorized output folder.")
                }
            } else if let properties = try? resolved.resourceValues(forKeys: [.isRegularFileKey, .isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey]) {
                guard properties.isRegularFile == true else {
                    throw PulseMCPError("FILE_UNAVAILABLE", "Choose an existing regular file in the authorized folder.")
                }
                if properties.isUbiquitousItem == true,
                   properties.ubiquitousItemDownloadingStatus != .current && properties.ubiquitousItemDownloadingStatus != .downloaded {
                    throw PulseMCPError("FILE_UNAVAILABLE", "Download the file locally before using it in PulseCanvas.")
                }
            } else {
                throw PulseMCPError("FILE_UNAVAILABLE", "The file could not be read. Check that it exists and is downloaded.")
            }
            return AuthorizedPath(url: writing ? candidate : resolved, scope: grant)
        }
        throw PulseMCPError("PERMISSION_REQUIRED", "Authorize the containing folder under PulseCanvas Studio → Settings → Agent access.")
    }

    static var command: String {
        Bundle.main.executableURL?.path ?? "/Applications/PulseCanvas Studio.app/Contents/MacOS/PulseCanvas"
    }

    static func saveClaudeConnection(in directory: URL) throws {
        let config = directory.appendingPathComponent(".mcp.json", isDirectory: false)
        let fileManager = FileManager.default
        let exists = fileManager.fileExists(atPath: config.path)
        let original: Data?
        var contents: PulseMCP.Object
        if exists {
            let info = try config.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])
            guard info.isRegularFile == true, info.isSymbolicLink != true, (info.fileSize ?? Int.max) <= PulseMCP.maxMessage else {
                throw PulseMCPError("INVALID_CONFIG", "Choose a project with a regular .mcp.json file smaller than 2 MB.")
            }
            let data = try Data(contentsOf: config)
            guard let object = try JSONSerialization.jsonObject(with: data) as? PulseMCP.Object else {
                throw PulseMCPError("INVALID_CONFIG", "The existing .mcp.json must contain a JSON object.")
            }
            contents = object
            original = data
        } else {
            contents = [:]
            original = nil
        }
        guard contents["mcpServers"] == nil || contents["mcpServers"] is PulseMCP.Object else {
            throw PulseMCPError("INVALID_CONFIG", "Correct the existing mcpServers object before adding PulseCanvas.")
        }
        var servers = contents["mcpServers"] as? PulseMCP.Object ?? [:]
        let entry: PulseMCP.Object = ["type": "stdio", "command": command, "args": [PulseMCP.argument]]
        if let existing = servers["pulsecanvas"] {
            guard let existing = existing as? PulseMCP.Object, existing["command"] as? String == command,
                  existing["args"] as? [String] == [PulseMCP.argument] else {
                throw PulseMCPError("CONFIG_CONFLICT", "This project already has a different pulsecanvas entry. Edit that entry explicitly.")
            }
            return
        }
        servers["pulsecanvas"] = entry
        contents["mcpServers"] = servers
        let data = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        if let original {
            guard try Data(contentsOf: config) == original else {
                throw PulseMCPError("CONFIG_CONFLICT", "The project configuration changed. Check the existing file and try again.")
            }
            try (data + Data([10])).write(to: config, options: .atomic)
        } else {
            try (data + Data([10])).write(to: config, options: .withoutOverwriting)
        }
    }
}

struct PulseMCPSettings: View {
    @ObservedObject var access: PulseMCPAccess
    @State private var client = "Claude Code"
    @State private var feedback = ""
    @State private var testing = false

    var body: some View {
        Section("Agent access") {
            Toggle("Allow local agents to connect", isOn: $access.enabled)
            VStack(alignment: .leading, spacing: 10) {
                Text(access.lastConnection.map { "Last local request: \($0.formatted())" }
                     ?? (access.hostRunning ? "Ready for a local connection" : "Connection unavailable"))
                    .foregroundStyle(.secondary)
                Toggle("Allow song loading and playback control", isOn: $access.playback)
                Toggle("Allow favorites and project edits", isOn: $access.editing)
                Toggle("Allow previews and video exports", isOn: $access.rendering)
                folderRow("Input folder", .input)
                folderRow("Project and export folder", .output)
                Picker("Client", selection: $client) {
                    Text("Claude Code").tag("Claude Code")
                    Text("Codex").tag("Codex")
                }.pickerStyle(.segmented)
                if client == "Claude Code" {
                    Button("Save project connection…") { saveProjectConnection() }
                    Text("Open Claude → Code and start a new local session in that folder. Approve the project connection and check Connectors for PulseCanvas.")
                } else {
                    Text("In Codex, open Settings → MCP servers → Add server → STDIO. Name the server pulsecanvas. Save, restart, and enter /mcp in a local chat.")
                    copyRow("Command", PulseMCPAccess.command)
                    copyRow("Argument", PulseMCP.argument)
                }
                DisclosureGroup("Advanced") {
                    Text(PulseMCP.jsonText(["mcpServers": ["pulsecanvas": ["type": "stdio", "command": PulseMCPAccess.command, "args": [PulseMCP.argument]]]]))
                        .font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                }
                Button("Test connection") { testConnection() }.disabled(testing)
                if !feedback.isEmpty { Text(feedback).textSelection(.enabled) }
            }.font(.callout).disabled(!access.enabled)
        }
    }

    private func folderRow(_ title: String, _ folder: PulseMCPAccess.Folder) -> some View {
        HStack {
            Text(title)
            Spacer()
            if let scope = access.scope(folder) {
                Text(scope.url.path).lineLimit(1).truncationMode(.middle).help(scope.url.path)
                Button("Remove") { access.revoke(folder) }
            }
            Button("Choose…") {
                let panel = folderPicker()
                panel.begin { response in
                    guard response == .OK, let url = panel.url else { return }
                    do { try access.grant(folder, url: url); feedback = "Folder authorized." }
                    catch { feedback = error.localizedDescription }
                }
            }
        }
    }

    private func copyRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Text(value).lineLimit(1).truncationMode(.middle).textSelection(.enabled)
            Spacer()
            Button("Copy \(label.lowercased())") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(value, forType: .string)
            }
        }
    }

    private func folderPicker() -> NSOpenPanel {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        return panel
    }

    private func saveProjectConnection() {
        let panel = folderPicker()
        panel.message = "Choose the folder you open in Claude Code."
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let scope = SecurityScopedAccess(url: url)
            defer { withExtendedLifetime(scope) {} }
            do {
                try PulseMCPAccess.saveClaudeConnection(in: scope.url)
                feedback = "Project connection saved in \(scope.url.lastPathComponent)/.mcp.json."
            } catch { feedback = error.localizedDescription }
        }
    }

    private func testConnection() {
        testing = true
        Task {
            let connected = await Task.detached {
                let response = PulseMCPMailbox.call("get_app_status", [:])["value"] as? PulseMCP.Object
                return response?["enabled"] as? Bool == true
            }.value
            testing = false
            feedback = connected ? "Local connection passed." : "Connection failed. Reopen PulseCanvas Studio and try again."
        }
    }
}
#endif
