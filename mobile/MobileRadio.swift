import SwiftUI

struct MobileRadio: View {
    @ObservedObject var editor: MobileEditor
    @ObservedObject var radio: RadioController
    @ObservedObject var audio: AudioController
    @ObservedObject private var library = ProjectMPresets.shared
    let present: () -> Void
    @State private var favorites = false
    init(editor: MobileEditor, present: @escaping () -> Void) { self.editor = editor; radio = editor.radio; audio = editor.audio; self.present = present }
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Text(radio.sceneTitle.isEmpty ? "Radio" : radio.sceneTitle).font(.headline).lineLimit(1)
                    if radio.isActive {
                        Button { library.toggleFavorite(radio.visualizer.scene, appearance: VisualPreset(render: radio.visualizer)) } label: {
                            Image(systemName: library.isFavorite(radio.visualizer.scene) ? "heart.fill" : "heart")
                        }.accessibilityLabel("Favorite radio visualizer")
                    }
                    Spacer()
                    Button { radio.randomizeCurrentVisualizer() } label: { Image(systemName: "shuffle") }.disabled(!radio.canRandomizeVisualizer).accessibilityLabel("Random radio visualizer")
                    Button(action: present) { Image(systemName: "arrow.up.left.and.arrow.down.right") }.accessibilityLabel("Present radio")
                }.buttonStyle(MobileButton())
                VisualizerRandomizerPicker(fillsWidth: true)
                VisualizerView(state: radio.visualizer).aspectRatio(16 / 9.0, contentMode: .fit).clipShape(RoundedRectangle(cornerRadius: 18))
                HStack {
                    Text(radio.currentTrack?.title ?? "PulseCanvas Radio").font(.headline).lineLimit(1)
                    if let track = radio.currentTrack {
                        Button { radio.toggleFavoriteSong(track) } label: { Image(systemName: radio.isFavoriteSong(track) ? "heart.fill" : "heart") }.accessibilityLabel("Favorite song")
                    }
                    Spacer()
                    Button { favorites = true } label: { Image(systemName: "heart.text.clipboard") }.accessibilityLabel("Favorite songs")
                }.buttonStyle(MobileButton())
                HStack {
                    Menu {
                        Button("All music") { radio.selectMusicGroup("all-music", startPlayback: true) }
                        Button("Favorite songs") { radio.playFavoriteStation() }
                        ForEach(radio.stations.filter { $0.id != "all-music" }) { station in
                            Button(station.title) { radio.selectMusicGroup(station.id, startPlayback: true) }
                        }
                    } label: { Label(radio.favoriteSongsOnly ? "Favorite songs" : radio.stationTitle, systemImage: "antenna.radiowaves.left.and.right") }
                    Spacer()
                    Button { if radio.isActive { radio.togglePlayback() } else { radio.start() } } label: {
                        Label(radio.isPlaybackRequested ? "Pause" : "Play radio", systemImage: radio.isPlaybackRequested ? "pause.fill" : "play.fill")
                    }.buttonStyle(MobileButton(prominent: true)).disabled(!radio.canStart || radio.isLoading)
                    Button { radio.next() } label: { Image(systemName: "forward.end.fill") }.disabled(!radio.isActive || radio.isLoading).accessibilityLabel("Next song")
                }.buttonStyle(MobileButton())
                if radio.isCatalogLoading || radio.isLoading { ProgressView(radio.status).frame(maxWidth: .infinity) }
                else { Text(radio.status).font(.caption).foregroundStyle(.secondary) }
                if radio.favoriteSongsOnly && radio.favoriteSongs.isEmpty { Text("No favorite songs yet. Choose All music, then save songs with the heart.").foregroundStyle(.secondary) }
                if !radio.canStart && !radio.isCatalogLoading && !radio.favoriteSongsOnly { Button("Retry radio") { radio.loadSavedCatalogIfNeeded(refresh: true) }.buttonStyle(MobileButton()) }
                HStack { Image(systemName: "speaker.fill"); Slider(value: $radio.volume, in: 0...1).accessibilityLabel("Radio volume"); Image(systemName: "speaker.wave.3.fill") }
                if let error = radio.visualizerGroupMessage { Text(error).font(.caption).foregroundStyle(.secondary) }
            }.padding(16)
        }.onAppear { radio.loadSavedCatalogIfNeeded(refresh: !radio.isActive) }
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
}
