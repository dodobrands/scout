import Foundation

/// Raw CLI inputs from ArgumentParser. All fields are optional.
public struct LOCCLIInputs: Sendable {
    /// Path to repository with sources
    public let repoPath: String?

    /// Commit hashes to analyze
    public let commits: [String]?

    /// Clean working directory before analysis
    public let gitClean: Bool

    /// Fix broken LFS pointers
    public let fixLfs: Bool

    /// Initialize submodules
    public let initializeSubmodules: Bool

    public init(
        repoPath: String?,
        commits: [String]?,
        gitClean: Bool = false,
        fixLfs: Bool = false,
        initializeSubmodules: Bool = false
    ) {
        self.repoPath = repoPath
        self.commits = commits
        self.gitClean = gitClean
        self.fixLfs = fixLfs
        self.initializeSubmodules = initializeSubmodules
    }
}
