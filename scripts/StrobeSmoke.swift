import Foundation
@main struct StrobeSmoke {
    static func main() {
        var detector = StrobeDetector()
        let silence = [Float](repeating: 0, count: 32)
        var bass = silence; bass[2] = 1; bass[3] = 1
        for frame in 0..<120 { precondition(detector.nextFrame(time: Double(frame) / 60, bands: frame % 4 == 0 ? bass : silence) == 0) }
        detector.reset()
        var hats = silence; for band in 24..<32 { hats[band] = 0.8 }
        var triggers = 0
        for frame in 0..<120 {
            let flash = detector.nextFrame(time: Double(frame) / 60, bands: frame % 6 == 0 ? hats : silence)
            if frame % 6 == 0 { precondition(flash == 1); triggers += 1 }
            if frame % 6 == 3 { precondition(flash == 0) }
        }
        precondition(triggers == 20)
        precondition(detector.nextFrame(time: 0, bands: silence) == 0, "Seek backwards must reset")
        detector.reset(); _ = detector.nextFrame(time: 0, bands: hats)
        for frame in 1..<120 { precondition(detector.nextFrame(time: Double(frame) / 60, bands: hats) == (frame == 1 ? 1 : 0)) }
        print("PASS strobe: 10 rapid hat attacks/sec, bass rejection, short flashes, sustained treble rejection, seek reset")
    }
}
