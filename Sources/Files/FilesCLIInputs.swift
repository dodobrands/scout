import Common
import Foundation

/// Raw CLI inputs from ArgumentParser. All fields are optional.
struct FilesCLIInputs: Sendable {
    /// File extensions to count (e.g., ["swift", "storyboard"])
    let filetypes: [String]?

    /// Commit hashes to analyze
    let commits: [String]?

    /// Git configuration from CLI flags
    let git: GitCLIInputs

    init(
        filetypes: [String]?,
        repoPath: String?,
        commits: [String]?,
        gitClean: Bool? = nil,
        fixLfs: Bool? = nil,
        initializeSubmodules: Bool? = nil
    ) {
        self.filetypes = filetypes
        self.commits = commits
        self.git = GitCLIInputs(
            repoPath: repoPath,
            clean: gitClean,
            fixLFS: fixLfs,
            initializeSubmodules: initializeSubmodules
        )
    }
}
