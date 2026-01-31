import Foundation
import Logging
import System

public class GitFix {
    private static let logger = Logger(label: "mobile-code-metrics.GitFix")

    public static func fixGitIssues(in repoPath: URL, initializeSubmodules: Bool = false)
        async throws
    {
        try await fixBrokenLFS(in: repoPath)
        if initializeSubmodules {
            try await fixSubmodules(in: repoPath)
        }
    }

    /// Cleans untracked files and resets working directory to HEAD.
    /// Executes: `git clean -ffdx && git reset --hard HEAD`
    public static func cleanAndReset(in repoPath: URL) async throws {
        let repoPathString = repoPath.path(percentEncoded: false)

        logger.debug("Cleaning untracked files and resetting working directory")

        let repoPathFilePath = FilePath(repoPathString)

        // Clean untracked files and directories (force, force, directories, exclude .gitignore)
        try await Shell.execute(
            "git",
            arguments: ["clean", "-ffdx"],
            workingDirectory: repoPathFilePath
        )

        // Reset working directory to HEAD
        try await Shell.execute(
            "git",
            arguments: ["reset", "--hard", "HEAD"],
            workingDirectory: repoPathFilePath
        )

        logger.debug("Working directory cleaned and reset")
    }

    private static func fixBrokenLFS(in repoPath: URL) async throws {
        let repoPathFilePath = FilePath(repoPath.path(percentEncoded: false))
        let gitDiff = try await Shell.execute(
            "git",
            arguments: ["ls-files", "-m"],
            workingDirectory: repoPathFilePath
        )
        // there may be broken git-lfs commits in pizza
        // file types marked as stored under lfs, but files aren't there actually
        if !gitDiff.isEmpty {
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
