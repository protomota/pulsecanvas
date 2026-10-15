import Foundation

/// One native visualizer. Its index in `NativeEffects.all` is its permanent scene ID:
/// saved projects, favorites and Studio timelines store `native:<index>`, so entries
/// are only ever appended. External presets follow the native catalog.
struct NativeEffect: Sendable {
    /// Default appearance for a newly opened effect. Saved settings always win.
    struct Look: Sendable {
        var palette = 0
        var size: Float = 1
        var speed: Float = 1
        var zoomSpeed: Float = 1
        var brightness: Float = 1.15
        var fog: Float = 0.5
        var detail: Float = 0.6
        var chaos: Float = 0.6
        var zoom: Float = 1
    }

    let name: String
    let icon: String
    /// Fragment function `<shader>Fragment` in `file`; nil for the original mesh, point and spatial families.
    let shader: String?
    let file: String?
    /// Label for the shared size control.
    let sizeLabel: String
    /// Label for the detail control, when the design uses it.
    let detailLabel: String?
    /// The design moves through its own space for Zoom speed, so no post-zoom pass is applied.
    let travels: Bool
    let look: Look
    /// Set when a design has been withdrawn. Its ID stays reserved, and saved projects,
    /// favorites and timelines that name it open this design instead.
    var replacement: Int? = nil

    static func original(_ name: String, icon: String, size: String = "Particle size", detail: String? = nil, travels: Bool = false, look: Look) -> NativeEffect {
        NativeEffect(name: name, icon: icon, shader: nil, file: nil, sizeLabel: size, detailLabel: detail, travels: travels, look: look)
    }

    static func retired(_ name: String, icon: String, replacement: Int) -> NativeEffect {
        NativeEffect(name: name, icon: icon, shader: nil, file: nil, sizeLabel: "Particle size", detailLabel: nil, travels: false, look: Look(), replacement: replacement)
    }

    static func metal(_ name: String, icon: String, _ shader: String, in file: String, size: String, detail: String? = nil, travels: Bool = true, look: Look) -> NativeEffect {
        NativeEffect(name: name, icon: icon, shader: shader, file: file, sizeLabel: size, detailLabel: detail, travels: travels, look: look)
    }
}

enum NativeEffects {
    // Compatibility with retained development tools.
    static var activeScenes: [Int] { activeIDs }
    static var activeCount: Int { activeIDs.count }
    /// Native effect sources, each compiled after NativeCommon.metal.
    static let shaderFiles = ["NativeFlow.metal", "NativeStructure.metal", "NativeGeometry.metal", "NativeParticles.metal", "NativeNature.metal",
                              "NativeTunnels.metal", "NativeWormholes.metal", "NativeDrive.metal", "NativeDance.metal", "NativeRave.metal", "NativeExpansionDrive.metal", "NativeExpansionDance.metal", "NativeExpansionVoyage.metal", "NativeExpansionPassage.metal", "NativeExpansionFestival.metal",
                              "NativeExpansionBore.metal", "NativeExpansionPortal.metal", "NativeExpansionKinetic.metal", "NativeExpansionFlight.metal", "NativeExpansionMaterial.metal", "NativeExpansionCosmos.metal",
                              "NativeExpansionFractal.metal", "NativeExpansionFractalTunnel.metal",
                              "NativeExpansionPortalII.metal", "NativeExpansionFlightII.metal", "NativeExpansionMaterialII.metal", "NativeExpansionCosmosII.metal"]
    /// Projects saved before the catalog grew store external presets from this index.
    static let legacyCount = 31

    private static let flow = "NativeFlow.metal", structure = "NativeStructure.metal", geometry = "NativeGeometry.metal"
    private static let particles = "NativeParticles.metal", nature = "NativeNature.metal"
    private static let tunnels = "NativeTunnels.metal", wormholes = "NativeWormholes.metal", drive = "NativeDrive.metal"
    private static let dance = "NativeDance.metal", rave = "NativeRave.metal"
    private static let driveExpansion = "NativeExpansionDrive.metal"
    private static let danceExpansion = "NativeExpansionDance.metal"
    private static let voyageExpansion = "NativeExpansionVoyage.metal"
    private static let passageExpansion = "NativeExpansionPassage.metal"
    private static let festivalExpansion = "NativeExpansionFestival.metal"
    private static let boreExpansion = "NativeExpansionBore.metal"
    private static let portalExpansion = "NativeExpansionPortal.metal"
    private static let kineticExpansion = "NativeExpansionKinetic.metal"
    private static let flightExpansion = "NativeExpansionFlight.metal"
    private static let materialExpansion = "NativeExpansionMaterial.metal"
    private static let cosmosExpansion = "NativeExpansionCosmos.metal"
    private static let fractalExpansion = "NativeExpansionFractal.metal"
    private static let fractalTunnelExpansion = "NativeExpansionFractalTunnel.metal"
    private static let portalIIExpansion = "NativeExpansionPortalII.metal"
    private static let flightIIExpansion = "NativeExpansionFlightII.metal"
    private static let materialIIExpansion = "NativeExpansionMaterialII.metal"
    private static let cosmosIIExpansion = "NativeExpansionCosmosII.metal"
    private typealias L = NativeEffect.Look
    /// Released designs keep their original Chaos and zoom-speed defaults; only exposure,
    /// fog and palette are tuned so each opens with an attractive look.
    private static func legacy(_ palette: Int, _ brightness: Float, fog: Float = 0.5, size: Float = 1, zoom: Float = 1) -> L {
        L(palette: palette, size: size, speed: 1, zoomSpeed: 1.5, brightness: brightness, fog: fog, detail: 0.6, chaos: 0.5, zoom: zoom)
    }

    static let all: [NativeEffect] = [
        // Red Finder labels in the review folder are the keeper list. Withdrawn IDs
        // remain reserved so existing projects resolve to an offered effect.
        .retired("Prism Wake", icon: "pyramid", replacement: 20),
        .retired("Lumen Veil", icon: "sun.haze", replacement: 10),
        .retired("Pulse Well", icon: "circle.circle", replacement: 22),
        .retired("Velvet Passage", icon: "torus", replacement: 29),
        .retired("Bead Surge", icon: "circle.grid.hex", replacement: 101),
        .retired("Facet Flow", icon: "diamond", replacement: 23),
        .retired("Glass Current", icon: "circle.square", replacement: 29),
        .retired("Contour Flux", icon: "waveform.path", replacement: 17),
        .retired("Recursive Corridor", icon: "square.stack.3d.up", replacement: 22),
        .retired("Spiral Tide", icon: "hurricane", replacement: 25),
        .original("Aurora Fold", icon: "sun.horizon", travels: true, look: legacy(4, 1.4, fog: 0.3)),
        .retired("Petal Passage", icon: "rosette", replacement: 15),
        .original("Pearl Terrain", icon: "circle.hexagongrid", travels: true, look: legacy(3, 1.2, fog: 0.4)),
        .retired("Vapor Run", icon: "wind", replacement: 10),
        .retired("Scatter Flight", icon: "point.3.connected.trianglepath.dotted", replacement: 101),
        .original(OriginalGeometry.Scene.audioMandala.title, icon: "asterisk", look: legacy(2, 2)),
        .original(OriginalGeometry.Scene.orbitalRings.title, icon: "atom", look: legacy(3, 2)),
        .original(OriginalGeometry.Scene.ribbonWave.title, icon: "wave.3.right", look: legacy(1, 1.9)),
        .original(OriginalGeometry.Scene.spectralHelix.title, icon: "infinity", look: legacy(0, 1.7, size: 1.6, zoom: 1.05)),
        .original(OriginalGeometry.Scene.particleFountain.title, icon: "burst", look: legacy(2, 1.8, size: 1.6, zoom: 1.05)),
        .original(OriginalGeometry.Scene.pulseGrid.title, icon: "square.grid.3x3", look: legacy(3, 1.8)),
        .original(OriginalGeometry.Scene.harmonicBloom.title, icon: "snowflake", look: legacy(4, 1.3)),
        .original("Octagon Vault", icon: "circle.hexagonpath", size: "Line width", travels: true, look: legacy(1, 1.2)),
        .original("Mercury Fold", icon: "drop", size: "Surface thickness", detail: "Liquid detail", look: legacy(3, 1.2)),
        .original("Voltage Weave", icon: "bolt.horizontal", travels: true, look: legacy(0, 1)),
        .original("Ink Cyclone", icon: "tornado", travels: true, look: legacy(2, 1)),
        .original("Prism Rain", icon: "rainbow", travels: true, look: legacy(1, 1.3)),
        .original("Monolith Rush", icon: "cube", travels: true, look: legacy(3, 1.2)),
        .original("Halo Engine", icon: "circle.dotted.circle", size: "Ring thickness", travels: true, look: legacy(2, 1.3)),
        .original("Tidal Glass", icon: "water.waves", travels: true, look: legacy(3, 1.1)),
        .retired("Grid Vortex", icon: "squareshape.dashed.squareshape", replacement: 22),
        .metal("Silk Cascade", icon: "scribble", "silkCascade", in: flow, size: "Fold scale", detail: "Sheen", look: L(palette: 3, size: 1.1, speed: 0.8, zoomSpeed: 0.6)),
        .metal("Chrome Reef", icon: "circle.hexagongrid.fill", "chromeReef", in: structure, size: "Coral scale", look: L(palette: 3, speed: 0.8, zoomSpeed: 0.9)),
        .metal("Ribbon Foundry", icon: "scribble.variable", "ribbonFoundry", in: flow, size: "Ribbon width", look: L(palette: 2, speed: 0.9, zoomSpeed: 0.8)),
        .retired("Electric Orchard", icon: "tree", replacement: 101),
        .retired("Glass Mosaic", icon: "rectangle.split.3x3", replacement: 101),
        .retired("Graviton Petals", icon: "camera.macro", replacement: 101),
        .retired("Ion Cathedral", icon: "building.columns", replacement: 101),
        .retired("Velvet Circuit", icon: "cpu", replacement: 101),
        .retired("Lunar Loom", icon: "moon", replacement: 101),
        .retired("Lava Estuary", icon: "flame", replacement: 101),
        .retired("Photon Rapids", icon: "sparkles", replacement: 101),
        .metal("Sonic Topography", icon: "map", "sonicTopography", in: nature, size: "Terrain scale", look: L(palette: 4, speed: 0.8, zoomSpeed: 1)),
        .metal("Prismatic Dunes", icon: "mountain.2", "prismaticDunes", in: nature, size: "Dune scale", look: L(palette: 2, speed: 0.7, zoomSpeed: 1, fog: 0.4)),
        .retired("Honeycomb Tide", icon: "hexagon", replacement: 101),
        .retired("Nebula Nursery", icon: "sparkle", replacement: 101),
        .metal("Crystal Orchard", icon: "triangle", "crystalOrchard", in: nature, size: "Crystal size", look: L(palette: 3, speed: 0.75, zoomSpeed: 0.9)),
        .metal("Opal Tessera", icon: "seal", "opalTessera", in: geometry, size: "Tile size", look: L(palette: 1, speed: 0.75, zoomSpeed: 0.6)),
        .metal("Velvet Nebula", icon: "cloud", "velvetNebula", in: nature, size: "Pillar scale", look: L(palette: 2, speed: 0.6, zoomSpeed: 0.7, fog: 0.55)),
        .retired("Arc Foundry", icon: "bolt.circle", replacement: 101),
        .metal("Magnetic Ballet", icon: "oval", "magneticBallet", in: particles, size: "Field density", look: L(palette: 3, speed: 0.8, zoomSpeed: 0.6)),
        .retired("Paper Cascades", icon: "square.3.layers.3d", replacement: 101),
        .retired("Diamond Undertow", icon: "rhombus", replacement: 101),
        .retired("Fractal Canopy", icon: "arrow.triangle.branch", replacement: 101),
        .retired("Gyroscopic Garden", icon: "rotate.3d", replacement: 101),
        .retired("Bubble Choir", icon: "bubbles.and.sparkles", replacement: 101),
        .retired("Laser Origami", icon: "paperplane", replacement: 101),
        .retired("Echo Lanterns", icon: "lightbulb", replacement: 101),
        .retired("Kelp Cathedral", icon: "leaf", replacement: 101),
        .retired("Solar Filigree", icon: "sun.max", replacement: 101),
        .metal("Mandel Bloom", icon: "circle.dashed", "mandelBloom", in: geometry, size: "Bloom scale", detail: "Fractal detail", look: L(palette: 0, speed: 0.7, zoomSpeed: 0.6)),
        .metal("Menger Nave", icon: "square.grid.3x3.fill", "mengerNave", in: geometry, size: "Vault scale", look: L(palette: 2, speed: 0.8, zoomSpeed: 1, fog: 0.45)),
        .retired("Apollonian Foam", icon: "circle.grid.3x3", replacement: 101),
        .retired("Hyperbolic Rosette", icon: "smallcircle.filled.circle", replacement: 101),
        .metal("Quasicrystal Bloom", icon: "staroflife", "quasicrystalBloom", in: geometry, size: "Wave scale", look: L(palette: 0, speed: 0.8, zoomSpeed: 0.7)),
        .retired("Tesseract Garden", icon: "cube.transparent", replacement: 101),
        .retired("Harmonograph", icon: "lasso", replacement: 101),
        .retired("Moire Engine", icon: "circle.lefthalf.filled", replacement: 101),
        .retired("Riley Undulation", icon: "line.3.horizontal", replacement: 101),
        .retired("Kaleido Chamber", icon: "camera.aperture", replacement: 101),
        .retired("Girih Lattice", icon: "star", replacement: 101),
        .retired("Gear Works", icon: "gearshape.2", replacement: 101),
        .metal("Piston Hall", icon: "engine.combustion", "pistonHall", in: structure, size: "Piston scale", look: L(palette: 3, speed: 0.9, zoomSpeed: 0.9, fog: 0.45)),
        .retired("Orrery Engine", icon: "globe", replacement: 101),
        .metal("Space Frame", icon: "square.split.diagonal.2x2", "spaceFrame", in: structure, size: "Beam width", look: L(palette: 3, speed: 0.8, zoomSpeed: 1.2, fog: 0.5)),
        .retired("Brutalist Shift", icon: "building.2", replacement: 101),
        .retired("Rose Window", icon: "rays", replacement: 101),
        .retired("Zen Rake", icon: "line.3.horizontal.decrease", replacement: 101),
        .retired("Ferrofluid Crown", icon: "drop.fill", replacement: 101),
        .metal("Windowpane Drizzle", icon: "cloud.rain", "windowpaneDrizzle", in: flow, size: "Drop size", look: L(palette: 1, speed: 0.8, zoomSpeed: 0.6)),
        .metal("Ink Bloom", icon: "paintbrush", "inkBloom", in: flow, size: "Plume scale", look: L(palette: 3, speed: 0.7, zoomSpeed: 0.6)),
        .metal("Oil Marble", icon: "swirl.circle.righthalf.filled", "oilMarble", in: flow, size: "Swirl scale", look: L(palette: 1, speed: 0.7, zoomSpeed: 0.6)),
        .retired("Chladni Sand", icon: "dot.radiowaves.left.and.right", replacement: 101),
        .metal("Ripple Tank", icon: "circle.dotted", "rippleTank", in: flow, size: "Wave scale", look: L(palette: 3, speed: 0.8, zoomSpeed: 0.6)),
        .metal("Chrome Metaballs", icon: "drop.circle", "chromeMetaballs", in: flow, size: "Blob size", look: L(palette: 0, speed: 0.8, zoomSpeed: 0.7)),
        .metal("Ocean Swell", icon: "wave.3.forward", "oceanSwell", in: flow, size: "Swell scale", look: L(palette: 3, speed: 0.8, zoomSpeed: 0.9, fog: 0.45)),
        .metal("Plexus Constellations", icon: "point.3.filled.connected.trianglepath.dotted", "plexusConstellations", in: particles, size: "Star size", look: L(palette: 3, speed: 0.7, zoomSpeed: 0.9)),
        .retired("Murmuration", icon: "bird", replacement: 101),
        .metal("Ring Shepherds", icon: "circle.grid.cross", "ringShepherds", in: particles, size: "Ringlet width", look: L(palette: 2, speed: 0.7, zoomSpeed: 0.7)),
        .retired("Pendulum Wave", icon: "metronome", replacement: 101),
        .retired("Firework Garden", icon: "fireworks", replacement: 101),
        .metal("Event Horizon", icon: "smallcircle.circle", "eventHorizon", in: particles, size: "Disk width", look: L(palette: 2, speed: 0.7, zoomSpeed: 0.6)),
        .metal("Atom Lattice", icon: "circle.grid.3x3.fill", "atomLattice", in: structure, size: "Atom size", look: L(palette: 1, speed: 0.8, zoomSpeed: 1.1, fog: 0.5)),
        .retired("Mitosis Garden", icon: "allergens", replacement: 101),
        .retired("Neural Bloom", icon: "brain", replacement: 101),
        .retired("Jellyfish Abyss", icon: "umbrella", replacement: 101),
        .retired("Glacier Rift", icon: "snowflake.circle", replacement: 101),
        .retired("Firefly Meadow", icon: "moon.zzz", replacement: 101),
        .metal("Synth Horizon", icon: "sunset", "synthHorizon", in: structure, size: "Grid scale", look: L(palette: 1, speed: 0.9, zoomSpeed: 1.2)),
        .retired("Neon Calligraphy", icon: "signature", replacement: 101),
        .metal("Plasma Bore", icon: "circle.dashed.inset.filled", "plasmaBore", in: tunnels, size: "Plasma scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, fog: 0.45)),
        .metal("LED Corridor", icon: "square.grid.4x3.fill", "ledCorridor", in: tunnels, size: "Pixel size", look: L(palette: 1, speed: 1, zoomSpeed: 1.4, fog: 0.4)),
        .metal("Prism Shaft", icon: "triangle.fill", "prismShaft", in: tunnels, size: "Facet scale", look: L(palette: 0, speed: 0.9, zoomSpeed: 1.2, fog: 0.45)),
        .metal("Hyperloop", icon: "tram.tunnel.fill", "hyperloop", in: tunnels, size: "Ring spacing", look: L(palette: 3, speed: 1.1, zoomSpeed: 1.6, fog: 0.35)),
        .metal("Barrel Wave", icon: "wave.3.left", "barrelWave", in: tunnels, size: "Curl scale", look: L(palette: 3, speed: 0.9, zoomSpeed: 1.1, fog: 0.4)),
        .metal("Magma Tube", icon: "flame.fill", "magmaTube", in: tunnels, size: "Crust scale", look: L(palette: 2, speed: 0.8, zoomSpeed: 1, fog: 0.45)),
        .metal("Data Conduit", icon: "memorychip", "dataConduit", in: tunnels, size: "Trace width", look: L(palette: 4, speed: 1, zoomSpeed: 1.5, fog: 0.4)),
        .metal("Helix Stair", icon: "stairs", "helixStair", in: tunnels, size: "Step size", look: L(palette: 0, speed: 0.8, zoomSpeed: 1, fog: 0.5)),
        .retired("Mirror Regress", icon: "rectangle.on.rectangle", replacement: 101),
        .metal("Laser Bore", icon: "bolt.horizontal.fill", "laserBore", in: tunnels, size: "Beam width", look: L(palette: 1, speed: 1.1, zoomSpeed: 1.4, fog: 0.35)),
        .metal("Twist Checker", icon: "checkerboard.rectangle", "twistChecker", in: tunnels, size: "Tile size", look: L(palette: 2, speed: 1, zoomSpeed: 1.3, fog: 0.4)),
        .metal("Foam Tube", icon: "bubbles.and.sparkles.fill", "foamTube", in: tunnels, size: "Bubble size", look: L(palette: 1, speed: 0.9, zoomSpeed: 1.1, fog: 0.45)),
        .metal("Polygon Stack", icon: "pentagon", "polygonStack", in: tunnels, size: "Edge width", look: L(palette: 0, speed: 1, zoomSpeed: 1.2, fog: 0.4)),
        .metal("Gyroid Caverns", icon: "aqi.medium", "gyroidCaverns", in: tunnels, size: "Cavern scale", look: L(palette: 0, speed: 0.8, zoomSpeed: 1, fog: 0.55)),
        .metal("Spectrum Bore", icon: "chart.bar.fill", "spectrumBore", in: tunnels, size: "Bar width", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, fog: 0.4)),
        .retired("Ribbon Vortex", icon: "wind", replacement: 101),
        .retired("Gate Run", icon: "building.columns.fill", replacement: 101),
        .metal("Storm Eye", icon: "cloud.bolt.fill", "stormEye", in: wormholes, size: "Cloud scale", look: L(palette: 3, speed: 0.9, zoomSpeed: 1.2, fog: 0.4)),
        .metal("Sonar Pipe", icon: "dot.radiowaves.forward", "sonarPipe", in: wormholes, size: "Ring spacing", look: L(palette: 3, speed: 0.9, zoomSpeed: 1.2, fog: 0.45)),
        .metal("Cube Helix", icon: "cube.fill", "cubeHelix", in: wormholes, size: "Cube size", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, fog: 0.45)),
        .metal("Phyllo Tube", icon: "camera.filters", "phylloTube", in: wormholes, size: "Dot size", look: L(palette: 4, speed: 0.9, zoomSpeed: 1.1, fog: 0.4)),
        .metal("Tesla Tube", icon: "bolt.fill", "teslaTube", in: wormholes, size: "Arc width", look: L(palette: 4, speed: 1, zoomSpeed: 1.2, fog: 0.4)),
        .metal("Fold Tunnel", icon: "paperplane.fill", "foldTunnel", in: wormholes, size: "Fold scale", look: L(palette: 4, speed: 0.9, zoomSpeed: 1.1, fog: 0.45)),
        .metal("Vector Tube", icon: "cylinder.split.1x2", "vectorTube", in: wormholes, size: "Line width", look: L(palette: 1, speed: 1.1, zoomSpeed: 1.5, fog: 0.35)),
        .metal("Orbital Corridor", icon: "rectangle.split.3x1", "orbitalCorridor", in: wormholes, size: "Panel scale", look: L(palette: 3, speed: 0.9, zoomSpeed: 1.2, fog: 0.5)),
        .metal("Mirrorball Tunnel", icon: "square.grid.3x3.square", "mirrorballTunnel", in: wormholes, size: "Tile size", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, fog: 0.4)),
        .retired("Fractal Throat", icon: "triangle.circle", replacement: 101),
        .metal("Chroma Pipe", icon: "capsule.fill", "chromaPipe", in: wormholes, size: "Ring width", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, fog: 0.35)),
        .retired("Coral Burrow", icon: "leaf.fill", replacement: 101),
        .metal("Rainbow Slide", icon: "figure.pool.swim", "rainbowSlide", in: wormholes, size: "Slide width", look: L(palette: 1, speed: 1.1, zoomSpeed: 1.6, fog: 0.3)),
        .metal("Pulse Arteries", icon: "heart.fill", "pulseArteries", in: wormholes, size: "Vessel width", look: L(palette: 2, speed: 0.9, zoomSpeed: 1.2, fog: 0.45)),
        .metal("Zebra Warp", icon: "line.3.horizontal.circle", "zebraWarp", in: wormholes, size: "Stripe width", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, fog: 0.35)),
        .metal("Pixel Tunnel", icon: "square.grid.2x2.fill", "pixelTunnel", in: wormholes, size: "Pixel size", look: L(palette: 1, speed: 1, zoomSpeed: 1.4, fog: 0.35)),
        .metal("Geode Passage", icon: "diamond.fill", "geodePassage", in: wormholes, size: "Crystal size", look: L(palette: 3, speed: 0.8, zoomSpeed: 1, fog: 0.5)),
        .retired("Night Highway", icon: "car.fill", replacement: 101),
        .retired("Neon Boulevard", icon: "building.2.crop.circle", replacement: 101),
        .retired("Desert Interstate", icon: "sun.dust.fill", replacement: 101),
        .retired("Mountain Switchbacks", icon: "mountain.2.fill", replacement: 101),
        .retired("Sodium Tunnel", icon: "lightbulb.fill", replacement: 101),
        .retired("Coastal Cruise", icon: "beach.umbrella", replacement: 101),
        .retired("Long Exposure", icon: "timelapse", replacement: 101),
        .metal("Neon Trails", icon: "bicycle", "neonTrails", in: drive, size: "Trail width", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, fog: 0.35)),
        .retired("Rally Forest", icon: "tree.fill", replacement: 101),
        .retired("Bridge Run", icon: "road.lanes", replacement: 101),
        .retired("Coaster Loop", icon: "point.topleft.down.curvedto.point.bottomright.up", replacement: 101),
        .retired("Hover Lanes", icon: "airplane", replacement: 101),
        .retired("Bullet Train", icon: "tram.fill", replacement: 101),
        .retired("Apex Chase", icon: "flag.checkered", replacement: 101),
        .retired("Snow Drive", icon: "cloud.snow.fill", replacement: 101),
        .retired("Dashboard Glow", icon: "gauge.with.dots.needle.67percent", replacement: 101),
        .retired("Midnight Skyline", icon: "building.2.fill", replacement: 101),
        .retired("Orbit Freeway", icon: "infinity.circle", replacement: 101),
        .retired("Canyon Run", icon: "map.fill", replacement: 101),
        .retired("Interchange", icon: "arrow.triangle.swap", replacement: 101),
        .retired("Lean Angle", icon: "scooter", replacement: 101),
        .retired("Runway Rush", icon: "airplane.departure", replacement: 101),
        .retired("Wake Racer", icon: "sailboat.fill", replacement: 101),
        .retired("Bobsled Chute", icon: "figure.skiing.downhill", replacement: 101),
        .retired("Rail Rush", icon: "train.side.front.car", replacement: 101),
        .retired("Starlane Convoy", icon: "moon.stars.fill", replacement: 101),
        .retired("Marquee Strip", icon: "star.circle.fill", replacement: 101),
        .retired("Sky Causeway", icon: "cloud.sun.fill", replacement: 101),
        .retired("Turbine Road", icon: "wind.circle.fill", replacement: 101),
        .retired("Chevron Rush", icon: "chevron.right.2", replacement: 101),
        .retired("Street Circuit", icon: "flag.2.crossed.fill", replacement: 101),
        .retired("Glider Valley", icon: "paperplane.circle.fill", replacement: 101),
        .retired("Rocket Sled", icon: "bolt.car.fill", replacement: 101),
        .retired("Groove Tiles", icon: "square.grid.3x3.topleft.filled", replacement: 101),
        .retired("Mirror Ball", icon: "light.beacon.max", replacement: 101),
        .retired("Drone Ballet", icon: "airplane.circle", replacement: 101),
        .retired("Ribbon Gymnast", icon: "figure.gymnastics", replacement: 101),
        .retired("Laser Haze", icon: "line.3.crossed.swirl.circle", replacement: 101),
        .retired("Moving Heads", icon: "light.cylindrical.ceiling.fill", replacement: 101),
        .retired("Conga Orbs", icon: "ellipsis.circle.fill", replacement: 101),
        .retired("Headspin", icon: "arrow.triangle.2.circlepath", replacement: 101),
        .retired("Waltz Pairs", icon: "figure.socialdance", replacement: 101),
        .metal("Pigment Burst", icon: "paintpalette.fill", "pigmentBurst", in: dance, size: "Cloud scale", look: L(palette: 1, speed: 0.9, zoomSpeed: 1, brightness: 1, fog: 0.4)),
        .retired("Pirouette Bloom", icon: "seal.fill", replacement: 101),
        .metal("Stretch Membrane", icon: "hand.raised.fill", "stretchMembrane", in: dance, size: "Bulge size", look: L(palette: 0, speed: 1, zoomSpeed: 1, brightness: 1, fog: 0.4)),
        .metal("Kinetic Mirrors", icon: "squares.below.rectangle", "kineticMirrors", in: dance, size: "Tile size", look: L(palette: 1, speed: 1, zoomSpeed: 1, fog: 0.4)),
        .metal("Fire Dance", icon: "flame.circle", "fireDance", in: dance, size: "Flame size", look: L(palette: 2, speed: 1, zoomSpeed: 1, fog: 0.4)),
        .retired("Chiffon Swirl", icon: "hurricane", replacement: 101),
        .metal("Fountain Show", icon: "humidity.fill", "fountainShow", in: dance, size: "Jet width", look: L(palette: 3, speed: 1, zoomSpeed: 1, fog: 0.4)),
        .metal("Glowstick Rave", icon: "wand.and.stars", "glowstickRave", in: dance, size: "Stick width", look: L(palette: 4, speed: 1.1, zoomSpeed: 1, fog: 0.4)),
        .metal("Smoke Rings", icon: "smoke.fill", "smokeRings", in: rave, size: "Ring size", look: L(palette: 3, speed: 1, zoomSpeed: 1.1, fog: 0.45)),
        .metal("Wand Orbs", icon: "camera.metering.spot", "wandOrbs", in: rave, size: "Orb size", look: L(palette: 1, speed: 1, zoomSpeed: 1, fog: 0.4)),
        .retired("Faraday Dish", icon: "aqi.low", replacement: 101),
        .metal("String Resonance", icon: "guitars.fill", "stringResonance", in: rave, size: "String width", look: L(palette: 2, speed: 1, zoomSpeed: 1, fog: 0.4)),
        .metal("Light Bars", icon: "rectangle.split.1x2.fill", "lightBars", in: rave, size: "Bar width", look: L(palette: 4, speed: 1, zoomSpeed: 1, fog: 0.45)),
        .metal("Sequin Curtain", icon: "rectangle.grid.3x2.fill", "sequinCurtain", in: rave, size: "Sequin size", look: L(palette: 1, speed: 1, zoomSpeed: 1, fog: 0.4)),
        .retired("Torsion Wave", icon: "wave.3.backward", replacement: 101),
        .retired("Spin Paint", icon: "paintbrush.pointed.fill", replacement: 101),
        .metal("Stadium Wave", icon: "wave.3.right.circle.fill", "stadiumWave", in: rave, size: "Ball size", look: L(palette: 1, speed: 1, zoomSpeed: 1.1, fog: 0.35)),
        .metal("Liquid Floor", icon: "drop.circle.fill", "liquidFloor", in: rave, size: "Ripple scale", look: L(palette: 3, speed: 1, zoomSpeed: 1, brightness: 1.2, fog: 0.4)),
        .retired("Confetti Storm", icon: "party.popper.fill", replacement: 101),
        .retired("Bokeh Club", icon: "circle.hexagonpath.fill", replacement: 101),
        .retired("Persistence Fans", icon: "fan.fill", replacement: 101),
        .metal("Domino Run", icon: "square.stack.3d.forward.dottedline.fill", "dominoRun", in: rave, size: "Domino size", look: L(palette: 1, speed: 1.1, zoomSpeed: 1.3, fog: 0.35)),
        .retired("Aerial Silks", icon: "figure.climbing", replacement: 101),
        .retired("Hula Hoops", icon: "smallcircle.filled.circle.fill", replacement: 101),
        .retired("Chromatic Speedway", icon: "road.lanes", replacement: 101),
        .metal("Iridescent Raceway", icon: "speedometer", "iridescentRaceway", in: driveExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.0, brightness: 1.35, fog: 0.25)),
        .metal("Cobalt Catapult", icon: "arrow.up.forward", "cobaltCatapult", in: driveExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.1, brightness: 1.35, fog: 0.25)),
        .metal("Tangerine Rocket", icon: "airplane", "tangerineRocket", in: driveExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.5, brightness: 1.35, fog: 0.25)),
        .metal("Prismatic Overdrive", icon: "pentagon", "prismaticOverdrive", in: driveExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.2, brightness: 1.35, fog: 0.25)),
        .metal("Scarlet Slipstream", icon: "flag.2.crossed", "scarletSlipstream", in: driveExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.0, brightness: 1.35, fog: 0.25)),
        .metal("Laser Autobahn", icon: "steeringwheel", "laserAutobahn", in: driveExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.2, brightness: 1.35, fog: 0.25)),
        .metal("Rainbow Riptide", icon: "sailboat", "rainbowRiptide", in: driveExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.1, brightness: 1.35, fog: 0.25)),
        .metal("Electric Switchback", icon: "arrow.triangle.swap", "electricSwitchback", in: driveExpansion, size: "Structure scale", look: L(palette: 4, speed: 1, zoomSpeed: 1.0, brightness: 1.35, fog: 0.25)),
        .metal("Disco Transit", icon: "train.side.front.car", "discoTransit", in: driveExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.2, brightness: 1.35, fog: 0.25)),
        .metal("Velvet Samba", icon: "figure.dance", "velvetSamba", in: danceExpansion, size: "Form scale", travels: false, look: L(palette: 0, speed: 1, zoomSpeed: 0.6, brightness: 1.3, fog: 0.25)),
        .metal("Neon Caper", icon: "figure.step.training", "neonCaper", in: danceExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.6, brightness: 1.3, fog: 0.25)),
        .metal("Carnival Pulse", icon: "party.popper", "carnivalPulse", in: danceExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.6, brightness: 1.3, fog: 0.25)),
        .metal("Ribbon Rumba", icon: "figure.flexibility", "ribbonRumba", in: danceExpansion, size: "Form scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0.6, brightness: 1.3, fog: 0.25)),
        .metal("Elastic Jive", icon: "figure.jumprope", "elasticJive", in: danceExpansion, size: "Form scale", travels: false, look: L(palette: 3, speed: 1, zoomSpeed: 0.6, brightness: 1.3, fog: 0.25)),
        .metal("Liquid Tango", icon: "figure.2", "liquidTango", in: danceExpansion, size: "Form scale", travels: false, look: L(palette: 0, speed: 1, zoomSpeed: 0.6, brightness: 1.3, fog: 0.25)),
        .metal("Prism Pirouette", icon: "figure.gymnastics", "prismPirouette", in: danceExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.6, brightness: 1.3, fog: 0.25)),
        .retired("Orbit Salsa", icon: "figure.socialdance", replacement: 101),
        .metal("Molten Mambo", icon: "flame.circle", "moltenMambo", in: danceExpansion, size: "Form scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0.6, brightness: 1.3, fog: 0.25)),
        .retired("Vivid Foxtrot", icon: "figure.walk.motion", replacement: 101),
        .metal("Fuchsia Flyway", icon: "road.lanes", "fuchsiaFlyway", in: voyageExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Amber Aqueduct", icon: "water.waves", "amberAqueduct", in: voyageExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Photon Overpass", icon: "arrow.triangle.merge", "photonOverpass", in: voyageExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Indigo Escalator", icon: "stairs", "indigoEscalator", in: voyageExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Solar Slalom", icon: "flag.checkered", "solarSlalom", in: voyageExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Glacial Sprint", icon: "mountain.2", "glacialSprint", in: voyageExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Velour Velocity", icon: "sailboat", "velvetVoyage", in: voyageExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Plasma Rally", icon: "bolt.shield", "plasmaRally", in: voyageExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Crystal Causeway", icon: "triangle.fill", "crystalCauseway", in: voyageExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Luminous Lift", icon: "arrow.up.square", "luminousLift", in: voyageExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Arc Jetstream", icon: "wind", "arcJetstream", in: voyageExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Ruby Rollway", icon: "circle.rectangle.filled.pattern.diagonalline", "rubyRollway", in: voyageExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Neon Regatta", icon: "ferry", "neonRegatta", in: voyageExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Radiant Runway", icon: "airplane.departure", "radiantRunway", in: voyageExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Electric Viaduct", icon: "building.columns", "electricViaduct", in: voyageExpansion, size: "Structure scale", look: L(palette: 4, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Orbit Express", icon: "tram", "orbitExpress", in: voyageExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Molten Highway", icon: "flame", "moltenHighway", in: voyageExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Violet Flight", icon: "paperplane.fill", "violetFlight", in: voyageExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Emerald Launch", icon: "leaf.circle", "emeraldLaunch", in: voyageExpansion, size: "Structure scale", look: L(palette: 4, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Coral Driftway", icon: "fish", "coralDriftway", in: voyageExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Azure Ascent", icon: "arrow.up.forward.square", "azureAscent", in: voyageExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Festival Cruise", icon: "party.popper", "festivalCruise", in: voyageExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Quantum Sled", icon: "arrow.down.right.and.arrow.up.left", "quantumSled", in: voyageExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Citrus Surge", icon: "drop.circle.fill", "citrusSurge", in: voyageExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Starlight Pursuit", icon: "sparkles", "starlightPursuit", in: voyageExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Saffron Spindle", icon: "rays", "saffronSpindle", in: passageExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Opaline Iris", icon: "camera.aperture", "opalineIris", in: passageExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Electric Helicoid", icon: "arrow.triangle.2.circlepath", "electricHelicoid", in: passageExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Ultramarine Arcade", icon: "building.columns", "ultramarineArcade", in: passageExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Fuchsia Furnace", icon: "gearshape", "fuchsiaFurnace", in: passageExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Amber Aperture", icon: "squareshape", "amberAperture", in: passageExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Aurora Corkscrew", icon: "tornado", "auroraCorkscrew", in: passageExpansion, size: "Structure scale", look: L(palette: 4, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Prism Portals", icon: "triangle", "prismPortals", in: passageExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Magenta Conduit", icon: "cpu", "magentaConduit", in: passageExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Verdant Spiral", icon: "leaf.fill", "verdantSpiral", in: passageExpansion, size: "Structure scale", look: L(palette: 4, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Sapphire Cascade", icon: "water.waves", "sapphireCascade", in: passageExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Garnet Gallery", icon: "diamond", "garnetGallery", in: passageExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Luminous Nautilus", icon: "tornado", "luminousNautilus", in: passageExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Indigo Infinity", icon: "infinity", "indigoInfinity", in: passageExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Golden Gyre", icon: "sun.max.fill", "goldenGyre", in: passageExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Fluid Odyssey", icon: "drop.triangle", "liquidLabyrinth", in: passageExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Photon Petals", icon: "camera.macro", "photonPetals", in: passageExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .retired("Neon Needle", icon: "pencil.tip", replacement: 270),
        .metal("Astral Torque", icon: "circle.dotted.circle", "celestialCoil", in: passageExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Chrome Comet", icon: "sparkle", "chromeComet", in: passageExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Candy Cathedral", icon: "building.columns.circle", "candyCathedral", in: passageExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Scarlet Siphon", icon: "drop.fill", "scarletSiphon", in: passageExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Emerald Echo", icon: "octagon", "emeraldEcho", in: passageExpansion, size: "Structure scale", look: L(palette: 4, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Arctic Raceway", icon: "snowflake", "arcticRaceway", in: passageExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Plasma Passage", icon: "allergens", "plasmaPassage", in: passageExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Violet Velocity", icon: "arrow.forward.square", "violetVelocity", in: passageExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Tangerine Turbine", icon: "fanblades", "tangerineTurbine", in: passageExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Cerulean Shell", icon: "fossil.shell", "ceruleanShell", in: passageExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Disco Helix", icon: "hexagon.fill", "discoHelix", in: passageExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Iridescent Descent", icon: "square.3.layers.3d", "iridescentDescent", in: passageExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Solar Serpent", icon: "scribble.variable", "solarSerpent", in: passageExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Rainbow Reactor", icon: "atom", "rainbowReactor", in: passageExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .retired("Velvet Wormhole", icon: "curtains.closed", replacement: 270),
        .metal("Crystal Carousel", icon: "cube.transparent", "crystalCarousel", in: passageExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Neon Maelstrom", icon: "hurricane", "neonMaelstrom", in: passageExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Radiant Rondo", icon: "circle.grid.cross", "radiantRondo", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Fuchsia Fandango", icon: "figure.dance", "fuchsiaFandango", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Satin Shuffle", icon: "shuffle", "satinShuffle", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Chromatic Charleston", icon: "figure.step.training", "chromaticCharleston", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Prismatic Polka", icon: "triangle.circle", "prismaticPolka", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Neon Bolero", icon: "rectangle.on.rectangle.angled", "neonBolero", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 4, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Pearlescent Swing", icon: "circle.hexagongrid.fill", "pearlescentSwing", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 3, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Solar Sway", icon: "sun.haze.fill", "solarSway", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Liquid Limbo", icon: "checkerboard.rectangle", "liquidLimbo", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 0, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Violet Vogue", icon: "figure.flexibility", "violetVogue", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 0, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Disco Ripple", icon: "circle.dotted", "discoRipple", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Gilded Groove", icon: "waveform.path", "gildedGroove", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Aurora Waltz", icon: "sparkles.square.filled.on.square", "auroraWaltz", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 4, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Elastic Anthem", icon: "allergens", "elasticAnthem", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Crimson Cadence", icon: "fan", "crimsonCadence", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Sapphire Stomp", icon: "wave.3.right", "sapphireStomp", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 3, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Coral Crescendo", icon: "camera.macro", "coralCrescendo", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Electric Encore", icon: "point.3.connected.trianglepath.dotted", "electricEncore", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 0, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Luminous Lockstep", icon: "diamond.fill", "luminousLockstep", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 4, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Festival Finale", icon: "party.popper.fill", "festivalFinale", in: festivalExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Serpent Bore", icon: "lasso", "serpentBore", in: boreExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Ringworld Drift", icon: "circle.bottomhalf.filled", "ringworldDrift", in: boreExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Twin Bore", icon: "circle.circle", "twinBore", in: boreExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Coil Run", icon: "rotate.3d", "coilRun", in: boreExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, brightness: 1.2, fog: 0.25)),
        .metal("Bellows Passage", icon: "rectangle.compress.vertical", "bellowsPassage", in: boreExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Branching Bore", icon: "arrow.triangle.branch", "branchingBore", in: boreExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.3, brightness: 1.5, fog: 0.25)),
        .metal("Skyward Shaft", icon: "arrow.up.to.line", "skywardShaft", in: boreExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Veil Passage", icon: "curtains.open", "veilPassage", in: boreExpansion, size: "Structure scale", look: L(palette: 4, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Glass Pipeworks", icon: "pipe.and.drop", "glassPipeworks", in: boreExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Möbius Ride", icon: "infinity.circle", "mobiusRide", in: boreExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Chainmail Bore", icon: "link", "chainmailBore", in: portalExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Feather Vault", icon: "leaf", "featherVault", in: portalExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Tartan Tube", icon: "squareshape.split.3x3", "tartanTube", in: portalExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Herringbone Hall", icon: "chevron.up.chevron.down", "herringboneHall", in: portalExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Quilted Pipe", icon: "square.grid.3x3.middle.filled", "quiltedPipe", in: portalIIExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Lace Funnel", icon: "seal.fill", "laceFunnel", in: portalExpansion, size: "Structure scale", look: L(palette: 4, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Zipper Run", icon: "arrow.left.and.right", "zipperRun", in: portalExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Cable Knit Tube", icon: "line.3.crossed.swirl.circle", "cableKnitTube", in: portalExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Basket Weave Burrow", icon: "basket", "basketWeaveBurrow", in: portalExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Louvre Tunnel", icon: "blinds.horizontal.open", "louvreTunnel", in: portalExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Pin Art", icon: "pin.fill", "pinArt", in: kineticExpansion, size: "Form scale", travels: false, look: L(palette: 3, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Kinetic Rain", icon: "cloud.drizzle", "kineticRain", in: kineticExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Plasma Globe", icon: "globe.desk", "plasmaGlobe", in: kineticExpansion, size: "Form scale", travels: false, look: L(palette: 0, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Jacob's Ladder", icon: "bolt.ring.closed", "jacobsLadder", in: kineticExpansion, size: "Form scale", travels: false, look: L(palette: 3, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        // Not red-tagged in the owner's review; opens Pin Art like the 1.0.3 build.
        .retired("Hanging Mobile", icon: "scalemass", replacement: 320),
        .metal("Prism Carousel", icon: "triangle.lefthalf.filled", "prismCarousel", in: kineticExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Cone Splash", icon: "speaker.wave.2", "coneSplash", in: kineticExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Wind Tunnel", icon: "wind.circle", "windTunnel", in: kineticExpansion, size: "Form scale", travels: false, look: L(palette: 3, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Tensegrity Pulse", icon: "perspective", "tensegrityPulse", in: kineticExpansion, size: "Form scale", travels: false, look: L(palette: 3, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Shadow Modulator", icon: "light.max", "shadowModulator", in: kineticExpansion, size: "Form scale", travels: false, look: L(palette: 0, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Canopy Flight", icon: "lightbulb.2", "canopyFlight", in: flightExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Strata Glide", icon: "square.stack.3d.down.forward", "strataGlide", in: flightExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Pillar Forest", icon: "chart.bar.xaxis", "pillarForest", in: flightExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Parallax Express", icon: "rectangle.3.group", "parallaxExpress", in: flightExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Delta Flyover", icon: "point.topleft.down.to.point.bottomright.curvepath", "deltaFlyover", in: flightExpansion, size: "Structure scale", look: L(palette: 4, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Aurora Overpass", icon: "moon.stars", "auroraOverpass", in: flightExpansion, size: "Structure scale", look: L(palette: 4, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Cascade Climb", icon: "water.waves.and.arrow.up", "cascadeClimb", in: flightExpansion, size: "Structure scale", look: L(palette: 4, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Night Orbit", icon: "globe", "nightOrbit", in: flightExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Comet Chase", icon: "star.circle", "cometChase", in: flightExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Cloud Sea", icon: "cloud.fill", "cloudSea", in: flightExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Acrylic Cells", icon: "paintpalette", "acrylicCells", in: materialExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Molten Glass", icon: "flask", "moltenGlass", in: materialExpansion, size: "Form scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Liquid Crystal", icon: "circle.lefthalf.filled", "liquidCrystal", in: materialExpansion, size: "Form scale", travels: false, look: L(palette: 0, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Incense Drift", icon: "smoke", "incenseDrift", in: materialExpansion, size: "Form scale", travels: false, look: L(palette: 3, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Shibori Bloom", icon: "circle.grid.2x2", "shiboriBloom", in: materialExpansion, size: "Form scale", travels: false, look: L(palette: 3, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Heat Haze", icon: "thermometer.sun", "heatHaze", in: materialExpansion, size: "Form scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Gel Overlap", icon: "square.on.square", "gelOverlap", in: materialExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Holo Foil", icon: "rectangle.portrait.on.rectangle.portrait.angled", "holoFoil", in: materialExpansion, size: "Form scale", travels: false, look: L(palette: 0, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Opal Fire", icon: "suit.diamond", "opalFire", in: materialExpansion, size: "Form scale", travels: false, look: L(palette: 4, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Raku Crackle", icon: "rectangle.dashed", "rakuCrackle", in: materialExpansion, size: "Form scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0.4, brightness: 1.35, fog: 0.25)),
        .metal("Pulsar Beacon", icon: "light.beacon.max", "pulsarBeacon", in: cosmosExpansion, size: "Structure scale", travels: false, look: L(palette: 0, speed: 1, zoomSpeed: 0.6, brightness: 1.35, fog: 0.25)),
        .metal("Twin Suns", icon: "sun.and.horizon", "twinSuns", in: cosmosExpansion, size: "Structure scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0.6, brightness: 1.35, fog: 0.25)),
        .metal("Supernova Shell", icon: "staroflife.circle", "supernovaShell", in: cosmosExpansion, size: "Structure scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.6, brightness: 1.35, fog: 0.25)),
        .metal("Galaxy Collision", icon: "hurricane.circle", "galaxyCollision", in: cosmosExpansion, size: "Structure scale", travels: false, look: L(palette: 0, speed: 1, zoomSpeed: 0.6, brightness: 1.35, fog: 0.25)),
        .metal("Solar Prominence", icon: "sun.dust", "solarProminence", in: cosmosExpansion, size: "Structure scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0.6, brightness: 1.35, fog: 0.25)),
        .metal("Quasar Jet", icon: "arrow.up.and.down", "quasarJet", in: cosmosExpansion, size: "Structure scale", travels: false, look: L(palette: 3, speed: 1, zoomSpeed: 0.6, brightness: 1.35, fog: 0.25)),
        .metal("Ring Plane Run", icon: "circle.and.line.horizontal", "ringPlaneRun", in: cosmosExpansion, size: "Structure scale", travels: false, look: L(palette: 4, speed: 1, zoomSpeed: 0.6, brightness: 1.35, fog: 0.25)),
        .metal("Magnetosphere", icon: "dot.radiowaves.left.and.right", "magnetosphere", in: cosmosExpansion, size: "Structure scale", travels: false, look: L(palette: 3, speed: 1, zoomSpeed: 0.6, brightness: 1.35, fog: 0.25)),
        .metal("Nebular Filaments", icon: "network", "cosmicWeb", in: cosmosExpansion, size: "Structure scale", travels: false, look: L(palette: 0, speed: 1, zoomSpeed: 0.6, brightness: 1.35, fog: 0.25)),
        .metal("Einstein Ring", icon: "smallcircle.filled.circle", "einsteinRing", in: cosmosExpansion, size: "Structure scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0.6, brightness: 1.35, fog: 0.25)),
        .metal("Julia Dive", icon: "arrow.down.right.and.arrow.up.left.circle", "juliaDive", in: fractalExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Julia Braid", icon: "arrow.triangle.2.circlepath.circle", "juliaBraid", in: fractalExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Newton Vortex", icon: "tornado.circle", "newtonVortex", in: fractalExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Phoenix Spiral", icon: "bird", "phoenixSpiral", in: fractalExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Droste Fractal", icon: "square.on.square.dashed", "drosteFractal", in: fractalExpansion, size: "Structure scale", look: L(palette: 4, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Mandelbrot Wormhole", icon: "circle.circle.fill", "mandelbrotWormhole", in: fractalTunnelExpansion, size: "Structure scale", look: L(palette: 1, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Burning Ship Abyss", icon: "sailboat.circle", "burningShipAbyss", in: fractalTunnelExpansion, size: "Structure scale", look: L(palette: 2, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Fractal Double Helix", icon: "point.forward.to.point.capsulepath", "fractalDoubleHelix", in: fractalTunnelExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Quaternion Bloom", icon: "circle.hexagonpath.fill", "quaternionBloom", in: fractalTunnelExpansion, size: "Structure scale", look: L(palette: 4, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Loxodrome Fractal", icon: "arrow.uturn.down.circle", "loxodromeFractal", in: fractalTunnelExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.3, brightness: 1.35, fog: 0.25)),
        .metal("Cascade Climb II", icon: "water.waves.and.arrow.up", "cascadeClimbII", in: flightIIExpansion, size: "Structure scale", look: L(palette: 4, speed: 1, zoomSpeed: 1.4, brightness: 1.2, fog: 0.25)),
        .metal("Night Orbit II", icon: "globe", "nightOrbitII", in: flightIIExpansion, size: "Structure scale", look: L(palette: 3, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Cloud Sea II", icon: "cloud.fill", "cloudSeaII", in: flightIIExpansion, size: "Structure scale", look: L(palette: 0, speed: 1, zoomSpeed: 1.4, brightness: 1.35, fog: 0.25)),
        .metal("Acrylic Cells II", icon: "paintpalette", "acrylicCellsII", in: materialIIExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0, brightness: 1.35, fog: 0.25)),
        .metal("Molten Glass II", icon: "flask", "moltenGlassII", in: materialIIExpansion, size: "Form scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0, brightness: 1.35, fog: 0.25)),
        .metal("Liquid Crystal II", icon: "circle.lefthalf.filled", "liquidCrystalII", in: materialIIExpansion, size: "Form scale", travels: false, look: L(palette: 0, speed: 1, zoomSpeed: 0, brightness: 1.35, fog: 0.25)),
        .metal("Incense Drift II", icon: "smoke", "incenseDriftII", in: materialIIExpansion, size: "Form scale", travels: false, look: L(palette: 3, speed: 1, zoomSpeed: 0, brightness: 1.5, fog: 0.25)),
        .metal("Heat Haze II", icon: "thermometer.sun", "heatHazeII", in: materialIIExpansion, size: "Form scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0, brightness: 1.35, fog: 0.25)),
        .metal("Gel Overlap II", icon: "square.on.square", "gelOverlapII", in: materialIIExpansion, size: "Form scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0, brightness: 1.35, fog: 0.25)),
        .metal("Holo Foil II", icon: "rectangle.portrait.on.rectangle.portrait.angled", "holoFoilII", in: materialIIExpansion, size: "Form scale", travels: false, look: L(palette: 0, speed: 1, zoomSpeed: 0, brightness: 1.35, fog: 0.25)),
        .metal("Opal Fire II", icon: "suit.diamond", "opalFireII", in: materialIIExpansion, size: "Form scale", travels: false, look: L(palette: 4, speed: 1, zoomSpeed: 0, brightness: 1.35, fog: 0.25)),
        .metal("Raku Crackle II", icon: "rectangle.dashed", "rakuCrackleII", in: materialIIExpansion, size: "Form scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0, brightness: 1.35, fog: 0.25)),
        .metal("Twin Suns II", icon: "sun.and.horizon", "twinSunsII", in: cosmosIIExpansion, size: "Structure scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0, brightness: 1.7, fog: 0.25)),
        .metal("Supernova Shell II", icon: "staroflife.circle", "supernovaShellII", in: cosmosIIExpansion, size: "Structure scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0, brightness: 1.45, fog: 0.25)),
        .metal("Galaxy Collision II", icon: "hurricane.circle", "galaxyCollisionII", in: cosmosIIExpansion, size: "Structure scale", travels: false, look: L(palette: 0, speed: 1, zoomSpeed: 0, brightness: 1.6, fog: 0.25)),
        .metal("Solar Prominence II", icon: "sun.dust", "solarProminenceII", in: cosmosIIExpansion, size: "Structure scale", travels: false, look: L(palette: 2, speed: 1, zoomSpeed: 0, brightness: 1.35, fog: 0.25)),
        .metal("Quasar Jet II", icon: "arrow.up.and.down", "quasarJetII", in: cosmosIIExpansion, size: "Structure scale", travels: false, look: L(palette: 3, speed: 1, zoomSpeed: 0, brightness: 1.35, fog: 0.25)),
        .metal("Magnetosphere II", icon: "dot.radiowaves.left.and.right", "magnetosphereII", in: cosmosIIExpansion, size: "Structure scale", travels: false, look: L(palette: 3, speed: 1, zoomSpeed: 0, brightness: 1.35, fog: 0.25)),
        .metal("Nebular Filaments II", icon: "network", "cosmicWebII", in: cosmosIIExpansion, size: "Structure scale", travels: false, look: L(palette: 0, speed: 1, zoomSpeed: 0, brightness: 1.35, fog: 0.25)),
        .metal("Einstein Ring II", icon: "smallcircle.filled.circle", "einsteinRingII", in: cosmosIIExpansion, size: "Structure scale", travels: false, look: L(palette: 1, speed: 1, zoomSpeed: 0, brightness: 1.45, fog: 0.25)),
    ]

    /// Studio's automatic timeline order: released and new designs interleaved so that
    /// neighbouring sections differ in family, composition and color.
    static let timelineOrder: [Int] = [
        101, 201, 91, 300, 202, 100, 203, 370, 310, 184, 204, 33, 320, 205, 360, 206, 117, 330, 207, 84,
        371, 208, 340, 118, 209, 210, 350, 185, 211, 212, 301, 98, 213, 372, 64, 311, 214, 215, 102, 321,
        216, 361, 22, 218, 331, 220, 373, 119, 221, 341, 222, 223, 224, 351, 103, 225, 226, 302, 227, 374,
        228, 229, 312, 120, 230, 187, 322, 231, 362, 232, 233, 332, 375, 104, 234, 18, 342, 235, 236, 237,
        352, 238, 239, 61, 303, 376, 240, 121, 241, 313, 242, 188, 243, 323, 244, 363, 31, 105, 377, 333,
        246, 74, 247, 343, 248, 249, 250, 353, 122, 251, 23, 378, 304, 252, 43, 253, 314, 189, 254, 255,
        256, 364, 25, 257, 379, 334, 106, 258, 260, 344, 261, 123, 263, 354, 46, 264, 265, 380, 305, 266,
        85, 267, 315, 268, 107, 269, 325, 270, 365, 17, 381, 271, 335, 272, 80, 273, 345, 92, 274, 275,
        355, 276, 124, 382, 278, 306, 279, 141, 280, 316, 29, 281, 282, 326, 283, 366, 383, 284, 285, 336,
        81, 286, 21, 346, 287, 125, 288, 356, 60, 384, 289, 192, 307, 290, 291, 292, 317, 28, 293, 109,
        327, 294, 385, 367, 88, 295, 337, 176, 296, 297, 347, 298, 299, 193, 357, 386, 24, 42, 110, 308,
        83, 127, 72, 318, 86, 111, 178, 328, 387, 26, 368, 16, 48, 338, 112, 179, 19, 348, 129, 12,
        113, 388, 358, 180, 27, 130, 309, 197, 10, 114, 319, 15, 131, 79, 389, 329, 182, 369, 132, 20,
        339, 47, 50, 183, 349, 32, 133, 245, 359, 259,
    ]

    static var names: [String] { all.map(\.name) }
    static func effect(_ scene: Int) -> NativeEffect? { all.indices.contains(scene) ? all[scene] : nil }
    static func isRetired(_ scene: Int) -> Bool { effect(scene)?.replacement != nil }
    /// The design shown for a scene ID: retired designs open their replacement.
    static func resolved(_ scene: Int) -> Int { effect(scene)?.replacement ?? scene }
    /// Native IDs offered in the library, timeline and random choices.
    static let activeIDs: [Int] = all.indices.filter { all[$0].replacement == nil }
    /// The design a new session opens with.
    static var defaultScene: Int { timelineOrder[0] }
}
