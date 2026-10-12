import AppKit
import MetalKit

@main struct OrganicPulseSmoke {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let state = RenderState(), renderer = VisualizerRenderer(state: state)
        let width = 320, height = 180
        try renderer.prepareOffscreen(width: width, height: height)
        state.speed = 1; state.zoomSpeed = 0; state.palette = VisualPalette.blueHour.rawValue
        let root = URL(fileURLWithPath: ".build/organic-pulse-validation")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        func image(chaos: Float, hit: Bool) throws -> [UInt8] {
            state.chaos = chaos
            // Hold time/camera fixed to isolate shape deformation from acceleration.
            let texture = try renderer.renderOffscreen(time: 2.3,
                audioBands: Array(repeating: hit ? 0.65 : 0, count: 32),
                audioPulse: hit ? 0.9 : 0, audioMomentum: hit ? 0.85 : 0)
            var bytes = [UInt8](repeating: 0, count: width*height*4)
            bytes.withUnsafeMutableBytes { texture.getBytes($0.baseAddress!, bytesPerRow: width*4, from: MTLRegionMake2D(0,0,width,height), mipmapLevel: 0) }
            return bytes
        }
        func difference(_ a: [UInt8], _ b: [UInt8]) -> Double {
            var total = 0.0
            for i in stride(from: 0, to: a.count, by: 4) { for c in 0..<3 { total += Double(abs(Int(a[i+c])-Int(b[i+c]))) } }
            return total / Double(width*height*3)
        }
        // Fit global zoom, translation and brightness. Local ripples must retain
        // substantial differences after the best whole-screen transform.
        func globalResidual(_ quiet: [UInt8], _ active: [UInt8]) -> Double {
            var best = Double.infinity
            for scaleIndex in -10...10 {
                let scale = 1 + Double(scaleIndex)*0.02
                for dx in [-5,0,5] { for dy in [-5,0,5] {
                    var samples: [(Double,Double)] = [], aa = 0.0, ab = 0.0
                    for y in stride(from: 16, to: height-16, by: 4) { for x in stride(from: 24, to: width-24, by: 4) {
                        let sx = Int((Double(x-width/2-dx)/scale)+Double(width/2))
                        let sy = Int((Double(y-height/2-dy)/scale)+Double(height/2))
                        guard (0..<width).contains(sx), (0..<height).contains(sy) else { continue }
                        for c in 0..<3 {
                            let a = Double(quiet[(sy*width+sx)*4+c]), b = Double(active[(y*width+x)*4+c])
                            samples.append((a,b)); aa += a*a; ab += a*b
                        }
                    } }
                    let gain = min(2,max(0.5,ab/max(1,aa)))
                    let error = samples.reduce(0.0) { $0 + abs(min(255,$1.0*gain)-$1.1) } / Double(samples.count)
                    best = min(best,error)
                } }
            }
            return best
        }
        func save(_ pixels: [UInt8], _ name: String) throws {
            let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: width*4, bitsPerPixel: 32)!
            for i in stride(from: 0, to: pixels.count, by: 4) {
                bitmap.bitmapData![i]=pixels[i+2]; bitmap.bitmapData![i+1]=pixels[i+1]; bitmap.bitmapData![i+2]=pixels[i]; bitmap.bitmapData![i+3]=255
            }
            try bitmap.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent(name+".png"))
        }
        for scene in [18,22,23,25,30] {
            state.scene = scene
            let quiet = try image(chaos: 1, hit: false), low = try image(chaos: 0.2, hit: true), high = try image(chaos: 1, hit: true)
            let lowChange = difference(quiet,low), highChange = difference(quiet,high)
            let residual = globalResidual(quiet,high)
            print("\(RenderState.sceneNames[scene]): low/high shape change \(lowChange)/\(highChange), residual after best global transform \(residual)")
            precondition(highChange > lowChange*1.25 && residual > 1 && residual > highChange*0.35, "Beat response must deform local elements and grow more liquid with Chaos")
            let repeatHigh = try image(chaos: 1, hit: true), released = try image(chaos: 1, hit: false), zero = try image(chaos: 0, hit: true)
            precondition(high == repeatHigh && quiet == released && quiet == zero, "Waves must release, stay deterministic, and disappear at zero Chaos")
            try save(quiet,"\(scene)-quiet"); try save(high,"\(scene)-waves")
        }
        print("PASS: local geometry waves cannot be explained by global zoom/translation/brightness; higher Chaos strengthens deformation, release and zero restore exact procedural frames")
    }
}
