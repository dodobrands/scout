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

        var description: String {
            guard !outputs.isEmpty else { return "" }
            var lines = ["Pattern matches:"]
            for output in outputs {
                let commit = output.commit.prefix(Git.shortHashLength)
                for result in output.results {
                    lines.append("  - \(commit): \(result.pattern): \(result.matches.count)")
                }
            }
            return lines.joined(separator: "\n")
        }

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

        // Load config from file
        let fileConfig = try await PatternConfig(configPath: config)

        // Parse extensions from CLI (comma-separated string)
        let parsedExtensions: [String]?
        if let extensions {
            parsedExtensions = extensions.split(separator: ",").map {
                String($0.trimmingCharacters(in: .whitespaces))
            }
        } else {
            parsedExtensions = nil
        }

        // Build CLI inputs
        let cliInputs = PatternCLIInputs(
            patterns: patterns.nilIfEmpty,
            repoPath: repoPath,
            commits: commits.nilIfEmpty,
            extensions: parsedExtensions,
            gitClean: gitClean ? true : nil,
            fixLfs: fixLfs ? true : nil,
            initializeSubmodules: initializeSubmodules ? true : nil
        )

        // Merge CLI > Config > Default (HEAD commits resolved in SDK.analyze)
        let input = PatternSDK.Input(cli: cliInputs, config: fileConfig)

        let commitCount = Set(input.metrics.flatMap { $0.commits }).count
        Self.logger.info(
            "Will analyze \(commitCount) commit(s) for \(input.metrics.count) pattern(s)"
        )

        let sdk = PatternSDK()
        var outputs: [PatternSDK.Output] = []

        for try await output in sdk.analyze(input: input) {
            for result in output.results {
                Self.logger.notice(
                    "Found \(result.matches.count) matches for '\(result.pattern)' at \(output.commit)"
                )
            }
            outputs.append(output)

            if let outputPath = self.output {
                try outputs.writeJSON(to: outputPath)
            }
        }

        Self.logger.notice(
            "Summary: analyzed \(outputs.count) commit(s) for \(input.metrics.count) pattern(s)"
        )

        let summary = Summary(outputs: outputs)
        logSummary(summary)
    }

    private func logSummary(_ summary: Summary) {
        if !summary.outputs.isEmpty {
            Self.logger.info("\(summary)")
        }
        GitHubActionsLogHandler.writeSummary(summary)
    }
}
