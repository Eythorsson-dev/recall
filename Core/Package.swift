// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Core",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "FSRSBridge", targets: ["FSRSBridge"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.0"),
        .package(url: "https://github.com/open-spaced-repetition/swift-fsrs.git", from: "4.1.0")
    ],
    targets: [
        .target(
            name: "FSRSBridge",
            dependencies: [
                .product(name: "FSRS", package: "swift-fsrs")
            ]
        ),
        .target(
            name: "Core",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                "FSRSBridge"
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"]
        )
    ]
)
