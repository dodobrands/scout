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

    @Option(name: [.long, .short], help: "Path to repository")
    public var repoPath: String

    @Option(name: .long, help: "Path to configuration JSON file")
    public var config: String?

    @Option(
        name: [.long, .short],
        help: "Comma-separated list of commit hashes to analyze. If not provided, uses HEAD."
    )
    public var commits: String?

    @Flag(name: [.long, .short])
    public var verbose: Bool = false

    @Flag(
        name: [.long, .customShort("I")],
        help: "Initialize submodules (reset and update to correct commits)"
    )
    public var initializeSubmodules: Bool = false

    private static let logger = Logger(label: "scout.CountLOC")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)
        try await LOCSDK.checkClocInstalled()

        let configFilePath = SystemPackage.FilePath(config ?? "count-loc-config.json")
        let config = try await CountLOCConfig(configFilePath: configFilePath)

        let repoPathURL =
            try URL(string: repoPath) ?! URLError.invalidURL(parameter: "repoPath", value: repoPath)

        let commitHashes: [String]
        if let commits {
            commitHashes = commits.split(separator: ",").map {
                String($0.trimmingCharacters(in: .whitespaces))
            }
        } else {
            let head = try await Git.headCommit(in: repoPathURL)
            commitHashes = [head]
            Self.logger.info("No commits specified, using HEAD: \(head)")
        }

        let sdk = LOCSDK()
        var locResults: [(metric: String, count: Int)] = []

        for locConfig in config.configurations {
            let sdkConfig = LOCConfiguration(
                languages: locConfig.languages,
                include: locConfig.include,
                exclude: locConfig.exclude
            )
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
                    repoPath: repoPathURL,
                    configuration: sdkConfig,
                    initializeSubmodules: initializeSubmodules
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
            }
        }

        let summary = Summary(locResults: locResults)
        logSummary(summary)
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
}
