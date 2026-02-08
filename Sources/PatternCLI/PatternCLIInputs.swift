import Common
import Foundation

/// Raw CLI inputs from ArgumentParser. All fields are optional.
struct PatternCLIInputs: Sendable {
    /// Patterns to search for
    let patterns: [String]?

    /// Commit hashes to analyze
    let commits: [String]?

    /// File extensions to search (comma-separated string from CLI)
    let extensions: [String]?

    /// Git configuration from CLI flags
    let git: GitCLIInputs

    init(
        patterns: [String]?,
        repoPath: String?,
        commits: [String]?,
        extensions: [String]?,
        gitClean: Bool? = nil,
        fixLfs: Bool? = nil,
        initializeSubmodules: Bool? = nil
    ) {
        self.patterns = patterns
        self.commits = commits
        self.extensions = extensions
        self.git = GitCLIInputs(
            repoPath: repoPath,
            clean: gitClean,
            fixLFS: fixLfs,
            initializeSubmodules: initializeSubmodules
        )
    }
}
