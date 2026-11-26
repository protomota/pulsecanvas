import SwiftUI

struct CloudSyncView: View {
    @ObservedObject private var cloud = CloudSyncService.shared
    var prepare: () -> Void = {}
    var openProject: ((Data) -> Void)? = nil
    @State private var confirmEnable = false
    @State private var removing: CloudSyncChange?
    @State private var message: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Sync with iCloud", isOn: Binding(get: { cloud.enabled }, set: { value in
                if value { confirmEnable = true } else { cloud.setEnabled(false) }
            })).accessibilityIdentifier("iCloudSyncToggle")
            Text("Keep visualizer favorites, song favorites, saved looks and saved projects available on your Mac, iPhone, iPad and Apple Vision Pro using the same Apple Account.")
                .font(.callout).foregroundStyle(.secondary)
            Text("Saved projects include their soundtracks and use your iCloud storage. Each device shows the projects and visualizers it can open. Personal Radio albums, playback and volume stay on each device.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Button("Sync now", systemImage: "arrow.triangle.2.circlepath") { cloud.syncNow() }
                    .disabled(!cloud.enabled || cloud.busy).accessibilityIdentifier("iCloudSyncNow")
                if cloud.busy { ProgressView().controlSize(.small) }
            }
            Text(message ?? cloud.status).font(.callout).textSelection(.enabled).accessibilityIdentifier("iCloudSyncStatus")
            if let date = cloud.lastSync { Text("Last checked \(date.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(.secondary) }
            if cloud.enabled {
                DisclosureGroup("iCloud projects (\(cloud.projects.count))") {
                    if cloud.projects.isEmpty { Text("Save a project to add it to iCloud. Projects download when you open them.").font(.caption).foregroundStyle(.secondary) }
                    ForEach(cloud.projects, id: \.event) { change in
                        if let info = try? JSONDecoder().decode(CloudProjectInfo.self, from: change.payload) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(info.title).lineLimit(2)
                                    if change.key.hasPrefix("conflict-") { Text("Conflict copy — both edits were kept").font(.caption).foregroundStyle(.secondary) }
                                }
                                Spacer()
                                if let openProject {
                                    Button("Open") {
                                        prepare(); message = nil
                                        Task {
                                            do { openProject(try await cloud.openProject(change)) }
                                            catch { message = String(localized: "Couldn't open the project yet. \(cloud.status)") }
                                        }
                                    }.disabled(cloud.busy)
                                }
                                Button { removing = change } label: { Image(systemName: "trash") }
                                    .accessibilityLabel("Remove \(info.title) from iCloud")
                            }.padding(.vertical, 6)
                        }
                    }
                }
            }
        }.task { cloud.start() }
            .alert("Enable iCloud sync?", isPresented: $confirmEnable) {
                Button("Cancel", role: .cancel) {}
                Button("Enable iCloud") { cloud.setEnabled(true) }
            } message: {
                Text("Merge this device’s favorites and saved looks with your Apple Account, and upload saved projects with their music. Changes sync to your other PulseCanvas devices. Turning sync off keeps local data and existing iCloud copies.")
            }
            .alert("Remove this project from iCloud?", isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } })) {
                Button("Cancel", role: .cancel) { removing = nil }
                Button("Remove from iCloud", role: .destructive) {
                    if let removing { cloud.removeProject(removing) }
                    removing = nil
                }
            } message: { Text("This removes it from the synced project list on all devices. Existing local project and audio files are kept.") }
    }
}
