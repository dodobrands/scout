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

        let fileConfig = try await TypesConfig(configPath: config)
        let input = try await buildInput(fileConfig: fileConfig)

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

    private func buildInput(fileConfig: TypesConfig?) async throws -> TypesSDK.Input {
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

        // Build metrics from CLI args or config file
        var metrics: [TypesSDK.MetricInput] = []
        if !types.isEmpty {
            // CLI args take priority
            let commitList = commits.isEmpty ? ["HEAD"] : commits
            metrics = types.map { TypesSDK.MetricInput(type: $0, commits: commitList) }
        } else if let configMetrics = fileConfig?.metrics {
            metrics = configMetrics.map {
                TypesSDK.MetricInput(type: $0.type, commits: $0.commits ?? ["HEAD"])
            }
        }

        // Resolve HEAD commits
        let resolvedMetrics = try await metrics.resolvingHeadCommits(repoPath: repoPathURL.path)

        return TypesSDK.Input(git: gitConfig, metrics: resolvedMetrics)
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
