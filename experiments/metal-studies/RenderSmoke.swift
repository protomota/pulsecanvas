import Foundation
import Metal

private struct StudyFrame {
    var phase: Float
    var beat: Float
}

private enum Study: String {
    case backlitRift = "backlit-rift"
    case undersurface = "undersurface"
    case mercuryFold = "mercury-fold"
    case emberFront = "ember-front"
    case anvilFlyover = "anvil-flyover"
    case pigmentStrata = "pigment-strata"

    var kernel: String {
        switch self {
        case .backlitRift: "smokeFrame"
        case .undersurface: "undersurface"
        case .mercuryFold: "mercuryFold"
        case .emberFront: "emberFront"
        case .anvilFlyover: "anvilFlyover"
        case .pigmentStrata: "pigmentStrata"
        }
    }
}

private enum RenderError: Error {
    case usage
    case metalUnavailable
    case kernelMissing
    case frameFailed(Error?)
}

let arguments = CommandLine.arguments
guard (5...6).contains(arguments.count),
      let width = Int(arguments[1]), (1...4096).contains(width),
      let height = Int(arguments[2]), (1...4096).contains(height),
      let frameCount = Int(arguments[3]), frameCount > 0,
      let firstFrame = Int(arguments[4]), (0..<480).contains(firstFrame),
      frameCount <= 480 - firstFrame,
      let study = Study(rawValue: arguments.count == 6 ? arguments[5] : "backlit-rift") else {
    FileHandle.standardError.write(Data("Usage: render-study width height frame-count first-frame [study-name]\n".utf8))
    throw RenderError.usage
}

guard let device = MTLCreateSystemDefaultDevice(),
      let queue = device.makeCommandQueue() else {
    throw RenderError.metalUnavailable
}
let source = try String(contentsOfFile: "Sources/PulseCanvas/Resources/NativeExpansionAtmospheric.metal", encoding: .utf8)
let options = MTLCompileOptions()
options.preprocessorMacros = ["PULSECANVAS_STUDY": 1 as NSNumber]
let library = try device.makeLibrary(source: source, options: options)
guard let function = library.makeFunction(name: study.kernel) else {
    throw RenderError.kernelMissing
}
let pipeline = try device.makeComputePipelineState(function: function)
let descriptor = MTLTextureDescriptor.texture2DDescriptor(
    pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false
)
descriptor.storageMode = .shared
descriptor.usage = .shaderWrite
guard let output = device.makeTexture(descriptor: descriptor) else {
    throw RenderError.metalUnavailable
}

let rowBytes = width * 4
let region = MTLRegionMake2D(0, 0, width, height)
var pixels = Data(count: rowBytes * height)
var gpuSeconds = 0.0
for index in firstFrame..<(firstFrame + frameCount) {
    let phase = Float(index) * 2 * .pi / 480
    // The preview uses sixteen evenly spaced beats over its eight-second loop.
    var frame = StudyFrame(phase: phase, beat: pow(max(0, cos(16 * phase)), 9))
    guard let command = queue.makeCommandBuffer(),
          let encoder = command.makeComputeCommandEncoder() else {
        throw RenderError.metalUnavailable
    }
    encoder.setComputePipelineState(pipeline)
    encoder.setTexture(output, index: 0)
    encoder.setBytes(&frame, length: MemoryLayout<StudyFrame>.stride, index: 0)
    encoder.dispatchThreads(
        MTLSize(width: width, height: height, depth: 1),
        threadsPerThreadgroup: MTLSize(width: pipeline.threadExecutionWidth, height: 4, depth: 1)
    )
    encoder.endEncoding()
    command.commit()
    command.waitUntilCompleted()
    guard command.status == .completed else {
        throw RenderError.frameFailed(command.error)
    }
    gpuSeconds += command.gpuEndTime - command.gpuStartTime
    pixels.withUnsafeMutableBytes { bytes in
        output.getBytes(bytes.baseAddress!, bytesPerRow: rowBytes, from: region, mipmapLevel: 0)
    }
    try FileHandle.standardOutput.write(contentsOf: pixels)
}
let milliseconds = gpuSeconds * 1_000 / Double(frameCount)
let summary = "\(study.rawValue) on \(device.name): \(frameCount) frames at \(width)×\(height), mean GPU time \(String(format: "%.2f", milliseconds)) ms/frame\n"
FileHandle.standardError.write(Data(summary.utf8))
