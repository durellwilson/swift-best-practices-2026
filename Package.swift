// swift-tools-version: 6.0
// Swift Best Practices 2026 - Detroit Open Source Ecosystem

import PackageDescription

let package = Package(
    name: "SwiftBestPractices2026",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2)
    ],
    products: [
        .library(name: "DetroitSwiftFoundation", targets: ["DetroitSwiftFoundation"]),
        .library(name: "ModernSwiftUI", targets: ["ModernSwiftUI"]),
        .library(name: "SwiftConcurrency2026", targets: ["SwiftConcurrency2026"]),
        .library(name: "SwiftTesting2026", targets: ["SwiftTesting2026"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing", from: "0.10.0"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "DetroitSwiftFoundation",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .target(
            name: "ModernSwiftUI",
            dependencies: ["DetroitSwiftFoundation"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "SwiftConcurrency2026",
            dependencies: ["DetroitSwiftFoundation"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "SwiftTesting2026",
            dependencies: [
                "DetroitSwiftFoundation",
                .product(name: "Testing", package: "swift-testing")
            ]
        ),
        .testTarget(
            name: "SwiftBestPractices2026Tests",
            dependencies: [
                "DetroitSwiftFoundation",
                "ModernSwiftUI", 
                "SwiftConcurrency2026",
                "SwiftTesting2026"
            ]
        )
    ]
)
