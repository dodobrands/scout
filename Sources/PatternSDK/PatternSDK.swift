import Common
import Foundation
import Logging
import System

/// SDK for searching string patterns in source files.
public struct PatternSDK: Sendable {
    private static let logger = Logger(label: "scout.PatternSDK")

    public init() {}

    /// A single pattern metric with its commits to analyze.
    public struct MetricInput: Sendable, CommitResolvable {
        /// Pattern to search for (e.g., "// TODO:")
        public let pattern: String

        /// Commits to analyze for this pattern
        public let commits: [String]

        public init(pattern: String, commits: [String] = ["HEAD"]) {
            self.pattern = pattern
            self.commits = commits
        }

        public func withResolvedCommits(_ commits: [String]) -> MetricInput {
            MetricInput(pattern: pattern, commits: commits)
        }
    }

    /// Input parameters for PatternSDK operations.
    public struct Input: Sendable {
        public let commit: String
        public let git: GitConfiguration
        public let metrics: [MetricInput]
        public let extensions: [String]

        public init(
            commit: String,
            git: GitConfiguration,
            metrics: [MetricInput],
            extensions: [String] = ["swift"]
        ) {
            self.commit = commit
            self.git = git
            self.metrics = metrics
            self.extensions = extensions
        }
    }

    /// A single match of a pattern in a file.
    public struct Match: Sendable, Encodable {
        public let file: String
        public let line: Int

        public init(file: String, line: Int) {
            self.file = file
            self.line = line
        }
    }

    /// A single pattern result item.
    public struct ResultItem: Sendable, Encodable {
        public let pattern: String
        public let matches: [Match]

        public init(pattern: String, matches: [Match]) {
            self.pattern = pattern
            self.matches = matches
        }
    }

    /// Output of pattern analysis for a single commit.
    public struct Output: Sendable, Encodable {
        public let commit: String
        public let date: String
        public let results: [ResultItem]

        public init(commit: String, date: String, results: [ResultItem]) {
            self.commit = commit
            self.date = date
            self.results = results
        }
    }

    /// Result of pattern search operation.
    public struct Result: Sendable, Encodable {
        public let pattern: String
        public let matches: [Match]

        public init(pattern: String, matches: [Match]) {
            self.pattern = pattern
            self.matches = matches
        }
    }

    /// Searches for occurrences of all patterns in input.metrics.
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Array of results, one for each pattern
    func search(input: Input) async throws -> [Result] {
        let repoPath = URL(filePath: input.git.repoPath)

        try await GitFix.prepareRepository(git: input.git)

        var results: [Result] = []
        for metric in input.metrics {
            var allMatches: [Match] = []
            for ext in input.extensions {
                let files = findFiles(of: ext, in: repoPath)
                for file in files {
                    let fileMatches = try searchInFile(
                        pattern: metric.pattern,
                        file: file,
                        repoPath: repoPath
                    )
                    allMatches.append(contentsOf: fileMatches)
                }
            }
            results.append(Result(pattern: metric.pattern, matches: allMatches))
        }
        return results
    }

    /// Checks out a commit and searches for pattern occurrences.
    /// - Parameter input: Input parameters for the operation including commit hash
    /// - Returns: Output with commit info, date, and results
    public func analyzeCommit(input: Input) async throws -> Output {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Shell.execute(
            "git",
            arguments: ["checkout", input.commit],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        let results = try await search(input: input)
        let date = try await Git.commitDate(for: input.commit, in: repoPath)

        let resultItems = results.map { ResultItem(pattern: $0.pattern, matches: $0.matches) }
        return Output(commit: input.commit, date: date, results: resultItems)
    }

    private func searchInFile(pattern: String, file: URL, repoPath: URL) throws -> [Match] {
        let content = try String(contentsOf: file, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        var matches: [Match] = []

        let relativePath = file.path.replacingOccurrences(
            of: repoPath.path + "/",
            with: ""
        )

        for (index, line) in lines.enumerated() {
            if line.contains(pattern) {
                matches.append(Match(file: relativePath, line: index + 1))
            }
        }

        return matches
    }

    private func findFiles(of type: String, in directory: URL) -> [URL] {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: directory.path) else {
            Self.logger.info("Directory does not exist: \(directory.path)")
            return []
        }

        guard
            let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles],
                errorHandler: nil
            )
        else {
            Self.logger.info("Failed to create enumerator for: \(directory.path)")
            return []
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
