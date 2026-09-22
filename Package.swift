// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Clock",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0"),
        .package(path: "Vendor/HelpMenu"),
        .package(path: "Vendor/AppCitizenshipKit"),
        .package(path: "Vendor/FeedbackKit")
    ],
    targets: [
        .testTarget(name: "ClockTests", dependencies: ["Clock"]),
        .executableTarget(name: "Clock", dependencies: [.product(name: "Sparkle", package: "Sparkle"),
                          .product(name: "HelpMenu", package: "HelpMenu"),
                          .product(name: "AppCitizenshipKit", package: "AppCitizenshipKit"),
                          .product(name: "FeedbackKit", package: "FeedbackKit")], path: "Sources/Clock",
                          resources: [.copy("Resources/zone.tab"), .copy("Resources/cities.json"), .process("Resources/Help"), .copy("Resources/Licenses")],
                          linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])])
    ]
)
