// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "PulseCanvas",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "PulseCanvas", targets: ["PulseCanvas"])],
    dependencies: [.package(url: "https://github.com/weichsel/ZIPFoundation.git", exact: "0.9.20")],
    targets: [
        .executableTarget(name: "PulseCanvas", dependencies: ["ZIPFoundation"], resources: [.copy("Resources")], swiftSettings: [.swiftLanguageMode(.v5)])
    ]
)
