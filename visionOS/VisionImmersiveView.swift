import SwiftUI
import RealityKit
import Metal

@MainActor private final class VisionImmersiveSurface {
    let texture: TextureResource
    private let lowLevel: LowLevelTexture
    private let renderer: VisualizerRenderer
    private let queue: MTLCommandQueue
    private let source: MTLTexture
    private let smoothing: MTLComputePipelineState
    private var task: Task<Void, Never>?
    private var pending = 0

    init(studio: VisionStudio, session: VisionSession) async throws {
        renderer = VisualizerRenderer(state: studio.render)
        // Initialize pipelines without keeping an unused full-size export texture alive.
        try renderer.prepareOffscreen(width: 1, height: 1)
        guard let device = renderer.offscreenDevice, let queue = device.makeCommandQueue() else { throw CocoaError(.coderInvalidValue) }
        self.queue = queue
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
            width: VisionPresentation.width, height: VisionPresentation.height, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]; descriptor.storageMode = .private
        guard let source = device.makeTexture(descriptor: descriptor),
              let function = try await device.makeLibrary(source: VisionPresentation.smoothingShader, options: nil)
                .makeFunction(name: "smoothPresentation") else { throw CocoaError(.coderInvalidValue) }
        self.source = source
        smoothing = try await device.makeComputePipelineState(function: function)
        lowLevel = try LowLevelTexture(descriptor: .init(pixelFormat: .bgra8Unorm,
            width: VisionPresentation.width, height: VisionPresentation.height,
            textureUsage: [.shaderWrite, .shaderRead]))
        texture = try await TextureResource(from: lowLevel)
        task = Task { [weak self, weak studio, weak session] in
            let clock = ContinuousClock()
            var deadline = clock.now
            while !Task.isCancelled {
                guard let self, let studio, let session else { return }
                // Never queue stale frames behind a slow shader, or block the main actor waiting for the GPU.
                if self.pending == 0, let command = self.queue.makeCommandBuffer() {
                    do {
                        let target = self.lowLevel.replace(using: command)
                        try self.renderer.encodeImmersive(into: self.source, command: command,
                            time: studio.render.playbackTime ?? 0)
                        guard let encoder = command.makeComputeCommandEncoder() else { throw CocoaError(.coderInvalidValue) }
                        encoder.setComputePipelineState(self.smoothing)
                        encoder.setTexture(self.source, index: 0); encoder.setTexture(target, index: 1)
                        var enabled: UInt32 = session.edgeSmoothing ? 1 : 0
                        encoder.setBytes(&enabled, length: MemoryLayout<UInt32>.size, index: 0)
                        let width = self.smoothing.threadExecutionWidth
                        encoder.dispatchThreads(MTLSize(width: target.width, height: target.height, depth: 1),
                            threadsPerThreadgroup: MTLSize(width: width, height: min(8, self.smoothing.maxTotalThreadsPerThreadgroup / width), depth: 1))
                        encoder.endEncoding()
                        self.pending += 1
                        command.addCompletedHandler { [weak self, weak studio] command in
                            let error = command.error?.localizedDescription
                            Task { @MainActor in
                                self?.pending -= 1
                                if let error { studio?.message = "Immersive rendering failed: \(error)" }
                            }
                        }
                        command.commit()
                    } catch { studio.message = error.localizedDescription; return }
                }
                // Encoding time counts toward the frame interval, rather than being added to it.
                deadline = max(deadline + .milliseconds(17), clock.now)
                do { try await clock.sleep(until: deadline) } catch { return }
            }
        }
    }
    func stop() { task?.cancel(); task = nil }
    deinit { task?.cancel() }
}

struct VisionImmersiveView: View {
    @ObservedObject var studio: VisionStudio
    @ObservedObject var session: VisionSession
    @State private var surface: VisionImmersiveSurface?
    @State private var controls = true
    @State private var controlsEpoch = UUID()
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissImmersiveSpace) private var dismissSpace

    var body: some View {
        RealityView { content, attachments in
            if let panel = attachments.entity(for: "controls") {
                panel.position = [0, 1.05, -1.5]; content.add(panel)
            }
            do {
                let surface = try await VisionImmersiveSurface(studio: studio, session: session)
                self.surface = surface
                var material = UnlitMaterial()
                material.color = .init(texture: .init(surface.texture))
                material.faceCulling = .none
                let screen = ModelEntity(mesh: try mesh(distance: 1, full: session.fullImmersion), materials: [material])
                screen.name = "PulseCanvas immersive screen"
                screen.position.y = studio.screenHeight
                screen.scale = SIMD3(repeating: studio.screenDistance)
                screen.components.set(InputTargetComponent())
                screen.components.set(CollisionComponent(shapes: [.generateBox(size: [20, 14, 0.1])
                    .offsetBy(translation: [0, 0, -1])]))
                content.add(screen)
            } catch { studio.message = error.localizedDescription }
        } update: { content, _ in
            if let screen = content.entities.first(where: { $0.name == "PulseCanvas immersive screen" }) as? ModelEntity {
                screen.position.y = studio.screenHeight
                screen.scale = SIMD3(repeating: studio.screenDistance)
            }
        } attachments: {
            Attachment(id: "controls") {
                if controls { VisionImmersiveControls(studio: studio, session: session, hide: { controls = false }, returnToStudio: {
                    openWindow(id: "studio"); session.studioWindowHidden = false
                    Task { await dismissSpace() }
                }).padding(20).glassBackgroundEffect()
                    .simultaneousGesture(TapGesture().onEnded { controlsEpoch = UUID() }) }
            }
        }
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { value in
            guard value.entity.name == "PulseCanvas immersive screen" else { return }
            controls.toggle(); controlsEpoch = UUID()
        })
        .task(id: controlsEpoch) {
            do { try await Task.sleep(for: .seconds(5)) } catch { return }
            if studio.transport.playing && studio.message == nil { controls = false }
        }
        .onChange(of: studio.screenDistance) { _, _ in controlsEpoch = UUID() }
        .onAppear { studio.immersiveActive = true; session.immersiveActive = true }
        .onDisappear {
            surface?.stop(); surface = nil; studio.immersiveActive = false; session.immersiveActive = false
            if session.studioWindowHidden { openWindow(id: "studio"); session.studioWindowHidden = false }
        }
    }

    private func mesh(distance: Float, full: Bool) throws -> MeshResource {
        var positions = [SIMD3<Float>](), uv = [SIMD2<Float>](), indices = [UInt32]()
        let columns = 48, rows = 12
        let arc: Float = full ? 2.8 : 1.65
        let height = full ? distance * 1.9 : distance * arc * 9 / 16
        for row in 0...rows {
            for column in 0...columns {
                let u = Float(column) / Float(columns), v = Float(row) / Float(rows)
                let angle = (u - 0.5) * arc
                positions.append(SIMD3(sin(angle) * distance, (0.5 - v) * height, -cos(angle) * distance))
                uv.append(SIMD2(u, v))
                if row < rows && column < columns {
                    let a = UInt32(row * (columns + 1) + column), next = UInt32(columns + 1)
                    indices += [a, a + next, a + 1, a + 1, a + next, a + next + 1]
                }
            }
        }
        var descriptor = MeshDescriptor(name: "Curved viewing canvas")
        descriptor.positions = .init(positions); descriptor.textureCoordinates = .init(uv)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }
}

private struct VisionImmersiveControls: View {
    @ObservedObject var studio: VisionStudio
    @ObservedObject var session: VisionSession
    @ObservedObject private var library = ProjectMPresets.shared
    let hide: () -> Void
    let returnToStudio: () -> Void
    var body: some View {
        VStack(spacing: 10) {
            if let message = studio.message { Text(message).font(.callout).foregroundStyle(.orange) }
            HStack(alignment: .center, spacing: 12) {
                VisionImmersivePlayback(studio: studio, transport: studio.transport, session: session)
                if session.radioMode {
                    Button("Next song", systemImage: "forward.end.fill") { session.radio.nextSong() }
                        .labelStyle(.iconOnly).disabled(session.radio.loading)
                        .frame(minWidth: 44, minHeight: 44)
                    separator
                    VisionImmersiveSongControls(radio: session.radio)
                } else {
                    Label(studio.project.audioTitle, systemImage: "music.note")
                        .font(.callout).lineLimit(1).frame(maxWidth: 190, alignment: .leading)
                }
                separator
                Label(NativeEffects.names[studio.selectedScene], systemImage: "sparkles")
                    .font(.callout).lineLimit(1).frame(maxWidth: 210, alignment: .leading)
                    .accessibilityIdentifier("immersiveVisualizerName")
                Button {
                    library.toggleFavorite(studio.selectedScene)
                } label: {
                    Label(library.isFavorite(studio.selectedScene) ? "Visualizer saved" : "Save visualizer",
                          systemImage: library.isFavorite(studio.selectedScene) ? "heart.fill" : "heart")
                        .frame(minHeight: 32)
                }.accessibilityLabel(library.isFavorite(studio.selectedScene) ? "Unfavorite visualizer" : "Favorite visualizer")
                    .accessibilityIdentifier("favoriteImmersiveVisualizerButton")
                Button("Random visualizer", systemImage: "shuffle") { studio.randomizeVisualizer() }
                    .labelStyle(.iconOnly).disabled(library.eligibleScenes.isEmpty)
                    .frame(minWidth: 44, minHeight: 44)
                separator
                Menu {
                    Toggle("Edge smoothing", isOn: $session.edgeSmoothing)
                } label: { Image(systemName: "slider.horizontal.3").frame(width: 32, height: 32) }
                    .accessibilityLabel("Viewing settings")
                Button("Hide controls", systemImage: "eye.slash", action: hide)
                    .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                Button("Studio", systemImage: "rectangle.on.rectangle", action: returnToStudio)
                    .frame(minHeight: 32)
                    .accessibilityLabel("Back to Studio")
                    .accessibilityIdentifier("backToStudioButton")
            }.font(.callout).lineLimit(1).fixedSize(horizontal: false, vertical: true)
        }.frame(width: session.radioMode ? 1280 : 1080)
    }

    private var separator: some View {
        Divider().frame(height: 32).padding(.horizontal, 2)
    }
}

private struct VisionImmersiveSongControls: View {
    @ObservedObject var radio: VisionRadio
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Label(radio.playingTrack?.title ?? "Radio", systemImage: "music.note")
                .font(.callout).lineLimit(1).frame(maxWidth: 190, alignment: .leading)
                .accessibilityIdentifier("immersiveSongName")
            if let track = radio.playingTrack {
                Button { radio.toggleFavoriteSong(track) } label: {
                    Label(radio.isFavoriteSong(track) ? "Song saved" : "Save song",
                          systemImage: radio.isFavoriteSong(track) ? "heart.fill" : "heart")
                        .frame(minHeight: 32)
                }.disabled(radio.loading)
                    .accessibilityLabel(radio.isFavoriteSong(track) ? "Unfavorite song" : "Favorite song")
                    .accessibilityIdentifier("favoriteImmersiveSongButton")
            }
        }
    }
}

private struct VisionImmersivePlayback: View {
    @ObservedObject var studio: VisionStudio
    @ObservedObject var transport: VisionTransport
    @ObservedObject var session: VisionSession
    var body: some View {
        if session.radioMode {
            VisionRadioPlaybackButton(radio: session.radio, transport: transport)
                .accessibilityIdentifier("immersivePlayPauseButton")
        } else {
            Button(transport.playing ? "Pause" : "Play", systemImage: transport.playing ? "pause.fill" : "play.fill") {
                studio.togglePlayback()
            }.labelStyle(.iconOnly).disabled(studio.loading)
                .accessibilityIdentifier("immersivePlayPauseButton")
        }
    }
}
