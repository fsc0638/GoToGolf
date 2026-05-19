// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GolfCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v13)
    ],
    products: [
        .library(name: "GolfCore", targets: ["GolfCore"]),
        .executable(name: "golfcore-demo", targets: ["golfcore-demo"])
    ],
    targets: [
        .target(
            name: "GolfCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "golfcore-demo",
            dependencies: ["GolfCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "GolfCoreTests",
            dependencies: ["GolfCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
