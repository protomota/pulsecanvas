import SwiftUI
import Combine
import UIKit
import UniformTypeIdentifiers

struct MobileRadio: View {
    @ObservedObject var editor: MobileEditor
    @ObservedObject var radio: RadioController
    @ObservedObject var audio: AudioController
    @ObservedObject private var library = ProjectMPresets.shared
    let present: () -> Void
    @State private var favorites = false
    @State private var musicFolder = false
    @State private var folderError: String?
    init(editor: MobileEditor, present: @escaping () -> Void) { self.editor = editor; radio = editor.radio; audio = editor.audio; self.present = present }
    var body: some View {
        GeometryReader { geometry in
            if UIDevice.current.userInterfaceIdiom == .pad && geometry.size.width > geometry.size.height {
                landscapeRadio
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        visualizerControls(inlinePicker: false)
                        VisualizerRandomizerPicker(fillsWidth: true)
                        VisualizerView(state: radio.visualizer).aspectRatio(16 / 9.0, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        songHeading
                        HStack {
                            stationPicker
                            Spacer()
                            nextSong
                        }.buttonStyle(MobileButton())
                        MobileRadioTransport(radio: radio, audio: audio)
                        status
                        volume
                    }.padding(16)
                }
            }
        }.onAppear { radio.loadSavedCatalogIfNeeded(refresh: !radio.isActive) }
        .fileImporter(isPresented: $musicFolder, allowedContentTypes: [.folder]) { result in
            switch result {
            case .success(let url): radio.importMusicFolder(url)
            case .failure(let error): folderError = error.localizedDescription
            }
        }
        .alert("Music folder", isPresented: Binding(get: { folderError != nil }, set: { if !$0 { folderError = nil } })) {
            Button("OK") { folderError = nil }
        } message: { Text(folderError ?? "") }
        .sheet(isPresented: $favorites) {
            NavigationStack {
                List {
                    Button("Play favorite songs", systemImage: "play.fill") { radio.playFavoriteStation(); favorites = false }.disabled(radio.favoriteSongs.isEmpty)
                    ForEach(radio.favoriteSongs) { song in
                        HStack {
                            Button { radio.playFavoriteSong(song); favorites = false } label: { VStack(alignment: .leading) { Text(song.track.title); Text(song.track.genre).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).frame(minHeight: 44) }
                            Button { radio.toggleFavoriteSong(song.track) } label: { Image(systemName: "heart.fill").frame(width: 44, height: 44) }.buttonStyle(.borderless).accessibilityLabel("Unfavorite \(song.track.title)")
                        }
                    }
                    if radio.favoriteSongs.isEmpty { Text("Save songs with the heart while listening to Radio.").foregroundStyle(.secondary) }
                }.navigationTitle("Favorite songs").toolbar { Button("Done") { favorites = false } }
            }.task { await radio.refreshFavoriteSongs() }
        }
    }
    // The preview takes only the space left after the controls. A width-driven
    // 16:9 preview exceeds an iPad's available landscape height.
    private var landscapeRadio: some View {
        VStack(spacing: 10) {
            visualizerControls(inlinePicker: true)
            GeometryReader { preview in
                VisualizerView(state: radio.visualizer)
                    .frame(width: preview.size.width, height: preview.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }.frame(minHeight: 0, maxHeight: .infinity)
                .accessibilityElement(children: .ignore).accessibilityLabel("Radio visualization")
                .accessibilityIdentifier("mobileRadioPreview")
            HStack(spacing: 12) {
                songHeading
                stationPicker.frame(maxWidth: 260)
                nextSong
            }.buttonStyle(MobileButton())
            HStack(spacing: 20) {
                MobileRadioTransport(radio: radio, audio: audio)
                volume.frame(width: 170)
            }
            status
        }.padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("mobileRadioLandscape")
    }
    private func visualizerControls(inlinePicker: Bool) -> some View {
        HStack(spacing: 12) {
            if radio.isActive {
                Button { library.toggleFavorite(radio.visualizer.scene, appearance: VisualPreset(render: radio.visualizer)) } label: {
                    Image(systemName: library.isFavorite(radio.visualizer.scene) ? "heart.fill" : "heart").frame(width: 16)
                }.accessibilityLabel("Favorite radio visualizer")
            }
            Text(radio.sceneTitle.isEmpty ? "Radio" : radio.sceneTitle).font(.headline).lineLimit(1)
            Spacer(minLength: 0)
            if inlinePicker { VisualizerRandomizerPicker(fillsWidth: true).frame(maxWidth: 320) }
            Button { radio.randomizeCurrentVisualizer() } label: { Image(systemName: "shuffle") }
                .disabled(!radio.canRandomizeVisualizer).accessibilityLabel("Random radio visualizer")
            Button(action: present) { Image(systemName: "arrow.up.left.and.arrow.down.right") }.accessibilityLabel("Present radio")
        }.buttonStyle(MobileButton())
    }
    private var songHeading: some View {
        HStack {
            if let track = radio.currentTrack, radio.canFavoriteCurrentSong {
                Button { radio.toggleFavoriteSong(track) } label: {
                    Image(systemName: radio.isFavoriteSong(track) ? "heart.fill" : "heart").frame(width: 16)
                }.accessibilityLabel("Favorite song")
            }
            Text(radio.currentTrack?.title ?? "PulseCanvas Radio").font(.headline).lineLimit(1)
                .accessibilityIdentifier("radioCurrentSongTitle")
            Spacer(minLength: 0)
            Button { favorites = true } label: { Image(systemName: "heart.text.clipboard") }.accessibilityLabel("Favorite songs")
        }.buttonStyle(MobileButton())
    }
    private var stationPicker: some View {
        Menu {
            Button("All music") { radio.selectMusicGroup("all-music", startPlayback: true) }
            Button("Favorite songs") { radio.playFavoriteStation() }
            Divider()
            if radio.hasPersonalMusic { Button("My music folder") { radio.usePersonalMusic() } }
            Button("Choose music folder…", systemImage: "folder.badge.plus") { musicFolder = true }
            Toggle("Shuffle songs", isOn: $radio.shuffle)
            ForEach(radio.isPersonalMusic ? [] : radio.stations.filter { $0.id != "all-music" }) { station in
                Button(station.title) { radio.selectMusicGroup(station.id, startPlayback: true) }
            }
        } label: {
            Label(radio.favoriteSongsOnly ? "Favorite songs" : radio.stationTitle, systemImage: "antenna.radiowaves.left.and.right")
                .lineLimit(1)
        }.disabled(radio.isCatalogLoading).accessibilityIdentifier("radioStationPicker")
    }
    private var nextSong: some View {
        Button { radio.next() } label: { Image(systemName: "forward.end.fill") }
            .disabled(!radio.isActive || radio.isLoading).accessibilityLabel("Next song")
    }
    private var volume: some View {
        HStack {
            Image(systemName: "speaker.fill")
            Slider(value: $radio.volume, in: 0...1).accessibilityLabel("Radio volume")
            Image(systemName: "speaker.wave.3.fill")
        }
    }
    private var status: some View {
        VStack(spacing: 4) {
            if radio.isCatalogLoading || radio.isLoading { ProgressView(radio.status).frame(maxWidth: .infinity) }
            else { Text(radio.status).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
            if radio.isPersonalMusic, let notice = radio.folderImportNotice { Text(notice).font(.caption).foregroundStyle(.secondary) }
            if radio.favoriteSongsOnly && radio.favoriteSongs.isEmpty {
                Text("No favorite songs yet. Choose All music, then save songs with the heart.").font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            if radio.catalogError != nil && !radio.isCatalogLoading {
                Button("Retry radio") { radio.loadSavedCatalogIfNeeded(refresh: true) }.buttonStyle(MobileButton()).accessibilityIdentifier("retryRadioButton")
            }
            if let error = radio.visualizerGroupMessage { Text(error).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
        }
    }

}

/// Observe only the small transport at playback cadence, not the Metal preview
/// and catalog. Seeking commits on release and preserves play/pause state.
private struct MobileRadioTransport: View {
    @ObservedObject var radio: RadioController
    @ObservedObject var audio: AudioController
    @State private var fraction = 0.0
    @State private var seeking = false
    var body: some View {
        HStack(spacing: 10) {
            Button { if radio.isActive { radio.togglePlayback() } else { radio.start() } } label: {
                Image(systemName: radio.isActive && radio.isPlaybackRequested ? "pause.fill" : "play.fill")
                    .frame(width: 30)
            }.buttonStyle(MobileButton(prominent: true))
                .accessibilityLabel(radio.isActive && radio.isPlaybackRequested ? "Pause" : "Play")
                .accessibilityIdentifier("radioPlaybackButton")
                .disabled(!radio.isActive && !radio.canStart)
            Text(MobileTransport.time(radio.canSeek ? (seeking ? fraction * audio.duration : audio.playbackSeconds) : 0))
                .monospacedDigit().font(.caption).frame(minWidth: 34).accessibilityIdentifier("radioElapsedTime")
            Slider(value: $fraction, in: 0...1, onEditingChanged: { editing in
                seeking = editing
                if !editing { radio.seek(fraction: fraction) }
            }).disabled(!radio.canSeek).accessibilityLabel("Radio song position")
                .accessibilityIdentifier("radioSongPosition")
            Text(MobileTransport.time(radio.canSeek ? audio.duration : 0)).monospacedDigit().font(.caption)
        }.onReceive(audio.visualizationUpdated.throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)) { _ in
            if !seeking { fraction = radio.canSeek ? audio.progress : 0 }
        }
    }
}
