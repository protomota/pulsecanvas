import Foundation

struct VisualPreset: Codable, Equatable {
    var isValid: Bool {
        [speed, brightness, particleSize, fog, rotation, zoom, motionBlur, strobeSensitivity, strobeStrength, chaos, liquidDetail, zoomSpeed].allSatisfy { $0.isFinite } && (0...4).contains(palette) && (0...1).contains(chaos) && (0...1).contains(liquidDetail) && (0...3).contains(zoomSpeed) && (1...12).contains(haloCount)
    }
    var speed: Float = 1
    var brightness: Float = 1
    var particleSize: Float = 1
    var palette: Int = 0
    var fog: Float = 0.5
    var rotation: Float = 0
    var zoom: Float = 1
    var motionBlur: Float = 0
    var strobeEnabled = false
    var strobeSensitivity: Float = 1
    var strobeStrength: Float = 1
    var chaos: Float = 0.5
    var liquidDetail: Float = 0.6
    var zoomSpeed: Float = 1.5
    var haloCount: Int = 6
}

// Projects saved before the Chaos control retain a balanced beat response.
extension VisualPreset {
    enum CodingKeys: String, CodingKey {
        case speed, brightness, particleSize, palette, fog, rotation, zoom, motionBlur
        case strobeEnabled, strobeSensitivity, strobeStrength, chaos, liquidDetail, zoomSpeed, haloCount
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(speed: try values.decode(Float.self, forKey: .speed),
                  brightness: try values.decode(Float.self, forKey: .brightness),
                  particleSize: try values.decode(Float.self, forKey: .particleSize),
                  palette: try values.decode(Int.self, forKey: .palette),
                  fog: try values.decode(Float.self, forKey: .fog),
                  rotation: try values.decode(Float.self, forKey: .rotation),
                  zoom: try values.decode(Float.self, forKey: .zoom),
                  motionBlur: try values.decode(Float.self, forKey: .motionBlur),
                  strobeEnabled: try values.decode(Bool.self, forKey: .strobeEnabled),
                  strobeSensitivity: try values.decode(Float.self, forKey: .strobeSensitivity),
                  strobeStrength: try values.decode(Float.self, forKey: .strobeStrength),
                  chaos: try values.decodeIfPresent(Float.self, forKey: .chaos) ?? 0.5,
                  liquidDetail: try values.decodeIfPresent(Float.self, forKey: .liquidDetail) ?? 0.6,
                  zoomSpeed: try values.decodeIfPresent(Float.self, forKey: .zoomSpeed) ?? 1.5,
                  haloCount: try values.decodeIfPresent(Int.self, forKey: .haloCount) ?? 6)
    }
}

@MainActor
extension VisualPreset {
    /// One default profile serves the editor, reset and Studio export. Existing
    /// saved appearances take precedence; changing defaults cannot overwrite them.
    static func defaults(for scene: Int) -> VisualPreset {
        if scene >= RenderState.nativeSceneNames.count { return VisualPreset(chaos: 1, zoomSpeed: 0) }
        var result = VisualPreset()
        if let look = NativeEffects.effect(scene)?.look {
            result.palette = look.palette; result.particleSize = look.size
            result.speed = look.speed; result.zoomSpeed = look.zoomSpeed
            result.brightness = look.brightness; result.fog = look.fog
            result.liquidDetail = look.detail; result.chaos = look.chaos; result.zoom = look.zoom
        }
        return result
    }
}

@MainActor
extension VisualPreset {
    func apply(to render: RenderState) {
        let saved = self
        render.chaos = saved.chaos
        render.liquidDetail = saved.liquidDetail
        render.zoomSpeed = saved.zoomSpeed
        render.haloCount = saved.haloCount
        render.speed = saved.speed; render.brightness = saved.brightness; render.particleSize = saved.particleSize
        render.palette = saved.palette; render.fog = saved.fog; render.rotation = saved.rotation
        render.zoom = saved.zoom; render.motionBlur = saved.motionBlur
        render.strobeEnabled = saved.strobeEnabled; render.strobeSensitivity = saved.strobeSensitivity; render.strobeStrength = saved.strobeStrength
    }
}


@MainActor extension VisualPreset {
    init(render: RenderState) {
        self.init(speed: render.speed, brightness: render.brightness, particleSize: render.particleSize,
            palette: render.palette, fog: render.fog, rotation: render.rotation, zoom: render.zoom,
            motionBlur: render.motionBlur, strobeEnabled: render.strobeEnabled,
            strobeSensitivity: render.strobeSensitivity, strobeStrength: render.strobeStrength,
            chaos: render.chaos, liquidDetail: render.liquidDetail, zoomSpeed: render.zoomSpeed, haloCount: render.haloCount)
    }

    /// Fresh looks share one range on Mac and Vision Pro. Flashing always requires
    /// an explicit choice; the style dice can preserve an existing strobe toggle.
    static func randomized(strobeEnabled: Bool = false) -> VisualPreset {
        VisualPreset(speed: .random(in: 0.6...2.1), brightness: .random(in: 0.85...1.5),
            particleSize: .random(in: 0.8...2.4), palette: .random(in: 0...4),
            fog: .random(in: 0.08...0.6), rotation: .random(in: -.pi...(.pi)),
            zoom: .random(in: 0.75...1.4), motionBlur: .random(in: 0...0.25),
            strobeEnabled: strobeEnabled, strobeSensitivity: .random(in: 0.6...2.4),
            strobeStrength: .random(in: 0.35...1), chaos: .random(in: 0.35...1),
            liquidDetail: .random(in: 0.3...1), zoomSpeed: .random(in: 0.5...2.5), haloCount: .random(in: 2...12))
    }
}
