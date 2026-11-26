import Foundation
import Metal

@main struct ProjectMCompositorSmoke {
    static func main() throws {
        let device = MTLCreateSystemDefaultDevice()!
        let sourceURL = URL(fileURLWithPath: "Sources/PulseCanvas/Resources/Strobe.metal")
        let library = try device.makeLibrary(source: String(contentsOf: sourceURL, encoding: .utf8), options: nil)
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "whiteFlashVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "projectMFragment")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        let pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        let queue = device.makeCommandQueue()!
        // Distinct quadrants expose edge clamping and cropping when source and drawable sizes differ.
        let colors: [[UInt8]] = [[0,0,255,255], [0,255,0,255], [255,0,0,255], [255,255,255,255]]
        for (width,height) in [(3840,2160), (2160,3840), (2560,1600), (577,325)] {
            let size = ProjectMPreviewSize.dimensions(width: width, height: height)
            let sourceDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: size.width, height: size.height, mipmapped: false)
            sourceDescriptor.storageMode = .shared; sourceDescriptor.usage = [.shaderRead]
            let source = device.makeTexture(descriptor: sourceDescriptor)!
            var pixels = [UInt8](repeating: 0, count: size.width * size.height * 4)
            for y in 0..<size.height { for x in 0..<size.width {
                let color = colors[(y >= size.height / 2 ? 2 : 0) + (x >= size.width / 2 ? 1 : 0)]
                let offset = (y * size.width + x) * 4
                for channel in 0..<4 { pixels[offset + channel] = color[channel] }
            }}
            source.replace(region: MTLRegionMake2D(0,0,size.width,size.height), mipmapLevel: 0, withBytes: pixels, bytesPerRow: size.width * 4)
            let targetDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
            targetDescriptor.storageMode = .shared; targetDescriptor.usage = [.renderTarget]
            let target = device.makeTexture(descriptor: targetDescriptor)!
            let command = queue.makeCommandBuffer()!
            let pass = MTLRenderPassDescriptor(); pass.colorAttachments[0].texture = target
            pass.colorAttachments[0].loadAction = .dontCare; pass.colorAttachments[0].storeAction = .store
            let encoder = command.makeRenderCommandEncoder(descriptor: pass)!
            encoder.setRenderPipelineState(pipeline); encoder.setFragmentTexture(source, index: 0)
            var style = SIMD4<Float>(1,1,0,0), dimensions = SIMD2<Float>(Float(width),Float(height))
            encoder.setFragmentBytes(&style, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
            encoder.setFragmentBytes(&dimensions, length: MemoryLayout<SIMD2<Float>>.stride, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3); encoder.endEncoding()
            command.commit(); command.waitUntilCompleted()
            if let error = command.error { throw error }
            for yFraction in [0.05,0.25,0.75,0.95] { for xFraction in [0.05,0.25,0.75,0.95] {
                let x = Int(Double(width) * xFraction), y = Int(Double(height) * yFraction)
                var actual = [UInt8](repeating: 0, count: 4)
                target.getBytes(&actual, bytesPerRow: 4, from: MTLRegionMake2D(x,y,1,1), mipmapLevel: 0)
                let expected = colors[(yFraction < 0.5 ? 2 : 0) + (xFraction >= 0.5 ? 1 : 0)]
                guard zip(actual,expected).allSatisfy({abs(Int($0)-Int($1)) <= 1}) else {
                    throw NSError(domain: "ProjectMCompositor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Incorrect full-screen mapping at \(width)×\(height), (\(xFraction),\(yFraction)): \(actual), expected \(expected)"])
                }
            }}
            print("PASS full-screen mapping: \(size.width)×\(size.height) OpenGL source fills \(width)×\(height) drawable without edge smearing")
        }
    }
}
