import AppKit
import MetalKit
import Foundation
@main struct VisualPerformanceSmoke {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let state = RenderState(), renderer = VisualizerRenderer(state: state)
        let spectrum = (0..<32).map { Float($0 % 7) / 10 }
        state.scene = 21; state.motionBlur = 0
        for (width,height) in [(1920,1080),(960,540),(540,960)] {
            try renderer.prepareOffscreen(width: width, height: height)
            for index in 0..<5 { _ = try renderer.renderOffscreen(time: Double(index)/60, audioBands: spectrum) }
            let start = Date()
            for index in 0..<60 { _ = try renderer.renderOffscreen(time: Double(index+5)/60, audioBands: spectrum) }
            print("Resonant Shell \(width)x\(height), 60 completed GPU frames, mean \(Date().timeIntervalSince(start)*1000/60) ms/frame")
        }
        if CommandLine.arguments.count > 1 {
            let destination = URL(fileURLWithPath: CommandLine.arguments[1])
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
            for (width,height) in [(960,540),(540,960)] {
                try renderer.prepareOffscreen(width: width, height: height)
                for scene in [14,17,18,21] {
                    state.scene = scene; state.palette = scene == 18 ? 3 : 0; state.particleSize = 1.6; state.zoom = 1.05
                    let texture = try renderer.renderOffscreen(time: 3.4, audioBands: spectrum, audioPulse: 0.5)
                    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: width*4, bitsPerPixel: 32)!
                    texture.getBytes(bitmap.bitmapData!, bytesPerRow: width*4, from: MTLRegionMake2D(0,0,width,height), mipmapLevel: 0)
                    let bytes = bitmap.bitmapData!
                    for i in stride(from: 0, to: width*height*4, by: 4) { let b = bytes[i]; bytes[i] = bytes[i+2]; bytes[i+2] = b }
                    try bitmap.representation(using: .png, properties: [:])!.write(to: destination.appendingPathComponent("visual-\(scene)-\(width)x\(height).png"))
                }
            }
        }
    }
}
