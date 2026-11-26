import Foundation
import Metal

@main struct VisionPresentationSmoke {
    static func main() throws {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue(),
              let function = try device.makeLibrary(source: VisionPresentation.smoothingShader, options: nil)
                .makeFunction(name: "smoothPresentation") else { fatalError("Metal unavailable") }
        let pipeline = try device.makeComputePipelineState(function: function)
        func filtered(_ pixels: [UInt8], width: Int, height: Int, enabled: Bool) throws -> [UInt8] {
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
            descriptor.storageMode = .shared; descriptor.usage = [.shaderRead, .shaderWrite]
            let source = device.makeTexture(descriptor: descriptor)!, target = device.makeTexture(descriptor: descriptor)!
            pixels.withUnsafeBytes { source.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: $0.baseAddress!, bytesPerRow: width * 4) }
            let command = queue.makeCommandBuffer()!, encoder = command.makeComputeCommandEncoder()!
            encoder.setComputePipelineState(pipeline); encoder.setTexture(source, index: 0); encoder.setTexture(target, index: 1)
            var enabled: UInt32 = enabled ? 1 : 0
            encoder.setBytes(&enabled, length: 4, index: 0)
            encoder.dispatchThreads(MTLSize(width: width, height: height, depth: 1), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            encoder.endEncoding(); command.commit(); command.waitUntilCompleted()
            if let error = command.error { throw error }
            var output = pixels
            output.withUnsafeMutableBytes { target.getBytes($0.baseAddress!, bytesPerRow: width * 4, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0) }
            return output
        }
        let width = 67, height = 45 // Non-multiple-of-threadgroup bounds are intentional.
        let color: [UInt8] = [70, 110, 160, 255]
        let uniform = Array(repeating: color, count: width * height).flatMap { $0 }
        let flat = try filtered(uniform, width: width, height: height, enabled: true)
        precondition(flat == uniform)
        var diagonal = [UInt8]()
        for y in 0..<height { for x in 0..<width {
            let value: UInt8 = x > y ? 255 : 0
            diagonal += [value, value, value, 255]
        } }
        let unchanged = try filtered(diagonal, width: width, height: height, enabled: false)
        precondition(unchanged == diagonal)
        let smoothed = try filtered(diagonal, width: width, height: height, enabled: true)
        let softened = stride(from: 0, to: smoothed.count, by: 4).filter { smoothed[$0] > 0 && smoothed[$0] < 255 }.count
        precondition(softened > 0 && smoothed[4 * width * (height - 1)] == 0 && smoothed[4 * (width - 1)] == 255)
        precondition(stride(from: 3, to: smoothed.count, by: 4).allSatisfy { smoothed[$0] == 255 })
        print("PASS headset presentation Metal: flat colors preserved, smoothing-off exact bytes, diagonal edge coverage (\(softened) filtered pixels), clamped borders and alpha")
    }
}
