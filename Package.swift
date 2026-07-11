// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Lunar",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Lunar", targets: ["Lunar"])],
    targets: [.executableTarget(name: "Lunar", path: "Sources/Lunar")]
)
