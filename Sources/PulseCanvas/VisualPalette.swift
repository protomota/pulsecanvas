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
        [UInt32(0x312078), 0x7341D9, 0xD646E8, 0xFF70C7, 0x7341D9],
        [0x05F5E5, 0x51FF95, 0xE6FF38, 0xFF3FBA, 0x9B49FF],
        [0xA71317, 0xED3024, 0xFF761B, 0xFFCC37, 0xFFF0AA],
        [0x102C85, 0x1757D9, 0x278EFF, 0x58C0FF, 0xA6DEFF],
        [0x145233, 0x25824A, 0x45BA59, 0x93D963, 0xD4EF99]
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
