import AppKit
import CoreVideo
@preconcurrency import Metal

@main struct EncoderSurfaceSmoke {
    @MainActor static func main() async throws {
        _ = NSApplication.shared
        for scene in NativeEffects.activeIDs {
            let a = RenderState(), b = RenderState()
            for state in [a,b] {
                state.scene = scene; state.chaos = 0.8; state.motionBlur = 0.55
                state.strobeEnabled = true; state.strobeSensitivity = 0.8; state.strobeStrength = 0.65
            }
            let reference = VisualizerRenderer(state: a), shared = VisualizerRenderer(state: b)
            try reference.prepareOffscreen(width: 480, height: 270)
            try shared.prepareOffscreen(width: 480, height: 270)
            var cache: CVMetalTextureCache?
            precondition(CVMetalTextureCacheCreate(nil, nil, shared.offscreenDevice!, nil, &cache) == kCVReturnSuccess)
            for frame in 0..<4 {
                let time = Double(frame) / 30
                let bands: [Float] = [0.4,0.7,0.1,0.9,0.2,0.6,0.8,0.3]
                let source = try reference.renderOffscreen(time: time, audioBands: bands, audioPulse: 0.8, audioMomentum: 0.7, audioBeatMotionTime: time, audioTreblePulse: 0.9, audioTrebleAttackTime: time)
                var buffer: CVPixelBuffer?
                precondition(CVPixelBufferCreate(nil,480,270,kCVPixelFormatType_32BGRA,[kCVPixelBufferMetalCompatibilityKey: true, kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary,&buffer) == kCVReturnSuccess)
                var surface: CVMetalTexture?
                precondition(CVMetalTextureCacheCreateTextureFromImage(nil,cache!,buffer!,nil,.bgra8Unorm,480,270,0,&surface) == kCVReturnSuccess)
                let target = CVMetalTextureGetTexture(surface!)!
                try await shared.renderOffscreen(into: target,time: time,audioBands: bands,audioPulse: 0.8,audioMomentum: 0.7,audioBeatMotionTime: time,audioTreblePulse: 0.9,audioTrebleAttackTime: time)
                withExtendedLifetime(surface) {}
                var expected = [UInt8](repeating:0,count:480*270*4)
                source.getBytes(&expected,bytesPerRow:480*4,from:MTLRegionMake2D(0,0,480,270),mipmapLevel:0)
                CVPixelBufferLockBaseAddress(buffer!, .readOnly)
                let bytes = CVPixelBufferGetBaseAddress(buffer!)!, stride = CVPixelBufferGetBytesPerRow(buffer!)
                for row in 0..<270 {
                    let actual = Array(UnsafeBufferPointer(start:bytes.advanced(by:row*stride).assumingMemoryBound(to:UInt8.self),count:480*4))
                    precondition(actual == Array(expected[(row*480*4)..<((row+1)*480*4)]), "Encoder surface differs for scene \(scene), frame \(frame)")
                }
                CVPixelBufferUnlockBaseAddress(buffer!, .readOnly)
            }
        }
        print("PASS: all \(NativeEffects.activeIDs.count) visualizers produce byte-identical encoder-surface frames, including content blur, music response and strobe over consecutive frames")
    }
}
