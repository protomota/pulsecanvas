import Foundation
import AppKit
import SwiftUI
@main struct PresetStripSmoke {
    @MainActor static func main() {
        _ = NSApplication.shared
        let library = ProjectMPresets.shared
        let strip = PresetStripView(frame: NSRect(x:0,y:0,width:1000,height:90))
        precondition(strip.hasHorizontalScroller && !strip.autohidesScrollers && strip.scrollerStyle == .legacy, "The library row needs a persistent scrollbar")
        var chosen = -1
        for scene in [10, 2000, library.sceneNames.count - 1, 22, 7000] where library.availableScenes.contains(scene) {
            let beforeSelection = strip.contentView.bounds.origin.x
            strip.update(library:library,selected:scene,accent:.systemPink,background:.black) {chosen=$0}
            strip.layoutSubtreeIfNeeded()
            precondition(abs(strip.contentView.bounds.origin.x - beforeSelection) < 1, "Selecting a visualizer must not jump the row")
            let font = NSFont.systemFont(ofSize:12,weight:.medium)
            let position = library.availableScenes.firstIndex(of: scene)!
            let start = library.availableScenes.prefix(position).map { library.sceneNames[$0] }.reduce(CGFloat(0)) { $0 + ceil(($1 as NSString).size(withAttributes:[.font:font]).width) + 78 }
            strip.contentView.scroll(to: NSPoint(x:min(start,max(0,strip.documentView!.frame.width-strip.contentView.bounds.width)),y:0))
            strip.reflectScrolledClipView(strip.contentView)
            strip.layoutSubtreeIfNeeded()
            let buttons = strip.documentView!.subviews.compactMap {$0 as? NSButton}
            precondition(!buttons.isEmpty && buttons.count < 20, "The row must only instantiate visible buttons")
            let selected = buttons.first {$0.tag == scene}!
            let textWidth = (selected.title as NSString).size(withAttributes:[.font:NSFont.systemFont(ofSize:12,weight:.medium)]).width
            precondition(selected.frame.width >= textWidth + 71 && selected.frame.height == 62)
            precondition(strip.contentView.bounds.intersects(selected.frame), "Large jumps must reach the selected preset directly")
            precondition(strip.contentView.bounds.contains(selected.frame), "Scrollbar must not clip the selected card")
            precondition(selected.accessibilityLabel() == library.sceneNames[scene] && selected.toolTip != nil)
            selected.performClick(nil)
            precondition(chosen == scene, "Entire native button sends its own preset identity")
        }
        let beforeResize = strip.contentView.bounds.origin.x
        strip.frame.size.width = 650
        strip.layoutSubtreeIfNeeded()
        precondition(abs(strip.contentView.bounds.origin.x - beforeResize) < 1, "Resize must preserve the browsing position")
        for (request, scene) in [10, 22, library.sceneNames.count - 1].enumerated() {
            strip.update(library:library,selected:scene,accent:.systemPink,background:.black,revealRequest:request + 1) {chosen=$0}
            strip.layoutSubtreeIfNeeded()
            let revealed = strip.documentView!.subviews.compactMap {$0 as? NSButton}.first {$0.tag == scene}!
            precondition(abs(revealed.frame.minX - strip.contentView.bounds.minX) < 1, "Randomizer reveal must align left")
        }
        let beforeNormalSelection = strip.contentView.bounds.origin.x
        strip.update(library:library,selected:22,accent:.systemPink,background:.black,isEnabled:false,revealRequest:3) {chosen=$0}
        precondition(abs(strip.contentView.bounds.origin.x - beforeNormalSelection) < 1, "Normal selection after randomize must stay still")
        precondition(strip.documentView!.subviews.compactMap {$0 as? NSButton}.allSatisfy {!$0.isEnabled})
        print("PASS virtual preset row: persistent scrollbar; ordinary selection and resize stay still; randomizer reveal aligns left; fewer than 20 resident controls; full names; accessible whole-card actions")
    }
}
