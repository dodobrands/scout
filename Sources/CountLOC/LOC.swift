import ArgumentParser
import CodeReader
import Common
import Foundation
import Logging
import SourceKittenFramework
import System
import SystemPackage

enum ClocError: Error {
    case notInstalled
}

extension ClocError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return """
                cloc is not installed. Please install it manually:

                macOS:
                  brew install cloc

                Linux (Ubuntu/Debian):
                  sudo apt-get update && sudo apt-get install -y cloc

                Linux (Fedora/RHEL):
                  sudo dnf install cloc

                Or download from: https://github.com/AlDanial/cloc/releases
                """
        }
    }
}

public struct LOC: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "loc",
        abstract: "Count lines of code"
    )

    struct Summary: JobSummaryFormattable {
        let locResults: [(metric: String, count: Int)]

        var markdown: String {
            var md = "## CountLOC Summary\n\n"

            if !locResults.isEmpty {
                md += "### Lines of Code Counts\n\n"
                md += "| Configuration | LOC |\n"
                md += "|---------------|-----|\n"
                for result in locResults {
                    md += "| \(result.metric) | \(result.count) |\n"
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

    private static let logger = Logger(label: "mobile-code-metrics.CountLOC")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)
        try await checkClocInstalled()

        let configFilePath = SystemPackage.FilePath(config ?? "count-loc-config.json")
        let config = try await CountLOCConfig(configFilePath: configFilePath)

        let repoPathURL =
            try URL(string: repoPath) ?! URLError.invalidURL(parameter: "repoPath", value: repoPath)

        let commitHashes = commits.split(separator: ",").map {
            String($0.trimmingCharacters(in: .whitespaces))
        }

        var locResults: [(metric: String, count: Int)] = []

        for locConfig in config.configurations {
            let metric = "LOC \(locConfig.languages) \(locConfig.include)"
            Self.logger.info("Processing LOC configuration: \(metric)")

            Self.logger.info(
                "Will analyze \(commitHashes.count) commits for configuration '\(metric)'",
                metadata: [
                    "commits": .array(commitHashes.map { .string($0) })
                ]
            )

            let codeReader = CodeReader()

            var lastLOCCount = 0
            for hash in commitHashes {
                try await Shell.execute(
                    "git",
                    arguments: ["checkout", hash],
                    workingDirectory: System.FilePath(repoPathURL.path(percentEncoded: false))
                )
                try await GitFix.fixGitIssues(
                    in: repoPathURL,
                    initializeSubmodules: initializeSubmodules
                )

                let foldersToAnalyze = foldersToAnalyze(
                    in: repoPathURL,
                    include: locConfig.include,
                    exclude: locConfig.exclude
                )

                let loc =
                    try await locConfig.languages
                    .asyncFlatMap { language in
                        try await foldersToAnalyze.asyncMap {
                            try await codeReader.linesOfCode(at: $0, language: language)
                        }
                    }
                    .compactMap { Int($0) }
                    .reduce(0, +)

                Self.logger.notice(
                    "Found \(loc) lines of '\(locConfig.languages)' code at \(hash)"
                )
                lastLOCCount = loc
            }

            Self.logger.notice(
                "Summary for '\(metric)': analyzed \(commitHashes.count) commit(s)"
            )
            if !commitHashes.isEmpty {
                locResults.append((metric, lastLOCCount))
            }
        }

        let summary = Summary(locResults: locResults)
        logSummary(summary)
    }

    private func logSummary(_ summary: Summary) {
        if !summary.locResults.isEmpty {
            Self.logger.info("Lines of code counts:")
            for result in summary.locResults {
                Self.logger.info("  - \(result.metric): \(result.count)")
            }
        }

        writeJobSummary(summary)
    }

    private func writeJobSummary(_ summary: Summary) {
        GitHubActionsLogHandler.writeSummary(summary)
    }

    private func foldersToAnalyze(in repoPath: URL, include: [String], exclude: [String]) -> [URL] {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: repoPath, includingPropertiesForKeys: nil)
        else { return [] }

        var folders = [URL]()

        for case let url as URL in enumerator {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
                isDirectory.boolValue
            {
                if include.contains(where: { url.path.hasSuffix($0) }) {
                    folders.append(url)
                }
            }
        }

        folders = folders.filter { folder in
            !exclude.contains(where: { folder.path.range(of: $0, options: .caseInsensitive) != nil }
            )
        }

        return folders
    }

    private func checkClocInstalled() async throws {
        let result = try await Shell.execute("which", arguments: ["cloc"])
        let isInstalled =
            !result.isEmpty && !result.contains("not found") && result.contains("cloc")

        guard isInstalled else {
            throw ClocError.notInstalled
        }
    }

}
