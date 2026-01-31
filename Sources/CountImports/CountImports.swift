import ArgumentParser
import CodeReader
import Common
import Foundation
import Logging
import System
import SystemPackage

@main
public class CountImports: AsyncParsableCommand {
    required public init() {}

    struct Summary: JobSummaryFormattable {
        let importResults: [(importName: String, count: Int)]

        var markdown: String {
            var md = "## CountImports Summary\n\n"

            if !importResults.isEmpty {
                md += "### Import Counts\n\n"
                md += "| Import | Count |\n"
                md += "|--------|-------|\n"
                for result in importResults {
                    md += "| `\(result.importName)` | \(result.count) |\n"
                }
                md += "\n"
            }

            return md
        }
    }

    @Option(name: [.long, .short], help: "Path to iOS repository")
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

    private static let logger = Logger(label: "mobile-code-metrics.CountImports")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)

        let configFilePath = SystemPackage.FilePath(config ?? "count-imports-config.json")
        let config = try await CountImportsConfig(configFilePath: configFilePath)

        let repoPathURL =
            try URL(string: repoPath) ?! URLError.invalidURL(parameter: "repoPath", value: repoPath)

        let commitHashes = commits.split(separator: ",").map {
            String($0.trimmingCharacters(in: .whitespaces))
        }

        var importResults: [(importName: String, count: Int)] = []

        for importName in config.imports {
            Self.logger.info("Processing import: \(importName)")

            Self.logger.info(
                "Will analyze \(commitHashes.count) commits for import '\(importName)'",
                metadata: [
                    "commits": .array(commitHashes.map { .string($0) })
                ]
            )

            var lastImportCount = 0
            for hash in commitHashes {
                lastImportCount = try await analyzeCommit(
                    hash: hash,
                    repoPath: repoPathURL,
                    importName: importName
                )
            }

            Self.logger.notice(
                "Summary for '\(importName)': analyzed \(commitHashes.count) commit(s)"
            )
            if !commitHashes.isEmpty {
                importResults.append((importName, lastImportCount))
            }
        }

        let summary = Summary(importResults: importResults)
        logSummary(summary)
    }

    private func logSummary(_ summary: Summary) {
        if !summary.importResults.isEmpty {
            Self.logger.info("Import counts:")
            for result in summary.importResults {
                Self.logger.info("  - \(result.importName): \(result.count)")
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
        importName: String
    ) async throws -> Int {
        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: System.FilePath(repoPath.path(percentEncoded: false))
        )
        try await GitFix.fixGitIssues(in: repoPath, initializeSubmodules: initializeSubmodules)

        let files = findFiles(of: "swift", in: repoPath) ?? []
        let codeReader = CodeReader()
        let imports =
            try files
            .flatMap { try codeReader.readImports(from: $0) }
            .filter { $0 == importName }

        let value = imports.count

        Self.logger.notice(
            "Found \(value) imports '\(importName)' at \(hash)"
        )

        return value
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
