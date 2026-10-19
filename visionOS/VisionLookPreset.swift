import Foundation

extension VisionLook {
    init(_ preset: VisualPreset) {
        self.init(scene: NativeEffects.defaultScene)
        zoom = preset.zoom; speed = preset.speed; zoomSpeed = preset.zoomSpeed; chaos = preset.chaos
        brightness = preset.brightness; size = preset.particleSize; detail = preset.liquidDetail
        fog = preset.fog; palette = preset.palette; rotation = preset.rotation; motionBlur = preset.motionBlur
        haloCount = preset.haloCount; strobeEnabled = preset.strobeEnabled
        strobeSensitivity = preset.strobeSensitivity; strobeStrength = preset.strobeStrength
    }
    var preset: VisualPreset {
        VisualPreset(speed: speed, brightness: brightness, particleSize: size, palette: palette,
            fog: fog, rotation: rotation, zoom: zoom, motionBlur: motionBlur,
            strobeEnabled: strobeEnabled, strobeSensitivity: strobeSensitivity, strobeStrength: strobeStrength,
            chaos: chaos, liquidDetail: detail, zoomSpeed: zoomSpeed, haloCount: haloCount)
    }
}

