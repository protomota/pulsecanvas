import SwiftUI
import RealityKit
import Metal

@MainActor private final class VisionImmersiveSurface {
    let texture: TextureResource
    private let lowLevel: LowLevelTexture
    private let renderer: VisualizerRenderer
    private let queue: MTLCommandQueue
    private var task: Task<Void, Never>?
    private var pending = 0

    init(studio: VisionStudio) async throws {
        renderer = VisualizerRenderer(state: studio.render)
        try renderer.prepareOffscreen(width: 1536, height: 864)
        guard let queue = renderer.offscreenDevice?.makeCommandQueue() else { throw CocoaError(.coderInvalidValue) }
        self.queue = queue
        lowLevel = try LowLevelTexture(descriptor: .init(pixelFormat: .bgra8Unorm, width: 1536, height: 864,
            textureUsage: [.renderTarget, .shaderRead]))
        texture = try await TextureResource(from: lowLevel)
        task = Task { [weak self, weak studio] in
            while !Task.isCancelled {
                guard let self, let studio else { return }
                if self.pending < 2, let command = self.queue.makeCommandBuffer() {
                    do {
                        let target = self.lowLevel.replace(using: command)
                        try self.renderer.encodeImmersive(into: target, command: command,
                            time: studio.render.playbackTime ?? 0)
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
                do { try await Task.sleep(for: .milliseconds(33)) } catch { return }
            }
        }
    }
    func stop() { task?.cancel(); task = nil }
    deinit { task?.cancel() }
}

struct VisionImmersiveView: View {
    @ObservedObject var studio: VisionStudio
    @State private var surface: VisionImmersiveSurface?

    var body: some View {
        RealityView { content in
            do {
                let surface = try await VisionImmersiveSurface(studio: studio)
                self.surface = surface
                var material = UnlitMaterial()
                material.color = .init(texture: .init(surface.texture))
                material.faceCulling = .none
                let screen = ModelEntity(mesh: try mesh(distance: studio.screenDistance), materials: [material])
                screen.name = "PulseCanvas immersive screen"
                screen.position.y = studio.screenHeight
                content.add(screen)
            } catch { studio.message = error.localizedDescription }
        } update: { content in
            if let screen = content.entities.first as? ModelEntity {
                screen.position.y = studio.screenHeight
                if let mesh = try? mesh(distance: studio.screenDistance) { screen.model?.mesh = mesh }
            }
        }
        .onAppear { studio.immersiveActive = true }
        .onDisappear { surface?.stop(); surface = nil; studio.immersiveActive = false }
    }

    private func mesh(distance: Float) throws -> MeshResource {
        var positions = [SIMD3<Float>](), uv = [SIMD2<Float>](), indices = [UInt32]()
        let columns = 48, rows = 12
        let arc: Float = 1.65
        let height = distance * arc * 9 / 16
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
