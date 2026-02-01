import Common
import Foundation

/// Raw CLI inputs from ArgumentParser. All fields are optional.
public struct FilesCLIInputs: Sendable {
    /// File extensions to count (e.g., ["swift", "storyboard"])
    public let filetypes: [String]?

    /// Commit hashes to analyze
    public let commits: [String]?

    /// Git configuration from CLI flags
    public let git: GitCLIInputs

    public init(
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

    public init(filetypes: [String]?, commits: [String]?, git: GitCLIInputs) {
        self.filetypes = filetypes
        self.commits = commits
        self.git = git
    }
}
