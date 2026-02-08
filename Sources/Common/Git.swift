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
        guard let date = ISO8601UTCDateFormatter.utc.date(from: raw) else {
            throw ParseError.invalidDateFormat(
                string: raw,
                format: "ISO 8601 (e.g. 2024-12-01T11:51:11+03:00)"
            )
        }
        return ISO8601UTCDateFormatter.utc.string(from: date)
    }
}
