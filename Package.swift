// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-async-stream",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "Async Stream", targets: ["Async Stream"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-async.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-async-broadcast.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-async-channel.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-buffer.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-buffer-ring.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-cardinal.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-clock.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-clocks.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-clocks-dependencies.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-column.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-memory.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-memory-allocation.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-ownership.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-queue.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-reference.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-standard-library-extensions.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-storage-memory.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Async Stream",
            dependencies: [
                .product(name: "Async", package: "swift-async"),
                .product(name: "Async Broadcast", package: "swift-async-broadcast"),
                .product(name: "Async Channel", package: "swift-async-channel"),
                .product(name: "Buffer", package: "swift-buffer"),
                .product(name: "Buffer Ring", package: "swift-buffer-ring"),
                .product(name: "Buffer Ring Bounded Primitive", package: "swift-buffer-ring"),
                .product(name: "Buffer Ring Primitive", package: "swift-buffer-ring"),
                .product(name: "Cardinal", package: "swift-cardinal"),
                .product(name: "Clock", package: "swift-clock"),
                .product(name: "Clocks", package: "swift-clocks"),
                .product(name: "Clocks Dependencies", package: "swift-clocks-dependencies"),
                .product(name: "Column", package: "swift-column"),
                .product(name: "Memory", package: "swift-memory"),
                .product(name: "Memory Allocator", package: "swift-memory-allocation"),
                .product(name: "Ownership", package: "swift-ownership"),
                .product(name: "Queue", package: "swift-queue"),
                .product(name: "Reference", package: "swift-reference"),
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Storage Memory", package: "swift-storage-memory"),
            ],
            path: "Sources/Async Stream"
        ),
        .testTarget(
            name: "Async Stream Tests",
            dependencies: [
                .product(name: "Async", package: "swift-async"),
                .product(name: "Clocks Dependencies", package: "swift-clocks-dependencies"),
                .target(name: "Async Stream"),
            ],
            path: "Tests/Async Stream Tests"
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
