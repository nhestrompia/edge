// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HyperliquidPositions",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "HyperliquidPositions",
            targets: ["HyperliquidPositions"]
        )
    ],
    targets: [
        .executableTarget(
            name: "HyperliquidPositions"
        ),
        .testTarget(
            name: "HyperliquidPositionsTests",
            dependencies: ["HyperliquidPositions"]
        )
    ]
)
