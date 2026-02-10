import Foundation

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
        let pathComponents = normalize(path).split(separator: "/", omittingEmptySubsequences: true)
        let patternComponents = normalize(pattern).split(
            separator: "/",
            omittingEmptySubsequences: true
        )
        return matchComponents(
            pathComponents: Array(pathComponents),
            patternComponents: Array(patternComponents)
        )
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

    private static func matchComponents(
        pathComponents: [Substring],
        patternComponents: [Substring]
    ) -> Bool {
        var pi = 0  // path index
        var qi = 0  // pattern index

        while qi < patternComponents.count {
            let patternPart = patternComponents[qi]

            if patternPart == "**" {
                // `**` matches zero or more path segments
                qi += 1
                if qi == patternComponents.count {
                    // `**` at end matches everything remaining
                    return true
                }
                // Try matching remaining pattern against each suffix of remaining path
                for start in pi...pathComponents.count {
                    if matchComponents(
                        pathComponents: Array(pathComponents[start...]),
                        patternComponents: Array(patternComponents[qi...])
                    ) {
                        return true
                    }
                }
                return false
            }

            guard pi < pathComponents.count else {
                return false
            }

            if matchSegment(segment: pathComponents[pi], pattern: patternPart) {
                pi += 1
                qi += 1
            } else {
                return false
            }
        }

        return pi == pathComponents.count
    }

    /// Matches a single path segment against a pattern segment containing `*` and `?`.
    private static func matchSegment(segment: Substring, pattern: Substring) -> Bool {
        var si = segment.startIndex
        var pi = pattern.startIndex

        var starSi = segment.endIndex  // saved segment position after star
        var starPi = pattern.endIndex  // saved pattern position after star

        while si < segment.endIndex {
            if pi < pattern.endIndex && (pattern[pi] == "?" || pattern[pi] == segment[si]) {
                si = segment.index(after: si)
                pi = pattern.index(after: pi)
            } else if pi < pattern.endIndex && pattern[pi] == "*" {
                starPi = pattern.index(after: pi)
                starSi = si
                pi = starPi
            } else if starPi != pattern.endIndex {
                starSi = segment.index(after: starSi)
                si = starSi
                pi = starPi
            } else {
                return false
            }
        }

        // Consume trailing * in pattern
        while pi < pattern.endIndex && pattern[pi] == "*" {
            pi = pattern.index(after: pi)
        }

        return pi == pattern.endIndex
    }
}
