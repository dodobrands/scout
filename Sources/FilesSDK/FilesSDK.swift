import Common
import Foundation
import Logging
import System

/// A single file extension metric with its commits to analyze.
public struct FileMetricInput: Sendable, CommitResolvable {
    /// File extension to count (e.g., "swift", "storyboard")
    public let `extension`: String

    /// Commits to analyze for this extension
    public let commits: [String]

    public init(extension: String, commits: [String] = ["HEAD"]) {
        self.extension = `extension`
        self.commits = commits
    }

    public func withResolvedCommits(_ commits: [String]) -> FileMetricInput {
        FileMetricInput(extension: `extension`, commits: commits)
    }
}

/// Input parameters for FilesSDK operations.
public struct FilesInput: Sendable {
    public let git: GitConfiguration
    public let metrics: [FileMetricInput]

    public init(
        git: GitConfiguration,
        metrics: [FileMetricInput]
    ) {
        self.git = git
        self.metrics = metrics
    }
}

/// SDK for counting files by extension.
public struct FilesSDK: Sendable {
    private static let logger = Logger(label: "scout.FilesSDK")

    public init() {}

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

    /// Counts files for all metrics in the input.
    /// - Parameter input: Input parameters containing metrics and git configuration
    /// - Returns: Array of results, one for each metric
    func countFiles(input: FilesInput) async throws -> [Result] {
        try await GitFix.prepareRepository(git: input.git)

        let repoPath = URL(filePath: input.git.repoPath)
        return input.metrics.map { metric in
            let files = findFiles(of: metric.extension, in: repoPath)
            return Result(filetype: metric.extension, files: files)
        }
    }

    /// Checks out a commit and counts files for all metrics in input.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - input: Input parameters containing metrics and git configuration
    /// - Returns: Output with commit info, date, and results
    public func analyzeCommit(hash: String, input: FilesInput) async throws -> Output {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        let results = try await countFiles(input: input)
        let date = try await Git.commitDate(for: hash, in: repoPath)

        let resultItems = results.map { ResultItem(filetype: $0.filetype, files: $0.files) }
        return Output(commit: hash, date: date, results: resultItems)
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
