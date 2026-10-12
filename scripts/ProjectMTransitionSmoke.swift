import Foundation
import Metal

/// A preset displays red only when its progress, frame counter and initialization
/// FPS are valid. This catches timing corruption independently of bundled artwork.
@main struct ProjectMTransitionSmoke {
    static func main() throws {
        let root = URL(fileURLWithPath: ".build/validation/projectm-transitions")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        guard let device = MTLCreateSystemDefaultDevice() else { fatalError("Metal unavailable") }
        let pcm = (0..<1024).flatMap { sample -> [Float] in
            let value = Float(sin(Double(sample) * 0.017) * 0.6)
            return [value, value]
        }
        for fps in [24, 30, 60] {
            let fixture = """
            [preset00]
            fDecay=0
            fWaveAlpha=0
            shapecode_0_enabled=1
            shapecode_0_sides=4
            shapecode_0_x=0.5
            shapecode_0_y=0.5
            shapecode_0_rad=1
            shapecode_0_r=1
            shapecode_0_g=0
            shapecode_0_b=0
            shapecode_0_a=1
            shapecode_0_r2=1
            shapecode_0_g2=0
            shapecode_0_b2=0
            shapecode_0_a2=1
            per_frame_init_1=q3=fps;
            per_frame_1=q1=progress;q2=frame;
            shape_0_per_frame1=r=if(below(q1,0),0,1);g=if(above(q2,3),1,0);b=if(equal(q3,\(fps)),0,1);r2=r;g2=g;b2=b;
            """
            let first = root.appendingPathComponent("first-\(fps).milk")
            let second = root.appendingPathComponent("second-\(fps).milk")
            try fixture.write(to: first, atomically: true, encoding: .utf8)
            try fixture.write(to: second, atomically: true, encoding: .utf8)
            let engine = try ProjectMEngine()
            func pixel(_ preset: URL, _ time: Double, chaos: Float = 1) throws -> [UInt8] {
                let texture = try engine.frame(preset: preset, texturePaths: [], device: device, width: 64, height: 64,
                    time: time, sourceTime: time, pcm: pcm, chaos: chaos, fps: fps)
                var pixels = [UInt8](repeating: 0, count: 64 * 64 * 4)
                texture.getBytes(&pixels, bytesPerRow: 256, from: MTLRegionMake2D(0, 0, 64, 64), mipmapLevel: 0)
                let offset = (32 * 64 + 32) * 4
                return Array(pixels[offset..<offset + 4])
            }
            func requireRed(_ value: [UInt8], _ message: String) {
                precondition(value[2] > 230 && value[1] < 5 && value[0] < 5, "\(message): BGRA \(value)")
            }
            for frame in 0...fps * 5 { _ = try pixel(first, Double(frame) / Double(fps)) }
            let oldFrame = try pixel(first, 5 + 1 / Double(fps))
            precondition(oldFrame[1] > 230, "The first preset must have accumulated frame history")
            _ = try pixel(second, 5 + 2 / Double(fps))
            let switched = try pixel(second, 5 + 3 / Double(fps))
            requireRed(switched, "A preset switch must reset frame history and retain nonnegative progress and the chosen FPS")
            let cached = try pixel(second, 5 + 3 / Double(fps))
            precondition(cached == switched, "A paused/cached frame must not advance the engine")
            _ = try pixel(second, 0)
            requireRed(try pixel(second, 1 / Double(fps)), "A backward seek must restart cleanly")
            _ = try pixel(second, 2 / Double(fps), chaos: 0)
            requireRed(try pixel(second, 3 / Double(fps), chaos: 0), "Zero Chaos must restart cleanly without music history")
            _ = try pixel(first, 10, chaos: 0)
            requireRed(try pixel(first, 10 + 1 / Double(fps), chaos: 0), "A late switch at zero Chaos must remain valid")
        }
        print("PASS ProjectM transitions: fresh frame/audio timing, nonnegative progress, initialization FPS, cached pause, backward seek and zero Chaos at 24/30/60 fps")
    }
}
