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

    struct Summary: JobSummaryFormattable {
        let filetypeResults: [(filetype: String, count: Int)]

        var markdown: String {
            var md = "## CountFiles Summary\n\n"

            if !filetypeResults.isEmpty {
                md += "### File Type Counts\n\n"
                md += "| File Type | Count |\n"
                md += "|-----------|-------|\n"
                for result in filetypeResults {
                    md += "| `.\(result.filetype)` | \(result.count) |\n"
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

        // Resolve commits - need to fetch HEAD if not specified
        let commitHashes: [String]
        if !input.commits.isEmpty && input.commits != ["HEAD"] {
            commitHashes = input.commits
        } else {
            let head = try await Git.headCommit(in: repoPathURL)
            commitHashes = [head]
            Self.logger.info("No commits specified, using HEAD: \(head)")
        }

        let sdk = FilesSDK()
        var filetypeResults: [(filetype: String, count: Int)] = []
        var allResults: [FilesSDK.Result] = []

        for filetype in input.filetypes {
            Self.logger.info("Processing file type: \(filetype)")

            Self.logger.info(
                "Will analyze \(commitHashes.count) commits for file type '\(filetype)'",
                metadata: [
                    "commits": .array(commitHashes.map { .string($0) })
                ]
            )

            var lastResult: FilesSDK.Result?
            for hash in commitHashes {
                lastResult = try await sdk.analyzeCommit(
                    hash: hash,
                    filetype: filetype,
                    input: input
                )

                Self.logger.notice(
                    "Found \(lastResult!.files.count) files of type '\(filetype)' at \(hash)"
                )
            }

            Self.logger.notice(
                "Summary for '\(filetype)': analyzed \(commitHashes.count) commit(s)"
            )
            if let result = lastResult {
                filetypeResults.append((filetype, result.files.count))
                allResults.append(result)
            }
        }

        let summary = Summary(filetypeResults: filetypeResults)
        logSummary(summary)

        if let output {
            try saveResults(allResults, to: output)
        }
    }

    private func logSummary(_ summary: Summary) {
        if !summary.filetypeResults.isEmpty {
            Self.logger.info("File type counts:")
            for result in summary.filetypeResults {
                Self.logger.info("  - \(result.filetype): \(result.count)")
            }
        }

        GitHubActionsLogHandler.writeSummary(summary)
    }

    private func saveResults(_ results: [FilesSDK.Result], to path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(results)
        try data.write(to: URL(fileURLWithPath: path))
        Self.logger.info("Results saved to \(path)")
    }
}
