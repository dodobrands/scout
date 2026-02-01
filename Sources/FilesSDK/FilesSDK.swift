import Common
import Foundation
import Logging
import System

/// Input parameters for FilesSDK operations.
public struct FilesInput: Sendable {
    public let git: GitConfiguration
    public let filetypes: [String]
    public let commits: [String]

    public init(
        git: GitConfiguration,
        filetypes: [String],
        commits: [String] = ["HEAD"]
    ) {
        self.git = git
        self.filetypes = filetypes
        self.commits = commits
    }
}

/// SDK for counting files by extension.
public struct FilesSDK: Sendable {
    private static let logger = Logger(label: "scout.FilesSDK")

    public init() {}

    /// Result of file counting operation.
    public struct Result: Sendable, Codable {
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

    /// Counts files with the specified extension in the repository.
    /// - Parameters:
    ///   - filetype: File extension to count
    ///   - input: Input parameters for the operation
    /// - Returns: Result containing count and list of matching files
    public func countFiles(filetype: String, input: FilesInput) async throws -> Result {
        let repoPath = URL(filePath: input.git.repoPath)

        try await GitFix.prepareRepository(git: input.git)

        let files = findFiles(of: filetype, in: repoPath)

        return Result(
            filetype: filetype,
            files: files
        )
    }

    /// Counts files with all specified extensions in the repository.
    /// - Parameter input: Input parameters including array of filetypes
    /// - Returns: Array of results, one for each filetype
    public func countFiles(input: FilesInput) async throws -> [Result] {
        var results: [Result] = []
        for filetype in input.filetypes {
            let result = try await countFiles(filetype: filetype, input: input)
            results.append(result)
        }
        return results
    }

    /// Checks out a commit and counts files with the specified extension.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - filetype: File extension to count
    ///   - input: Input parameters for the operation
    /// - Returns: Result containing count and list of matching files
    public func analyzeCommit(
        hash: String,
        filetype: String,
        input: FilesInput
    ) async throws -> Result {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        return try await countFiles(filetype: filetype, input: input)
    }

    /// Checks out a commit and counts files with all specified extensions.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - input: Input parameters including array of filetypes
    /// - Returns: Array of results, one for each filetype
    public func analyzeCommit(
        hash: String,
        input: FilesInput
    ) async throws -> [Result] {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        return try await countFiles(input: input).map {
            Result(commit: hash, filetype: $0.filetype, files: $0.files)
        }
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
