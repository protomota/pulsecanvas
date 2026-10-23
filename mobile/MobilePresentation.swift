import SwiftUI

struct MobilePresentation: View {
    @ObservedObject var editor: MobileEditor
    @ObservedObject var audio: AudioController
    @ObservedObject var radio: RadioController
    @ObservedObject var render: RenderState
    @State private var showsControls = true
    init(editor: MobileEditor) { self.editor = editor; audio = editor.audio; radio = editor.radio; render = editor.currentRender }
    private var autoHide: Bool { audio.isPlaying && showsControls }
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            VisualizerView(state: render).ignoresSafeArea()
                .contentShape(Rectangle()).onTapGesture { showsControls.toggle() }
                .accessibilityElement(children: .ignore).accessibilityLabel("Full-screen visualization")
                .accessibilityValue(editor.library.sceneNames[render.scene])
                .accessibilityIdentifier("mobilePresentationPreview")
                .modifier(MobileVisualizerSwipe { editor.randomizePreviewVisualizer() })
            if showsControls {
                HStack {
                    Button("Close", systemImage: "xmark") { editor.presenting = false }
                    Spacer(minLength: 0)
                    Button { editor.randomizePreviewVisualizer() } label: { Image(systemName: "shuffle") }.accessibilityLabel("Randomize")
                    if editor.selectedTab == 1 {
                        Button { radio.next() } label: { Image(systemName: "forward.end.fill").frame(width: 22) }
                            .accessibilityLabel("Next song").accessibilityIdentifier("presentationNextSong")
                            .disabled(!radio.isActive || radio.isLoading)
                    }
                    Button { if editor.selectedTab == 1 { if radio.isActive { radio.togglePlayback() } else { radio.start() } } else { audio.playPause() } } label: { Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill").frame(width: 30) }
                        .accessibilityLabel(audio.isPlaying ? "Pause" : "Play").accessibilityIdentifier("presentationPlayback")
                }.buttonStyle(MobileButton()).padding(.horizontal, 12).padding(.vertical, 8).background(.ultraThinMaterial)
            }
        }.ignoresSafeArea(.container, edges: .bottom)
            .tint(MobileTheme.accent).statusBarHidden()
            .task(id: autoHide) {
                guard autoHide else { return }
                do { try await Task.sleep(for: .seconds(4)) } catch { return }
                if autoHide { showsControls = false }
            }
    }
}
