import Common
import Foundation
import Logging
import System

/// SDK for counting files by extension.
public struct FilesSDK: Sendable {
    private static let logger = Logger(label: "scout.FilesSDK")

    public init() {}

    /// Result of file counting operation.
    public struct Result: Sendable, Codable {
        public let filetype: String
        public let files: [String]

        public init(filetype: String, files: [URL]) {
            self.filetype = filetype
            self.files = files.map { $0.path }
        }
    }

    /// Counts files with the specified extension in the repository.
    /// - Parameters:
    ///   - filetype: File extension to count (without dot)
    ///   - repoPath: Path to the repository
    ///   - initializeSubmodules: Whether to initialize git submodules
    /// - Returns: Result containing count and list of matching files
    public func countFiles(
        of filetype: String,
        in repoPath: URL,
        initializeSubmodules: Bool = false
    ) async throws -> Result {
        try await GitFix.fixGitIssues(in: repoPath, initializeSubmodules: initializeSubmodules)

        let files = findFiles(of: filetype, in: repoPath)

        return Result(
            filetype: filetype,
            files: files
        )
    }

    /// Checks out a commit and counts files with the specified extension.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - repoPath: Path to the repository
    ///   - filetype: File extension to count (without dot)
    ///   - initializeSubmodules: Whether to initialize git submodules
    /// - Returns: Result containing count and list of matching files
    public func analyzeCommit(
        hash: String,
        repoPath: URL,
        filetype: String,
        initializeSubmodules: Bool = false
    ) async throws -> Result {
        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        return try await countFiles(
            of: filetype,
            in: repoPath,
            initializeSubmodules: initializeSubmodules
        )
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
