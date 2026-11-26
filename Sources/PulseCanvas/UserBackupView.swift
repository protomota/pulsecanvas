import SwiftUI
import UniformTypeIdentifiers

struct UserBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.zip, .json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents, data.count <= UserBackup.maximumSourceBytes + 32_000_000 else { throw UserBackup.fail(String(localized: "The backup is too large.")) }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

/// Shared native file pickers and confirmation on Mac, iPhone/iPad and Vision Pro.
struct UserBackupView: View {
    let currentProject: () throws -> Data?
    let prepare: () -> Void
    var openProject: ((Data) -> Void)? = nil
    @State private var exporting = false
    @State private var importing = false
    @State private var addingProjects = false
    @State private var busy = false
    @State private var status = ""
    @State private var document = UserBackupDocument(data: Data())
    @State private var pending: UserBackup.Archive?
    @State private var confirmation = false
    @State private var additionalProjects: [URL] = []
    @State private var leases: [SecurityScopedAccess] = []
    @State private var staged = false
    @State private var savedProjects: [URL] = []
    @State private var exportWork: URL?
    @State private var importWork: URL?
    @State private var visible = false

    private var platform: String {
        #if os(visionOS)
        "visionOS"
        #elseif os(iOS)
        "iOS"
        #else
        "macOS"
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Backup & Restore", systemImage: "externaldrive").font(.title2.bold())
            Text("Save your favorites, saved looks, projects, imported music and preferences in one ZIP file. Keep a copy outside this device.")
            Text("Your current Studio project and app-managed files are included. Add older projects saved elsewhere to include them and their soundtracks. Downloaded public Radio caches, exported videos, sign-in data and purchase records are excluded.")
                .font(.callout).foregroundStyle(.secondary)
            Button("Add project files…", systemImage: "folder.badge.plus") { addingProjects = true }
                .accessibilityIdentifier("backupAddProjects")
            if !additionalProjects.isEmpty { Text("\(additionalProjects.count) additional projects selected").font(.caption) }
            HStack(spacing: 12) {
                Button("Export Backup", systemImage: "square.and.arrow.up") { exportBackup() }
                    .buttonStyle(.borderedProminent).accessibilityIdentifier("exportUserBackup")
                Button("Import / Restore", systemImage: "square.and.arrow.down") { importing = true }
                    .buttonStyle(.bordered).accessibilityIdentifier("importUserBackup")
            }
            if busy { ProgressView("Preparing backup…") }
            if !status.isEmpty { Text(status).font(.callout).textSelection(.enabled).accessibilityIdentifier("userBackupStatus") }
            if let error = UserBackup.startupError { Text(error).foregroundStyle(.red) }
            if let openProject, !savedProjects.isEmpty {
                DisclosureGroup("Saved & restored projects") {
                    ForEach(savedProjects, id: \.self) { url in
                        Button(url.deletingPathExtension().lastPathComponent) {
                            do { prepare(); openProject(try Data(contentsOf: url)); status = String(localized: "Project opened. Close Settings to continue.") }
                            catch { status = error.localizedDescription }
                        }
                    }
                }
            }
            #if os(macOS)
            Button("Show saved projects in Finder") {
                try? FileManager.default.createDirectory(at: UserBackup.documents, withIntermediateDirectories: true)
                NSWorkspace.shared.open(UserBackup.documents)
            }
            #endif
            Text("Backups include personal music files. Store them somewhere private.")
                .font(.caption).foregroundStyle(.secondary)
            DisclosureGroup("Backup library license") {
                Text(Bundle.main.url(forResource: "ZIPFoundation-LICENSE", withExtension: "txt", subdirectory: "Legal")
                    .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? "ZIPFoundation is licensed under MIT. See the matching source package for its full notice.")
                    .font(.caption).textSelection(.enabled)
            }
        }.disabled(busy || staged)
            .onAppear { visible = true; savedProjects = UserBackup.savedProjects() }
            .onDisappear {
                visible = false
                if !busy { document = UserBackupDocument(data: Data()); pending = nil; cleanExport(); cleanImport() }
            }
            .fileExporter(isPresented: $exporting, document: document, contentType: .zip,
                          defaultFilename: "PulseCanvas-Backup-\(Date().formatted(.iso8601.year().month().day().dateSeparator(.dash)))") { result in
                switch result {
                case .success: status = String(localized: "Backup saved.")
                case .failure(let error): status = String(localized: "Backup wasn't saved: \(error.localizedDescription)")
                }
                document = UserBackupDocument(data: Data())
                cleanExport()
            }
            .fileImporter(isPresented: $addingProjects, allowedContentTypes: [.json, UTType(filenameExtension: "pulsecanvas") ?? .json, UTType(filenameExtension: "pulsevision") ?? .json], allowsMultipleSelection: true) { result in
                do {
                    for url in try result.get() where !additionalProjects.contains(url) {
                        leases.append(SecurityScopedAccess(url: url)); additionalProjects.append(url)
                    }
                } catch { status = error.localizedDescription }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.zip, .json]) { result in
                do {
                    let url = try result.get()
                    let lease = SecurityScopedAccess(url: url)
                    busy = true
                    Task {
                        defer { busy = false; withExtendedLifetime(lease) {} }
                        do {
                            cleanImport()
                            let work = try workspace(); importWork = work
                            let archive = try await Task.detached {
                                url.pathExtension.lowercased() == "zip" ? try UserBackup.readZIP(url, workspace: work.appendingPathComponent("Files")) : try UserBackup.read(url)
                            }.value
                            guard visible else { cleanImport(); return }
                            guard archive.platform == platform else { throw UserBackup.fail(String(localized: "Restore this full backup on \(archive.platform). Individual PulseCanvas projects can be opened on other platforms.")) }
                            try validateProjects(archive)
                            pending = archive; confirmation = true
                        } catch { status = String(localized: "Nothing restored: \(error.localizedDescription)"); pending = nil; cleanImport() }
                    }
                } catch { status = error.localizedDescription }
            }
            .alert("Restore this backup?", isPresented: $confirmation) {
                Button("Cancel", role: .cancel) { pending = nil; cleanImport() }
                Button("Restore", role: .destructive) { restore() }
            } message: {
                Text("This replaces the app’s saved data and preferences with the backup after you close and reopen PulseCanvas. Existing project files outside the app remain unchanged. Export a current backup first if you want to keep both.")
            }
    }

    @MainActor private func exportBackup() {
        prepare(); busy = true; status = ""
        do {
            let project = try currentProject()
            let projects = additionalProjects, sourcePlatform = platform
            Task {
                defer { busy = false }
                do {
                    cleanExport()
                    let work = try workspace(); exportWork = work
                    let zip = work.appendingPathComponent("PulseCanvas-Backup.zip")
                    let archive = try await Task.detached {
                        let archive = try UserBackup.collect(currentProject: project, additionalProjects: projects, platform: sourcePlatform)
                        try UserBackup.writeZIP(archive, to: zip)
                        return archive
                    }.value
                    guard visible else { cleanExport(); return }
                    try validateProjects(archive)
                    document = UserBackupDocument(data: try Data(contentsOf: zip, options: .alwaysMapped)); exporting = true
                } catch { status = String(localized: "Nothing exported: \(error.localizedDescription)"); cleanExport() }
            }
        } catch { busy = false; status = String(localized: "Nothing exported: \(error.localizedDescription)") }
    }

    @MainActor private func restore() {
        guard let archive = pending else { return }
        prepare(); busy = true
        Task {
            defer { busy = false; pending = nil; cleanImport() }
            do {
                let changed = try await Task.detached { try UserBackup.stageRestore(archive) }.value
                staged = changed
                status = changed ? "Backup ready to restore. Close and reopen PulseCanvas to finish. Your current session stays unchanged until then. Restored projects are in the restored Projects folder." : "This backup has already been restored. No duplicates were added."
            } catch { status = String(localized: "Nothing restored: \(error.localizedDescription)") }
        }
    }

    private func workspace() throws -> URL {
        let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PulseCanvas/BackupWork/\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
    private func cleanExport() {
        if let exportWork { try? FileManager.default.removeItem(at: exportWork) }
        exportWork = nil
    }
    private func cleanImport() {
        if let importWork { try? FileManager.default.removeItem(at: importWork) }
        importWork = nil
    }

    @MainActor private func validateProjects(_ archive: UserBackup.Archive) throws {
        let preferences = try UserBackup.preferenceValues(archive)
        for (key, value) in preferences {
            guard let data = value as? Data else { continue }
            if key.hasSuffix(".appearances") {
                let looks = try JSONDecoder().decode([String: VisualPreset].self, from: data)
                guard looks.values.allSatisfy(\.isValid) else { throw UserBackup.fail(String(localized: "Invalid favorite appearance settings.")) }
            } else if key == "PulseCanvas.studio.v1" || key == "PulseCanvas.metalStudio.v1" {
                struct Saved: Decodable { var presets: [Int: VisualPreset]; var identities: [Int: String]? }
                let saved = try JSONDecoder().decode(Saved.self, from: data)
                guard saved.presets.values.allSatisfy(\.isValid), saved.presets.keys.allSatisfy({ (0..<100_000).contains($0) }) else { throw UserBackup.fail(String(localized: "Invalid saved visualizer settings.")) }
            } else if key.hasSuffix("Pool.v1") {
                let pool = try JSONDecoder().decode(VisualizerPool.self, from: data)
                guard pool.collection.count < 100, pool.category.count < 200 else { throw UserBackup.fail(String(localized: "Invalid saved visualizer filter.")) }
            } else if key.hasSuffix("favoriteSongs.v1") {
                let songs = try JSONDecoder().decode([FavoriteRadioSong].self, from: data)
                guard songs.count <= 2_000, songs.allSatisfy(\.isValid), Set(songs.map(\.id)).count == songs.count else { throw UserBackup.fail(String(localized: "Invalid saved song favorites.")) }
            } else if key.hasSuffix("videoFormat.v1") {
                struct Format: Decodable { var aspect: String; var resolution: Int; var fps: Int }
                let format = try JSONDecoder().decode(Format.self, from: data)
                guard SocialAspect(rawValue: format.aspect) != nil, [720, 1080, 2160].contains(format.resolution),
                      SocialExportController.supportedFrameRates.contains(format.fps) else { throw UserBackup.fail(String(localized: "Invalid saved export format.")) }
            }
        }
        for file in archive.files where UserBackup.isProject(file.path) {
            #if os(visionOS)
            _ = try VisionProject.openPortable(file.data)
            #else
            let project = try JSONDecoder().decode(CreatorProject.self, from: file.data)
            guard project.version == 1, project.appearance.isValid, project.visualPresets?.values.allSatisfy(\.isValid) ?? true,
                  project.scene >= 0, project.scene < 100_000,
                  project.visualPresets?.keys.allSatisfy({ (0..<100_000).contains($0) }) ?? true,
                  StudioTimeline.valid(project.timeline ?? [], sceneCount: 100_000),
                  SocialAspect(rawValue: project.aspect) != nil, [720, 1080, 2160].contains(project.resolution),
                  SocialExportController.supportedFrameRates.contains(project.fps),
                  project.barsPerSection.map({ (1...64).contains($0) }) ?? true else { throw UserBackup.fail(String(localized: "The backup contains an invalid project.")) }
            #endif
        }
    }
}
