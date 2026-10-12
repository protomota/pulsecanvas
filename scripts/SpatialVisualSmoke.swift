import AppKit
import MetalKit
import Foundation
@main struct SpatialVisualSmoke {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let root = URL(fileURLWithPath: ".build/spatial-validation")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let state = RenderState(), renderer = VisualizerRenderer(state: state)
        let scenes = [4,10,12,22,23,24,25,26,27,28,29,30]
        let spectrum = (0..<32).map { Float($0 % 7) / 10 }
        let width=960, height=540
        try renderer.prepareOffscreen(width: width, height: height)
        var results: [[UInt8]] = []
        for scene in scenes {
            state.scene=scene; state.palette=scene % 5; state.particleSize=1.5; state.zoom=1; state.motionBlur=0
            let texture = try renderer.renderOffscreen(time: 2.3, audioBands: spectrum, audioPulse: 0.35, audioMomentum: 0.5, audioBeatMotionTime: 0.3)
            let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: width*4, bitsPerPixel: 32)!
            texture.getBytes(bitmap.bitmapData!, bytesPerRow: width*4, from: MTLRegionMake2D(0,0,width,height), mipmapLevel: 0)
            for i in stride(from:0,to:width*height*4,by:4) { let b=bitmap.bitmapData![i]; bitmap.bitmapData![i]=bitmap.bitmapData![i+2]; bitmap.bitmapData![i+2]=b }
            try bitmap.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("\(scene)-\(RenderState.sceneNames[scene].replacingOccurrences(of:" ",with:"-")).png"))
            state.palette=0
            let image = try renderer.renderOffscreen(time:2.3,audioBands:spectrum)
            var bytes=[UInt8](repeating:0,count:width*height*4)
            bytes.withUnsafeMutableBytes { image.getBytes($0.baseAddress!,bytesPerRow:width*4,from:MTLRegionMake2D(0,0,width,height),mipmapLevel:0) }
            for other in results {
                let difference=zip(bytes,other).reduce(0.0) { $0+Double(abs(Int($1.0)-Int($1.1))) }/Double(bytes.count)
                precondition(difference>4,"New spatial styles must differ with the same palette and settings")
            }
            if scene == 22 {
                var occupied = Set<Int>()
                for pixel in 0..<(width * height) where (0..<3).contains(where: { bytes[pixel*4+$0] > 80 }) {
                    occupied.insert(((pixel / width) * 4 / height) * 4 + (pixel % width) * 4 / width)
                }
                precondition(occupied.count >= 14, "Octagon spiral must contain bright geometry throughout the canvas")
            }
            if scene == 23 {
                var edges = 0
                for pixel in 1..<(width * height) {
                    if (0..<3).contains(where: { abs(Int(bytes[pixel*4+$0])-Int(bytes[(pixel-1)*4+$0])) > 4 }) { edges += 1 }
                }
                precondition(edges > 300, "Liquid surface must retain local geometric detail instead of a flat color wash")
            }
            if scene == 23 {
                var detailFrames: [[UInt8]] = []
                for detail: Float in [0, 1] {
                    state.liquidDetail = detail
                    let image = try renderer.renderOffscreen(time: 2.3, audioBands: spectrum)
                    var detailPixels = [UInt8](repeating: 0, count: bytes.count)
                    detailPixels.withUnsafeMutableBytes { image.getBytes($0.baseAddress!, bytesPerRow: width*4, from: MTLRegionMake2D(0,0,width,height), mipmapLevel: 0) }
                    detailFrames.append(detailPixels)
                }
                let change = zip(detailFrames[0],detailFrames[1]).reduce(0.0) { $0+Double(abs(Int($1.0)-Int($1.1))) } / Double(bytes.count)
                precondition(change > 5, "Liquid detail must visibly change actual rendered geometry")
                let levels = stride(from: 0, to: bytes.count, by: 4).map { max(bytes[$0], max(bytes[$0+1], bytes[$0+2])) }
                precondition(levels.filter { $0 < 30 }.count > width*height/100 && levels.filter { $0 > 140 }.count > width*height/100, "Liquid frame needs both dark cavities and bright reflections")
                state.liquidDetail = 0.6
                print("PASS: Liquid detail changes GPU pixels (mean \(change)); dark cavities and bright reflections both cover visible areas")
            }
            if scene == 28 {
                var countFrames: [[UInt8]] = []
                for count in [1,12] {
                    state.haloCount = count
                    let texture = try renderer.renderOffscreen(time: 2.3, audioBands: spectrum)
                    var pixels = [UInt8](repeating: 0, count: bytes.count)
                    pixels.withUnsafeMutableBytes { texture.getBytes($0.baseAddress!, bytesPerRow: width*4, from: MTLRegionMake2D(0,0,width,height), mipmapLevel: 0) }
                    countFrames.append(pixels)
                    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: width*4, bitsPerPixel: 32)!
                    for pixel in 0..<(width*height) {
                        bitmap.bitmapData![pixel*4] = pixels[pixel*4+2]; bitmap.bitmapData![pixel*4+1] = pixels[pixel*4+1]
                        bitmap.bitmapData![pixel*4+2] = pixels[pixel*4]; bitmap.bitmapData![pixel*4+3] = 255
                    }
                    try bitmap.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("Halo-Count-\(count).png"))
                }
                let changed = zip(countFrames[0],countFrames[1]).reduce(0.0) { $0 + Double(abs(Int($1.0)-Int($1.1))) } / Double(bytes.count)
                func visible(_ frame: [UInt8]) -> Int { stride(from: 0, to: frame.count, by: 4).filter { max(frame[$0],max(frame[$0+1],frame[$0+2])) > 60 }.count }
                let sparse = visible(countFrames[0]), dense = visible(countFrames[1])
                precondition(changed > 3 && dense > sparse * 2, "Halo count must add visible rings rather than only changing their thickness")
                state.haloCount = 6
                print("PASS: Halo count changes GPU geometry, mean \(changed), visible pixels one/twelve \(sparse)/\(dense)")
            }
            results.append(bytes)
            let start=Date()
            for frame in 0..<20 { _ = try renderer.renderOffscreen(time:2.3+Double(frame)/60,audioBands:spectrum,audioPulse:0.35,audioMomentum:0.5) }
            print("\(RenderState.sceneNames[scene]): 960x540, 20 completed GPU frames, mean \(Date().timeIntervalSince(start)*1000/20) ms/frame")
        }
        print("PASS: all \(scenes.count) spatial designs are visually distinct using identical palette/settings; GPU captures saved for inspection")
    }
}
