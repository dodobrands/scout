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
        abstract: "Count Swift types inherited from specified base types"
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

    @Option(
        name: [.long, .short],
        help: "Path to repository with Swift sources (default: current directory)"
    )
    public var repoPath: String?

    @Option(help: "Path to configuration JSON file")
    public var config: String?

    @Argument(help: "Type names to count (e.g., UIView UIViewController)")
    public var types: [String] = []

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

    private static let logger = Logger(label: "scout.CountTypes")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)

        // Load config from file (one-liner convenience init)
        let fileConfig = try await TypesConfig(configPath: config)

        // Build CLI inputs (git flags are nil when not explicitly set on CLI)
        let cliInputs = TypesCLIInputs(
            types: types.nilIfEmpty,
            repoPath: repoPath,
            commits: commits.nilIfEmpty,
            gitClean: gitClean ? true : nil,
            fixLfs: fixLfs ? true : nil,
            initializeSubmodules: initializeSubmodules ? true : nil
        )

        // Merge CLI > Config > Default
        let input = TypesInput(cli: cliInputs, config: fileConfig)

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

        let sdk = TypesSDK()
        var typeResults: [(typeName: String, count: Int)] = []
        let jsonWriter = output.map { IncrementalJSONWriter<TypesSDK.Result>(path: $0) }

        for typeName in input.types {
            Self.logger.info("Processing type: \(typeName)")

            Self.logger.info(
                "Will analyze \(commitHashes.count) commits for type '\(typeName)'",
                metadata: [
                    "commits": .array(commitHashes.map { .string($0) })
                ]
            )

            var lastResult: TypesSDK.Result?
            for hash in commitHashes {
                let result = try await sdk.analyzeCommit(
                    hash: hash,
                    typeName: typeName,
                    input: input
                )
                lastResult = result

                Self.logger.notice(
                    "Found \(result.types.count) types inherited from \(typeName) at \(hash)"
                )

                try jsonWriter?.append(result)
            }

            Self.logger.notice(
                "Summary for '\(typeName)': analyzed \(commitHashes.count) commit(s)"
            )
            if let result = lastResult {
                typeResults.append((typeName, result.types.count))
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
