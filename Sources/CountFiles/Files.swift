import ArgumentParser
import Common
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

    @Option(name: [.long, .short], help: "Comma-separated list of commit hashes to analyze")
    public var commits: String

    @Flag(name: [.long, .short])
    public var verbose: Bool = false

    @Flag(
        name: [.long, .customShort("I")],
        help: "Initialize submodules (reset and update to correct commits)"
    )
    public var initializeSubmodules: Bool = false

    private static let logger = Logger(label: "mobile-code-metrics.CountFiles")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)

        let configFilePath = SystemPackage.FilePath(config ?? "count-files-config.json")
        let config = try await CountFilesConfig(configFilePath: configFilePath)

        let repoPathURL =
            try URL(string: repoPath) ?! URLError.invalidURL(parameter: "repoPath", value: repoPath)

        let commitHashes = commits.split(separator: ",").map {
            String($0.trimmingCharacters(in: .whitespaces))
        }

        var filetypeResults: [(filetype: String, count: Int)] = []

        for filetype in config.filetypes {
            Self.logger.info("Processing file type: \(filetype)")

            Self.logger.info(
                "Will analyze \(commitHashes.count) commits for file type '\(filetype)'",
                metadata: [
                    "commits": .array(commitHashes.map { .string($0) })
                ]
            )

            var lastFiletypeCount = 0
            for hash in commitHashes {
                lastFiletypeCount = try await analyzeCommit(
                    hash: hash,
                    repoPath: repoPathURL,
                    filetype: filetype
                )
            }

            Self.logger.notice(
                "Summary for '\(filetype)': analyzed \(commitHashes.count) commit(s)"
            )
            if !commitHashes.isEmpty {
                filetypeResults.append((filetype, lastFiletypeCount))
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

        writeJobSummary(summary)
    }

    private func writeJobSummary(_ summary: Summary) {
        GitHubActionsLogHandler.writeSummary(summary)
    }

    private func analyzeCommit(
        hash: String,
        repoPath: URL,
        filetype: String
    ) async throws -> Int {
        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: System.FilePath(repoPath.path(percentEncoded: false))
        )
        try await GitFix.fixGitIssues(in: repoPath, initializeSubmodules: initializeSubmodules)

        let files = findFiles(of: filetype, in: repoPath) ?? []

        Self.logger.notice(
            "Found \(files.count) files of type '\(filetype)' at \(hash)"
        )

        return files.count
    }

    private func findFiles(of type: String, in directory: URL) -> [URL]? {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: directory.path) else {
            Self.logger.info("Directory does not exist.")
            return nil
        }

        guard
            let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles],
                errorHandler: nil
            )
        else {
            Self.logger.info("Failed to create enumerator.")
            return nil
        }

        var matchingFiles: [URL] = []

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == type {
                matchingFiles.append(fileURL)
            }
        }

        return matchingFiles
    }
}
