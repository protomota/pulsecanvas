import AppKit
import MetalKit
import Foundation

@main struct BlurSmoke {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let device = MTLCreateSystemDefaultDevice()!, queue = device.makeCommandQueue()!
        let source = try String(contentsOfFile: "Sources/PulseCanvas/Resources/Strobe.metal", encoding: .utf8)
        let library = try device.makeLibrary(source: source, options: nil)
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "whiteFlashVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "contentBlurFragment")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        let pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        let width = 512, height = 256
        func texture() -> MTLTexture {
            let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
            d.storageMode = .shared; d.usage = [.shaderRead, .renderTarget]
            return device.makeTexture(descriptor: d)!
        }
        func soften(_ bytes: [UInt8]) -> [UInt8] {
            let input = texture(), horizontal = texture(), output = texture()
            bytes.withUnsafeBytes { input.replace(region: MTLRegionMake2D(0,0,width,height), mipmapLevel: 0, withBytes: $0.baseAddress!, bytesPerRow: width * 4) }
            let command = queue.makeCommandBuffer()!
            for (src, dst, offset) in [(input, horizontal, SIMD2<Float>(1 / Float(width), 0)), (horizontal, output, SIMD2<Float>(0, 1 / Float(height)))] {
                let pass = MTLRenderPassDescriptor(); pass.colorAttachments[0].texture = dst
                pass.colorAttachments[0].loadAction = .dontCare; pass.colorAttachments[0].storeAction = .store
                let encoder = command.makeRenderCommandEncoder(descriptor: pass)!
                encoder.setRenderPipelineState(pipeline); encoder.setFragmentTexture(src, index: 0)
                var offset = offset
                encoder.setFragmentBytes(&offset, length: MemoryLayout<SIMD2<Float>>.stride, index: 0)
                encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3); encoder.endEncoding()
            }
            command.commit(); command.waitUntilCompleted(); precondition(command.status == .completed)
            var result = [UInt8](repeating: 0, count: bytes.count)
            result.withUnsafeMutableBytes { output.getBytes($0.baseAddress!, bytesPerRow: width * 4, from: MTLRegionMake2D(0,0,width,height), mipmapLevel: 0) }
            return result
        }
        var impulses = [UInt8](repeating: 0, count: width * height * 4)
        let points = [(256,128), (20,20), (491,235)]
        for (x,y) in points { for c in 0..<3 { impulses[(y * width + x) * 4 + c] = 255 } }
        let blurred = soften(impulses)
        for (x,y) in points.dropFirst() {
            for dy in -6...6 { for dx in -6...6 {
                precondition(blurred[((y+dy)*width+x+dx)*4] == blurred[((128+dy)*width+256+dx)*4], "Blur cannot grow or smear toward canvas edges")
            } }
        }
        precondition(blurred[(128*width+256)*4] < 255 && blurred[(128*width+257)*4] > 0)
        var solid = [UInt8](repeating: 0, count: impulses.count)
        for i in stride(from: 0, to: solid.count, by: 4) { solid[i] = 40; solid[i+1] = 100; solid[i+2] = 180; solid[i+3] = 255 }
        precondition(soften(solid) == solid, "Solid color must stay unchanged at all borders")
        // A bright left edge must never wrap onto the dark right edge.
        var border = [UInt8](repeating: 0, count: impulses.count)
        for y in 0..<height { for c in 0..<3 { border[y*width*4+c] = 255 } }
        let edge = soften(border)
        for y in 0..<height { precondition(edge[(y*width+width-1)*4] == 0) }
        print("PASS: Gaussian kernel identical at centre and near all borders, solid colors preserved, no opposite-edge wrapping")

        let state = RenderState(), renderer = VisualizerRenderer(state: state)
        let w = 640, h = 360
        try renderer.prepareOffscreen(width: w, height: h)
        state.zoomSpeed = 0
        func frame() throws -> [UInt8] {
            let t = try renderer.renderOffscreen(time: 2.3, audioBands: Array(repeating: 0, count: 32))
            var b = [UInt8](repeating: 0, count: w*h*4)
            b.withUnsafeMutableBytes { t.getBytes($0.baseAddress!, bytesPerRow: w*4, from: MTLRegionMake2D(0,0,w,h), mipmapLevel: 0) }
            return b
        }
        for scene in NativeEffects.activeIDs {
            state.scene = scene; state.motionBlur = 0
            let sharp = try frame()
            state.motionBlur = 0.9
            let soft = try frame(), repeatSoft = try frame()
            let difference = zip(sharp,soft).reduce(0.0) { $0 + Double(abs(Int($1.0)-Int($1.1))) } / Double(sharp.count)
            precondition(difference > 0.05 && soft == repeatSoft, "Softness must visibly and deterministically affect every visualizer")
            state.motionBlur = 0
            let restored = try frame()
            precondition(sharp == restored, "Zero blur must restore exact sharp frame")
            print("PASS: \(RenderState.sceneNames[scene]) whole-image blur changes GPU pixels, deterministic, zero restores exact frame")
        }
    }
}
