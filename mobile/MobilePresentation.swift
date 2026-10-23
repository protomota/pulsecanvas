import SwiftUI

struct MobilePresentation: View {
    @ObservedObject var editor: MobileEditor
    @ObservedObject var audio: AudioController
    @ObservedObject var radio: RadioController
    @ObservedObject var render: RenderState
    @ObservedObject private var library = ProjectMPresets.shared
    @State private var showsControls = true
    init(editor: MobileEditor) { self.editor = editor; audio = editor.audio; radio = editor.radio; render = editor.currentRender }
    private var autoHide: Bool { audio.isPlaying && showsControls }
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Color.black.ignoresSafeArea()
                VisualizerView(state: render).ignoresSafeArea()
                    .accessibilityElement(children: .ignore).accessibilityLabel("Full-screen visualization")
                    .accessibilityValue(editor.library.sceneNames[render.scene])
                    .accessibilityIdentifier("mobilePresentationPreview")
                    .modifier(MobileVisualizerSwipe { editor.randomizePreviewVisualizer() })
                    .modifier(VisualizerFavoriteGesture(favorite: editor.favoritePreviewVisualizer, singleTap: { showsControls.toggle() }))
                if showsControls {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Button { library.toggleFavorite(render.scene, appearance: VisualPreset(render: render)) } label: {
                                Image(systemName: library.isFavorite(render.scene) ? "heart.fill" : "heart")
                            }.accessibilityLabel("Favorite visualizer")
                                .accessibilityIdentifier("presentationVisualizerFavorite")
                                .accessibilityValue(library.isFavorite(render.scene) ? "Favorited" : "Not favorited")
                            Text(library.sceneNames[render.scene]).font(.headline).lineLimit(1)
                                .accessibilityIdentifier("presentationVisualizerTitle")
                            Spacer(minLength: 0)
                            Button { editor.presenting = false } label: { Image(systemName: "xmark") }.accessibilityLabel("Close")
                        }
                        if editor.selectedTab == 1 {
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 12) {
                                    songHeading
                                    MobileRadioStationPicker(radio: radio, identifier: "presentationStationPicker").frame(maxWidth: 200)
                                    transport
                                }
                                VStack(spacing: 8) {
                                    songHeading
                                    HStack(spacing: 8) {
                                        MobileRadioStationPicker(radio: radio, identifier: "presentationStationPicker").frame(maxWidth: 180)
                                        Spacer(minLength: 0)
                                        transport
                                    }
                                }
                            }
                        } else {
                            HStack {
                                Text(audio.title).font(.subheadline).lineLimit(1)
                                Spacer(minLength: 0)
                                transport
                            }
                        }
                    }.buttonStyle(MobileButton())
                        .padding(.leading, max(12, geometry.safeAreaInsets.leading))
                        .padding(.trailing, max(12, geometry.safeAreaInsets.trailing))
                        .padding(.top, 8).padding(.bottom, max(8, geometry.safeAreaInsets.bottom))
                        .background(.ultraThinMaterial)
                }
            }
        }
            .tint(MobileTheme.accent).statusBarHidden()
            .task(id: autoHide) {
                guard autoHide else { return }
                do { try await Task.sleep(for: .seconds(4)) } catch { return }
                if autoHide { showsControls = false }
            }
    }
    private var songHeading: some View {
        HStack(spacing: 8) {
            if let track = radio.currentTrack, radio.canFavoriteCurrentSong {
                Button { radio.toggleFavoriteSong(track) } label: {
                    Image(systemName: radio.isFavoriteSong(track) ? "heart.fill" : "heart")
                }.accessibilityLabel("Favorite song")
                    .accessibilityIdentifier("presentationSongFavorite")
                    .accessibilityValue(radio.isFavoriteSong(track) ? "Favorited" : "Not favorited")
            }
            Text(radio.currentTrack?.title ?? "PulseCanvas Radio").font(.subheadline).lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("presentationSongTitle")
        }
    }

    private var transport: some View {
        HStack(spacing: 8) {
            Button { editor.randomizePreviewVisualizer() } label: { Image(systemName: "shuffle") }.accessibilityLabel("Randomize")
            if editor.selectedTab == 1 {
                Button { radio.next() } label: { Label("Next", systemImage: "forward.end.fill") }
                    .accessibilityLabel("Next song").accessibilityIdentifier("presentationNextSong")
                    .disabled(!radio.isActive || radio.isLoading)
            }
            Button { if editor.selectedTab == 1 { if radio.isActive { radio.togglePlayback() } else { radio.start() } } else { audio.playPause() } } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill").frame(width: 30)
            }.accessibilityLabel(audio.isPlaying ? "Pause" : "Play").accessibilityIdentifier("presentationPlayback")
        }.fixedSize(horizontal: true, vertical: false)
    }

}
