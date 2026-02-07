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
        let outputs: [PatternSDK.Output]

        var markdown: String {
            var md = "## Search Summary\n\n"

            if !outputs.isEmpty {
                md += "### Pattern Matches\n\n"
                md += "| Commit | Pattern | Matches |\n"
                md += "|--------|---------|--------|\n"
                for output in outputs {
                    let commit = output.commit.prefix(Git.shortHashLength)
                    for result in output.results {
                        md += "| `\(commit)` | `\(result.pattern)` | \(result.matches.count) |\n"
                    }
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

        let fileConfig = try await PatternConfig(configPath: config)
        let input = try await buildInput(fileConfig: fileConfig)

        let commitCount = Set(input.metrics.flatMap { $0.commits }).count
        Self.logger.info(
            "Will analyze \(commitCount) commit(s) for \(input.metrics.count) pattern(s)"
        )

        let sdk = PatternSDK()
        let outputs = try await sdk.analyze(input: input)

        for output in outputs {
            for result in output.results {
                Self.logger.notice(
                    "Found \(result.matches.count) matches for '\(result.pattern)' at \(output.commit)"
                )
            }
        }

        if let outputPath = output {
            try outputs.writeJSON(to: outputPath)
        }

        Self.logger.notice(
            "Summary: analyzed \(outputs.count) commit(s) for \(input.metrics.count) pattern(s)"
        )

        let summary = Summary(outputs: outputs)
        logSummary(summary)
    }

    private func buildInput(fileConfig: PatternConfig?) async throws -> PatternSDK.Input {
        let gitConfig = GitConfiguration(
            cli: GitCLIInputs(
                repoPath: repoPath,
                clean: gitClean ? true : nil,
                fixLFS: fixLfs ? true : nil,
                initializeSubmodules: initializeSubmodules ? true : nil
            ),
            fileConfig: fileConfig?.git
        )

        let repoPathURL =
            try URL(string: gitConfig.repoPath)
            ?! URLError.invalidURL(parameter: "repoPath", value: gitConfig.repoPath)

        // Parse extensions from CLI (comma-separated string)
        var resolvedExtensions: [String] = ["swift"]
        if let extensions {
            resolvedExtensions = extensions.split(separator: ",").map {
                String($0.trimmingCharacters(in: .whitespaces))
            }
        } else if let configExtensions = fileConfig?.extensions {
            resolvedExtensions = configExtensions
        }

        // Build metrics from CLI args or config file
        var metrics: [PatternSDK.MetricInput] = []
        if !patterns.isEmpty {
            let commitList = commits.isEmpty ? ["HEAD"] : commits
            metrics = patterns.map { PatternSDK.MetricInput(pattern: $0, commits: commitList) }
        } else if let configMetrics = fileConfig?.metrics {
            metrics = configMetrics.map {
                PatternSDK.MetricInput(pattern: $0.pattern, commits: $0.commits ?? ["HEAD"])
            }
        }

        // Resolve HEAD commits
        let resolvedMetrics = try await metrics.resolvingHeadCommits(repoPath: repoPathURL.path)

        return PatternSDK.Input(
            git: gitConfig,
            metrics: resolvedMetrics,
            extensions: resolvedExtensions
        )
    }

    private func logSummary(_ summary: Summary) {
        if !summary.outputs.isEmpty {
            Self.logger.info("Pattern matches:")
            for output in summary.outputs {
                let commit = output.commit.prefix(Git.shortHashLength)
                for result in output.results {
                    Self.logger.info("  - \(commit): \(result.pattern): \(result.matches.count)")
                }
            }
        }

        GitHubActionsLogHandler.writeSummary(summary)
    }
}
