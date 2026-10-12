import AppKit
import Combine
import Foundation
@preconcurrency import Metal
import MetalKit
import simd
import SwiftUI

@MainActor
final class RenderState: ObservableObject {
    // PulseCanvas display names; numeric scene IDs keep saved projects compatible.
    // The first three modes use scalar grids, formula pools, and point profiles.
    // Other families use mesh kernels with PulseCanvas camera, UV, and artwork controls.
    static let nativeSceneNames = ["Prism Wake", "Lumen Veil", "Pulse Well", "Velvet Passage", "Bead Surge", "Facet Flow", "Glass Current", "Contour Flux", "Recursive Corridor", "Spiral Tide", "Aurora Fold", "Petal Passage", "Pearl Terrain", "Vapor Run", "Scatter Flight"] + OriginalGeometry.sceneNames + ["Octagon Vault", "Mercury Fold", "Voltage Weave", "Ink Cyclone", "Prism Rain", "Monolith Rush", "Halo Engine", "Tidal Glass", "Grid Vortex"]
    static var sceneNames: [String] { ProjectMPresets.shared.sceneNames }
    // The draw loop reads telemetry directly; publishing it would invalidate the editor every frame.
    var audioPCM: [Float] = []
    var projectMFramesPerSecond = 60
    @Published var scene: Int = 0
    @Published var speed: Float = 1
    @Published var chaos: Float = 0.5
    var audioBeatMotionTime: Double = 0
    @Published var brightness: Float = 1
    @Published var particleSize: Float = 1
    @Published var liquidDetail: Float = 0.6
    @Published var zoomSpeed: Float = 1.5
    @Published var haloCount: Int = 6
    var audioTrebleAttackTime: Double? = nil
    var audioTreblePulse: Float? = nil
    var audioMomentum: Float = 0
    var audioPulse: Float = 0
    var audioBands: [Float] = Array(repeating: 0, count: 32)
    @Published var palette: Int = 0
    @Published var fog: Float = 0.5
    @Published var rotation: Float = 0
    @Published var zoom: Float = 1
    @Published var motionBlur: Float = 0
    @Published var strobeEnabled = false
    @Published var strobeSensitivity: Float = 1
    @Published var strobeStrength: Float = 1
    var playbackTime: Double? = nil
    @Published var paused = false
    @Published var errorMessage: String?
}

@MainActor
struct VisualizerView: NSViewRepresentable {
    @ObservedObject var state: RenderState
    func makeCoordinator() -> VisualizerRenderer { VisualizerRenderer(state: state) }
    func makeNSView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0.003, green: 0.003, blue: 0.012, alpha: 1)
        view.framebufferOnly = false
        view.preferredFramesPerSecond = 60
        view.delegate = context.coordinator
        context.coordinator.attach(view)
        return view
    }
    static func dismantleNSView(_ view: MTKView, coordinator: VisualizerRenderer) {
        view.isPaused = true
        view.delegate = nil
    }
    func updateNSView(_ view: MTKView, context: Context) {
        context.coordinator.state = state
    }
}

private enum ShaderFamily { case pointGrid, nebula, fractal, crystalMorph, crystalTunnel, galaxy }
private struct VisualVertex {
    var position: SIMD3<Float>
    var color: SIMD4<Float>
    var uv: SIMD2<Float>
}
private struct PointUniforms {
    var mvp: simd_float4x4
    var pointSize: Float
    var nearPlaneHeight: Float
    var padding = SIMD2<Float>(repeating: 0)
    var color: SIMD4<Float>
}
private struct NebulaUniforms {
    var mvp: simd_float4x4
    var fogDensity: Float
    var crossfade: Float
    var alpha: Float
    var textureRotation: Float
    var fogColor: SIMD3<Float>
}
private struct FractalUniforms {
    var mvp: simd_float4x4
    var fogDensity: Float
    var crossfade: Float
    var alpha: Float
    var padding: Float = 0
    var fogColor: SIMD3<Float>
    var textureRotation: Float
}
private struct SpatialUniforms {
    var resolution: SIMD2<Float>
    var time: Float
    var scene: Int32
    var rhythm: SIMD4<Float>
    var style: SIMD4<Float>
    var camera: SIMD4<Float>
    var color0: SIMD4<Float>
    var color1: SIMD4<Float>
    var color2: SIMD4<Float>
    var color3: SIMD4<Float>
    var color4: SIMD4<Float>
}
private struct NativeMorphState {
    var scene: Int
    var firstID: Int
    var secondID: Int
    var count: Float = 0
    var direction: Float = 1
}

@MainActor
final class VisualizerRenderer: NSObject, MTKViewDelegate {
    var state: RenderState
    private var projectMEngine: ProjectMEngine?
    private var projectMPipeline: MTLRenderPipelineState?
    private var projectMCommand: MTLCommandBuffer?
    private var device: MTLDevice?
    private var queue: MTLCommandQueue?
    private var library: MTLLibrary?
    private var sampler: MTLSamplerState?
    private var pipelines: [String: MTLRenderPipelineState] = [:]
    private var textures: [MTLTexture] = []
    private var zoomTexture: MTLTexture?
    private var zoomPipeline: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    private var time: Float = 0
    private var lastTime: CFTimeInterval = 0
    private var sourceClock: Double = 0
    private var lastError: String?
    private var nativeShapeCache: [Int: [SIMD3<Float>]] = [:]
    private var nativeMorph: NativeMorphState?
    private var timelineTime: Double?
    private var offscreenTarget: MTLTexture?
    private var strobeDetector = StrobeDetector()
    private var depthTexture: MTLTexture?
    private var depthState: MTLDepthStencilState?
    private var spatialPipeline: MTLRenderPipelineState?
    private var canvasPipeline: MTLRenderPipelineState?
    private var canvasHeight: Float = 24
    private var contentBlurPipeline: MTLRenderPipelineState?
    private var blurTexture: MTLTexture?
    private var strobePipeline: MTLRenderPipelineState?
    private let nativeDefaults = SurfaceGeometry.PointDefaults()
    private let flightSlots = DispatchSemaphore(value: 3)

    init(state: RenderState) { self.state = state; super.init() }

    func attach(_ view: MTKView) {
        do {
            guard let device = view.device, let queue = device.makeCommandQueue() else {
                throw RenderError("Metal is unavailable on this Mac")
            }
            self.device = device; self.queue = queue
            let candidates = [Bundle.module.url(forResource: "VisualShaders", withExtension: "metallib", subdirectory: "Resources"),
                              Bundle.module.url(forResource: "VisualShaders", withExtension: "metallib"),
                              URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".build/visual-shaders/VisualShaders.metallib")]
            guard let url = candidates.compactMap({ $0 }).first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
                throw RenderError("Visual shader library is missing. Run scripts/build-shaders.sh before building the app.")
            }
            library = try device.makeLibrary(URL: url)
            let s = MTLSamplerDescriptor(); s.minFilter = .linear; s.magFilter = .linear
            s.sAddressMode = .repeat; s.tAddressMode = .repeat
            sampler = device.makeSamplerState(descriptor: s)
            textures = [makeTexture(device: device, variant: 0), makeTexture(device: device, variant: 1), makeTexture(device: device, variant: 2)]
            for (v, f, points) in [
                ("pointGridVertexBanded", "pointGridFragment", true),
                ("galaxyJourneyVertex", "galaxyJourneyHaloFragment", true),
                ("nebulaTunnelsVertex", "nebulaTunnelsFogFragment", false),
                ("fractalTunnelsVertex", "fractalTunnelsFogFragment", false),
                ("crystalMorphVertex", "crystalMorphFragmentWithColorTint", false),
                ("crystalTunnelVertex", "crystalTunnelFragment", false)
            ] {
                pipelines[f] = try makePipeline(device: device, vertex: v, fragment: f, points: points)
            }
            pipelines["ballGalaxy"] = try makePipeline(device: device, vertex: "galaxyJourneyVertex", fragment: "galaxyJourneyCoreFragment", points: true, additive: false)
            pipelines["ballPoints"] = try makePipeline(device: device, vertex: "pointGridVertexBanded", fragment: "pointGridFragment", points: true, additive: false)
            let effectCandidates = [Bundle.module.url(forResource: "Strobe", withExtension: "metal", subdirectory: "Resources"), Bundle.module.url(forResource: "Strobe", withExtension: "metal"), URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Sources/PulseCanvas/Resources/Strobe.metal")]
            guard let effectURL = effectCandidates.compactMap({ $0 }).first(where: { FileManager.default.fileExists(atPath: $0.path) }) else { throw RenderError("White flash shader is missing") }
            let effects = try device.makeLibrary(source: String(contentsOf: effectURL, encoding: .utf8), options: nil)
            let effect = MTLRenderPipelineDescriptor()
            effect.vertexFunction = effects.makeFunction(name: "whiteFlashVertex")
            effect.fragmentFunction = effects.makeFunction(name: "whiteFlashFragment")
            effect.colorAttachments[0].pixelFormat = .bgra8Unorm
            effect.colorAttachments[0].isBlendingEnabled = true
            effect.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            effect.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            effect.colorAttachments[0].sourceAlphaBlendFactor = .one
            effect.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            strobePipeline = try device.makeRenderPipelineState(descriptor: effect)
            let projectMEffect = MTLRenderPipelineDescriptor()
            projectMEffect.vertexFunction = effects.makeFunction(name: "whiteFlashVertex")
            projectMEffect.fragmentFunction = effects.makeFunction(name: "projectMFragment")
            projectMEffect.colorAttachments[0].pixelFormat = .bgra8Unorm
            projectMPipeline = try device.makeRenderPipelineState(descriptor: projectMEffect)
            let zoomEffect = MTLRenderPipelineDescriptor()
            zoomEffect.vertexFunction = effects.makeFunction(name: "whiteFlashVertex")
            zoomEffect.fragmentFunction = effects.makeFunction(name: "forwardZoomFragment")
            zoomEffect.colorAttachments[0].pixelFormat = .bgra8Unorm
            zoomPipeline = try device.makeRenderPipelineState(descriptor: zoomEffect)
            let blurEffect = MTLRenderPipelineDescriptor()
            blurEffect.vertexFunction = effects.makeFunction(name: "whiteFlashVertex")
            blurEffect.fragmentFunction = effects.makeFunction(name: "contentBlurFragment")
            blurEffect.colorAttachments[0].pixelFormat = .bgra8Unorm
            contentBlurPipeline = try device.makeRenderPipelineState(descriptor: blurEffect)
            let canvasSource = effectURL.deletingLastPathComponent().appendingPathComponent("Canvas.metal")
            let canvasLibrary = try device.makeLibrary(source: String(contentsOf: canvasSource, encoding: .utf8), options: nil)
            let canvas = MTLRenderPipelineDescriptor()
            canvas.vertexFunction = canvasLibrary.makeFunction(name: "canvasVertex")
            canvas.fragmentFunction = canvasLibrary.makeFunction(name: "canvasFragment")
            let descriptor = MTLVertexDescriptor()
            descriptor.attributes[0].format = .float3; descriptor.attributes[0].offset = 0; descriptor.attributes[0].bufferIndex = 0
            descriptor.attributes[1].format = .float4; descriptor.attributes[1].offset = 16; descriptor.attributes[1].bufferIndex = 0
            descriptor.attributes[2].format = .float2; descriptor.attributes[2].offset = 32; descriptor.attributes[2].bufferIndex = 0
            descriptor.layouts[0].stride = MemoryLayout<VisualVertex>.stride
            canvas.vertexDescriptor = descriptor
            canvas.depthAttachmentPixelFormat = .depth32Float
            canvas.colorAttachments[0].pixelFormat = .bgra8Unorm
            canvasPipeline = try device.makeRenderPipelineState(descriptor: canvas)
            let spatialSource = effectURL.deletingLastPathComponent().appendingPathComponent("SpatialVisuals.metal")
            let spatialLibrary = try device.makeLibrary(source: String(contentsOf: spatialSource, encoding: .utf8), options: nil)
            let spatial = MTLRenderPipelineDescriptor()
            spatial.vertexFunction = spatialLibrary.makeFunction(name: "spatialVertex")
            spatial.fragmentFunction = spatialLibrary.makeFunction(name: "spatialFragment")
            spatial.colorAttachments[0].pixelFormat = .bgra8Unorm
            spatialPipeline = try device.makeRenderPipelineState(descriptor: spatial)
            let depth = MTLDepthStencilDescriptor(); depth.depthCompareFunction = .lessEqual; depth.isDepthWriteEnabled = true
            depthState = device.makeDepthStencilState(descriptor: depth)
            lastError = nil; state.errorMessage = nil
        } catch { report(error.localizedDescription) }
    }

    private func report(_ text: String) {
        if text != lastError { lastError = text; state.errorMessage = text }
    }

    private func makePipeline(device: MTLDevice, vertex: String, fragment: String, points: Bool, additive: Bool = true) throws -> MTLRenderPipelineState {
        guard let v = library?.makeFunction(name: vertex), let f = library?.makeFunction(name: fragment) else {
            throw RenderError("Missing visual shader: \(vertex) / \(fragment)")
        }
        let p = MTLRenderPipelineDescriptor(); p.label = "Visual \(fragment)"
        p.vertexFunction = v; p.fragmentFunction = f
        let vd = MTLVertexDescriptor()
        vd.attributes[0].format = .float3; vd.attributes[0].offset = 0; vd.attributes[0].bufferIndex = 0
        vd.attributes[1].format = .float4; vd.attributes[1].offset = 16; vd.attributes[1].bufferIndex = 0
        vd.attributes[2].format = .float2; vd.attributes[2].offset = 32; vd.attributes[2].bufferIndex = 0
        vd.layouts[0].stride = MemoryLayout<VisualVertex>.stride
        if !vertex.contains("BlurVertex") { p.vertexDescriptor = vd }
        p.colorAttachments[0].pixelFormat = .bgra8Unorm
        if points { p.inputPrimitiveTopology = .point }
        let c = p.colorAttachments[0]!
        c.isBlendingEnabled = !fragment.contains("Blur")
        c.rgbBlendOperation = .add; c.alphaBlendOperation = .add
        c.sourceRGBBlendFactor = .sourceAlpha; c.destinationRGBBlendFactor = points && additive ? .one : .oneMinusSourceAlpha
        c.sourceAlphaBlendFactor = .one; c.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        return try device.makeRenderPipelineState(descriptor: p)
    }

    private func family(_ scene: Int) -> ShaderFamily {
        if scene >= 15 {
            return scene == 18 || scene == 19 ? .pointGrid : .crystalMorph
        }
        switch scene {
        case 9, 10, 14: return .galaxy
        case 3, 13: return .nebula
        case 5, 7: return .crystalMorph
        case 6: return .crystalTunnel
        case 8, 11: return .fractal
        default: return .pointGrid
        }
    }

    private var nativePointScene: SurfaceGeometry.PointScene? {
        switch state.scene {
        case 0: return .prismWake
        case 1: return .lumenVeil
        case 2: return .pulseWell
        default: return nil
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { blurTexture = nil }

    func draw(in view: MTKView) {
        guard device != nil, let queue, !textures.isEmpty, let drawable = view.currentDrawable else { return }
        guard flightSlots.wait(timeout: .now()) == .success else { return }
        guard let command = queue.makeCommandBuffer() else { flightSlots.signal(); return }
        command.label = "Visual shader frame"
        let now = CACurrentMediaTime()
        let dt = lastTime == 0 ? Float(1.0 / 60.0) : Float(min(now - lastTime, 0.05))
        lastTime = now
        if !state.paused { sourceClock += Double(dt) }
        timelineTime = state.playbackTime
        if let absoluteTime = timelineTime {
            time = animationTime(at: absoluteTime)
        } else if !state.paused { time += dt * max(0, state.speed) }
        do { try encodeFrame(command: command, target: drawable.texture, preview: true); if lastError != nil {lastError = nil; state.errorMessage = nil} }
        catch { report(error.localizedDescription); flightSlots.signal(); return }
        command.present(drawable)
        let semaphore = flightSlots
        command.addCompletedHandler { [weak self] buffer in
            semaphore.signal()
            let error = buffer.error?.localizedDescription
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error { self.report("GPU render failed: \(error)") }
            }
        }
        command.commit()
    }

    /// Prepare an independent renderer for exact-size offline output. No window or drawable is required.
    func prepareOffscreen(width: Int, height: Int) throws {
        guard (1...8192).contains(width), (1...8192).contains(height) else {
            throw RenderError("Export dimensions must be between 1 and 8192 pixels")
        }
        if device == nil {
            let view = MTKView(frame: NSRect(x: 0, y: 0, width: width, height: height), device: MTLCreateSystemDefaultDevice())
            attach(view)
        }
        if let error = state.errorMessage { throw RenderError(error) }
        guard let device, let target = makeTarget(device, width, height, shared: true) else {
            throw RenderError("Could not allocate offline render target")
        }
        offscreenTarget = target
    }

    /// Returns GPU-complete, shared BGRA8 pixels at absolute soundtrack time.
    /// The target is reused; consumers must read it before requesting the next frame.
    func renderOffscreen(time absoluteTime: Double, audioBands: [Float], audioPulse: Float = 0, audioMomentum: Float = 0, audioBeatMotionTime: Double = 0, audioTreblePulse: Float? = nil, audioTrebleAttackTime: Double? = nil) throws -> MTLTexture {
        guard let target = offscreenTarget else { throw RenderError("Call prepareOffscreen(width:height:) before rendering") }
        let command = try offscreenCommand(target: target, time: absoluteTime, audioBands: audioBands, audioPulse: audioPulse, audioMomentum: audioMomentum, audioBeatMotionTime: audioBeatMotionTime, audioTreblePulse: audioTreblePulse, audioTrebleAttackTime: audioTrebleAttackTime)
        command.commit(); command.waitUntilCompleted()
        if let error = command.error { throw RenderError("Offline GPU render failed: \(error.localizedDescription)") }
        return target
    }

    var offscreenDevice: MTLDevice? { device }

    /// Render directly into the encoder's IOSurface, yielding the UI while the GPU works.
    func renderOffscreen(into target: MTLTexture, time absoluteTime: Double, audioBands: [Float], audioPulse: Float = 0, audioMomentum: Float = 0, audioBeatMotionTime: Double = 0, audioTreblePulse: Float? = nil, audioTrebleAttackTime: Double? = nil) async throws {
        let command = try offscreenCommand(target: target, time: absoluteTime, audioBands: audioBands, audioPulse: audioPulse, audioMomentum: audioMomentum, audioBeatMotionTime: audioBeatMotionTime, audioTreblePulse: audioTreblePulse, audioTrebleAttackTime: audioTrebleAttackTime)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            command.addCompletedHandler { _ in continuation.resume() }
            command.commit()
        }
        if let error = command.error { throw RenderError("Offline GPU render failed: \(error.localizedDescription)") }
    }

    private func offscreenCommand(target: MTLTexture, time absoluteTime: Double, audioBands: [Float], audioPulse: Float, audioMomentum: Float, audioBeatMotionTime: Double, audioTreblePulse: Float?, audioTrebleAttackTime: Double?) throws -> MTLCommandBuffer {
        guard absoluteTime.isFinite, absoluteTime >= 0 else { throw RenderError("Invalid export timestamp") }
        guard let queue, let command = queue.makeCommandBuffer(), target.pixelFormat == .bgra8Unorm else {
            throw RenderError("Offline renderer is unavailable or the frame format is invalid")
        }
        timelineTime = absoluteTime
        state.audioBeatMotionTime = audioBeatMotionTime.isFinite ? max(0, audioBeatMotionTime) : 0
        time = animationTime(at: absoluteTime)
        state.audioTrebleAttackTime = audioTrebleAttackTime
        state.audioTreblePulse = audioTreblePulse
        state.audioMomentum = audioMomentum.isFinite ? min(1, max(0, audioMomentum)) : 0
        state.audioPulse = audioPulse.isFinite ? min(1, max(0, audioPulse)) : 0
        state.audioBands = audioBands.map { $0.isFinite ? max(0, min(1, $0)) : 0 }
        try encodeFrame(command: command, target: target)
        if lastError != nil {lastError = nil; state.errorMessage = nil}
        return command
    }

    private var chaosAmount: Float { state.chaos.isFinite ? min(1, max(0, state.chaos)) : 0.5 }
    private var chaosDrive: Float { min(1, max(0, state.audioMomentum)) * chaosAmount * 2 }
    // Keep source analysis intact for playback/export. Scale every visual
    // consumer here so zero Chaos is pure procedural motion in every family.
    private var visualPulse: Float {
        (state.audioPulse.isFinite ? min(1, max(0, state.audioPulse)) : 0) * chaosAmount
    }
    private var visualBands: [Float] {
        state.audioBands.map { ($0.isFinite ? min(1, max(0, $0)) : 0) * chaosAmount }
    }

    private func animationTime(at sourceTime: Double) -> Float {
        // Integrating the source beat envelope accelerates smoothly without a
        // changing time multiplier that would rewind or jump on every attack.
        let motion = state.audioBeatMotionTime.isFinite ? max(0, state.audioBeatMotionTime) : 0
        return Float(sourceTime + motion * Double(chaosAmount) * 3) * max(0, state.speed)
    }

    private func encodeFrame(command: MTLCommandBuffer, target: MTLTexture, preview: Bool = false) throws {
        guard let d = device else { throw RenderError("Metal device is unavailable") }
        if let preset = ProjectMPresets.shared.preset(for: state.scene) {
            // The external engine writes a shared surface. Finish its previous
            // Metal consumer before reusing that surface on the OpenGL queue.
            projectMCommand?.waitUntilCompleted()
            if projectMEngine == nil { projectMEngine = try ProjectMEngine() }
            let size = preview ? ProjectMPreviewSize.dimensions(width: target.width, height: target.height) : (width: target.width, height: target.height)
            let source = try projectMEngine!.frame(preset: ProjectMPresets.shared.url(for: preset),
                texturePaths: ProjectMPresets.shared.texturePaths(for: preset), device: d,
                width: size.width, height: size.height, time: Double(time),
                sourceTime: timelineTime ?? sourceClock, pcm: state.audioPCM, chaos: chaosAmount, fps: state.projectMFramesPerSecond)
            let pass = MTLRenderPassDescriptor(); pass.colorAttachments[0].texture = target
            pass.colorAttachments[0].loadAction = .dontCare; pass.colorAttachments[0].storeAction = .store
            guard let encoder = command.makeRenderCommandEncoder(descriptor: pass), let projectMPipeline else { throw RenderError("ProjectM compositor is unavailable") }
            encoder.setRenderPipelineState(projectMPipeline); encoder.setFragmentTexture(source, index: 0)
            var style = SIMD4<Float>(state.brightness, state.zoom, state.rotation, 0)
            encoder.setFragmentBytes(&style, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
            var outputSize = SIMD2<Float>(Float(target.width), Float(target.height))
            encoder.setFragmentBytes(&outputSize, length: MemoryLayout<SIMD2<Float>>.stride, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3); encoder.endEncoding()
            try encodeEffects(command: command, target: target)
            projectMCommand = command
            return
        }
        projectMEngine = nil; projectMCommand = nil
        if [4, 10, 12, 22, 23, 24, 25, 26, 27, 28, 29, 30].contains(state.scene) {
            try encodeSpatial(command: command, target: target)
            return
        }
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = target
        let family = family(state.scene)
        let width = target.width, height = target.height
        let aspect = Float(width) / Float(max(height, 1))
        var projection = perspective(fov: Float.pi / (2.6 * max(0.55, state.zoom)), aspect: aspect, near: 0.1, far: 120)
        var mvp = projection * rotateZ(state.rotation + time * 0.08)
        if let scene = nativePointScene {
            // Native0x10040bcb4/0x10040c9a0: fixed90° rotation, uniform
            // cameraZoom*.018 scale, FOV56°, near1, far1500. UI adds rotation/zoom.
            let fov = nativeDefaults.projectionFov * .pi / 180
            projection = perspective(fov: fov, aspect: aspect, near: 1, far: 1500)
            var camera = matrix_identity_float4x4
            camera.columns.3.z = -nativeDefaults.cameraDistance
            var model = matrix_identity_float4x4
            let scale = nativeDefaults.modelScale * scene.cameraZoom * max(0.35, state.zoom)
            model.columns.0.x = scale
            model.columns.1.y = scale
            model.columns.2.z = scale
            mvp = projection * camera * rotateZ(state.rotation + .pi / 2) * model
        }
        if state.scene >= 15 {
            canvasHeight = (state.scene == 18 ? 20 : 24) / max(0.65, state.zoom)
            let distance: Float = 44
            projection = perspective(fov: 2 * atan(canvasHeight / (2 * distance)), aspect: aspect, near: 0.1, far: 180)
            var camera = matrix_identity_float4x4
            camera.columns.3 = SIMD4(sin(time * 0.33) * 0.7, cos(time * 0.27) * 0.5, -distance, 1)
            let pitch = sin(time * 0.28) * 0.22
            let yaw = sin(time * 0.21) * 0.35
            mvp = projection * camera * rotateX(pitch) * rotateY(yaw) * rotateZ(state.rotation)
        }
        let brightness = max(0, state.brightness)
        let bass = bandEnergy(0..<9)
        let (rawVertices, indices) = geometry(family: family, bass: bass, aspect: aspect)
        let strength = visualPulse * (0.2 + chaosAmount * 0.55) + chaosDrive * 0.08 + bass * 0.12
        let nativeScale = nativePointScene.map { nativeDefaults.modelScale * $0.cameraZoom * max(0.35, state.zoom) } ?? 1
        let vertices = rawVertices.map { vertex -> VisualVertex in
            guard strength > 0 else { return vertex }
            var result = vertex
            let p = vertex.position * nativeScale
            let ripple = SIMD3<Float>(sin(p.y * 0.53 + p.z * 0.31 - time * 1.3),
                                      sin(p.x * 0.47 - p.z * 0.39 + time * 1.1),
                                      sin(p.x * 0.41 + p.y * 0.37 - time * 0.9))
            // Waves bend individual points and surface patches, leaving the
            // camera framing steady instead of scaling the whole screen.
            result.position += ripple * (strength * 0.85 / nativeScale)
            return result
        }
        guard !vertices.isEmpty else { throw RenderError("Scene geometry is empty") }
        vertexBuffer = vertices.withUnsafeBytes { d.makeBuffer(bytes: $0.baseAddress!, length: $0.count, options: .storageModeShared) }
        if !indices.isEmpty { indexBuffer = indices.withUnsafeBytes { d.makeBuffer(bytes: $0.baseAddress!, length: $0.count, options: .storageModeShared) } }
        pass.colorAttachments[0].loadAction = .clear; pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0.002, green: 0.002, blue: 0.007, alpha: 1)
        let usesDepth = state.scene >= 15 && family == .crystalMorph
        if usesDepth {
            if depthTexture?.width != width || depthTexture?.height != height {
                let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: width, height: height, mipmapped: false)
                descriptor.storageMode = .private; descriptor.usage = .renderTarget
                depthTexture = d.makeTexture(descriptor: descriptor)
            }
            guard let depthTexture else { throw RenderError("Cannot allocate surface depth buffer") }
            pass.depthAttachment.texture = depthTexture; pass.depthAttachment.clearDepth = 1
            pass.depthAttachment.loadAction = .clear; pass.depthAttachment.storeAction = .dontCare
        }
        guard let encoder = command.makeRenderCommandEncoder(descriptor: pass), let vertexBuffer else { throw RenderError("Could not create Metal render encoder") }
        encoder.label = "Visual frame"
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentSamplerState(sampler, index: 0)
        encoder.setFragmentTexture(textures[0], index: 0)
        encoder.setFragmentTexture(textures[1], index: 1)
        encoder.setCullMode(.none)
        var alpha: Float = 1
        var blend: Float = (sin(time * 0.13) + 1) * 0.5
        switch family {
        case .pointGrid, .galaxy:
            let nativeScene = nativePointScene
            let pointSize = (nativeScene == nil ? (state.scene == 18 ? 0.36 : (state.scene == 19 ? 0.30 : 0.40)) : nativeDefaults.coreSize) * max(0.1, state.particleSize)
            let nearPlaneHeight = state.scene >= 15 ? Float(height) * 44 / canvasHeight : (nativeScene == nil ? Float(height) * 1.2 : (height > 1 ? Float(height) / 0.8284271 : 1448.5282))
            var u = PointUniforms(mvp: mvp, pointSize: pointSize, nearPlaneHeight: nearPlaneHeight, color: SIMD4<Float>(repeating: brightness))
            if family == .galaxy { u.color = paletteColor(time * 0.025) * SIMD4<Float>(repeating: brightness) }
            u.color.w = nativeScene == nil ? 0.82 : nativeDefaults.coreAlpha
            encoder.setVertexBytes(&u, length: MemoryLayout<PointUniforms>.stride, index: 1)
            let fragment = family == .galaxy ? "ballGalaxy" : (nativeScene == nil ? "ballPoints" : "pointGridFragment")
            encoder.setRenderPipelineState(pipelines[fragment]!)
            encoder.setFragmentTexture(textures[2], index: 0)
            if family == .pointGrid {
                let bands = (0..<32).map { paletteColor(Float($0) / 32 + time * 0.015) * SIMD4<Float>(repeating: brightness) }
                bands.withUnsafeBytes { encoder.setVertexBytes($0.baseAddress!, length: $0.count, index: 2) }
                var count: UInt32 = 32; var cluster: UInt32 = 64
                encoder.setVertexBytes(&count, length: 4, index: 3); encoder.setVertexBytes(&cluster, length: 4, index: 4)
            }
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
            if let nativeScene {
                u.pointSize = nativeScene.haloSize * max(0.1, state.particleSize)
                u.color.w = nativeDefaults.haloAlpha
                encoder.setVertexBytes(&u, length: MemoryLayout<PointUniforms>.stride, index: 1)
                encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
            }
            if family == .galaxy {
                encoder.setRenderPipelineState(pipelines["galaxyJourneyHaloFragment"]!)
                u.pointSize *= 2; u.color.w = 0.025
                encoder.setVertexBytes(&u, length: MemoryLayout<PointUniforms>.stride, index: 1)
                encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
            }
        case .nebula:
            var u = NebulaUniforms(mvp: mvp, fogDensity: max(0, state.fog) * 0.018, crossfade: blend, alpha: 1, textureRotation: state.rotation + time * 0.04, fogColor: SIMD3<Float>(0.006, 0.001, 0.02))
            encoder.setVertexBytes(&u, length: MemoryLayout<NebulaUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&u, length: MemoryLayout<NebulaUniforms>.stride, index: 0)
            encoder.setRenderPipelineState(pipelines["nebulaTunnelsFogFragment"]!)
            drawMesh(encoder, count: indices.count)
        case .fractal:
            var u = FractalUniforms(mvp: mvp, fogDensity: max(0, state.fog) * 0.02, crossfade: blend, alpha: 1, fogColor: SIMD3<Float>(0.004, 0.003, 0.01), textureRotation: state.rotation + time * 0.1)
            encoder.setVertexBytes(&u, length: MemoryLayout<FractalUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&u, length: MemoryLayout<FractalUniforms>.stride, index: 0)
            encoder.setRenderPipelineState(pipelines["fractalTunnelsFogFragment"]!)
            drawMesh(encoder, count: indices.count)
        case .crystalMorph:
            if state.scene >= 15, let canvasPipeline {
                var matrix = mvp
                encoder.setVertexBytes(&matrix, length: 64, index: 1)
                encoder.setRenderPipelineState(canvasPipeline)
                encoder.setDepthStencilState(depthState)
                var scene = UInt32(state.scene)
                encoder.setVertexBytes(&scene, length: 4, index: 2)
                drawMesh(encoder, count: indices.count)
                break
            }
            var matrix = mvp
            encoder.setVertexBytes(&matrix, length: 64, index: 1)
            encoder.setFragmentBytes(&alpha, length: 4, index: 2)
            encoder.setFragmentBytes(&blend, length: 4, index: 3)
            var tint = paletteColor(time * 0.04) * SIMD4<Float>(repeating: brightness)
            tint.w = 1
            encoder.setFragmentBytes(&tint, length: 16, index: 4)
            encoder.setRenderPipelineState(pipelines["crystalMorphFragmentWithColorTint"]!)
            drawMesh(encoder, count: indices.count)
        case .crystalTunnel:
            var matrix = mvp
            encoder.setVertexBytes(&matrix, length: 64, index: 1)
            var textureParams = SIMD2<Int32>(0, 64)
            encoder.setVertexBytes(&textureParams, length: 8, index: 3)
            encoder.setFragmentBytes(&alpha, length: 4, index: 2)
            encoder.setRenderPipelineState(pipelines["crystalTunnelFragment"]!)
            drawMesh(encoder, count: indices.count)
        }
        encoder.endEncoding()
        try encodeEffects(command: command, target: target)
    }

    private func encodeSpatial(command: MTLCommandBuffer, target: MTLTexture) throws {
        guard let spatialPipeline else { throw RenderError("Spatial visual shader is unavailable") }
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = target
        pass.colorAttachments[0].loadAction = .dontCare; pass.colorAttachments[0].storeAction = .store
        guard let encoder = command.makeRenderCommandEncoder(descriptor: pass) else { throw RenderError("Could not encode spatial visual") }
        let palette = VisualPalette(rawValue: state.palette) ?? .ultraviolet
        let colors = palette.stops.map { SIMD4<Float>($0, 1) }
        var frame = SpatialUniforms(resolution: SIMD2(Float(target.width), Float(target.height)), time: time, scene: Int32(state.scene),
            rhythm: SIMD4(visualPulse, chaosDrive, bandEnergy(0..<9), bandEnergy(24..<32)),
            style: SIMD4(state.brightness, state.particleSize, state.fog, state.zoom),
            camera: SIMD4(state.rotation, chaosAmount, state.scene == 28 ? Float(state.haloCount) : state.liquidDetail, state.zoomSpeed),
            color0: colors[0], color1: colors[1], color2: colors[2], color3: colors[3], color4: colors[4])
        encoder.setRenderPipelineState(spatialPipeline)
        encoder.setFragmentBytes(&frame, length: MemoryLayout<SpatialUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        try encodeEffects(command: command, target: target)
    }

    private func encodeEffects(command: MTLCommandBuffer, target: MTLTexture) throws {
        // Spatial corridors move their camera through the actual scene. Other
        // designs use seamless expanding layers, with no zoom pass at zero.
        let hasSpatialTravel = [4,10,12,22,24,25,26,27,28,29,30].contains(state.scene)
        let zoomSpeed = state.zoomSpeed.isFinite ? min(3, max(0, state.zoomSpeed)) : 0
        if !hasSpatialTravel && zoomSpeed > 0, let device, let zoomPipeline {
            if zoomTexture?.width != target.width || zoomTexture?.height != target.height {
                zoomTexture = makeTarget(device, target.width, target.height, shared: false)
            }
            guard let source = zoomTexture, let blit = command.makeBlitCommandEncoder() else { throw RenderError("Could not prepare forward zoom") }
            blit.copy(from: target, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0), sourceSize: MTLSize(width: target.width, height: target.height, depth: 1), to: source, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
            blit.endEncoding()
            let pass = MTLRenderPassDescriptor(); pass.colorAttachments[0].texture = target
            pass.colorAttachments[0].loadAction = .dontCare; pass.colorAttachments[0].storeAction = .store
            guard let encoder = command.makeRenderCommandEncoder(descriptor: pass) else { throw RenderError("Could not encode forward zoom") }
            encoder.setRenderPipelineState(zoomPipeline)
            encoder.setFragmentTexture(source, index: 0)
            var travel = time * zoomSpeed * 0.16
            encoder.setFragmentBytes(&travel, length: 4, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()
        }
        if state.motionBlur > 0.001 {
            guard let device, let contentBlurPipeline else { throw RenderError("Content blur is unavailable") }
            if blurTexture?.width != target.width || blurTexture?.height != target.height {
                blurTexture = makeTarget(device, target.width, target.height, shared: false)
            }
            guard let horizontal = blurTexture else { throw RenderError("Cannot allocate blur texture") }
            // Radius scales with output size, keeping preview and 4K exports consistent.
            let step = min(1, max(0, state.motionBlur)) * Float(min(target.width, target.height)) * 0.003
            for (input, output, direction) in [(target, horizontal, SIMD2<Float>(step / Float(target.width), 0)),
                                               (horizontal, target, SIMD2<Float>(0, step / Float(target.height)))] {
                let pass = MTLRenderPassDescriptor(); pass.colorAttachments[0].texture = output
                pass.colorAttachments[0].loadAction = .dontCare; pass.colorAttachments[0].storeAction = .store
                guard let encoder = command.makeRenderCommandEncoder(descriptor: pass) else { throw RenderError("Could not encode content blur") }
                encoder.setRenderPipelineState(contentBlurPipeline)
                encoder.setFragmentTexture(input, index: 0)
                var direction = direction
                encoder.setFragmentBytes(&direction, length: MemoryLayout<SIMD2<Float>>.stride, index: 0)
                encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                encoder.endEncoding()
            }
        }
        let flash: Float
        if state.strobeEnabled && chaosAmount > 0 {
            let sourceTime = timelineTime ?? sourceClock
            let onset: Float
            if let strength = state.audioTreblePulse {
                onset = strobeDetector.nextSourceFrame(time: sourceTime, attackTime: state.audioTrebleAttackTime,
                    strength: strength, sensitivity: state.strobeSensitivity)
            } else { onset = strobeDetector.nextFrame(time: sourceTime, bands: state.audioBands, sensitivity: state.strobeSensitivity) }
            flash = onset * min(1, max(0, state.strobeStrength))
        } else { strobeDetector.reset(); flash = 0 }
        if flash > 0, let strobePipeline {
            let overlay = MTLRenderPassDescriptor()
            overlay.colorAttachments[0].texture = target
            overlay.colorAttachments[0].loadAction = .load
            overlay.colorAttachments[0].storeAction = .store
            guard let e = command.makeRenderCommandEncoder(descriptor: overlay) else { throw RenderError("Could not encode white flash") }
            e.setRenderPipelineState(strobePipeline)
            var strength = flash
            e.setFragmentBytes(&strength, length: 4, index: 0)
            e.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            e.endEncoding()
        }
    }

    private func drawMesh(_ encoder: MTLRenderCommandEncoder, count: Int) {
        guard let indexBuffer else { return }
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: count, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
    }

    private func makeTarget(_ device: MTLDevice, _ width: Int, _ height: Int, shared: Bool) -> MTLTexture? {
        let t = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
        t.storageMode = shared ? .shared : .private; t.usage = [.renderTarget, .shaderRead]
        return device.makeTexture(descriptor: t)
    }

    private func bandEnergy(_ range: Range<Int>) -> Float {
        let bands = visualBands
        let values = range.compactMap { bands.indices.contains($0) ? bands[$0] : nil }
        return values.isEmpty ? 0 : min(1, max(0, values.reduce(0, +) / Float(values.count)))
    }

    private func paletteColor(_ position: Float) -> SIMD4<Float> {
        VisualPalette.color(position, palette: state.palette)
    }

    private func nativeVertices(_ points: [SIMD3<Float>], scene: SurfaceGeometry.PointScene) -> [VisualVertex] {
        let scale = nativeDefaults.modelScale * scene.cameraZoom * max(0.35, state.zoom)
        let depthLimit = nativeDefaults.cameraDistance * 0.45 / scale
        return points.map { point in
            var point = point
            if scene == .lumenVeil {
                // Some height formulas are unbounded and can carry the whole
                // field through the camera. Preserve the XY grid and smoothly
                // compress depth into the visible camera range at any zoom.
                point.z = point.z.isFinite ? tanh(point.z / depthLimit) * depthLimit : 0
            }
            return VisualVertex(position: point, color: SIMD4<Float>(repeating: 1), uv: .zero)
        }
    }

    /// The first three modes use scalar point grids and linear formula morphing.
    /// Textured families use mesh kernels with host camera and UV transforms.
    private func geometry(family: ShaderFamily, bass: Float, aspect: Float) -> ([VisualVertex], [UInt32]) {
        var vertices: [VisualVertex] = []; var indices: [UInt32] = []
        if state.scene >= 15 {
            let mesh = OriginalGeometry.make(scene: state.scene, time: time, spectrum: visualBands, intensity: 1 + chaosDrive * 0.9, palette: state.palette)
            return immersive(mesh: mesh, aspect: aspect)
        }
        if let scene = nativePointScene {
            let pool = scene.availableFormulaPool
            guard !pool.isEmpty else { return ([], []) }
            if timelineTime != nil {
                // Soundtrack seeks/export use the same deterministic pool traversal;
                // original frame morph arithmetic is preserved, random scheduling is replaced.
                let length = scene.morphLength
                let frame = max(0, Int(Double(time) * 60))
                let halfCycle = frame / length
                let firstID = pool[(halfCycle / 2) % pool.count]
                let secondID = pool[(halfCycle / 2 + 1) % pool.count]
                if nativeShapeCache[firstID] == nil { nativeShapeCache[firstID] = SurfaceGeometry.pointGrid(formulaID: firstID) }
                if nativeShapeCache[secondID] == nil { nativeShapeCache[secondID] = SurfaceGeometry.pointGrid(formulaID: secondID) }
                let count = halfCycle % 2 == 0 ? frame % length : length - frame % length
                let points = SurfaceGeometry.morph(nativeShapeCache[firstID]!, nativeShapeCache[secondID]!, count: count, length: length)
                return (nativeVertices(points, scene: scene), [])
            }
            // Native0x100408400 pingpongs one integer per renderedframe, replacing
            // the invisible endpoint with a nonrepeating random pool member.
            // Native speedMode4 resolves to110frames (0x100a94128). UI speed scales
            // advancement while retaining integer weights in the linear morph.
            let length = 110
            if nativeMorph?.scene != scene.rawValue {
                let first = pool.randomElement()!
                let second = pool.filter { $0 != first }.randomElement() ?? first
                nativeMorph = NativeMorphState(scene: scene.rawValue, firstID: first, secondID: second)
            }
            var morph = nativeMorph!
            let firstID = morph.firstID, secondID = morph.secondID
            if nativeShapeCache[firstID] == nil { nativeShapeCache[firstID] = SurfaceGeometry.pointGrid(formulaID: firstID) }
            if nativeShapeCache[secondID] == nil { nativeShapeCache[secondID] = SurfaceGeometry.pointGrid(formulaID: secondID) }
            let points = SurfaceGeometry.morph(nativeShapeCache[firstID]!, nativeShapeCache[secondID]!, count: Int(morph.count), length: length)
            if !state.paused && state.speed > 0 {
                morph.count += morph.direction * max(0, state.speed)
                if morph.count >= Float(length) {
                    morph.count = Float(length); morph.direction = -1
                    morph.firstID = pool.filter { $0 != morph.secondID }.randomElement() ?? morph.secondID
                } else if morph.count <= 0 {
                    morph.count = 0; morph.direction = 1
                    morph.secondID = pool.filter { $0 != morph.firstID }.randomElement() ?? morph.firstID
                }
                nativeMorph = morph
            }
            vertices = nativeVertices(points, scene: scene)
            return (vertices, [])
        }
        if state.scene == 14 {
            let tangent = tan(.pi / (5.2 * max(0.55, state.zoom)))
            for index in 0..<9000 {
                let seed = UInt32(index)
                let depth = 4 + (particleNoise(seed &+ 71) * 72 - time * 8).truncatingRemainder(dividingBy: 72)
                let z = depth < 4 ? depth + 72 : depth
                let x = (particleNoise(seed &* 3 &+ 19) * 2 - 1) * 60 * tangent * aspect
                let y = (particleNoise(seed &* 3 &+ 23) * 2 - 1) * 60 * tangent
                let sway = sin(time * 0.5 + Float(index % 17)) * (0.7 + bass * 1.2)
                let position = SIMD3(x + sway, y + cos(time * 0.4 + Float(index % 13)) * 0.8, -z)
                vertices.append(VisualVertex(position: position, color: paletteColor(particleNoise(seed &+ 101) + time * 0.018), uv: .zero))
            }
            vertices.sort { $0.position.z < $1.position.z }
            return (vertices, [])
        }
        if state.scene == 9 {
            let stars = MeshGeometry.galaxyStars(depthSpan: 10000, specialized: true)
            let fit = max(1, tan(.pi / (5.2 * max(0.55, state.zoom))) / tan(.pi / 5.2)) * max(1, aspect / (16.0 / 9.0))
            for arm in 0..<4 {
                let angle = Float(arm) * .pi / 2 - time * 0.18
                for (index, p) in stars.enumerated() {
                    let radius: Float = 0.008 * fit * (1 + bass * 0.18)
                    let x = p.x * radius, y = p.y * radius
                    let position = SIMD3(x * cos(angle) - y * sin(angle), x * sin(angle) + y * cos(angle), -12 + p.z * 0.00006 + sin(time * 0.3 + Float(arm)) * 1.2)
                    vertices.append(VisualVertex(position: position, color: paletteColor(Float(index) / 1050 + Float(arm) * 0.19 + time * 0.03), uv: .zero))
                }
            }
            return (vertices, [])
        }
        if family == .nebula || family == .fractal || family == .crystalMorph || family == .crystalTunnel {
            let rings = 100
            let segments = family == .crystalMorph ? 40 : 20
            let offset = Int(time * 4) % 600
            var tunnel = MeshGeometry.TunnelParameters()
            tunnel.innerRadius = family == .fractal ? 2 : 3
            tunnel.wavelength = family == .fractal ? 80 : 14
            tunnel.pathLength = state.scene == 13 ? 22000 : 80
            var morph = MeshGeometry.MorphParameters()
            morph.frequency = 0.0125 + Double(bass) * 0.002
            var crystal = MeshGeometry.CrystalTunnelParameters()
            crystal.radiusFactor = 1 + bass * 0.4
            if state.scene == 11 { tunnel.innerRadius = 3.4; tunnel.wavelength = 32; tunnel.rideRadius = 4.5 }
            let first = MeshGeometry.tunnel(ring: offset + 100, segment: 0, parameters: tunnel)
            let opposite = MeshGeometry.tunnel(ring: offset + 100, segment: segments / 2, parameters: tunnel)
            let nativeCenter = (first + opposite) * 0.5
            for ring in 0...rings {
                for segment in 0...segments {
                    let native: SIMD3<Float>
                    let position: SIMD3<Float>
                    if state.scene == 7 {
                        native = MeshGeometry.cyborg(ring: ring + offset, segment: segment % 20, profile: Int(time / 6) % 8)
                        // Native axes retain the mesh shape; host camera moves along Y.
                        position = SIMD3(native.x * 6, native.z * 6, -2 - Float(ring) * 0.6)
                    } else if family == .crystalMorph {
                        native = MeshGeometry.crystalMorph(ring: ring + offset, segment: segment % segments, parameters: morph)
                        position = SIMD3(native.x * 0.12, native.y * 0.12, -2 - Float(ring) * 1.08)
                    } else if family == .crystalTunnel {
                        native = MeshGeometry.crystalTunnel(ring: ring + 1, segment: segment % segments, parameters: crystal)
                        let radial = max(0.001, sqrt(native.x * native.x + native.y * native.y))
                        let wallRadius = (3.6 + 1.2 * sin(Float(ring) * 0.11 - time * 0.65)) * (1 + bass * 0.25)
                        position = SIMD3(native.x / radial * wallRadius, native.y / radial * wallRadius, -0.8 - Float(ring) * 0.65)
                    } else {
                        native = MeshGeometry.tunnel(ring: ring + offset + 100, segment: segment % segments, parameters: tunnel)
                        // Camera translation, z handedness, fitted scale and moving window are host reconstruction.
                        let petal: Float = state.scene == 11 ? 1 + 0.22 * sin(Float(segment) / Float(segments) * .pi * 16 + time * 0.65 + Float(ring) * 0.08) : 1
                        position = SIMD3((native.x - nativeCenter.x) * 0.20 * petal, (native.y - nativeCenter.y) * 0.20 * petal, -1 - Float(ring) * 0.60)
                    }
                    var color = paletteColor(Float(segment) / Float(segments) + Float(ring) * 0.017 + time * 0.02)
                    color *= SIMD4<Float>(repeating: max(0, state.brightness)); color.w = 1
                    vertices.append(VisualVertex(position: position, color: color, uv: SIMD2(Float(segment) / Float(segments) * 4, Float(ring) * 0.22 - time * 0.88)))
                }
            }
            appendIndices(rings: rings, segments: segments, into: &indices)
            return (vertices, indices)
        }
        return (vertices, indices)
    }

    private func immersive(mesh: OriginalGeometry.Mesh, aspect: Float) -> ([VisualVertex], [UInt32]) {
        let scale: Float
        let step: SIMD2<Float>
        switch state.scene {
        case 15: scale = 1.4; step = SIMD2(23, 23)
        case 16: scale = 1.4; step = SIMD2(22, 22)
        case 17: scale = 1.3; step = SIMD2(21, 24)
        case 18: scale = 1.5; step = SIMD2(11, 30)
        case 19: scale = 1.25; step = SIMD2(14, 24)
        case 20: scale = 1.2; step = SIMD2(25.92, 25.92)
        default: scale = 1.6; step = SIMD2(19, 23)
        }
        let c = abs(cos(state.rotation)), s = abs(sin(state.rotation))
        let halfX = canvasHeight * (aspect * c + s) * 0.80
        let halfY = canvasHeight * (aspect * s + c) * 0.80
        let columns = Int(ceil(halfX / step.x)) + 1
        let rows = Int(ceil(halfY / step.y)) + 1
        let drift = SIMD2<Float>(sin(time * 0.22) * step.x * 0.14, cos(time * 0.17) * step.y * 0.12)
        var vertices: [VisualVertex] = [], indices: [UInt32] = []
        let capacity = (rows * 2 + 1) * (columns * 2 + 1)
        let twist = state.scene == 18
        let brightness = max(0, state.brightness)
        vertices.reserveCapacity(mesh.vertices.count * capacity)
        indices.reserveCapacity(mesh.indices.count * capacity)
        for row in -rows...rows {
            for column in -columns...columns {
                let center = SIMD2(Float(column) * step.x, Float(row) * step.y) + drift
                // Skip instances completely outside the rotated viewport, while
                // retaining a full surrounding tile for camera motion and beats.
                if abs(center.x) > halfX + step.x * 0.7 || abs(center.y) > halfY + step.y * 0.7 { continue }
                let offset = UInt32(vertices.count)
                let depthOffset = sin(time * 0.45 + Float(column) * 1.7 + Float(row) * 2.1) * (twist ? 6 : 3)
                for v in mesh.vertices {
                    var position = v.position * scale
                    position.x += center.x; position.y += center.y
                    if twist { position.z *= 2.5 }
                    position.z += depthOffset
                    var color = v.color * SIMD4<Float>(repeating: brightness)
                    color.w = 1
                    vertices.append(VisualVertex(position: position, color: color, uv: v.uv))
                }
                indices.append(contentsOf: mesh.indices.map { $0 + offset })
            }
        }
        if mesh.indices.isEmpty { vertices.sort { $0.position.z < $1.position.z } }

        return (vertices, indices)
    }

    private func appendIndices(rings: Int, segments: Int, into indices: inout [UInt32]) {
        indices.reserveCapacity(rings * segments * 6)
        for ring in 0..<rings { for segment in 0..<segments {
            let a = UInt32(ring * (segments + 1) + segment), b = a + UInt32(segments + 1)
            indices.append(contentsOf: [a, b, a + 1, a + 1, b, b + 1])
        } }
    }

    /// Procedural texture assets generated for the host renderer.
    private func makeTexture(device: MTLDevice, variant: Int) -> MTLTexture {
        let size = 256
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: size, height: size, mipmapped: false)
        descriptor.storageMode = .shared; descriptor.usage = .shaderRead
        let texture = device.makeTexture(descriptor: descriptor)!
        var bytes = [UInt8](repeating: 0, count: size * size * 4)
        for y in 0..<size { for x in 0..<size {
            let u = Float(x) / Float(size - 1), v = Float(y) / Float(size - 1)
            let offset = (y * size + x) * 4
            if variant == 2 {
                let distance = simd_length(SIMD2<Float>(u - 0.5, v - 0.5)) * 2
                let nx = (u - 0.5) * 2 / 0.78, ny = (v - 0.5) * 2 / 0.78
                let sphereRadius = nx * nx + ny * ny
                let shade: Float
                let opacity: Float
                if sphereRadius <= 1 {
                    let nz = sqrt(max(0, 1 - sphereRadius))
                    let diffuse = max(0, -nx * 0.4 - ny * 0.45 + nz * 0.8)
                    let shine = pow(max(0, -nx * 0.25 - ny * 0.3 + nz * 0.92), 24)
                    shade = min(1, 0.16 + diffuse * 0.7 + shine * 0.32)
                    opacity = min(1, (1 - sqrt(sphereRadius)) * 24)
                } else { shade = 0.35; opacity = max(0, 1 - distance) * 0.12 }
                let channel = UInt8(min(255, max(0, shade * 255)))
                bytes[offset] = channel; bytes[offset + 1] = channel; bytes[offset + 2] = channel
                bytes[offset + 3] = UInt8(min(255, max(0, opacity * 255)))
            } else {
                let phase = variant == 0 ? sin(u * 26) * cos(v * 20) + sin((u + v) * 45) * 0.35 : sin(u * 60 + cos(v * 20) * 3) * sin(v * 50)
                let lines = pow(max(0, 1 - abs(phase)), 8)
                let value = 0.08 + lines * 0.92
                bytes[offset] = UInt8(value * 255); bytes[offset + 1] = UInt8(value * 255); bytes[offset + 2] = UInt8(value * 255); bytes[offset + 3] = 255
            }
        } }
        bytes.withUnsafeBytes { texture.replace(region: MTLRegionMake2D(0, 0, size, size), mipmapLevel: 0, withBytes: $0.baseAddress!, bytesPerRow: size * 4) }
        return texture
    }

    private func perspective(fov: Float, aspect: Float, near: Float, far: Float) -> simd_float4x4 {
        let y = 1 / tan(fov * 0.5), x = y / max(aspect, 0.01), z = far / (near - far)
        return simd_float4x4(columns: (SIMD4<Float>(x, 0, 0, 0), SIMD4<Float>(0, y, 0, 0), SIMD4<Float>(0, 0, z, -1), SIMD4<Float>(0, 0, z * near, 0)))
    }
    private func particleNoise(_ seed: UInt32) -> Float {
        var value = seed &+ 0x9e3779b9
        value = (value ^ (value >> 16)) &* 0x85ebca6b
        value = (value ^ (value >> 13)) &* 0xc2b2ae35
        return Float((value ^ (value >> 16)) >> 8) / 16_777_216
    }
    private func rotateX(_ angle: Float) -> simd_float4x4 {
        let c = cos(angle), s = sin(angle)
        return simd_float4x4(columns: (SIMD4(1,0,0,0), SIMD4(0,c,s,0), SIMD4(0,-s,c,0), SIMD4(0,0,0,1)))
    }
    private func rotateY(_ angle: Float) -> simd_float4x4 {
        let c = cos(angle), s = sin(angle)
        return simd_float4x4(columns: (SIMD4(c,0,-s,0), SIMD4(0,1,0,0), SIMD4(s,0,c,0), SIMD4(0,0,0,1)))
    }
    private func rotateZ(_ angle: Float) -> simd_float4x4 {
        let c = cos(angle), s = sin(angle)
        return simd_float4x4(columns: (SIMD4<Float>(c, s, 0, 0), SIMD4<Float>(-s, c, 0, 0), SIMD4<Float>(0, 0, 1, 0), SIMD4<Float>(0, 0, 0, 1)))
    }
}

private struct RenderError: LocalizedError {
    let text: String
    init(_ text: String) { self.text = text }
    var errorDescription: String? { text }
}
