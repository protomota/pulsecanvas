import SwiftUI
import AppKit

/// Lay out names once, then create controls only for the visible portion of the row.
/// Jumping thousands of presets must not build every intervening SwiftUI button.
struct VisualizerPresetStrip: NSViewRepresentable, Equatable {
    @ObservedObject private var library = ProjectMPresets.shared
    let selected: Int
    var revealRequest = 0
    var poolRevision = 0
    let accent: Color
    let background: Color
    let choose: (Int) -> Void
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.selected == rhs.selected && lhs.poolRevision == rhs.poolRevision && lhs.revealRequest == rhs.revealRequest && lhs.accent == rhs.accent && lhs.background == rhs.background
    }
    func makeNSView(context: Context) -> PresetStripView { PresetStripView() }
    func updateNSView(_ view: PresetStripView, context: Context) {
        view.update(library: library, selected: selected, accent: NSColor(accent), background: NSColor(background), isEnabled: context.environment.isEnabled, revealRequest: revealRequest, choose: choose)
    }
}

final class PresetStripView: NSScrollView {
    private let canvas = NSView()
    private var starts: [CGFloat] = []
    private var widths: [CGFloat] = []
    private var rowWidth: CGFloat = 0
    private var viewportWidth: CGFloat = -1
    private var names: [String] = []
    /// Scene ID for each laid-out position; the row offers only available scenes.
    private var scenes: [Int] = []
    private var positions: [Int: Int] = [:]
    private var library: ProjectMPresets?
    private var selected = -1
    private var revealRequest = 0
    private var accent = NSColor.systemPink
    private var buttonBackground = NSColor.windowBackgroundColor
    private var choose: ((Int) -> Void)?
    private var controlsEnabled = true
    private var buttons: [Int: PresetStripButton] = [:]
    private var observer: PresetStripObservation?
    override init(frame: NSRect) {
        super.init(frame: frame)
        drawsBackground = false; hasHorizontalScroller = true; hasVerticalScroller = false
        autohidesScrollers = false; scrollerStyle = .legacy; scrollerKnobStyle = .light
        horizontalScrollElasticity = .allowed; verticalScrollElasticity = .none
        documentView = canvas; contentView.postsBoundsChangedNotifications = true
        observer = PresetStripObservation(NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: contentView, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.showVisibleButtons() }
        })
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layout() {
        super.layout()
        canvas.frame.size.height = max(62, contentView.bounds.height)
        if viewportWidth != contentView.bounds.width {
            updateCanvasWidth()
        }
        showVisibleButtons()
    }
    func update(library: ProjectMPresets, selected: Int, accent: NSColor, background: NSColor, isEnabled: Bool = true, revealRequest: Int = 0, choose: @escaping (Int) -> Void) {
        self.library = library; self.choose = choose
        let available = library.eligibleScenes
        let changedNames = scenes != available || names != available.map { library.sceneNames[$0] }
        let changedEnabled = controlsEnabled != isEnabled
        controlsEnabled = isEnabled
        let changedStyle = self.selected != selected || self.accent != accent || buttonBackground != background
        if changedNames {
            scenes = available
            names = available.map { library.sceneNames[$0] }
            positions = Dictionary(uniqueKeysWithValues: available.enumerated().map { ($0.element, $0.offset) })
            var position: CGFloat = 0
            starts = []; widths = []
            let font = NSFont.systemFont(ofSize: 12, weight: .medium)
            for name in names {
                let width = ceil((name as NSString).size(withAttributes: [.font: font]).width) + 72
                starts.append(position); widths.append(width); position += width + 6
            }
            rowWidth = max(0, position - 6)
            updateCanvasWidth()
            // A newly filtered list starts at its own left edge; ordinary selections stay still.
            contentView.scroll(to: .zero); reflectScrolledClipView(contentView)
            buttons.values.forEach { $0.removeFromSuperview() }; buttons.removeAll()
        }
        self.selected = selected; self.accent = accent; buttonBackground = background
        if self.revealRequest != revealRequest, let position = positions[selected] {
            let x = min(starts[position], max(0, canvas.frame.width - contentView.bounds.width))
            contentView.scroll(to: NSPoint(x: x, y: 0)); reflectScrolledClipView(contentView)
        }
        self.revealRequest = revealRequest
        showVisibleButtons()
        if changedStyle || changedEnabled { for (index, button) in buttons { style(button, index: index) } }
    }
    private func updateCanvasWidth() {
        viewportWidth = contentView.bounds.width
        let trailingSpace = max(0, viewportWidth - (widths.last ?? 0))
        canvas.frame = NSRect(x: 0, y: 0, width: max(viewportWidth, rowWidth + trailingSpace), height: max(62, contentView.bounds.height))
    }
    private func style(_ button: PresetStripButton, index: Int) {
        button.isEnabled = controlsEnabled
        button.isSelected = scenes[index] == selected; button.accent = accent; button.fill = buttonBackground
        button.needsDisplay = true
    }
    private func showVisibleButtons() {
        guard let library, !starts.isEmpty else { return }
        let visible = contentView.bounds.insetBy(dx: -100, dy: 0)
        // Binary search avoids scanning the full library on every scroll event.
        var low = 0, high = starts.count
        while low < high { let middle = (low + high) / 2; if starts[middle] + widths[middle] < visible.minX { low = middle + 1 } else { high = middle } }
        var wanted = Set<Int>(), index = low
        while index < starts.count && starts[index] < visible.maxX { wanted.insert(index); index += 1 }
        for index in Array(buttons.keys) where !wanted.contains(index) { buttons.removeValue(forKey: index)?.removeFromSuperview() }
        for index in wanted.sorted() {
            let button: PresetStripButton
            if let existing = buttons[index] { button = existing } else {
                let scene = scenes[index]
                button = PresetStripButton()
                button.title = names[index]; button.setAccessibilityLabel(names[index])
                button.image = NSImage(systemSymbolName: library.icon(for: scene), accessibilityDescription: nil)?.withSymbolConfiguration(.init(pointSize: 27, weight: .light))
                button.toolTip = library.preset(for: scene)?.originalTitle ?? names[index]
                button.tag = scene; button.target = self; button.action = #selector(pick(_:))
                buttons[index] = button; canvas.addSubview(button); style(button, index: index)
            }
            button.frame = NSRect(x: starts[index], y: (canvas.frame.height - 62) / 2, width: widths[index], height: 62)
        }
    }
    @objc private func pick(_ sender: NSButton) { if controlsEnabled { choose?(sender.tag) } }
}

private final class PresetStripButton: NSButton {
    var isSelected = false
    var accent = NSColor.systemPink
    var fill = NSColor.windowBackgroundColor
    override init(frame: NSRect) { super.init(frame: frame); isBordered = false; setButtonType(.momentaryPushIn) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 0.5, dy: 0.5), path = NSBezierPath(roundedRect: rect, xRadius: 9, yRadius: 9)
        (isSelected ? accent.withAlphaComponent(0.13) : fill.withAlphaComponent(0.65)).setFill(); path.fill()
        (isSelected ? accent.withAlphaComponent(0.8) : NSColor.white.withAlphaComponent(0.08)).setStroke(); path.lineWidth = 1; path.stroke()
        let color = isSelected ? accent : NSColor(red: 0.79, green: 0.69, blue: 0.89, alpha: 1)
        if let image {
            let size = image.size
            let scale = min(32 / max(1, size.width), 32 / max(1, size.height))
            let icon = NSRect(x: 10 + (42 - size.width * scale) / 2, y: (bounds.height - size.height * scale) / 2, width: size.width * scale, height: size.height * scale)
            image.withSymbolConfiguration(.init(paletteColors: [color]))?.draw(in: icon)
        }
        let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: NSColor.white]
        let size = (title as NSString).size(withAttributes: attributes)
        (title as NSString).draw(at: NSPoint(x: 62, y: (bounds.height - size.height) / 2), withAttributes: attributes)
    }
}

private final class PresetStripObservation: @unchecked Sendable {
    let token: NSObjectProtocol
    init(_ token: NSObjectProtocol) { self.token = token }
    deinit { NotificationCenter.default.removeObserver(token) }
}
