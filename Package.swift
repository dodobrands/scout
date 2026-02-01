// swift-tools-version: 6.2
import PackageDescription
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
            name: "TypesSDK",
            targets: ["TypesSDK"]
        ),
        .library(
            name: "FilesSDK",
            targets: ["FilesSDK"]
        ),
        .library(
            name: "PatternSDK",
            targets: ["PatternSDK"]
        ),
        .library(
            name: "LOCSDK",
            targets: ["LOCSDK"]
        ),
        .library(
            name: "BuildSettingsSDK",
            targets: ["BuildSettingsSDK"]
        ),
        .executable(
            name: "scout",
            targets: ["Scout"]
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
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "TypesSDK",
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
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "FilesSDK",
            dependencies: [
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                "Common",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "PatternSDK",
            dependencies: [
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                "Common",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "LOCSDK",
            dependencies: [
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                "Common",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "BuildSettingsSDK",
            dependencies: [
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                "Common",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "Types",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                "TypesSDK",
                "Common",
            ],
            exclude: ["README.md"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "Files",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                "FilesSDK",
                "Common",
            ],
            exclude: ["README.md"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "Pattern",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                "PatternSDK",
                "Common",
            ],
            exclude: ["README.md"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "LOC",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                "LOCSDK",
                "Common",
            ],
            exclude: ["README.md"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "BuildSettings",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                "BuildSettingsSDK",
                "Common",
            ],
            exclude: ["README.md"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .executableTarget(
            name: "Scout",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                "Types",
                "Files",
                "Pattern",
                "LOC",
                "BuildSettings",
            ]
        ),
        .testTarget(
            name: "TypesSDKTests",
            dependencies: [
                "TypesSDK",
                .product(
                    name: "InlineSnapshotTesting",
                    package: "swift-snapshot-testing"
                ),
            ],
            resources: [
                .copy("Samples")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "TypesTests",
            dependencies: [
                "Types",
                "TypesSDK",
                "Common",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "FilesSDKTests",
            dependencies: [
                "FilesSDK",
            ],
            resources: [
                .copy("Samples")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "FilesTests",
            dependencies: [
                "Files",
                "FilesSDK",
                "Common",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "PatternSDKTests",
            dependencies: [
                "PatternSDK",
            ],
            resources: [
                .copy("Samples")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "PatternTests",
            dependencies: [
                "Pattern",
                "PatternSDK",
                "Common",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "LOCSDKTests",
            dependencies: [
                "LOCSDK",
            ],
            resources: [
                .copy("Samples")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "LOCTests",
            dependencies: [
                "LOC",
                "LOCSDK",
                "Common",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "BuildSettingsSDKTests",
            dependencies: [
                "BuildSettingsSDK",
            ],
            resources: [
                .copy("Samples")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "BuildSettingsTests",
            dependencies: [
                "BuildSettings",
                "BuildSettingsSDK",
                "Common",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
