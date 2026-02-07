import ArgumentParser
import Common
import Foundation
import Logging
import System
import SystemPackage
import TypesSDK

public struct Types: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "types",
        abstract: "Count Swift types inherited from specified base types"
    )

    @Option(
        name: [.long, .short],
        help: "Path to repository with Swift sources (default: current directory)"
    )
    public var repoPath: String?

    @Option(help: "Path to configuration JSON file")
    public var config: String?

    @Argument(help: "Type names to count (e.g., UIView UIViewController)")
    public var types: [String] = []

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

    private static let logger = Logger(label: "scout.CountTypes")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)

        // Load config from file (one-liner convenience init)
        let fileConfig = try await TypesConfig(configPath: config)

        // Build CLI inputs (git flags are nil when not explicitly set on CLI)
        let cliInputs = TypesCLIInputs(
            types: types.nilIfEmpty,
            repoPath: repoPath,
            commits: commits.nilIfEmpty,
            gitClean: gitClean ? true : nil,
            fixLfs: fixLfs ? true : nil,
            initializeSubmodules: initializeSubmodules ? true : nil
        )

        // Merge CLI > Config > Default
        let cliConfig = TypesCLIConfig(cli: cliInputs, config: fileConfig)

        let repoPathURL =
            try URL(string: cliConfig.git.repoPath)
            ?! URLError.invalidURL(parameter: "repoPath", value: cliConfig.git.repoPath)

        // Resolve HEAD commits
        let resolvedMetrics = try await cliConfig.metrics.resolvingHeadCommits(
            repoPath: repoPathURL.path
        )

        let sdk = TypesSDK()
        var outputResults: [TypesSDK.Output] = []

        // Group metrics by commits to minimize checkouts
        var commitToTypes: [String: [String]] = [:]
        for metric in resolvedMetrics {
            for commit in metric.commits {
                commitToTypes[commit, default: []].append(metric.type)
            }
        }

        let allCommits = Array(commitToTypes.keys)
        Self.logger.info(
            "Will analyze \(allCommits.count) commits for \(resolvedMetrics.count) metric(s)",
            metadata: [
                "commits": .array(allCommits.map { .string($0) }),
                "types": .array(resolvedMetrics.map { .string($0.type) }),
            ]
        )

        for (hash, typeNames) in commitToTypes {
            Self.logger.info("Processing commit: \(hash) for types: \(typeNames)")

            let commitInput = TypesSDK.Input(
                commit: hash,
                git: cliConfig.git,
                metrics: typeNames.map { TypesSDK.MetricInput(type: $0) }
            )
            let commitOutput = try await sdk.analyzeCommit(input: commitInput)

            for result in commitOutput.results {
                Self.logger.notice(
                    "Found \(result.types.count) types inherited from \(result.typeName) at \(hash)"
                )
            }

            outputResults.append(commitOutput)
        }

        if let outputPath = output {
            try outputResults.writeJSON(to: outputPath)
        }

        Self.logger.notice("Summary: analyzed \(allCommits.count) commit(s)")

        let summary = TypesSummary(outputs: outputResults)
        logSummary(summary)
    }

    private func logSummary(_ summary: TypesSummary) {
        if !summary.outputs.isEmpty {
            Self.logger.info("Type counts:")
            for output in summary.outputs {
                let commit = output.commit.prefix(Git.shortHashLength)
                for result in output.results {
                    Self.logger.info("  - \(commit): \(result.typeName): \(result.types.count)")
                }
            }
        }

        GitHubActionsLogHandler.writeSummary(summary)
    }
}
