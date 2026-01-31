import CodeReader
import Common
import Foundation
import Logging
import System

/// SDK for counting import statements.
public struct ImportsSDK: Sendable {
    private static let logger = Logger(label: "scout.ImportsSDK")

    public init() {}

    /// Result of import counting operation.
    public struct Result: Sendable {
        public let importName: String
        public let count: Int

        public init(importName: String, count: Int) {
            self.importName = importName
            self.count = count
        }
    }

    /// Counts occurrences of the specified import in the repository.
    /// - Parameters:
    ///   - importName: Import name to count
    ///   - repoPath: Path to the repository
    ///   - initializeSubmodules: Whether to initialize git submodules
    /// - Returns: Result containing count of matching imports
    public func countImports(
        of importName: String,
        in repoPath: URL,
        initializeSubmodules: Bool = false
    ) async throws -> Result {
        try await GitFix.fixGitIssues(in: repoPath, initializeSubmodules: initializeSubmodules)

        let files = findFiles(of: "swift", in: repoPath)
        let codeReader = CodeReader()
        let imports =
            try files
            .flatMap { try codeReader.readImports(from: $0) }
            .filter { $0 == importName }

        return Result(
            importName: importName,
            count: imports.count
        )
    }

    /// Checks out a commit and counts occurrences of the specified import.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - repoPath: Path to the repository
    ///   - importName: Import name to count
    ///   - initializeSubmodules: Whether to initialize git submodules
    /// - Returns: Result containing count of matching imports
    public func analyzeCommit(
        hash: String,
        repoPath: URL,
        importName: String,
        initializeSubmodules: Bool = false
    ) async throws -> Result {
        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        return try await countImports(
            of: importName,
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
