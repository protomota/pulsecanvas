import Foundation
// SwiftPM supplies Bundle.module for its resource bundle. Xcode app builds
// copy the same Resources folder directly into Contents/Resources.
extension Bundle { static var module: Bundle { .main } }
