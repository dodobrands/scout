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
        let outputs = try await sdk.analyze(input: input)

        for output in outputs {
            for result in output.results {
                Self.logger.notice(
                    "Found \(result.types.count) types inherited from \(result.typeName) at \(output.commit)"
                )
            }
        }

        if let outputPath = output {
            try outputs.writeJSON(to: outputPath)
        }

        Self.logger.notice("Summary: analyzed \(outputs.count) commit(s)")

        let summary = TypesSummary(outputs: outputs)
        logSummary(summary)
    }

    private func logSummary(_ summary: TypesSummary) {
        if !summary.outputs.isEmpty {
            Self.logger.info("Type counts:")
            for output in summary.outputs {
                let commit = output.commit.prefix(Git.shortHashLength)
                for result in output.results {
                    Self.logger.info("  - \(commit): \(result.typeName): \(result.types.count)")
                }
            }
        }

        GitHubActionsLogHandler.writeSummary(summary)
    }
}
