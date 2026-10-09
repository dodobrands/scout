import Logging
import OrderedCollections

/// Protocol for metric types that have commits which may need HEAD resolution.
package protocol CommitResolvable {
    var commits: [String] { get }
    func withResolvedCommits(_ commits: [String]) -> Self
}

extension Array where Element: CommitResolvable {
    /// True when no metric names a commit other than `HEAD`.
    /// Such a run analyzes the working tree as it is: no checkout and no git preparation,
    /// so uncommitted changes are measured and the branch stays attached.
    /// Any explicit commit switches the whole run to checkouts, because once another commit
    /// is checked out the working tree no longer reflects `HEAD`.
    /// Warns when `git` asks for clean, LFS fix or submodules, since they only run on checkout.
    package func analyzesWorkingTree(git: GitConfiguration) -> Bool {
        let analyzesWorkingTree = allSatisfy { $0.commits.allSatisfy { $0 == "HEAD" } }
        if analyzesWorkingTree, git.clean || git.fixLFS || git.initializeSubmodules {
            Logger(label: "scout.Git").warning(
                """
                No commits to check out: analyzing the working tree as is, \
                ignoring clean, fixLFS and initializeSubmodules
                """
            )
        }
        return analyzesWorkingTree
    }

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
