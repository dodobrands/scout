import ArgumentParser
import Common
import Foundation
import Logging
import PatternSDK
import System
import SystemPackage

public struct Pattern: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "pattern",
        abstract: "Search for string patterns in source files"
    )

    struct Summary: JobSummaryFormattable {
        let patternResults: [(pattern: String, matchCount: Int)]

        var markdown: String {
            var md = "## Search Summary\n\n"

            if !patternResults.isEmpty {
                md += "### Pattern Matches\n\n"
                md += "| Pattern | Matches |\n"
                md += "|---------|--------|\n"
                for result in patternResults {
                    md += "| `\(result.pattern)` | \(result.matchCount) |\n"
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

    @Option(name: [.long, .short], help: "Path to save JSON results")
    public var output: String?

    @Option(
        name: [.long, .short],
        help: "Comma-separated file extensions to search (default: swift)"
    )
    public var extensions: String?

    @Flag(name: [.long, .short])
    public var verbose: Bool = false

    @Flag(
        name: [.long, .customShort("I")],
        help: "Initialize submodules (reset and update to correct commits)"
    )
    public var initializeSubmodules: Bool = false

    private static let logger = Logger(label: "scout.Pattern")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)

        let configFilePath = SystemPackage.FilePath(config ?? "search-config.json")
        let searchConfig = try await SearchConfig(configFilePath: configFilePath)

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

        let fileExtensions: [String]
        if let extensions {
            fileExtensions = extensions.split(separator: ",").map {
                String($0.trimmingCharacters(in: .whitespaces))
            }
        } else {
            fileExtensions = searchConfig.extensions
        }

        let sdk = PatternSDK()
        var patternResults: [(pattern: String, matchCount: Int)] = []
        var allResults: [PatternSDK.Result] = []

        for pattern in searchConfig.patterns {
            Self.logger.info("Processing pattern: \(pattern)")

            Self.logger.info(
                "Will analyze \(commitHashes.count) commits for pattern '\(pattern)'",
                metadata: [
                    "commits": .array(commitHashes.map { .string($0) })
                ]
            )

            var lastResult: PatternSDK.Result?
            for hash in commitHashes {
                lastResult = try await sdk.analyzeCommit(
                    hash: hash,
                    repoPath: repoPathURL,
                    pattern: pattern,
                    extensions: fileExtensions,
                    initializeSubmodules: initializeSubmodules
                )

                Self.logger.notice(
                    "Found \(lastResult!.matches.count) matches for '\(pattern)' at \(hash)"
                )
            }

            Self.logger.notice(
                "Summary for '\(pattern)': analyzed \(commitHashes.count) commit(s)"
            )
            if let result = lastResult {
                patternResults.append((pattern, result.matches.count))
                allResults.append(result)
            }
        }

        let summary = Summary(patternResults: patternResults)
        logSummary(summary)

        if let output {
            try saveResults(allResults, to: output)
        }
    }

    private func logSummary(_ summary: Summary) {
        if !summary.patternResults.isEmpty {
            Self.logger.info("Pattern matches:")
            for result in summary.patternResults {
                Self.logger.info("  - \(result.pattern): \(result.matchCount)")
            }
        }

        GitHubActionsLogHandler.writeSummary(summary)
    }

    private func saveResults(_ results: [PatternSDK.Result], to path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(results)
        try data.write(to: URL(fileURLWithPath: path))
        Self.logger.info("Results saved to \(path)")
    }
}
