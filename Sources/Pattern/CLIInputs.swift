import Foundation

/// Raw CLI inputs from ArgumentParser. All fields are optional.
public struct PatternCLIInputs: Sendable {
    /// Patterns to search for
    public let patterns: [String]?

    /// Path to repository with sources
    public let repoPath: String?

    /// Commit hashes to analyze
    public let commits: [String]?

    /// File extensions to search (comma-separated string from CLI)
    public let extensions: [String]?

    /// Clean working directory before analysis
    public let gitClean: Bool

    /// Fix broken LFS pointers
    public let fixLfs: Bool

    /// Initialize submodules
    public let initializeSubmodules: Bool

    public init(
        patterns: [String]?,
        repoPath: String?,
        commits: [String]?,
        extensions: [String]?,
        gitClean: Bool = false,
        fixLfs: Bool = false,
        initializeSubmodules: Bool = false
    ) {
        self.patterns = patterns
        self.repoPath = repoPath
        self.commits = commits
        self.extensions = extensions
        self.gitClean = gitClean
        self.fixLfs = fixLfs
        self.initializeSubmodules = initializeSubmodules
    }
}
