import AppKit
import Foundation

let directory = URL(fileURLWithPath: CommandLine.arguments[1])
let artworkURL = URL(fileURLWithPath: "assets/app-icon/PulseCanvas-Octagon.png")
guard let artwork = NSImage(contentsOf: artworkURL) else {
    fatalError("Missing app icon artwork: \(artworkURL.path)")
}
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
for (name, pixels) in [("icon_16x16",16),("icon_16x16@2x",32),("icon_32x32",32),("icon_32x32@2x",64),("icon_128x128",128),("icon_128x128@2x",256),("icon_256x256",256),("icon_256x256@2x",512),("icon_512x512",512),("icon_512x512@2x",1024)] {
    // Explicit pixel backing keeps Retina displays from doubling icon dimensions.
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels,
        pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    let size = CGFloat(pixels)
    let frame = NSRect(x: size * 0.06, y: size * 0.06,
        width: size * 0.88, height: size * 0.88)
    NSBezierPath(roundedRect: frame, xRadius: size * 0.2,
        yRadius: size * 0.2).addClip()
    artwork.draw(in: frame, from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!
        .write(to: directory.appendingPathComponent(name + ".png"))
}
