// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OnAir",
    platforms: [.macOS("26.0")],
    dependencies: [
        // In-app updates from GitHub Releases (see scripts/release.sh).
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.10.0"),
    ],
    targets: [
        .target(name: "OnAirCore"),
        .executableTarget(name: "OnAir", dependencies: ["OnAirCore", .product(name: "Sparkle", package: "Sparkle")]),
        .testTarget(name: "OnAirCoreTests", dependencies: ["OnAirCore"]),
    ],
    // Swift 5 mode: AppKit/Carbon callback code stays readable without strict-concurrency ceremony.
    swiftLanguageModes: [.v5]
)
