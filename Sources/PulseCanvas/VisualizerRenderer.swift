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
    // Native designs are fragment shaders (NativeEffects), spatial raymarches
    // (SpatialVisuals.metal) or OriginalGeometry meshes and bead sprites (Canvas.metal).
    static let nativeSceneNames = NativeEffects.names
    static var sceneNames: [String] { ProjectMPresets.shared.sceneNames }
    // The draw loop reads telemetry directly; publishing it would invalidate the editor every frame.
    var audioPCM: [Float] = []
    var projectMFramesPerSecond = 60
    /// Retired native IDs always resolve to their replacement design.
    @Published var scene: Int = NativeEffects.defaultScene {
        didSet { if NativeEffects.isRetired(scene) { scene = NativeEffects.resolved(scene) } }
    }
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
    /// Per-song smoothed band levels and attack swell from SoundtrackAnalyzer.
    var audioEnvelopes = SIMD4<Float>(repeating: 0)
    var audioSwell: Float = 0
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
        context.coordinator.prewarmNativeEffects()
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

private struct VisualVertex {
    var position: SIMD3<Float>
    var color: SIMD4<Float>
    var uv: SIMD2<Float>
}
private struct CanvasPointUniforms {
    var mvp: simd_float4x4
    var pointSize: Float
    var viewportScale: Float
    var padding = SIMD2<Float>(repeating: 0)
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
    // Native designs only; the spatial shader reads the prefix above.
    var bands = SIMD4<Float>(repeating: 0)
    var motion = SIMD4<Float>(repeating: 0)
}
/// Time inputs for native designs. Audio levels arrive already smoothed per song from
/// SoundtrackAnalyzer, so every frame is a pure function of soundtrack time. Live slider
/// changes are absorbed into offsets so procedural time, zoom travel and the music clock
/// stay continuous while dragging; offline frames and seeks use none.
private struct NativeMotion {
    var scene = -1
    var lastSource: Double?
    var speed: Float = 1, zoomSpeed: Float = 0, clockScale: Float = 0
    var timeOffset: Double = 0, travelOffset: Double = 0, clockOffset: Double = 0
    var musicTravelOffset: Double = 0

    /// Returns (procedural time, zoom travel, music clock).
    mutating func advance(scene: Int, source: Double, live: Bool, speed: Float, zoomSpeed: Float, chaos: Float, beatMotion: Double, musicZoom: Bool) -> (Double, Double, Double) {
        let elapsed = lastSource.map { source - $0 } ?? -1
        let continuous = live && scene == self.scene && elapsed >= 0 && elapsed < 0.5
        let scale = chaos * speed
        if continuous {
            timeOffset += source * Double(self.speed - speed)
            let base = source * Double(speed) + timeOffset
            travelOffset += base * Double(self.zoomSpeed - zoomSpeed)
            clockOffset += beatMotion * Double(clockScale - scale)
            if musicZoom { musicTravelOffset += beatMotion * 1.6 * Double(clockScale * self.zoomSpeed - scale * zoomSpeed) }
        } else {
            timeOffset = 0; travelOffset = 0; clockOffset = 0; musicTravelOffset = 0
        }
        // Zero Chaos must not retain a phase derived from earlier music.
        if chaos == 0 { clockOffset = 0; musicTravelOffset = 0 }
        if zoomSpeed == 0 { musicTravelOffset = 0 }
        self.scene = scene; lastSource = source
        self.speed = speed; self.zoomSpeed = zoomSpeed; clockScale = scale
        let base = source * Double(speed) + timeOffset
        let musicTravel = musicZoom ? beatMotion * Double(scale * zoomSpeed) * 1.6 + musicTravelOffset : 0
        return (base, base * Double(zoomSpeed) + travelOffset + musicTravel, beatMotion * Double(scale) + clockOffset)
    }
}
@MainActor
final class VisualizerRenderer: NSObject, MTKViewDelegate {
    var state: RenderState
    #if !STORE_BUILD
    private var projectMEngine: ProjectMEngine?
    private var projectMPipeline: MTLRenderPipelineState?
    private var projectMCommand: MTLCommandBuffer?
    #endif
    private var device: MTLDevice?
    private var queue: MTLCommandQueue?
    private var zoomTexture: MTLTexture?
    private var zoomPipeline: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    private var time: Float = 0
    private var lastTime: CFTimeInterval = 0
    private var sourceClock: Double = 0
    private var lastError: String?
    private var timelineTime: Double?
    private var offscreenTarget: MTLTexture?
    private var strobeDetector = StrobeDetector()
    private var depthTexture: MTLTexture?
    private var depthState: MTLDepthStencilState?
    private var spatialPipeline: MTLRenderPipelineState?
    private var nativeLibraries: [String: MTLLibrary] = [:]
    private var nativeCompileErrors: [String: String] = [:]
    private var nativePipelines: [String: MTLRenderPipelineState] = [:]
    private var nativeMotion = NativeMotion()
    private var offscreenFrame = false
    private var canvasPipeline: MTLRenderPipelineState?
    private var pointPipeline: MTLRenderPipelineState?
    private var canvasHeight: Float = 24
    private var contentBlurPipeline: MTLRenderPipelineState?
    private var blurTexture: MTLTexture?
    private var strobePipeline: MTLRenderPipelineState?
    private let flightSlots = DispatchSemaphore(value: 3)

    init(state: RenderState) { self.state = state; super.init() }

    func attach(_ view: MTKView) {
        do {
            guard let device = view.device, let queue = device.makeCommandQueue() else {
                throw RenderError("Metal is unavailable on this Mac")
            }
            self.device = device; self.queue = queue
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
            #if !STORE_BUILD
            let projectMEffect = MTLRenderPipelineDescriptor()
            projectMEffect.vertexFunction = effects.makeFunction(name: "whiteFlashVertex")
            projectMEffect.fragmentFunction = effects.makeFunction(name: "projectMFragment")
            projectMEffect.colorAttachments[0].pixelFormat = .bgra8Unorm
            projectMPipeline = try device.makeRenderPipelineState(descriptor: projectMEffect)
            #endif
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
            let point = MTLRenderPipelineDescriptor()
            point.vertexFunction = canvasLibrary.makeFunction(name: "canvasPointVertex")
            point.fragmentFunction = canvasLibrary.makeFunction(name: "canvasPointFragment")
            point.vertexDescriptor = descriptor
            point.inputPrimitiveTopology = .point
            point.colorAttachments[0].pixelFormat = .bgra8Unorm
            let blend = point.colorAttachments[0]!
            blend.isBlendingEnabled = true
            blend.sourceRGBBlendFactor = .sourceAlpha; blend.destinationRGBBlendFactor = .oneMinusSourceAlpha
            blend.sourceAlphaBlendFactor = .one; blend.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            pointPipeline = try device.makeRenderPipelineState(descriptor: point)
            let spatialSource = effectURL.deletingLastPathComponent().appendingPathComponent("SpatialVisuals.metal")
            let spatialLibrary = try device.makeLibrary(source: String(contentsOf: spatialSource, encoding: .utf8), options: nil)
            let spatial = MTLRenderPipelineDescriptor()
            spatial.vertexFunction = spatialLibrary.makeFunction(name: "spatialVertex")
            spatial.fragmentFunction = spatialLibrary.makeFunction(name: "spatialFragment")
            spatial.colorAttachments[0].pixelFormat = .bgra8Unorm
            spatialPipeline = try device.makeRenderPipelineState(descriptor: spatial)
            try compileNativeLibraries(device: device, folder: effectURL.deletingLastPathComponent())
            nativePipelines = [:]
            let depth = MTLDepthStencilDescriptor(); depth.depthCompareFunction = .lessEqual; depth.isDepthWriteEnabled = true
            depthState = device.makeDepthStencilState(descriptor: depth)
            lastError = nil; state.errorMessage = nil
        } catch { report(error.localizedDescription) }
    }

    private func report(_ text: String) {
        if text != lastError { lastError = text; state.errorMessage = text }
    }

    /// Each native file is compiled after the shared prelude, so effects can be added
    /// by writing one function and registering it in NativeEffects. A file that fails
    /// to compile disables only its own designs, which report the compiler message.
    private func compileNativeLibraries(device: MTLDevice, folder: URL) throws {
        let prelude = try String(contentsOf: folder.appendingPathComponent("NativeCommon.metal"), encoding: .utf8)
        let options = MTLCompileOptions()
        nativeLibraries = [:]; nativeCompileErrors = [:]
        for file in NativeEffects.shaderFiles {
            do {
                let source = try String(contentsOf: folder.appendingPathComponent(file), encoding: .utf8)
                let activePrelude = file.hasPrefix("NativeExpansion") ? try String(contentsOf: folder.appendingPathComponent("NativeExpansionCommon.metal"), encoding: .utf8) : prelude
                nativeLibraries[file] = try device.makeLibrary(source: activePrelude + "\n#line 1 \"\(file)\"\n" + source, options: options)
            } catch { nativeCompileErrors[file] = "Native shader \(file) failed to compile: \(error.localizedDescription)" }
        }
    }

    private func nativeDescriptor(for effect: NativeEffect) -> MTLRenderPipelineDescriptor? {
        guard let shader = effect.shader, let file = effect.file, let library = nativeLibraries[file],
              let vertex = library.makeFunction(name: "nativeVertex"),
              let fragment = library.makeFunction(name: shader + "Fragment") else { return nil }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = effect.name
        descriptor.vertexFunction = vertex; descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        return descriptor
    }

    private func nativePipeline(for effect: NativeEffect) throws -> MTLRenderPipelineState {
        guard let shader = effect.shader else { throw RenderError("\(effect.name) is not a native Metal design") }
        if let cached = nativePipelines[shader] { return cached }
        if let file = effect.file, let error = nativeCompileErrors[file] { throw RenderError(error) }
        guard let device, let descriptor = nativeDescriptor(for: effect) else { throw RenderError("Native shader \(shader) is missing") }
        let pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        nativePipelines[shader] = pipeline
        return pipeline
    }

    /// Builds every native pipeline in the background so the first switch to a design
    /// never stalls the live view. Offline renderers build on demand instead.
    func prewarmNativeEffects() {
        guard let device else { return }
        for effect in NativeEffects.all {
            guard let shader = effect.shader, nativePipelines[shader] == nil, let descriptor = nativeDescriptor(for: effect) else { continue }
            device.makeRenderPipelineState(descriptor: descriptor) { [weak self] pipeline, _ in
                guard let pipeline else { return }
                Task { @MainActor in
                    guard let self, self.nativePipelines[shader] == nil else { return }
                    self.nativePipelines[shader] = pipeline
                }
            }
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { blurTexture = nil }

    func draw(in view: MTKView) {
        guard device != nil, let queue, canvasPipeline != nil, let drawable = view.currentDrawable else { return }
        guard flightSlots.wait(timeout: .now()) == .success else { return }
        guard let command = queue.makeCommandBuffer() else { flightSlots.signal(); return }
        command.label = "Visual shader frame"
        let now = CACurrentMediaTime()
        let dt = lastTime == 0 ? Float(1.0 / 60.0) : Float(min(now - lastTime, 0.05))
        lastTime = now
        if !state.paused { sourceClock += Double(dt) }
        timelineTime = state.playbackTime
        offscreenFrame = false
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
    func renderOffscreen(time absoluteTime: Double, audioBands: [Float], audioPulse: Float = 0, audioMomentum: Float = 0, audioBeatMotionTime: Double = 0, audioTreblePulse: Float? = nil, audioTrebleAttackTime: Double? = nil, audioEnvelopes: SIMD4<Float> = .zero, audioSwell: Float = 0) throws -> MTLTexture {
        guard let target = offscreenTarget else { throw RenderError("Call prepareOffscreen(width:height:) before rendering") }
        let command = try offscreenCommand(target: target, time: absoluteTime, audioBands: audioBands, audioPulse: audioPulse, audioMomentum: audioMomentum, audioBeatMotionTime: audioBeatMotionTime, audioTreblePulse: audioTreblePulse, audioTrebleAttackTime: audioTrebleAttackTime, audioEnvelopes: audioEnvelopes, audioSwell: audioSwell)
        command.commit(); command.waitUntilCompleted()
        if let error = command.error { throw RenderError("Offline GPU render failed: \(error.localizedDescription)") }
        return target
    }

    var offscreenDevice: MTLDevice? { device }

    /// Render directly into the encoder's IOSurface, yielding the UI while the GPU works.
    func renderOffscreen(into target: MTLTexture, time absoluteTime: Double, audioBands: [Float], audioPulse: Float = 0, audioMomentum: Float = 0, audioBeatMotionTime: Double = 0, audioTreblePulse: Float? = nil, audioTrebleAttackTime: Double? = nil, audioEnvelopes: SIMD4<Float> = .zero, audioSwell: Float = 0) async throws {
        let command = try offscreenCommand(target: target, time: absoluteTime, audioBands: audioBands, audioPulse: audioPulse, audioMomentum: audioMomentum, audioBeatMotionTime: audioBeatMotionTime, audioTreblePulse: audioTreblePulse, audioTrebleAttackTime: audioTrebleAttackTime, audioEnvelopes: audioEnvelopes, audioSwell: audioSwell)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            command.addCompletedHandler { _ in continuation.resume() }
            command.commit()
        }
        if let error = command.error { throw RenderError("Offline GPU render failed: \(error.localizedDescription)") }
    }

    private func offscreenCommand(target: MTLTexture, time absoluteTime: Double, audioBands: [Float], audioPulse: Float, audioMomentum: Float, audioBeatMotionTime: Double, audioTreblePulse: Float?, audioTrebleAttackTime: Double?, audioEnvelopes: SIMD4<Float>, audioSwell: Float) throws -> MTLCommandBuffer {
        guard absoluteTime.isFinite, absoluteTime >= 0 else { throw RenderError("Invalid export timestamp") }
        guard let queue, let command = queue.makeCommandBuffer(), target.pixelFormat == .bgra8Unorm else {
            throw RenderError("Offline renderer is unavailable or the frame format is invalid")
        }
        timelineTime = absoluteTime
        offscreenFrame = true
        state.audioBeatMotionTime = audioBeatMotionTime.isFinite ? max(0, audioBeatMotionTime) : 0
        time = animationTime(at: absoluteTime)
        state.audioTrebleAttackTime = audioTrebleAttackTime
        state.audioTreblePulse = audioTreblePulse
        state.audioMomentum = audioMomentum.isFinite ? min(1, max(0, audioMomentum)) : 0
        state.audioPulse = audioPulse.isFinite ? min(1, max(0, audioPulse)) : 0
        state.audioBands = audioBands.map { $0.isFinite ? max(0, min(1, $0)) : 0 }
        state.audioEnvelopes = simd_clamp(audioEnvelopes, .zero, SIMD4(repeating: 1))
        state.audioSwell = audioSwell.isFinite ? min(1, max(0, audioSwell)) : 0
        try encodeFrame(command: command, target: target)
        if lastError != nil {lastError = nil; state.errorMessage = nil}
        return command
    }

    private var chaosAmount: Float { state.chaos.isFinite ? min(1, max(0, state.chaos)) : 0.5 }
    private var visualPulse: Float {
        (state.audioPulse.isFinite ? min(1, max(0, state.audioPulse)) : 0) * chaosAmount
    }
    private var chaosDrive: Float { min(1, max(0, state.audioMomentum)) * chaosAmount * 2 }
    // Keep source analysis intact for playback/export. Scale every visual
    // consumer here so zero Chaos is pure procedural motion in every family.
    // Geometry that moves with the music reads the per-song smoothed levels and
    // attack swell, so motion swells instead of jumping frame to frame.
    private var visualLevels: SIMD4<Float> {
        simd_clamp(state.audioEnvelopes, .zero, SIMD4(repeating: 1)) * chaosAmount
    }
    private var visualSwell: Float {
        (state.audioSwell.isFinite ? min(1, max(0, state.audioSwell)) : 0) * chaosAmount
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
        #if !STORE_BUILD
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
        #endif
        if let effect = NativeEffects.effect(state.scene), effect.shader != nil {
            try encodeNative(effect, command: command, target: target)
            return
        }
        if Self.spatialScenes.contains(state.scene) {
            try encodeSpatial(command: command, target: target)
            return
        }
        try encodeCanvas(d, command: command, target: target)
    }

    /// Released designs drawn by SpatialVisuals.metal.
    private static let spatialScenes: Set<Int> = [4, 10, 12, 22, 23, 24, 25, 26, 27, 28, 29]

    /// Released designs 15–21: OriginalGeometry surfaces and bead sprites on a drifting canvas.
    private func encodeCanvas(_ d: MTLDevice, command: MTLCommandBuffer, target: MTLTexture) throws {
        guard let canvasPipeline, let pointPipeline else { throw RenderError("Canvas shaders are unavailable") }
        let width = target.width, height = target.height
        let aspect = Float(width) / Float(max(height, 1))
        canvasHeight = (state.scene == 18 ? 20 : 24) / max(0.65, state.zoom)
        let distance: Float = 44
        let projection = perspective(fov: 2 * atan(canvasHeight / (2 * distance)), aspect: aspect, near: 0.1, far: 180)
        var camera = matrix_identity_float4x4
        camera.columns.3 = SIMD4(sin(time * 0.33) * 0.7, cos(time * 0.27) * 0.5, -distance, 1)
        let pitch = sin(time * 0.28) * 0.22
        let yaw = sin(time * 0.21) * 0.35
        var mvp = projection * camera * rotateX(pitch) * rotateY(yaw) * rotateZ(state.rotation)
        let mesh = OriginalGeometry.make(scene: state.scene, time: time, spectrum: visualBands, intensity: 1 + chaosDrive * 0.9, palette: state.palette)
        let (rawVertices, indices) = immersive(mesh: mesh, aspect: aspect)
        let strength = visualSwell * (0.2 + chaosAmount * 0.55) + chaosDrive * 0.08 + visualLevels.x * 0.12
        let vertices = strength > 0 ? rawVertices.map { vertex -> VisualVertex in
            var result = vertex
            let p = vertex.position
            let ripple = SIMD3<Float>(sin(p.y * 0.53 + p.z * 0.31 - time * 1.3),
                                      sin(p.x * 0.47 - p.z * 0.39 + time * 1.1),
                                      sin(p.x * 0.41 + p.y * 0.37 - time * 0.9))
            // Waves bend individual points and surface patches, leaving the
            // camera framing steady instead of scaling the whole screen.
            result.position += ripple * (strength * 0.85)
            return result
        } : rawVertices
        guard !vertices.isEmpty else { throw RenderError("Scene geometry is empty") }
        vertexBuffer = vertices.withUnsafeBytes { d.makeBuffer(bytes: $0.baseAddress!, length: $0.count, options: .storageModeShared) }
        if !indices.isEmpty { indexBuffer = indices.withUnsafeBytes { d.makeBuffer(bytes: $0.baseAddress!, length: $0.count, options: .storageModeShared) } }
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = target
        pass.colorAttachments[0].loadAction = .clear; pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0.002, green: 0.002, blue: 0.007, alpha: 1)
        // Bead sprites arrive sorted far to near and blend without a depth buffer.
        let beads = indices.isEmpty
        if !beads {
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
        encoder.label = "Canvas frame"
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setCullMode(.none)
        if beads {
            var uniforms = CanvasPointUniforms(mvp: mvp, pointSize: (state.scene == 18 ? 0.36 : 0.30) * max(0.1, state.particleSize),
                                               viewportScale: Float(height) * distance / canvasHeight)
            encoder.setRenderPipelineState(pointPipeline)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<CanvasPointUniforms>.stride, index: 1)
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        } else {
            encoder.setRenderPipelineState(canvasPipeline)
            encoder.setDepthStencilState(depthState)
            encoder.setVertexBytes(&mvp, length: 64, index: 1)
            var scene = UInt32(state.scene)
            encoder.setVertexBytes(&scene, length: 4, index: 2)
            drawMesh(encoder, count: indices.count)
        }
        encoder.endEncoding()
        try encodeEffects(command: command, target: target)
    }

    private func encodeSpatial(command: MTLCommandBuffer, target: MTLTexture) throws {
        guard let pipeline = spatialPipeline else { throw RenderError("Spatial visual shader is unavailable") }
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = target
        pass.colorAttachments[0].loadAction = .dontCare; pass.colorAttachments[0].storeAction = .store
        guard let encoder = command.makeRenderCommandEncoder(descriptor: pass) else { throw RenderError("Could not encode spatial visual") }
        let palette = VisualPalette(rawValue: state.palette) ?? .ultraviolet
        let colors = palette.stops.map { SIMD4<Float>($0, 1) }
        var frame = SpatialUniforms(resolution: SIMD2(Float(target.width), Float(target.height)), time: time, scene: Int32(state.scene),
            rhythm: SIMD4(visualSwell, chaosDrive, visualLevels.x, visualLevels.w),
            style: SIMD4(state.brightness, state.particleSize, state.fog, state.zoom),
            camera: SIMD4(state.rotation, chaosAmount, state.scene == 28 ? Float(state.haloCount) : state.liquidDetail, state.zoomSpeed),
            color0: colors[0], color1: colors[1], color2: colors[2], color3: colors[3], color4: colors[4])
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&frame, length: MemoryLayout<SpatialUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        try encodeEffects(command: command, target: target)
    }

    private func encodeNative(_ effect: NativeEffect, command: MTLCommandBuffer, target: MTLTexture) throws {
        let pipeline = try nativePipeline(for: effect)
        let speed = state.speed.isFinite ? max(0, state.speed) : 1
        let zoomSpeed = state.zoomSpeed.isFinite ? min(3, max(0, state.zoomSpeed)) : 0
        let beatMotion = state.audioBeatMotionTime.isFinite ? max(0, state.audioBeatMotionTime) : 0
        let momentum = state.audioMomentum.isFinite ? min(1, max(0, state.audioMomentum)) : 0
        let (base, travel, clock) = nativeMotion.advance(scene: state.scene, source: timelineTime ?? sourceClock, live: !offscreenFrame,
            speed: speed, zoomSpeed: zoomSpeed, chaos: chaosAmount, beatMotion: beatMotion, musicZoom: effect.file?.hasPrefix("NativeExpansion") == true)
        let swell = state.audioSwell.isFinite ? min(1, max(0, state.audioSwell)) : 0
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = target
        pass.colorAttachments[0].loadAction = .dontCare; pass.colorAttachments[0].storeAction = .store
        guard let encoder = command.makeRenderCommandEncoder(descriptor: pass) else { throw RenderError("Could not encode \(effect.name)") }
        let colors = (VisualPalette(rawValue: state.palette) ?? .ultraviolet).stops.map { SIMD4<Float>($0, 1) }
        var frame = SpatialUniforms(resolution: SIMD2(Float(target.width), Float(target.height)), time: Float(base), scene: Int32(state.scene),
            rhythm: SIMD4(effect.file?.hasPrefix("NativeExpansion") == true ? visualPulse : swell * chaosAmount, chaosDrive, visualLevels.x, visualLevels.w),
            style: SIMD4(state.brightness, state.particleSize, state.fog, state.zoom),
            camera: SIMD4(state.rotation, chaosAmount, state.liquidDetail, zoomSpeed),
            color0: colors[0], color1: colors[1], color2: colors[2], color3: colors[3], color4: colors[4],
            bands: simd_clamp(state.audioEnvelopes, .zero, SIMD4(repeating: 1)) * chaosAmount,
            motion: SIMD4(Float(travel), Float(clock), Float(base), momentum * chaosAmount))
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&frame, length: MemoryLayout<SpatialUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        try encodeEffects(command: command, target: target)
    }

    private func encodeEffects(command: MTLCommandBuffer, target: MTLTexture) throws {
        // Spatial corridors move their camera through the actual scene. Other
        // designs use seamless expanding layers, with no zoom pass at zero.
        let hasSpatialTravel = NativeEffects.effect(state.scene)?.travels ?? false
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

    private func perspective(fov: Float, aspect: Float, near: Float, far: Float) -> simd_float4x4 {
        let y = 1 / tan(fov * 0.5), x = y / max(aspect, 0.01), z = far / (near - far)
        return simd_float4x4(columns: (SIMD4<Float>(x, 0, 0, 0), SIMD4<Float>(0, y, 0, 0), SIMD4<Float>(0, 0, z, -1), SIMD4<Float>(0, 0, z * near, 0)))
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
