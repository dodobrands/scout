import Foundation
import Glob

/// Matches file paths against glob patterns.
///
/// Supported wildcards:
/// - `*` — matches any characters within a single path segment
/// - `**` — matches any characters across multiple path segments (recursive)
/// - `?` — matches a single character
public struct GlobMatcher: Sendable {
    /// Returns `true` if `path` matches the glob `pattern`.
    ///
    /// Both `path` and `pattern` should use `/` as the path separator.
    /// Leading `/` and trailing `/` are stripped before matching.
    public static func match(path: String, pattern: String) -> Bool {
        let normalizedPath = normalize(path)
        let normalizedPattern = normalize(pattern)
        guard let globPattern = try? Glob.Pattern(normalizedPattern) else {
            return false
        }
        return globPattern.match(normalizedPath)
    }

    /// Returns `true` if `path` matches any pattern in `patterns`.
    public static func matchesAny(path: String, patterns: [String]) -> Bool {
        patterns.contains { match(path: path, pattern: $0) }
    }

    // MARK: - Private

    private static func normalize(_ value: String) -> String {
        var result = value
        if result.hasPrefix("/") { result = String(result.dropFirst()) }
        if result.hasSuffix("/") { result = String(result.dropLast()) }
        return result
    }
}
