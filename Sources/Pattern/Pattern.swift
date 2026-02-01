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

    @Option(name: [.long, .short], help: "Path to repository (default: current directory)")
    public var repoPath: String = FileManager.default.currentDirectoryPath

    @Option(help: "Path to configuration JSON file")
    public var config: String?

    @Argument(help: "Patterns to search (e.g., \"import UIKit\" \"import SwiftUI\")")
    public var patterns: [String] = []

    @Option(
        name: [.long, .short],
        parsing: .upToNextOption,
        help: "Commit hashes to analyze (default: HEAD)"
    )
    public var commits: [String] = []

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
        help: "Clean working directory before analysis (git clean -ffdx && git reset --hard HEAD)"
    )
    public var gitClean: Bool = false

    @Flag(help: "Fix broken LFS pointers by committing modified files after checkout")
    public var fixLfs: Bool = false

    @Flag(help: "Initialize submodules (reset and update to correct commits)")
    public var initializeSubmodules: Bool = false

    private static let logger = Logger(label: "scout.Pattern")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)

        // Load config from file if specified
        let fileConfig: SearchConfig?
        if let configPath = config {
            fileConfig = try await SearchConfig(configFilePath: SystemPackage.FilePath(configPath))
        } else if FileManager.default.fileExists(atPath: "search-config.json") {
            fileConfig = try await SearchConfig(
                configFilePath: SystemPackage.FilePath("search-config.json")
            )
        } else {
            fileConfig = nil
        }

        // Parse extensions from CLI (comma-separated string)
        let cliExtensions: [String]?
        if let extensions {
            cliExtensions = extensions.split(separator: ",").map {
                String($0.trimmingCharacters(in: .whitespaces))
            }
        } else {
            cliExtensions = nil
        }

        // Build CLI inputs
        let cliInputs = PatternCLIInputs(
            patterns: patterns.isEmpty ? nil : patterns,
            repoPath: repoPath == FileManager.default.currentDirectoryPath ? nil : repoPath,
            commits: commits.isEmpty ? nil : commits,
            extensions: cliExtensions,
            gitClean: gitClean,
            fixLfs: fixLfs,
            initializeSubmodules: initializeSubmodules
        )

        // Merge CLI > Config > Default
        let input = PatternInput(cli: cliInputs, config: fileConfig)

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

        let sdk = PatternSDK()
        var patternResults: [(pattern: String, matchCount: Int)] = []
        var allResults: [PatternSDK.Result] = []

        for pattern in input.patterns {
            Self.logger.info("Processing pattern: \(pattern)")

            Self.logger.info(
                "Will analyze \(commitHashes.count) commits for pattern '\(pattern)'",
                metadata: [
                    "commits": .array(commitHashes.map { .string($0) })
                ]
            )

            var lastResult: PatternSDK.Result?
            for hash in commitHashes {
                lastResult = try await sdk.analyzeCommit(hash: hash, pattern: pattern, input: input)

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
