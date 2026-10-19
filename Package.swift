// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VinylDesk",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "VinylDesk", targets: ["VinylDesk"]),
        .library(name: "VinylDeskCore", targets: ["VinylDeskCore"]),
        .executable(name: "VinylDeskTests", targets: ["VinylDeskTests"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VinylDeskCore",
            dependencies: [],
            path: "Sources/VinylDeskCore",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "VinylDesk",
            dependencies: ["VinylDeskCore"],
            path: "Sources/VinylDesk"
        ),
        .executableTarget(
            name: "VinylDeskTests",
            dependencies: ["VinylDeskCore"],
            path: "Sources/VinylDeskTests"
        )
    ]
)
