import Foundation
import Logging
import System

package enum Git {
    private static let logger = Logger(label: "scout.Git")

    /// Standard length for short commit hash display (e.g., "abc1234").
    package static let shortHashLength = 7

    /// Returns the current HEAD commit hash in the specified repository.
    /// - Parameter repoPath: Path to the repository as string
    /// - Returns: The HEAD commit hash
    package static func headCommit(repoPath: String) async throws -> String {
        let result = try await Shell.execute(
            "git",
            arguments: ["rev-parse", "HEAD"],
            workingDirectory: FilePath(repoPath)
        )
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns the commit timestamp in ISO 8601 format (UTC).
    /// - Parameters:
    ///   - hash: Commit hash
    ///   - repoPath: Path to the repository
    /// - Returns: The commit timestamp string in UTC (e.g. `2025-01-15T07:30:00Z`)
    package static func commitDate(for hash: String, in repoPath: URL) async throws -> String {
        let result = try await Shell.execute(
            "git",
            arguments: ["show", "-s", "--format=%cI", hash],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )
        let raw = result.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let date = ISO8601UTCDateFormatter.utc.date(from: raw) else {
            throw ParseError.invalidDateFormat(
                string: raw,
                format: "ISO 8601 (e.g. 2024-12-01T11:51:11+03:00)"
            )
        }
        return ISO8601UTCDateFormatter.utc.string(from: date)
    }

    // MARK: - Checkout & Repository Preparation

    /// Prepares the repository and checks out the specified commit.
    /// Runs clean/reset before checkout to ensure a clean working tree.
    package static func checkout(hash: String, git: GitConfiguration) async throws {
        try await prepareRepository(git: git)

        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(git.repoPath)
        )
    }

    /// Performs git operations before analysis based on GitConfiguration.
    package static func prepareRepository(git: GitConfiguration) async throws {
        let repoPath = URL(filePath: git.repoPath)
        if git.clean {
            try await cleanAndReset(in: repoPath)
        }
        if git.fixLFS {
            try await fixBrokenLFS(in: repoPath)
        }
        if git.initializeSubmodules {
            try await fixSubmodules(in: repoPath)
        }
    }

    /// Cleans untracked files and resets working directory to HEAD.
    /// Executes: `git clean -ffdx && git reset --hard HEAD`
    private static func cleanAndReset(in repoPath: URL) async throws {
        let repoPathFilePath = FilePath(repoPath.path(percentEncoded: false))

        logger.debug("Cleaning untracked files and resetting working directory")

        try await Shell.execute(
            "git",
            arguments: ["clean", "-ffdx"],
            workingDirectory: repoPathFilePath
        )

        try await Shell.execute(
            "git",
            arguments: ["reset", "--hard", "HEAD"],
            workingDirectory: repoPathFilePath
        )

        logger.debug("Working directory cleaned and reset")
    }

    /// Fixes broken Git LFS pointers by committing modified files.
    ///
    /// Some repositories have broken LFS commits where files are marked as LFS-tracked
    /// but the actual content wasn't uploaded to LFS storage. After checkout, these files
    /// appear as modified (containing LFS pointer text instead of actual content).
    /// This method commits those changes to allow analysis to proceed.
    private static func fixBrokenLFS(in repoPath: URL) async throws {
        let repoPathFilePath = FilePath(repoPath.path(percentEncoded: false))
        let modifiedFiles = try await Shell.execute(
            "git",
            arguments: ["ls-files", "-m"],
            workingDirectory: repoPathFilePath
        )

        if !modifiedFiles.isEmpty {
            logger.debug("Found modified files (possibly broken LFS), committing fix")
            try await Shell.execute(
                "git",
                arguments: ["add", "-A"],
                workingDirectory: repoPathFilePath
            )
            try await Shell.execute(
                "git",
                arguments: ["commit", "-m", "LFS Fix"],
                workingDirectory: repoPathFilePath
            )
            logger.debug("LFS fix committed")
        }
    }

    private static func fixSubmodules(in repoPath: URL) async throws {
        let repoPathFilePath = FilePath(repoPath.path(percentEncoded: false))
        try await Shell.execute(
            "git",
            arguments: ["reset", "--hard", "HEAD"],
            workingDirectory: repoPathFilePath
        )
        let submoduleStatus = try await Shell.execute(
            "git",
            arguments: ["submodule", "status", "--recursive"],
            workingDirectory: repoPathFilePath
        )
        let hasInitializedSubmodules = submoduleStatus.split(separator: "\n").contains { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return !trimmed.isEmpty && !trimmed.hasPrefix("-")
        }
        if hasInitializedSubmodules {
            try await Shell.execute(
                "git",
                arguments: [
                    "submodule", "foreach", "--recursive", "git", "reset", "--hard", "HEAD",
                ],
                workingDirectory: repoPathFilePath
            )
        }
        try await Shell.execute(
            "git",
            arguments: ["submodule", "update", "--init", "--recursive"],
            workingDirectory: repoPathFilePath
        )
    }
}
