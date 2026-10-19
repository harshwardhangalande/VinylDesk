// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VinylDesk",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "VinylDesk", targets: ["VinylDesk"]),
        .executable(name: "VinylDeskWidgets", targets: ["VinylDeskWidgets"]),
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
            name: "VinylDeskWidgets",
            dependencies: ["VinylDeskCore"],
            path: "Sources/VinylDeskWidgets"
        ),
        .executableTarget(
            name: "VinylDeskTests",
            dependencies: ["VinylDeskCore"],
            path: "Sources/VinylDeskTests"
        )
    ]
)
