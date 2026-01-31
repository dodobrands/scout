import ArgumentParser
import Common
import Foundation
import Logging
import System
import SystemPackage
import TypesSDK

public struct Types: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "types",
        abstract: "Count types inherited from specified base types"
    )

    struct Summary: JobSummaryFormattable {
        let typeResults: [(typeName: String, count: Int)]

        var markdown: String {
            var md = "## CountTypes Summary\n\n"

            if !typeResults.isEmpty {
                md += "### Type Counts\n\n"
                md += "| Type | Count |\n"
                md += "|------|-------|\n"
                for result in typeResults {
                    md += "| `\(result.typeName)` | \(result.count) |\n"
                }
                md += "\n"
            }

            return md
        }
    }

    @Option(name: [.long, .short], help: "Path to iOS repository")
    public var iosSources: String

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

    private static let logger = Logger(label: "scout.CountTypes")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)

        let configFilePath = SystemPackage.FilePath(config ?? "count-types-config.json")
        let config = try await CountTypesConfig(configFilePath: configFilePath)

        let repoPath =
            try URL(string: iosSources)
            ?! URLError.invalidURL(parameter: "iosSources", value: iosSources)

        let commitHashes: [String]
        if let commits {
            commitHashes = commits.split(separator: ",").map {
                String($0.trimmingCharacters(in: .whitespaces))
            }
        } else {
            let head = try await Git.headCommit(in: repoPath)
            commitHashes = [head]
            Self.logger.info("No commits specified, using HEAD: \(head)")
        }

        let sdk = TypesSDK()
        var typeResults: [(typeName: String, count: Int)] = []

        for typeName in config.types {
            Self.logger.info("Processing type: \(typeName)")

            Self.logger.info(
                "Will analyze \(commitHashes.count) commits for type '\(typeName)'",
                metadata: [
                    "commits": .array(commitHashes.map { .string($0) })
                ]
            )

            var lastResult: TypesSDK.Result?
            for hash in commitHashes {
                lastResult = try await sdk.analyzeCommit(
                    hash: hash,
                    repoPath: repoPath,
                    typeName: typeName,
                    initializeSubmodules: initializeSubmodules
                )

                Self.logger.notice(
                    "Found \(lastResult!.count) types inherited from \(typeName) at \(hash)"
                )
            }

            Self.logger.notice(
                "Summary for '\(typeName)': analyzed \(commitHashes.count) commit(s)"
            )
            if let result = lastResult {
                typeResults.append((typeName, result.count))
            }
        }

        let summary = Summary(typeResults: typeResults)
        logSummary(summary)
    }

    private func logSummary(_ summary: Summary) {
        if !summary.typeResults.isEmpty {
            Self.logger.info("Type counts:")
            for result in summary.typeResults {
                Self.logger.info("  - \(result.typeName): \(result.count)")
            }
        }

        GitHubActionsLogHandler.writeSummary(summary)
    }
}
