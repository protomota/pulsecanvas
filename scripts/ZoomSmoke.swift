import AppKit
import MetalKit
import Foundation
@main struct ZoomSmoke {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let state = RenderState(), renderer = VisualizerRenderer(state: RenderState())
        renderer.state = state
        state.chaos = 0
        let width = 320, height = 180
        try renderer.prepareOffscreen(width: width, height: height)
        func pixels(_ time: Double) throws -> [UInt8] {
            let texture = try renderer.renderOffscreen(time: time, audioBands: Array(repeating: 0, count: 32))
            var bytes = [UInt8](repeating: 0, count: width * height * 4)
            bytes.withUnsafeMutableBytes { texture.getBytes($0.baseAddress!, bytesPerRow: width * 4, from: MTLRegionMake2D(0,0,width,height), mipmapLevel: 0) }
            return bytes
        }
        func difference(_ a: [UInt8], _ b: [UInt8]) -> Double {
            zip(a,b).reduce(0.0) { $0 + Double(abs(Int($1.0)-Int($1.1))) } / Double(a.count)
        }
        for scene in NativeEffects.activeIDs {
            state.scene = scene; state.zoomSpeed = 0
            let flat = try pixels(2.3), movingFlat = try pixels(2.7)
            precondition(difference(flat, movingFlat) > 0.05, "Zero zoom must retain animation: \(RenderState.sceneNames[scene])")
            state.zoomSpeed = 1
            let travel = try pixels(2.3)
            state.zoomSpeed = 3
            let fast = try pixels(2.3)
            precondition(difference(flat,travel) > 0.5 && difference(travel,fast) > 0.5, "Zoom speed must visibly affect \(RenderState.sceneNames[scene])")
            state.zoomSpeed = 0
            let restored = try pixels(2.3)
            precondition(flat == restored, "Disabling zoom must restore deterministic framing")
            print("PASS: \(RenderState.sceneNames[scene]) zero retains animation, low/high speed changes GPU pixels, zero restores exact frame")
        }
        // Every expanding layer resets with zero contribution, including across
        // both its own boundary and the offset layer's boundary.
        state.scene = 18; state.zoomSpeed = 1
        for boundary in [3.125, 6.25, 9.375] {
            let before = try pixels(boundary - 0.0001), after = try pixels(boundary + 0.0001)
            precondition(difference(before,after) < 1, "Forward zoom loop cannot visibly jump at cycle boundaries")
        }
        for scene in [22,25,29] {
            state.scene = scene
            for speed: Float in [0,1.5,3] {
                state.zoomSpeed = speed
                var maximumChange = 0.0
                for timestamp in [0.3,2.3,3.125,6.25,9.375,17,33,60,90] {
                    let before = try pixels(timestamp - 0.0001), after = try pixels(timestamp + 0.0001)
                    let change = difference(before,after)
                    maximumChange = max(maximumChange,change)
                    precondition(change < 1, "Continuous tunnel motion cannot jump: \(RenderState.sceneNames[scene]), zoom \(speed), time \(timestamp), change \(change)")
                }
                print("PASS: \(RenderState.sceneNames[scene]) zero-Chaos tunnel continuity, zoom \(speed), max adjacent-time pixel change \(maximumChange)")
            }
        }
        // Real playback cadence also catches an isolated reset that a sparse
        // infinitesimal-time check could miss. Inspect early and late motion.
        var cadenceChecks = 0
        for scene in [22,25,29] {
            state.scene = scene
            for speed: Float in [0,1.5,3] {
                state.zoomSpeed = speed
                for fps in [30,60] {
                    for start in [2.0,85.0] {
                        var previous = try pixels(start), changes: [Double] = []
                        for frame in 1...fps * 2 {
                            let current = try pixels(start + Double(frame) / Double(fps))
                            changes.append(difference(previous,current)); previous = current
                            cadenceChecks += 1
                        }
                        let median = changes.sorted()[changes.count / 2]
                        let peak = changes.max()!
                        precondition(peak < median * 3 + 5, "Isolated tunnel jump at playback cadence: scene \(scene), speed \(speed), fps \(fps), start \(start), peak \(peak), median \(median)")
                    }
                }
            }
        }
        print("PASS: \(cadenceChecks) actual 30/60fps tunnel frame transitions without isolated jumps at early/late timestamps and three zoom speeds")
        print("PASS: seamless forward zoom cycle boundaries, smooth tunnels at zero Chaos, and all \(NativeEffects.activeIDs.count) styles")
    }
}
