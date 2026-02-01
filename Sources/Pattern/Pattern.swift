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

        let patternList: [String]
        if !patterns.isEmpty {
            patternList = patterns
        } else {
            let configFilePath = SystemPackage.FilePath(config ?? "search-config.json")
            let searchConfig = try await SearchConfig(configFilePath: configFilePath)
            patternList = searchConfig.patterns
        }

        let repoPathURL =
            try URL(string: repoPath) ?! URLError.invalidURL(parameter: "repoPath", value: repoPath)

        let commitHashes: [String]
        if !commits.isEmpty {
            commitHashes = commits
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
        } else if !patterns.isEmpty {
            fileExtensions = ["swift"]
        } else {
            let configFilePath = SystemPackage.FilePath(config ?? "search-config.json")
            let searchConfig = try await SearchConfig(configFilePath: configFilePath)
            fileExtensions = searchConfig.extensions
        }

        let sdk = PatternSDK()
        var patternResults: [(pattern: String, matchCount: Int)] = []
        var allResults: [PatternSDK.Result] = []

        for pattern in patternList {
            Self.logger.info("Processing pattern: \(pattern)")

            Self.logger.info(
                "Will analyze \(commitHashes.count) commits for pattern '\(pattern)'",
                metadata: [
                    "commits": .array(commitHashes.map { .string($0) })
                ]
            )

            let gitConfig = GitConfiguration(
                repoPath: repoPath,
                clean: gitClean,
                fixLFS: fixLfs,
                initializeSubmodules: initializeSubmodules
            )
            let input = PatternInput(
                git: gitConfig,
                pattern: pattern,
                extensions: fileExtensions
            )

            var lastResult: PatternSDK.Result?
            for hash in commitHashes {
                lastResult = try await sdk.analyzeCommit(hash: hash, input: input)

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
