import ArgumentParser
import Common
import Files
import Foundation
import Logging
import System
import SystemPackage

public struct FilesCLI: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "files",
        abstract: "Count files by extension"
    )

    @Option(name: [.long, .short], help: "Path to repository (default: current directory)")
    public var repoPath: String?

    @Option(help: "Path to configuration JSON file")
    public var config: String?

    @Argument(help: "File extensions to count (e.g., swift storyboard xib)")
    public var filetypes: [String] = []

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

    private static let logger = Logger(label: "scout.CountFiles")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)

        // Load config from file
        let fileConfig = try await FilesCLIConfig(configPath: config)

        // Build CLI inputs
        let cliInputs = FilesCLIInputs(
            filetypes: filetypes.nilIfEmpty,
            repoPath: repoPath,
            commits: commits.nilIfEmpty,
            gitClean: gitClean ? true : nil,
            fixLfs: fixLfs ? true : nil,
            initializeSubmodules: initializeSubmodules ? true : nil
        )

        // Merge CLI > Config > Default (HEAD commits resolved in SDK.analyze)
        let input = Files.Input(cli: cliInputs, config: fileConfig)

        let commitCount = Set(input.metrics.flatMap { $0.commits }).count
        Self.logger.info(
            "Will analyze \(commitCount) commit(s) for \(input.metrics.count) file type(s)"
        )

        let sdk = Files()
        var outputs: [Files.Output] = []

        for try await output in sdk.analyze(input: input) {
            for result in output.results {
                Self.logger.notice(
                    "Found \(result.files.count) files of type '\(result.filetype)' at \(output.commit)"
                )
            }
            outputs.append(output)

            if let outputPath = self.output {
                try outputs.writeJSON(to: outputPath)
            }
        }

        Self.logger.notice("Summary: analyzed \(outputs.count) commit(s)")

        let summary = FilesCLISummary(outputs: outputs)
        logSummary(summary)
    }

    private func logSummary(_ summary: FilesCLISummary) {
        if !summary.outputs.isEmpty {
            Self.logger.info("\(summary)")
        }
        GitHubActionsLogHandler.writeSummary(summary)
    }
}
