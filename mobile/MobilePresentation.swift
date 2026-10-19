import SwiftUI

struct MobilePresentation: View {
    @ObservedObject var editor: MobileEditor
    @ObservedObject var audio: AudioController
    @ObservedObject var radio: RadioController
    @ObservedObject var render: RenderState
    @State private var showsControls = true
    @State private var fitAspect = false
    init(editor: MobileEditor) { self.editor = editor; audio = editor.audio; radio = editor.radio; render = editor.currentRender }
    private var autoHide: Bool { audio.isPlaying && showsControls }
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            Group {
                if fitAspect { VisualizerView(state: render).aspectRatio(editor.exporter.aspect.aspectRatio, contentMode: .fit) }
                else { VisualizerView(state: render).ignoresSafeArea() }
            }.contentShape(Rectangle()).onTapGesture { showsControls.toggle() }
            if showsControls {
                HStack {
                    Button("Close", systemImage: "xmark") { editor.presenting = false }
                    Spacer(minLength: 0)
                    Toggle("Fit", isOn: $fitAspect).toggleStyle(.button).accessibilityLabel("Fit project aspect ratio")
                    Button { if editor.selectedTab == 1 { radio.randomizeCurrentVisualizer() } else { editor.studio.randomizeScene(render) } } label: { Image(systemName: "shuffle") }.accessibilityLabel("Randomize")
                    Button { if editor.selectedTab == 1 { if radio.isActive { radio.togglePlayback() } else { radio.start() } } else { audio.playPause() } } label: { Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill").frame(width: 30) }
                        .accessibilityLabel(audio.isPlaying ? "Pause" : "Play")
                }.buttonStyle(MobileButton()).padding(12).background(.ultraThinMaterial)
            }
        }.tint(MobileTheme.accent).statusBarHidden()
            .task(id: autoHide) {
                guard autoHide else { return }
                do { try await Task.sleep(for: .seconds(4)) } catch { return }
                if autoHide { showsControls = false }
            }
    }
}
