import ArgumentParser
import BuildSettingsSDK
import Common
import Foundation
import Logging
import System
import SystemPackage

public struct BuildSettings: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "build-settings",
        abstract: "Extract build settings from Xcode projects"
    )

    @Option(name: [.long, .short], help: "Path to repository (default: current directory)")
    public var repoPath: String?

    @Option(
        name: [.long, .short],
        help: "Path to Xcode workspace (.xcworkspace) or project (.xcodeproj)"
    )
    public var project: String?

    @Option(help: "Path to configuration JSON file")
    public var config: String?

    @Argument(
        help:
            "Build settings parameters to extract (e.g., SWIFT_VERSION IPHONEOS_DEPLOYMENT_TARGET)"
    )
    public var buildSettingsParameters: [String] = []

    @Option(
        name: [.long, .short],
        parsing: .upToNextOption,
        help: "Commit hashes to analyze (default: HEAD)"
    )
    public var commits: [String] = []

    @Option(name: [.long, .short], help: "Path to save JSON results")
    public var output: String?

    @Flag(name: [.long, .short])
    public var verbose: Bool = false

    @Flag(
        help: "Clean working directory before analysis (git clean -ffdx && git reset --hard HEAD)"
    )
    public var gitClean: Bool = false

    @Flag(help: "Fix broken LFS pointers by committing modified files after checkout")
    public var fixLfs: Bool = false

    @Flag(help: "Initialize submodules (reset and update to correct commits)")
    public var initializeSubmodules: Bool = false

    static let logger = Logger(label: "scout.ExtractBuildSettings")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)

        // Load config from file (one-liner convenience init)
        let fileConfig = try await BuildSettingsConfig(configPath: config)

        // Build CLI inputs (git flags are nil when not explicitly set on CLI)
        let cliInputs = BuildSettingsCLIInputs(
            project: project,
            buildSettingsParameters: buildSettingsParameters.nilIfEmpty,
            repoPath: repoPath,
            commits: commits.nilIfEmpty,
            gitClean: gitClean ? true : nil,
            fixLfs: fixLfs ? true : nil,
            initializeSubmodules: initializeSubmodules ? true : nil
        )

        // Merge CLI > Config > Default
        let input = try BuildSettingsInput(cli: cliInputs, config: fileConfig)

        let repoPathURL =
            try URL(string: input.git.repoPath)
            ?! URLError.invalidURL(parameter: "repoPath", value: input.git.repoPath)

        // Resolve HEAD commits
        let resolvedMetrics = try await input.metrics.resolvingHeadCommits(
            repoPath: repoPathURL.path
        )

        var outputResults: [BuildSettingsSDK.Output] = []

        // Group metrics by commits to minimize checkouts
        var commitToSettings: [String: [String]] = [:]
        for metric in resolvedMetrics {
            for commit in metric.commits {
                commitToSettings[commit, default: []].append(metric.setting)
            }
        }

        let allCommits = Array(commitToSettings.keys)
        Self.logger.info(
            "Will analyze \(allCommits.count) commits for \(resolvedMetrics.count) metric(s)",
            metadata: [
                "commits": .array(allCommits.map { Logger.MetadataValue.string($0) }),
                "parameters": .array(
                    resolvedMetrics.map { Logger.MetadataValue.string($0.setting) }
                ),
            ]
        )

        let sdk = BuildSettingsSDK()

        for (hash, settings) in commitToSettings {
            Self.logger.info(
                "Starting analysis for commit",
                metadata: ["hash": "\(hash)", "settings": "\(settings)"]
            )

            let commitOutput: BuildSettingsSDK.Output
            do {
                commitOutput = try await sdk.analyzeCommit(hash: hash, input: input)
            } catch let error as BuildSettingsSDK.AnalysisError {
                Self.logger.warning(
                    "Skipping commit due to analysis failure",
                    metadata: [
                        "hash": "\(hash)",
                        "error": "\(error.localizedDescription)",
                    ]
                )
                continue
            }

            Self.logger.notice(
                "Extracted build settings for \(commitOutput.results.count) targets at \(hash)"
            )

            outputResults.append(commitOutput)
        }

        if let outputPath = output {
            try outputResults.writeJSON(to: outputPath)
        }

        let summary = BuildSettingsSummary(outputs: outputResults)
        GitHubActionsLogHandler.writeSummary(summary)

        Self.logger.notice("Summary: analyzed \(allCommits.count) commit(s)")
    }
}
