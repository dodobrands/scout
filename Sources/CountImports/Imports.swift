import ArgumentParser
import Common
import Foundation
import ImportsSDK
import Logging
import System
import SystemPackage

public struct Imports: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "imports",
        abstract: "Count import statements"
    )

    struct Summary: JobSummaryFormattable {
        let importResults: [(importName: String, count: Int)]

        var markdown: String {
            var md = "## CountImports Summary\n\n"

            if !importResults.isEmpty {
                md += "### Import Counts\n\n"
                md += "| Import | Count |\n"
                md += "|--------|-------|\n"
                for result in importResults {
                    md += "| `\(result.importName)` | \(result.count) |\n"
                }
                md += "\n"
            }

            return md
        }
    }

    @Option(name: [.long, .short], help: "Path to iOS repository")
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

    @Flag(name: [.long, .short])
    public var verbose: Bool = false

    @Flag(
        name: [.long, .customShort("I")],
        help: "Initialize submodules (reset and update to correct commits)"
    )
    public var initializeSubmodules: Bool = false

    private static let logger = Logger(label: "scout.CountImports")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)

        let configFilePath = SystemPackage.FilePath(config ?? "count-imports-config.json")
        let config = try await CountImportsConfig(configFilePath: configFilePath)

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

        let sdk = ImportsSDK()
        var importResults: [(importName: String, count: Int)] = []
        var allResults: [ImportsSDK.Result] = []

        for importName in config.imports {
            Self.logger.info("Processing import: \(importName)")

            Self.logger.info(
                "Will analyze \(commitHashes.count) commits for import '\(importName)'",
                metadata: [
                    "commits": .array(commitHashes.map { .string($0) })
                ]
            )

            var lastResult: ImportsSDK.Result?
            for hash in commitHashes {
                lastResult = try await sdk.analyzeCommit(
                    hash: hash,
                    repoPath: repoPathURL,
                    importName: importName,
                    initializeSubmodules: initializeSubmodules
                )

                Self.logger.notice(
                    "Found \(lastResult!.files.count) imports '\(importName)' at \(hash)"
                )
            }

            Self.logger.notice(
                "Summary for '\(importName)': analyzed \(commitHashes.count) commit(s)"
            )
            if let result = lastResult {
                importResults.append((importName, result.files.count))
                allResults.append(result)
            }
        }

        let summary = Summary(importResults: importResults)
        logSummary(summary)

        if let output {
            try saveResults(allResults, to: output)
        }
    }

    private func logSummary(_ summary: Summary) {
        if !summary.importResults.isEmpty {
            Self.logger.info("Import counts:")
            for result in summary.importResults {
                Self.logger.info("  - \(result.importName): \(result.count)")
            }
        }

        GitHubActionsLogHandler.writeSummary(summary)
    }

    private func saveResults(_ results: [ImportsSDK.Result], to path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(results)
        try data.write(to: URL(fileURLWithPath: path))
        Self.logger.info("Results saved to \(path)")
    }
}
