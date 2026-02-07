import Common
import Foundation
import Logging
import System

/// SDK for counting files by extension.
public struct FilesSDK: Sendable {
    private static let logger = Logger(label: "scout.FilesSDK")

    public init() {}

    /// A single file extension metric with its commits to analyze.
    public struct MetricInput: Sendable, CommitResolvable {
        /// File extension to count (e.g., "swift", "storyboard")
        public let `extension`: String

        /// Commits to analyze for this extension
        public let commits: [String]

        public init(extension: String, commits: [String] = ["HEAD"]) {
            self.extension = `extension`
            self.commits = commits
        }

        public func withResolvedCommits(_ commits: [String]) -> MetricInput {
            MetricInput(extension: `extension`, commits: commits)
        }
    }

    /// Input parameters for FilesSDK operations.
    public struct Input: Sendable {
        public let git: GitConfiguration
        public let metrics: [MetricInput]

        public init(
            git: GitConfiguration,
            metrics: [MetricInput]
        ) {
            self.git = git
            self.metrics = metrics
        }
    }

    /// A single files result item.
    public struct ResultItem: Sendable, Encodable {
        public let filetype: String
        public let files: [String]

        public init(filetype: String, files: [String]) {
            self.filetype = filetype
            self.files = files
        }
    }

    /// Output of files analysis for a single commit.
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

    /// Result of file counting operation.
    public struct Result: Sendable, Encodable {
        public let commit: String
        public let filetype: String
        public let files: [String]

        public init(commit: String = "", filetype: String, files: [URL]) {
            self.commit = commit
            self.filetype = filetype
            self.files = files.map { $0.path }
        }

        public init(commit: String, filetype: String, files: [String]) {
            self.commit = commit
            self.filetype = filetype
            self.files = files
        }
    }

    /// Counts files for specific commit (filters metrics that include this commit).
    /// Counts files for specific commit (filters metrics that include this commit).
    private func countFilesForCommit(_ commit: String, input: Input) async throws -> [Result] {
        try await GitFix.prepareRepository(git: input.git)

        let repoPath = URL(filePath: input.git.repoPath)
        return input.metrics.filter { $0.commits.contains(commit) }.map { metric in
            let files = findFiles(of: metric.extension, in: repoPath)
            return Result(filetype: metric.extension, files: files)
        }
    }

    /// Counts files for all metrics without checkout (for testing).
    func countFiles(input: Input) async throws -> [Result] {
        try await GitFix.prepareRepository(git: input.git)

        let repoPath = URL(filePath: input.git.repoPath)
        return input.metrics.map { metric in
            let files = findFiles(of: metric.extension, in: repoPath)
            return Result(filetype: metric.extension, files: files)
        }
    }

    /// Analyzes all commits from metrics and returns outputs for each.
    /// Groups metrics by commit to minimize checkouts.
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Array of outputs, one for each unique commit
    public func analyze(input: Input) async throws -> [Output] {
        let repoPath = URL(filePath: input.git.repoPath)

        // Group metrics by commit to minimize checkouts
        var commitToFiletypes: [String: [String]] = [:]
        for metric in input.metrics {
            for commit in metric.commits {
                commitToFiletypes[commit, default: []].append(metric.extension)
            }
        }

        var outputs: [Output] = []
        for (hash, _) in commitToFiletypes {
            Self.logger.debug("Processing commit: \(hash)")

            try await Shell.execute(
                "git",
                arguments: ["checkout", hash],
                workingDirectory: FilePath(repoPath.path(percentEncoded: false))
            )

            let results = try await countFilesForCommit(hash, input: input)
            let date = try await Git.commitDate(for: hash, in: repoPath)

            let resultItems = results.map { ResultItem(filetype: $0.filetype, files: $0.files) }
            outputs.append(Output(commit: hash, date: date, results: resultItems))
        }

        return outputs
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
