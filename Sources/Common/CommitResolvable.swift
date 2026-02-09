import OrderedCollections

/// Protocol for metric types that have commits which may need HEAD resolution.
package protocol CommitResolvable {
    var commits: [String] { get }
    func withResolvedCommits(_ commits: [String]) -> Self
}

extension Array where Element: CommitResolvable {
    /// Resolves "HEAD" strings to actual commit hashes.
    /// Only calls Git if at least one element contains "HEAD".
    package func resolvingHeadCommits(repoPath: String) async throws -> [Element] {
        let needsHead = contains { $0.commits.contains("HEAD") }
        guard needsHead else { return self }

        let headHash = try await Git.headCommit(repoPath: repoPath)
        return map { metric in
            let resolved = metric.commits.map { $0 == "HEAD" ? headHash : $0 }
            return metric.withResolvedCommits(resolved)
        }
    }

    /// Groups metrics by commit hash, preserving the order commits first appear.
    /// This ensures chronological order is maintained when commits arrive sorted by timestamp.
    package func groupedByCommit() -> OrderedDictionary<String, [Element]> {
        var result: OrderedDictionary<String, [Element]> = [:]
        for metric in self {
            for commit in metric.commits {
                result[commit, default: []].append(metric)
            }
        }
        return result
    }
}
