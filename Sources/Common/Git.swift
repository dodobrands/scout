import Foundation
import System

public enum Git {
    /// Returns the current HEAD commit hash in the specified repository.
    /// - Parameter repoPath: Path to the repository as string
    /// - Returns: The HEAD commit hash
    public static func headCommit(repoPath: String) async throws -> String {
        let result = try await Shell.execute(
            "git",
            arguments: ["rev-parse", "HEAD"],
            workingDirectory: FilePath(repoPath)
        )
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns the commit timestamp in ISO 8601 format.
    /// - Parameters:
    ///   - hash: Commit hash
    ///   - repoPath: Path to the repository
    /// - Returns: The commit timestamp string
    package static func commitDate(for hash: String, in repoPath: URL) async throws -> String {
        let result = try await Shell.execute(
            "git",
            arguments: ["show", "-s", "--format=%cI", hash],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
