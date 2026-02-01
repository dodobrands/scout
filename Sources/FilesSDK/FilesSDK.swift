import Common
import Foundation
import Logging
import System

/// Input parameters for FilesSDK operations.
public struct FilesInput: Sendable {
    public let git: GitConfiguration
    public let filetype: String

    public init(
        git: GitConfiguration,
        filetype: String
    ) {
        self.git = git
        self.filetype = filetype
    }
}

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
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Result containing count and list of matching files
    public func countFiles(input: FilesInput) async throws -> Result {
        let repoPath = URL(filePath: input.git.repoPath)

        try await GitFix.prepareRepository(
            in: repoPath,
            gitClean: input.git.clean,
            fixLFS: input.git.fixLFS,
            initializeSubmodules: input.git.initializeSubmodules
        )

        let files = findFiles(of: input.filetype, in: repoPath)

        return Result(
            filetype: input.filetype,
            files: files
        )
    }

    /// Checks out a commit and counts files with the specified extension.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - input: Input parameters for the operation
    /// - Returns: Result containing count and list of matching files
    public func analyzeCommit(
        hash: String,
        input: FilesInput
    ) async throws -> Result {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        return try await countFiles(input: input)
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
