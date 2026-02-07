import ArgumentParser
import Common
import FilesSDK
import Foundation
import Logging
import System
import SystemPackage

public struct Files: AsyncParsableCommand {
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

        // Load config from file (one-liner convenience init)
        let fileConfig = try await FilesConfig(configPath: config)

        // Build CLI inputs (git flags are nil when not explicitly set on CLI)
        let cliInputs = FilesCLIInputs(
            filetypes: filetypes.nilIfEmpty,
            repoPath: repoPath,
            commits: commits.nilIfEmpty,
            gitClean: gitClean ? true : nil,
            fixLfs: fixLfs ? true : nil,
            initializeSubmodules: initializeSubmodules ? true : nil
        )

        // Merge CLI > Config > Default
        let input = FilesInput(cli: cliInputs, config: fileConfig)

        let repoPathURL =
            try URL(string: input.git.repoPath)
            ?! URLError.invalidURL(parameter: "repoPath", value: input.git.repoPath)

        // Resolve HEAD commits
        let resolvedMetrics = try await input.metrics.resolvingHeadCommits(
            repoPath: repoPathURL.path
        )

        let sdk = FilesSDK()
        var outputResults: [FilesSDK.Output] = []

        // Group metrics by commits to minimize checkouts
        var commitToFiletypes: [String: [String]] = [:]
        for metric in resolvedMetrics {
            for commit in metric.commits {
                commitToFiletypes[commit, default: []].append(metric.extension)
            }
        }

        let allCommits = Array(commitToFiletypes.keys)
        Self.logger.info(
            "Will analyze \(allCommits.count) commits for \(resolvedMetrics.count) file type(s)",
            metadata: [
                "commits": .array(allCommits.map { .string($0) }),
                "filetypes": .array(resolvedMetrics.map { .string($0.extension) }),
            ]
        )

        for (hash, filetypes) in commitToFiletypes {
            Self.logger.info("Processing commit: \(hash) for filetypes: \(filetypes)")

            let commitInput = FilesInput(
                git: input.git,
                metrics: filetypes.map { FileMetricInput(extension: $0) }
            )
            let commitOutput = try await sdk.analyzeCommit(hash: hash, input: commitInput)

            for result in commitOutput.results {
                Self.logger.notice(
                    "Found \(result.files.count) files of type '\(result.filetype)' at \(hash)"
                )
            }

            outputResults.append(commitOutput)
        }

        if let outputPath = output {
            try outputResults.writeJSON(to: outputPath)
        }

        Self.logger.notice("Summary: analyzed \(allCommits.count) commit(s)")

        let summary = FilesSummary(outputs: outputResults)
        logSummary(summary)
    }

    private func logSummary(_ summary: FilesSummary) {
        if !summary.outputs.isEmpty {
            Self.logger.info("File type counts:")
            for output in summary.outputs {
                let commit = output.commit.prefix(7)
                for result in output.results {
                    Self.logger.info("  - \(commit): \(result.filetype): \(result.files.count)")
                }
            }
        }

        GitHubActionsLogHandler.writeSummary(summary)
    }
}
