import ArgumentParser
import BuildSettingsSDK
import Common
import Foundation
import Logging
import System
import SystemPackage

/// JSON output structure for build-settings command.
struct BuildSettingsOutput: Encodable {
    let commit: String
    let date: String
    let results: [String: [String: String?]]
}

public struct BuildSettings: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "build-settings",
        abstract: "Extract build settings from Xcode projects"
    )

    @Option(name: [.long, .short], help: "Path to repository (default: current directory)")
    public var repoPath: String?

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
            buildSettingsParameters: buildSettingsParameters.nilIfEmpty,
            repoPath: repoPath,
            commits: commits.nilIfEmpty,
            gitClean: gitClean ? true : nil,
            fixLfs: fixLfs ? true : nil,
            initializeSubmodules: initializeSubmodules ? true : nil
        )

        // Merge CLI > Config > Default
        let input = BuildSettingsInput(cli: cliInputs, config: fileConfig)

        let repoPathURL =
            try URL(string: input.git.repoPath)
            ?! URLError.invalidURL(parameter: "repoPath", value: input.git.repoPath)

        // Resolve commits - need to fetch HEAD if not specified
        let commitHashes: [String]
        if !input.commits.isEmpty && input.commits != ["HEAD"] {
            commitHashes = input.commits
        } else {
            let head = try await Git.headCommit(in: repoPathURL)
            commitHashes = [head]
            Self.logger.info("No commits specified, using HEAD: \(head)")
        }

        var outputResults: [BuildSettingsOutput] = []

        Self.logger.info(
            "Will analyze \(commitHashes.count) commits for \(input.buildSettingsParameters.count) parameter(s)",
            metadata: [
                "commits": .array(commitHashes.map { Logger.MetadataValue.string($0) }),
                "parameters": .array(
                    input.buildSettingsParameters.map { Logger.MetadataValue.string($0) }
                ),
            ]
        )

        let sdk = BuildSettingsSDK()

        for hash in commitHashes {
            Self.logger.info(
                "Starting analysis for commit",
                metadata: ["hash": "\(hash)"]
            )

            let result: BuildSettingsSDK.Result
            do {
                result = try await sdk.analyzeCommit(hash: hash, input: input)
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

            let date = try await Git.commitDate(for: hash, in: repoPathURL)

            let resultsDict = result.reduce(into: [String: [String: String?]]()) { dict, target in
                dict[target.target] = input.buildSettingsParameters.reduce(into: [:]) {
                    $0[$1] = target.buildSettings[$1]
                }
            }

            Self.logger.notice(
                "Extracted build settings for \(result.count) targets at \(hash)"
            )

            let commitOutput = BuildSettingsOutput(commit: hash, date: date, results: resultsDict)
            outputResults.append(commitOutput)
        }

        if let outputPath = output {
            try outputResults.writeJSON(to: outputPath)
        }

        let summary = BuildSettingsSummary(results: outputResults)
        GitHubActionsLogHandler.writeSummary(summary)

        Self.logger.notice("Summary: analyzed \(commitHashes.count) commit(s)")
    }
}
