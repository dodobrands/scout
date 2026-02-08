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

        // Load config from file
        let fileConfig = try await TypesConfig(configPath: config)

        // Build CLI inputs
        let cliInputs = TypesCLIInputs(
            types: types.nilIfEmpty,
            repoPath: repoPath,
            commits: commits.nilIfEmpty,
            gitClean: gitClean ? true : nil,
            fixLfs: fixLfs ? true : nil,
            initializeSubmodules: initializeSubmodules ? true : nil
        )

        // Merge CLI > Config > Default (HEAD commits resolved in SDK.analyze)
        let input = TypesSDK.Input(cli: cliInputs, config: fileConfig)

        let commitCount = Set(input.metrics.flatMap { $0.commits }).count
        Self.logger.info(
            "Will analyze \(commitCount) commit(s) for \(input.metrics.count) metric(s)"
        )

        let sdk = TypesSDK()
        var outputs: [TypesSDK.Output] = []

        for try await output in sdk.analyze(input: input) {
            for result in output.results {
                Self.logger.notice(
                    "Found \(result.types.count) types inherited from \(result.typeName) at \(output.commit)"
                )
            }
            outputs.append(output)

            if let outputPath = self.output {
                try outputs.writeJSON(to: outputPath)
            }
        }

        Self.logger.notice("Summary: analyzed \(outputs.count) commit(s)")

        let summary = Summary(outputs: outputs)
        logSummary(summary)
    }

    struct Summary: JobSummaryFormattable {
        let outputs: [TypesSDK.Output]

        var description: String {
            guard !outputs.isEmpty else { return "" }
            var lines = ["Type counts:"]
            for output in outputs {
                let commit = output.commit.prefix(Git.shortHashLength)
                for result in output.results {
                    lines.append("  - \(commit): \(result.typeName): \(result.types.count)")
                }
            }
            return lines.joined(separator: "\n")
        }

        var markdown: String {
            var md = "## CountTypes Summary\n\n"

            if !outputs.isEmpty {
                md += "### Type Counts\n\n"
                md += "| Commit | Type | Count |\n"
                md += "|--------|------|-------|\n"
                for output in outputs {
                    let commit = output.commit.prefix(Git.shortHashLength)
                    for result in output.results {
                        md += "| `\(commit)` | `\(result.typeName)` | \(result.types.count) |\n"
                    }
                }
                md += "\n"
            }

            return md
        }
    }

    private func logSummary(_ summary: Summary) {
        if !summary.outputs.isEmpty {
            Self.logger.info("\(summary)")
        }
        GitHubActionsLogHandler.writeSummary(summary)
    }
}
