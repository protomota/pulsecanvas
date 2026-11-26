import Foundation
import simd

/// Fixed color stops, shared by every geometry and shader family.
enum VisualPalette: Int, CaseIterable {
    case ultraviolet, electricCandy, emberlight, blueHour, fernlight

    var title: String {
        switch self {
        case .ultraviolet: return "Ultraviolet"
        case .electricCandy: return "Electric Candy"
        case .emberlight: return "Emberlight"
        case .blueHour: return "Blue Hour"
        case .fernlight: return "Fernlight"
        }
    }

    var stops: [SIMD3<Float>] {
        Self.gradients[rawValue]
    }

    private static let gradients: [[SIMD3<Float>]] = [
        // Three anchor hues retain each palette's identity; two accents add contrast.
        [UInt32(0x44209D), 0xB34FF0, 0xFF9B78, 0x45E1CA, 0x9956EB],
        [0x05F5E5, 0x51FF95, 0xE6FF38, 0xFF3FBA, 0x9B49FF],
        [0xA51E32, 0xF5682D, 0xFFD267, 0xD966AC, 0x52CFC8],
        [0x142E91, 0x3376EF, 0x55D9DF, 0xFFB66D, 0x678DF6],
        [0x165A43, 0x38B771, 0xBCE76B, 0xFFBB82, 0x9D83EB]
    ].map { hex in hex.map { SIMD3(Float(($0 >> 16) & 255), Float(($0 >> 8) & 255), Float($0 & 255)) / 255 } }

    static func color(_ position: Float, palette: Int) -> SIMD4<Float> {
        let stops = (VisualPalette(rawValue: palette) ?? .ultraviolet).stops
        // Ping-pong through the stops so animation never introduces unrelated hues.
        let p = position.isFinite ? position : 0
        let cycle = p - floor(p / 2) * 2
        let location = (cycle <= 1 ? cycle : 2 - cycle) * Float(stops.count - 1)
        let first = min(stops.count - 1, Int(location))
        let second = min(stops.count - 1, first + 1)
        let rgb = stops[first] + (stops[second] - stops[first]) * (location - Float(first))
        return SIMD4(rgb, 1)
    }
}
