// swift-tools-version: 6.2
import PackageDescription

var products: [Product] = [
    .library(
        name: "Types",
        targets: ["Types"]
    ),
    .library(
        name: "Files",
        targets: ["Files"]
    ),
    .library(
        name: "Pattern",
        targets: ["Pattern"]
    ),
    .library(
        name: "LOC",
        targets: ["LOC"]
    ),
    .executable(
        name: "scout",
        targets: ["Scout"]
    ),
]

var scoutDependencies: [Target.Dependency] = [
    .product(
        name: "ArgumentParser",
        package: "swift-argument-parser"
    ),
    "TypesCLI",
    "FilesCLI",
    "PatternCLI",
    "LOCCLI",
]

// BuildSettings shells out to `xcodebuild`, which only exists on macOS.
// Keep its products, targets and CLI wiring out of the Linux build graph.
#if os(macOS)
    products.append(
        .library(
            name: "BuildSettings",
            targets: ["BuildSettings"]
        )
    )
    scoutDependencies.append("BuildSettingsCLI")
#endif

var targets: [Target] = [
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
            // LoggingOSLog wraps os.log and is Apple-only.
            .product(
                name: "LoggingOSLog",
                package: "swift-log-oslog",
                condition: .when(platforms: [.macOS])
            ),
            // FilePath is provided by the System framework on Apple platforms;
            // on Linux it comes from the swift-system package.
            .product(
                name: "SystemPackage",
                package: "swift-system",
                condition: .when(platforms: [.linux])
            ),
            .product(
                name: "OrderedCollections",
                package: "swift-collections"
            ),
        ],
        exclude: ["README.md", "GitConfiguration.md"],
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
    .target(
        name: "Types",
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
            .treatAllWarnings(as: .error),
        ]
    ),
    .target(
        name: "Files",
        dependencies: [
            .product(
                name: "Logging",
                package: "swift-log"
            ),
            "Common",
        ],
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
    .target(
        name: "Pattern",
        dependencies: [
            .product(
                name: "Logging",
                package: "swift-log"
            ),
            "Common",
        ],
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
    .target(
        name: "LOC",
        dependencies: [
            .product(
                name: "Logging",
                package: "swift-log"
            ),
            "Common",
        ],
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
    .target(
        name: "TypesCLI",
        dependencies: [
            .product(
                name: "ArgumentParser",
                package: "swift-argument-parser"
            ),
            .product(
                name: "Logging",
                package: "swift-log"
            ),
            "Types",
            "Common",
        ],
        exclude: ["README.md"],
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
    .target(
        name: "FilesCLI",
        dependencies: [
            .product(
                name: "ArgumentParser",
                package: "swift-argument-parser"
            ),
            .product(
                name: "Logging",
                package: "swift-log"
            ),
            "Files",
            "Common",
        ],
        exclude: ["README.md"],
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
    .target(
        name: "PatternCLI",
        dependencies: [
            .product(
                name: "ArgumentParser",
                package: "swift-argument-parser"
            ),
            .product(
                name: "Logging",
                package: "swift-log"
            ),
            "Pattern",
            "Common",
        ],
        exclude: ["README.md"],
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
    .target(
        name: "LOCCLI",
        dependencies: [
            .product(
                name: "ArgumentParser",
                package: "swift-argument-parser"
            ),
            .product(
                name: "Logging",
                package: "swift-log"
            ),
            "LOC",
            "Common",
        ],
        exclude: ["README.md"],
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
    .executableTarget(
        name: "Scout",
        dependencies: scoutDependencies,
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
    .testTarget(
        name: "CommonTests",
        dependencies: [
            "Common"
        ],
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
    .testTarget(
        name: "TypesTests",
        dependencies: [
            "Types",
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
            .treatAllWarnings(as: .error),
        ]
    ),
    .testTarget(
        name: "TypesCLITests",
        dependencies: [
            "TypesCLI",
            "Types",
            "Common",
            .product(
                name: "InlineSnapshotTesting",
                package: "swift-snapshot-testing"
            ),
        ],
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
    .testTarget(
        name: "FilesTests",
        dependencies: [
            "Files"
        ],
        resources: [
            .copy("Samples")
        ],
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
    .testTarget(
        name: "FilesCLITests",
        dependencies: [
            "FilesCLI",
            "Files",
            "Common",
            .product(
                name: "InlineSnapshotTesting",
                package: "swift-snapshot-testing"
            ),
        ],
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
    .testTarget(
        name: "PatternTests",
        dependencies: [
            "Pattern"
        ],
        resources: [
            .copy("Samples")
        ],
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
    .testTarget(
        name: "PatternCLITests",
        dependencies: [
            "PatternCLI",
            "Pattern",
            "Common",
            .product(
                name: "InlineSnapshotTesting",
                package: "swift-snapshot-testing"
            ),
        ],
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
    .testTarget(
        name: "LOCTests",
        dependencies: [
            "LOC"
        ],
        resources: [
            .copy("Samples")
        ],
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
    .testTarget(
        name: "LOCCLITests",
        dependencies: [
            "LOCCLI",
            "LOC",
            "Common",
            .product(
                name: "InlineSnapshotTesting",
                package: "swift-snapshot-testing"
            ),
        ],
        swiftSettings: [
            .swiftLanguageMode(.v6),
            .treatAllWarnings(as: .error),
        ]
    ),
]

// BuildSettings targets and tests are macOS-only (see note above).
#if os(macOS)
    targets.append(contentsOf: [
        .target(
            name: "BuildSettings",
            dependencies: [
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                .product(
                    name: "Glob",
                    package: "swift-glob"
                ),
                "Common",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .treatAllWarnings(as: .error),
            ]
        ),
        .target(
            name: "BuildSettingsCLI",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .product(
                    name: "Logging",
                    package: "swift-log"
                ),
                "BuildSettings",
                "Common",
            ],
            exclude: ["README.md"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .treatAllWarnings(as: .error),
            ]
        ),
        .testTarget(
            name: "BuildSettingsTests",
            dependencies: [
                "BuildSettings"
            ],
            resources: [
                .copy("Samples")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .treatAllWarnings(as: .error),
            ]
        ),
        .testTarget(
            name: "BuildSettingsCLITests",
            dependencies: [
                "BuildSettingsCLI",
                "BuildSettings",
                "Common",
                .product(
                    name: "InlineSnapshotTesting",
                    package: "swift-snapshot-testing"
                ),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .treatAllWarnings(as: .error),
            ]
        ),
    ])
#endif

let package = Package(
    name: "Scout",
    platforms: [
        .macOS(.v15)
    ],
    products: products,
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
        .package(
            url: "https://github.com/apple/swift-collections",
            .upToNextMajor(from: "1.1.0")
        ),
        .package(
            url: "https://github.com/apple/swift-system",
            .upToNextMajor(from: "1.0.0")
        ),
        .package(
            url: "https://github.com/davbeck/swift-glob.git",
            .upToNextMajor(from: "1.0.0")
        ),
    ],
    targets: targets
)
