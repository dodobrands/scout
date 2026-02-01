import Foundation
import Logging
import System

public class GitFix {
    private static let logger = Logger(label: "mobile-code-metrics.GitFix")

    /// Performs git operations before analysis based on provided flags.
    /// - Parameters:
    ///   - repoPath: Path to the repository
    ///   - gitClean: Run `git clean -ffdx && git reset --hard HEAD` to clean working directory
    ///   - fixLFS: Fix broken LFS pointers by committing modified files
    ///   - initializeSubmodules: Initialize and update git submodules
    public static func prepareRepository(
        in repoPath: URL,
        gitClean: Bool = false,
        fixLFS: Bool = false,
        initializeSubmodules: Bool = false
    ) async throws {
        if gitClean {
            try await cleanAndReset(in: repoPath)
        }
        if fixLFS {
            try await fixBrokenLFS(in: repoPath)
        }
        if initializeSubmodules {
            try await fixSubmodules(in: repoPath)
        }
    }

    /// Cleans untracked files and resets working directory to HEAD.
    /// Executes: `git clean -ffdx && git reset --hard HEAD`
    public static func cleanAndReset(in repoPath: URL) async throws {
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
        // Reset all submodules to the commits specified in the parent repository
        // This fixes cases where submodules point to different commits after checkout
        // Step 1: Reset changes in the main repository
        try await Shell.execute(
            "git",
            arguments: ["reset", "--hard", "HEAD"],
            workingDirectory: repoPathFilePath
        )
        // Step 2: Check if there are any initialized submodules
        // Only reset submodules if they are already initialized
        let submoduleStatus = try await Shell.execute(
            "git",
            arguments: ["submodule", "status", "--recursive"],
            workingDirectory: repoPathFilePath
        )
        // If there are initialized submodules (lines starting with space or +),
        // reset them. Lines starting with - indicate uninitialized submodules.
        let hasInitializedSubmodules = submoduleStatus.split(separator: "\n").contains { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Initialized submodules: start with space (on correct commit) or + (modified)
            // Uninitialized submodules: start with - (not initialized)
            return !trimmed.isEmpty && !trimmed.hasPrefix("-")
        }
        if hasInitializedSubmodules {
            // Reset changes in all initialized submodules recursively
            try await Shell.execute(
                "git",
                arguments: [
                    "submodule", "foreach", "--recursive", "git", "reset", "--hard", "HEAD",
                ],
                workingDirectory: repoPathFilePath
            )
        }
        // Step 3: Update all submodules to the commits specified in the parent repository
        // --init ensures submodules are initialized if they don't exist
        // --recursive handles nested submodules
        try await Shell.execute(
            "git",
            arguments: ["submodule", "update", "--init", "--recursive"],
            workingDirectory: repoPathFilePath
        )
    }
}
