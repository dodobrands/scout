import Common
import Foundation

/// Raw CLI inputs from ArgumentParser. All fields are optional.
public struct LOCCLIInputs: Sendable {
    /// Commit hashes to analyze
    public let commits: [String]?

    /// Git configuration from CLI flags
    public let git: GitCLIInputs

    public init(
        repoPath: String?,
        commits: [String]?,
        gitClean: Bool? = nil,
        fixLfs: Bool? = nil,
        initializeSubmodules: Bool? = nil
    ) {
        self.commits = commits
        self.git = GitCLIInputs(
            repoPath: repoPath,
            clean: gitClean,
            fixLFS: fixLfs,
            initializeSubmodules: initializeSubmodules
        )
    }

    public init(commits: [String]?, git: GitCLIInputs) {
        self.commits = commits
        self.git = git
    }
}
