import Common
import Foundation

/// Raw CLI inputs from ArgumentParser. All fields are optional.
struct TypesCLIInputs: Sendable {
    /// Type names to count (e.g., ["UIView", "UIViewController"])
    let types: [String]?

    /// Commit hashes to analyze
    let commits: [String]?

    /// Git configuration from CLI flags
    let git: GitCLIInputs

    init(
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
}
