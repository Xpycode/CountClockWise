// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Clock",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Clock", path: "Sources/Clock")
    ]
)
