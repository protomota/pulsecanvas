import Foundation

/// Short canvases share their title/footer area with the image instead of
/// subtracting fixed chrome that can leave the renderer only a few pixels high.
struct CanvasPreviewLayout {
    let overlaysChrome: Bool
    let padding: CGFloat
    let preview: CGRect

    init(size: CGSize, aspectRatio: Double) {
        // Reintroduce title space gradually as the window grows, so crossing a
        // compact-layout threshold does not suddenly shrink the visualization.
        let chrome = min(1, max(0, (size.height - 280) / 160))
        overlaysChrome = chrome < 1
        padding = 12 + 10 * chrome
        let top: CGFloat = 58 * chrome
        let bottom: CGFloat = 27 * chrome
        let available = CGRect(x: padding, y: padding + top,
            width: max(0, size.width - 2 * padding),
            height: max(0, size.height - 2 * padding - top - bottom))
        let ratio = CGFloat(aspectRatio)
        let width = min(available.width, available.height * ratio)
        let height = width / ratio
        preview = CGRect(x: available.midX - width / 2, y: available.midY - height / 2,
            width: width, height: height)
    }
}
