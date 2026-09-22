// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Clock",
    platforms: [.macOS(.v13)],
    targets: [
        .testTarget(name: "ClockTests", dependencies: ["Clock"]),
        .executableTarget(name: "Clock", path: "Sources/Clock", resources: [.copy("Resources/zone.tab"), .copy("Resources/cities.json")])
    ]
)
