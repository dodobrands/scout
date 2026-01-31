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

    @Option(name: [.long, .short], help: "Path to repository")
    public var repoPath: String

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

    private static let logger = Logger(label: "scout.CountFiles")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)

        let configFilePath = SystemPackage.FilePath(config ?? "count-files-config.json")
        let config = try await CountFilesConfig(configFilePath: configFilePath)

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

        let sdk = FilesSDK()
        var filetypeResults: [(filetype: String, count: Int)] = []

        for filetype in config.filetypes {
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
                    repoPath: repoPathURL,
                    filetype: filetype,
                    initializeSubmodules: initializeSubmodules
                )

                Self.logger.notice(
                    "Found \(lastResult!.count) files of type '\(filetype)' at \(hash)"
                )
            }

            Self.logger.notice(
                "Summary for '\(filetype)': analyzed \(commitHashes.count) commit(s)"
            )
            if let result = lastResult {
                filetypeResults.append((filetype, result.count))
            }
        }

        let summary = Summary(filetypeResults: filetypeResults)
        logSummary(summary)
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
}
