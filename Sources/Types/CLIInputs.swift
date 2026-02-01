import Common
import Foundation

/// Raw CLI inputs from ArgumentParser. All fields are optional.
public struct TypesCLIInputs: Sendable {
    /// Type names to count (e.g., ["UIView", "UIViewController"])
    public let types: [String]?

    /// Commit hashes to analyze
    public let commits: [String]?

    /// Git configuration from CLI flags
    public let git: GitCLIInputs

    public init(
        types: [String]?,
        repoPath: String?,
        commits: [String]?,
        gitClean: Bool? = nil,
        fixLfs: Bool? = nil,
        initializeSubmodules: Bool? = nil
    ) {
        self.types = types
        self.commits = commits
        self.git = GitCLIInputs(
            repoPath: repoPath,
            clean: gitClean,
            fixLFS: fixLfs,
            initializeSubmodules: initializeSubmodules
        )
    }

    public init(types: [String]?, commits: [String]?, git: GitCLIInputs) {
        self.types = types
        self.commits = commits
        self.git = git
    }
}
