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

    struct Summary: JobSummaryFormattable {
        let locResults: [(metric: String, count: Int)]

        var markdown: String {
            var md = "## CountLOC Summary\n\n"

            if !locResults.isEmpty {
                md += "### Lines of Code Counts\n\n"
                md += "| Configuration | LOC |\n"
                md += "|---------------|-----|\n"
                for result in locResults {
                    md += "| \(result.metric) | \(result.count) |\n"
                }
                md += "\n"
            }

            return md
        }
    }

    @Option(name: [.long, .short], help: "Path to repository (default: current directory)")
    public var repoPath: String?

    @Option(help: "Path to configuration JSON file")
    public var config: String?

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

        // Load config from file if specified
        let fileConfig: LOCConfig?
        if let configPath = config {
            fileConfig = try await LOCConfig(
                configFilePath: SystemPackage.FilePath(configPath)
            )
        } else if FileManager.default.fileExists(atPath: "count-loc-config.json") {
            fileConfig = try await LOCConfig(
                configFilePath: SystemPackage.FilePath("count-loc-config.json")
            )
        } else {
            fileConfig = nil
        }

        // Build CLI inputs (git flags are nil when not explicitly set on CLI)
        let cliInputs = LOCCLIInputs(
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

        // Resolve commits - need to fetch HEAD if not specified
        let commitHashes: [String]
        if !input.commits.isEmpty && input.commits != ["HEAD"] {
            commitHashes = input.commits
        } else {
            let head = try await Git.headCommit(in: repoPathURL)
            commitHashes = [head]
            Self.logger.info("No commits specified, using HEAD: \(head)")
        }

        let sdk = LOCSDK()
        var locResults: [(metric: String, count: Int)] = []
        var allResults: [LOCSDK.Result] = []

        for locConfig in input.configurations {
            let metric = "LOC \(locConfig.languages) \(locConfig.include)"
            Self.logger.info("Processing LOC configuration: \(metric)")

            Self.logger.info(
                "Will analyze \(commitHashes.count) commits for configuration '\(metric)'",
                metadata: [
                    "commits": .array(commitHashes.map { .string($0) })
                ]
            )

            var lastResult: LOCSDK.Result?
            for hash in commitHashes {
                lastResult = try await sdk.analyzeCommit(
                    hash: hash,
                    configuration: locConfig,
                    input: input
                )

                Self.logger.notice(
                    "Found \(lastResult!.linesOfCode) lines of '\(locConfig.languages)' code at \(hash)"
                )
            }

            Self.logger.notice(
                "Summary for '\(metric)': analyzed \(commitHashes.count) commit(s)"
            )
            if let result = lastResult {
                locResults.append((metric, result.linesOfCode))
                allResults.append(result)
            }
        }

        let summary = Summary(locResults: locResults)
        logSummary(summary)

        if let output {
            try saveResults(allResults, to: output)
        }
    }

    private func logSummary(_ summary: Summary) {
        if !summary.locResults.isEmpty {
            Self.logger.info("Lines of code counts:")
            for result in summary.locResults {
                Self.logger.info("  - \(result.metric): \(result.count)")
            }
        }

        GitHubActionsLogHandler.writeSummary(summary)
    }

    private func saveResults(_ results: [LOCSDK.Result], to path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(results)
        try data.write(to: URL(fileURLWithPath: path))
        Self.logger.info("Results saved to \(path)")
    }
}
