import ArgumentParser
import Common
import Foundation
import LOC
import Logging
import SystemPackage

public struct LOCCLI: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "loc",
        abstract: "Count lines of code"
    )

    @Option(name: [.long, .short], help: "Path to repository (default: current directory)")
    public var repoPath: String?

    @Option(help: "Path to configuration JSON file")
    public var config: String?

    @Argument(help: "Programming languages to count (e.g., Swift Objective-C)")
    public var languages: [String] = []

    @Option(
        name: [.long, .short],
        parsing: .upToNextOption,
        help: "Paths to include (e.g., Sources App)"
    )
    public var include: [String] = []

    @Option(
        name: [.long, .short],
        parsing: .upToNextOption,
        help: "Paths to exclude (e.g., Tests Vendor)"
    )
    public var exclude: [String] = []

    @Option(
        name: [.long, .short],
        parsing: .upToNextOption,
        help: "Commit hashes to analyze (default: HEAD)"
    )
    public var commits: [String] = []

    @Option(
        help: "Template for metric identifier with placeholders (%langs%, %include%, %exclude%)"
    )
    public var nameTemplate: String?

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

    private static let logger = Logger(label: "scout.CountLOC")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)
        try await LOC.checkClocInstalled()

        // Load config from file
        let fileConfig = try await LOCCLIConfig(configPath: config)

        // Build CLI inputs
        let cliInputs = LOCCLIInputs(
            languages: languages.nilIfEmpty,
            include: include.nilIfEmpty,
            exclude: exclude.nilIfEmpty,
            repoPath: repoPath,
            commits: commits.nilIfEmpty,
            nameTemplate: nameTemplate,
            gitClean: gitClean ? true : nil,
            fixLfs: fixLfs ? true : nil,
            initializeSubmodules: initializeSubmodules ? true : nil
        )

        // Merge CLI > Config > Default (HEAD commits resolved in SDK.analyze)
        let input = LOC.Input(cli: cliInputs, config: fileConfig)

        let commitCount = Set(input.metrics.flatMap { $0.commits }).count
        Self.logger.info(
            "Will analyze \(commitCount) commit(s) for \(input.metrics.count) metric(s)"
        )

        let sdk = LOC()
        var outputs: [LOC.Output] = []

        for try await output in sdk.analyze(input: input) {
            for result in output.results {
                Self.logger.info(
                    "Found \(result.linesOfCode) LOC for '\(result.metric)' at \(output.commit)"
                )
            }
            outputs.append(output)

            if let outputPath = self.output {
                try outputs.writeJSON(to: outputPath)
            }
        }

        Self.logger.notice("Summary: analyzed \(outputs.count) commit(s)")

        let summary = LOCCLISummary(outputs: outputs)
        logSummary(summary)
    }

    private func logSummary(_ summary: LOCCLISummary) {
        if !summary.outputs.isEmpty {
            Self.logger.info("\(summary)")
        }
        GitHubActionsLogHandler.writeSummary(summary)
    }
}
