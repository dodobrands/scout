import ArgumentParser
import Common
import Foundation
import Logging
import PatternSDK
import System
import SystemPackage

/// JSON output structure for pattern command.
struct PatternOutput: Encodable {
    let commit: String
    let date: String
    let results: [String: [PatternSDK.Match]]
}

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
    public var repoPath: String?

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

        // Load config from file (one-liner convenience init)
        let fileConfig = try await PatternConfig(configPath: config)

        // Parse extensions from CLI (comma-separated string)
        let cliExtensions: [String]?
        if let extensions {
            cliExtensions = extensions.split(separator: ",").map {
                String($0.trimmingCharacters(in: .whitespaces))
            }
        } else {
            cliExtensions = nil
        }

        // Build CLI inputs (git flags are nil when not explicitly set on CLI)
        let cliInputs = PatternCLIInputs(
            patterns: patterns.nilIfEmpty,
            repoPath: repoPath,
            commits: commits.nilIfEmpty,
            extensions: cliExtensions,
            gitClean: gitClean ? true : nil,
            fixLfs: fixLfs ? true : nil,
            initializeSubmodules: initializeSubmodules ? true : nil
        )

        // Merge CLI > Config > Default
        let input = PatternInput(cli: cliInputs, config: fileConfig)

        let repoPathURL =
            try URL(string: input.git.repoPath)
            ?! URLError.invalidURL(parameter: "repoPath", value: input.git.repoPath)

        // Resolve HEAD commits
        let resolvedMetrics = try await input.metrics.resolvingHeadCommits(
            repoPath: repoPathURL.path
        )

        let sdk = PatternSDK()
        var patternResults: [(pattern: String, matchCount: Int)] = []
        var outputResults: [PatternOutput] = []

        // Group metrics by commits to minimize checkouts
        var commitToPatterns: [String: [String]] = [:]
        for metric in resolvedMetrics {
            for commit in metric.commits {
                commitToPatterns[commit, default: []].append(metric.pattern)
            }
        }

        let allCommits = Array(commitToPatterns.keys)
        Self.logger.info(
            "Will analyze \(allCommits.count) commits for \(resolvedMetrics.count) metric(s)",
            metadata: [
                "commits": .array(allCommits.map { .string($0) }),
                "patterns": .array(resolvedMetrics.map { .string($0.pattern) }),
            ]
        )

        for (hash, patterns) in commitToPatterns {
            Self.logger.info("Processing commit: \(hash) for patterns: \(patterns)")

            let commitInput = PatternInput(
                git: input.git,
                metrics: patterns.map { PatternMetricInput(pattern: $0) },
                extensions: input.extensions
            )
            let results = try await sdk.analyzeCommit(hash: hash, input: commitInput)
            let date = try await Git.commitDate(for: hash, in: repoPathURL)

            var resultsDict: [String: [PatternSDK.Match]] = [:]
            for result in results {
                Self.logger.notice(
                    "Found \(result.matches.count) matches for '\(result.pattern)' at \(hash)"
                )
                resultsDict[result.pattern] = result.matches

                if let existingIndex = patternResults.firstIndex(where: {
                    $0.pattern == result.pattern
                }) {
                    patternResults[existingIndex] = (result.pattern, result.matches.count)
                } else {
                    patternResults.append((result.pattern, result.matches.count))
                }
            }

            let commitOutput = PatternOutput(commit: hash, date: date, results: resultsDict)
            outputResults.append(commitOutput)
        }

        if let outputPath = output {
            try outputResults.writeJSON(to: outputPath)
        }

        Self.logger.notice(
            "Summary: analyzed \(allCommits.count) commit(s) for \(resolvedMetrics.count) pattern(s)"
        )

        let summary = Summary(patternResults: patternResults)
        logSummary(summary)
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
}
