// swift-tools-version: 6.2

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .treatAllWarnings(as: .error),
]

let package = Package(
    name: "Scout",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "Common",
            targets: ["Common"]
        ),
        .library(
            name: "CodeReader",
            targets: ["CodeReader"]
        ),
        .executable(
            name: "CountTypes",
            targets: ["CountTypes"]
        ),
        .executable(
            name: "CountFiles",
            targets: ["CountFiles"]
        ),
        .executable(
            name: "CountImports",
            targets: ["CountImports"]
        ),
        .executable(
            name: "CountLOC",
            targets: ["CountLOC"]
        ),
        .executable(
            name: "ExtractBuildSettings",
            targets: ["ExtractBuildSettings"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            .upToNextMajor(from: "1.0.0")
        ),
        .package(
            url: "https://github.com/jpsim/SourceKitten",
            .upToNextMajor(from: "0.36.0")
        ),
        .package(
            url: "https://github.com/swiftlang/swift-subprocess",
            from: "0.2.1"
        ),
        .package(
            url: "https://github.com/apple/swift-log.git",
            .upToNextMajor(from: "1.6.0")
        ),
        .package(
            url: "https://github.com/chrisaljoudi/swift-log-oslog.git",
            .upToNextMajor(from: "0.2.1")
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            from: "1.0.0"
        ),
    ],
    targets: [
        .target(
            name: "Common",
            dependencies: [
                .product(
                    name: "Subprocess",
                    package: "swift-subprocess"
                ),
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                .product(
                    name: "LoggingOSLog",
                    package: "swift-log-oslog"
                ),
            ],
            exclude: ["README.md"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "CodeReader",
            dependencies: [
                .product(
                    name: "SourceKittenFramework",
                    package: "SourceKitten"
                ),
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                "Common",
            ],
            exclude: ["README.md"],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "CountTypes",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                "CodeReader",
                "Common",
            ],
            exclude: ["README.md"],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "CountFiles",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                "Common",
            ],
            exclude: ["README.md"],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "CountImports",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                "CodeReader",
                "Common",
            ],
            exclude: ["README.md"],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "CountLOC",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                "CodeReader",
                "Common",
            ],
            exclude: ["README.md"],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "ExtractBuildSettings",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                "Common",
            ],
            exclude: ["README.md"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "CodeReaderTests",
            dependencies: [
                "CodeReader",
                .product(
                    name: "InlineSnapshotTesting",
                    package: "swift-snapshot-testing"
                ),
            ],
            resources: [
                .copy("Samples")
            ],
            swiftSettings: swiftSettings
        ),
    ]
)
