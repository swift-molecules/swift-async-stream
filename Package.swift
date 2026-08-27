// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-async",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Async",
            targets: ["Async"]
        ),
        .library(
            name: "Async Sequence",
            targets: ["Async Sequence"]
        ),
        .library(
            name: "Async Stream",
            targets: ["Async Stream"]
        ),
        .library(
            name: "Async Fanout",
            targets: ["Async Fanout"]
        ),
        .library(
            name: "Async Test Support",
            targets: ["Async Test Support"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-molecules/swift-async.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-column.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-buffer-ring.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-buffer.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-queue.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-reference.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-standard-library-extensions.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-compositions/swift-clocks.git", branch: "main"),
        .package(
            url: "https://github.com/swift-compositions/swift-clocks-dependencies.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-memory-heap.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-storage.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Async Sequence",
            dependencies: [
                .product(name: "Async", package: "swift-async")
            ]
        ),

        .target(
            name: "Async Stream Core",
            dependencies: [
                .product(name: "Async", package: "swift-async"),
                .product(name: "Buffer", package: "swift-buffer"),
                .product(name: "Queue", package: "swift-queue"),
                .product(name: "Clocks", package: "swift-clocks"),
                .product(name: "Reference", package: "swift-reference"),
            ]
        ),

        .target(
            name: "Async Stream",
            dependencies: [
                .product(name: "Column", package: "swift-column"),
                .product(name: "Buffer Ring Primitive", package: "swift-buffer-ring"),
                .product(
                    name: "Buffer Ring Bounded Primitive",
                    package: "swift-buffer-ring"
                ),
                "Async Stream Core",
                .product(name: "Buffer Ring", package: "swift-buffer-ring"),
                .product(name: "Clocks Dependencies", package: "swift-clocks-dependencies"),
                .product(
                    name: "Standard Library Extensions",
                    package: "swift-standard-library-extensions"
                ),
                .product(name: "Memory Heap", package: "swift-memory-heap"),
                .product(
                    name: "Storage Contiguous",
                    package: "swift-storage"
                ),
            ]
        ),

        .target(
            name: "Async Fanout",
            dependencies: [
                .product(name: "Async", package: "swift-async")
            ]
        ),

        .target(
            name: "Async",
            dependencies: [
                "Async Sequence",
                "Async Stream",
                "Async Fanout",
            ]
        ),

        .target(
            name: "Async Test Support",
            dependencies: [
                "Async"
            ],
            path: "Tests/Support"
        ),

        .testTarget(
            name: "Async Fanout Tests",
            dependencies: [
                "Async Test Support"
            ]
        ),
        .testTarget(
            name: "Async Sequence Tests",
            dependencies: [
                "Async Test Support"
            ]
        ),
        .testTarget(
            name: "Async Stream Tests",
            dependencies: [
                "Async Test Support",
                .product(name: "Clocks Dependencies", package: "swift-clocks-dependencies"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
