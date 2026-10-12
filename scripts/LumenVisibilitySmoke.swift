import AppKit
import MetalKit

@main struct LumenVisibilitySmoke {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let state = RenderState(), renderer = VisualizerRenderer(state: state)
        state.scene = 1
        var checks = 0, minVisible = 1.0, worst = ""
        let count = SurfaceGeometry.PointScene.lumenVeil.availableFormulaPool.count
        for (width,height) in [(256,144), (144,256)] {
            try renderer.prepareOffscreen(width: width, height: height)
            for index in 0..<count {
                // Every source shape and halfway transition, plus the next cycle.
                for phase in [0.0,0.5] {
                    let time = (Double(index) * 2 + phase) * 110 / 60
                    for (zoom, rotation, travel, pulse) in [(Float(0.3),Float(0),Float(0),Float(0)), (1.55,2.7,3,1), (2,-2.7,0,0)] {
                        state.zoom = zoom; state.rotation = rotation; state.zoomSpeed = travel; state.chaos = 1
                        let texture = try renderer.renderOffscreen(time: time, audioBands: Array(repeating: pulse * 0.4, count: 32), audioPulse: pulse, audioMomentum: pulse)
                        var bytes = [UInt8](repeating: 0, count: width*height*4)
                        bytes.withUnsafeMutableBytes { texture.getBytes($0.baseAddress!, bytesPerRow: width*4, from: MTLRegionMake2D(0,0,width,height), mipmapLevel: 0) }
                        let lit = stride(from:0, to:bytes.count, by:4).filter { max(bytes[$0], max(bytes[$0+1],bytes[$0+2])) > 16 }.count
                        let fraction = Double(lit) / Double(width*height)
                        if fraction < minVisible { minVisible = fraction; worst = "shape \(index), phase \(phase), zoom \(zoom), canvas \(width)x\(height)" }
                        checks += 1
                    }
                }
            }
        }
        print("Lumen Veil: \(checks) shape/transition/framing/beat checks, least visible area \(minVisible), \(worst)")
        precondition(minVisible > 0.05, "Lumen Veil cannot disappear during any shape transition or randomized framing")
        print("PASS: every Lumen Veil shape and transition retains visible elements across wide/phone framing and extreme randomized controls")
    }
}
