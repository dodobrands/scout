import Common
import Foundation

/// Raw CLI inputs from ArgumentParser. All fields are optional.
public struct PatternCLIInputs: Sendable {
    /// Patterns to search for
    public let patterns: [String]?

    /// Commit hashes to analyze
    public let commits: [String]?

    /// File extensions to search (comma-separated string from CLI)
    public let extensions: [String]?

    /// Git configuration from CLI flags
    public let git: GitCLIInputs

    public init(
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

    public init(
        patterns: [String]?,
        commits: [String]?,
        extensions: [String]?,
        git: GitCLIInputs
    ) {
        self.patterns = patterns
        self.commits = commits
        self.extensions = extensions
        self.git = git
    }
}
