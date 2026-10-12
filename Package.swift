// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "PulseCanvas",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "PulseCanvas", targets: ["PulseCanvas"])],
    targets: [
        .executableTarget(name: "PulseCanvas", resources: [.copy("Resources")], swiftSettings: [.swiftLanguageMode(.v5)])
    ]
)
