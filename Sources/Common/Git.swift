import Foundation
import System

package enum Git {
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
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: raw) else {
            throw ParseError.invalidDateFormat(string: raw, format: "ISO 8601")
        }
        return formatter.string(from: date)
    }
}
