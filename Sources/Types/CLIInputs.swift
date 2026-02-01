import Foundation

/// Raw CLI inputs from ArgumentParser. All fields are optional.
public struct TypesCLIInputs: Sendable {
    /// Type names to count (e.g., ["UIView", "UIViewController"])
    public let types: [String]?

    /// Path to repository with Swift sources
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
        types: [String]?,
        repoPath: String?,
        commits: [String]?,
        gitClean: Bool = false,
        fixLfs: Bool = false,
        initializeSubmodules: Bool = false
    ) {
        self.types = types
        self.repoPath = repoPath
        self.commits = commits
        self.gitClean = gitClean
        self.fixLfs = fixLfs
        self.initializeSubmodules = initializeSubmodules
    }
}
