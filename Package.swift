// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "edge",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "edge",
            targets: ["Edge"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Edge",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "EdgeTests",
            dependencies: ["Edge"]
        )
    ]
)
