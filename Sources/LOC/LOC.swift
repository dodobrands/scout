import ArgumentParser
import Common
import Foundation
import LOCSDK
import Logging
import SystemPackage

/// JSON output structure for loc command.
struct LOCOutput: Encodable {
    let commit: String
    let date: String
    let results: [String: Int]
}

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
        let resolvedMetrics: [LOCMetricInput] = try await resolveHeadCommits(
            metrics: input.metrics,
            repoPath: repoPathURL
        )

        let sdk = LOCSDK()
        var allResults: [LOCSDK.Result] = []
        var outputResults: [LOCOutput] = []

        // Group metrics by commits to minimize checkouts
        var commitToConfigurations: [String: [LOCConfiguration]] = [:]
        for metric in resolvedMetrics {
            for commit in metric.commits {
                commitToConfigurations[commit, default: []].append(metric.configuration)
            }
        }

        let allCommits = Array(commitToConfigurations.keys)
        Self.logger.info(
            "Will analyze \(allCommits.count) commits for \(resolvedMetrics.count) metric(s)",
            metadata: [
                "commits": .array(allCommits.map { .string($0) })
            ]
        )

        for (hash, configurations) in commitToConfigurations {
            Self.logger.info("Processing commit: \(hash)")

            let results = try await sdk.analyzeCommit(
                hash: hash,
                configurations: configurations,
                input: input
            )
            let date = try await Git.commitDate(for: hash, in: repoPathURL)

            var resultsDict: [String: Int] = [:]
            for result in results {
                Self.logger.notice(
                    "Found \(result.linesOfCode) lines of code for '\(result.metric)' at \(hash)"
                )
                allResults.append(result)
                resultsDict[result.metric] = result.linesOfCode
            }

            let commitOutput = LOCOutput(commit: hash, date: date, results: resultsDict)
            outputResults.append(commitOutput)
        }

        if let outputPath = output {
            try outputResults.writeJSON(to: outputPath)
        }

        Self.logger.notice("Summary: analyzed \(allCommits.count) commit(s)")

        let summary = LOCSummary(results: allResults)
        logSummary(summary)
    }

    /// Resolves HEAD to actual commit hash for metrics that use HEAD
    private func resolveHeadCommits(
        metrics: [LOCMetricInput],
        repoPath: URL
    ) async throws -> [LOCMetricInput] {
        // Check if any metric uses HEAD
        let needsHeadResolution = metrics.contains { $0.commits.contains("HEAD") }
        guard needsHeadResolution else { return metrics }

        let head = try await Git.headCommit(in: repoPath)
        Self.logger.info("Resolved HEAD to: \(head)")

        return metrics.map { metric in
            let resolvedCommits = metric.commits.map { $0 == "HEAD" ? head : $0 }
            return LOCMetricInput(
                languages: metric.languages,
                include: metric.include,
                exclude: metric.exclude,
                commits: resolvedCommits
            )
        }
    }

    private func logSummary(_ summary: LOCSummary) {
        if !summary.results.isEmpty {
            Self.logger.info("Lines of code counts:")
            for result in summary.results {
                let commit = result.commit.prefix(7)
                Self.logger.info("  - \(commit): \(result.metric): \(result.linesOfCode)")
            }
        }

        GitHubActionsLogHandler.writeSummary(summary)
    }
}
