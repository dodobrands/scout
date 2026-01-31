import Foundation
import System

public enum Git {
    /// Returns the current HEAD commit hash in the specified repository.
    /// - Parameter repoPath: Path to the repository
    /// - Returns: The HEAD commit hash
    public static func headCommit(in repoPath: URL) async throws -> String {
        let result = try await Shell.execute(
            "git",
            arguments: ["rev-parse", "HEAD"],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
