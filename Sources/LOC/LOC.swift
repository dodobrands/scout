import ArgumentParser
import Common
import Foundation
import LOCSDK
import Logging
import SystemPackage

public struct LOC: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "loc",
        abstract: "Count lines of code"
    )

    @Option(name: [.long, .short], help: "Path to repository (default: current directory)")
    public var repoPath: String?

    @Option(help: "Path to configuration JSON file")
    public var config: String?

    @Argument(help: "Programming languages to count (e.g., Swift Objective-C)")
    public var languages: [String] = []

    @Option(
        name: [.long, .short],
        parsing: .upToNextOption,
        help: "Paths to include (e.g., Sources App)"
    )
    public var include: [String] = []

    @Option(
        name: [.long, .short],
        parsing: .upToNextOption,
        help: "Paths to exclude (e.g., Tests Vendor)"
    )
    public var exclude: [String] = []

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

    private static let logger = Logger(label: "scout.CountLOC")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)
        try await LOCSDK.checkClocInstalled()

        // Load config from file (one-liner convenience init)
        let fileConfig = try await LOCConfig(configPath: config)

        // Build CLI inputs (git flags are nil when not explicitly set on CLI)
        let cliInputs = LOCCLIInputs(
            languages: languages.nilIfEmpty,
            include: include.nilIfEmpty,
            exclude: exclude.nilIfEmpty,
            repoPath: repoPath,
            commits: commits.nilIfEmpty,
            gitClean: gitClean ? true : nil,
            fixLfs: fixLfs ? true : nil,
            initializeSubmodules: initializeSubmodules ? true : nil
        )

        // Merge CLI > Config > Default
        let input = LOCInput(cli: cliInputs, config: fileConfig)

        let repoPathURL =
            try URL(string: input.git.repoPath)
            ?! URLError.invalidURL(parameter: "repoPath", value: input.git.repoPath)

        // Resolve HEAD commits
        let resolvedMetrics = try await input.metrics.resolvingHeadCommits(
            repoPath: repoPathURL.path
        )

        let sdk = LOCSDK()
        var outputResults: [LOCSDK.Output] = []

        // Group metrics by commits to minimize checkouts
        var commitToMetrics: [String: [LOCMetricInput]] = [:]
        for metric in resolvedMetrics {
            for commit in metric.commits {
                commitToMetrics[commit, default: []].append(metric)
            }
        }

        let allCommits = Array(commitToMetrics.keys)
        Self.logger.info(
            "Will analyze \(allCommits.count) commits for \(resolvedMetrics.count) metric(s)",
            metadata: [
                "commits": .array(allCommits.map { .string($0) })
            ]
        )

        for (hash, metrics) in commitToMetrics {
            Self.logger.info("Processing commit: \(hash)")

            let commitInput = LOCInput(git: input.git, metrics: metrics)
            let commitOutput = try await sdk.analyzeCommit(hash: hash, input: commitInput)

            for result in commitOutput.results {
                Self.logger.notice(
                    "Found \(result.linesOfCode) lines of code for '\(result.metric)' at \(hash)"
                )
            }

            outputResults.append(commitOutput)
        }

        if let outputPath = output {
            try outputResults.writeJSON(to: outputPath)
        }

        Self.logger.notice("Summary: analyzed \(allCommits.count) commit(s)")

        let summary = LOCSummary(outputs: outputResults)
        logSummary(summary)
    }

    private func logSummary(_ summary: LOCSummary) {
        if !summary.outputs.isEmpty {
            Self.logger.info("Lines of code counts:")
            for output in summary.outputs {
                let commit = output.commit.prefix(7)
                for result in output.results {
                    Self.logger.info("  - \(commit): \(result.metric): \(result.linesOfCode)")
                }
            }
        }

        GitHubActionsLogHandler.writeSummary(summary)
    }
}
