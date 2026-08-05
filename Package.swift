// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Lyrix",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "LyrixCore",
            path: "Sources/LyrixCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "Lyrix",
            dependencies: ["LyrixCore"],
            path: "Sources/Lyrix",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "LyrixTests",
            dependencies: ["LyrixCore"],
            path: "Tests/LyrixTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
