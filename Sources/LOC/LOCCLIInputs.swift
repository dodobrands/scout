import Common
import Foundation

/// Raw CLI inputs from ArgumentParser. All fields are optional.
struct LOCCLIInputs: Sendable {
    /// Programming languages to count (e.g., ["Swift", "Objective-C"])
    public let languages: [String]?

    /// Commit hashes to analyze
    public let commits: [String]?

    /// Git configuration from CLI flags
    public let git: GitCLIInputs

    public init(
        languages: [String]?,
        repoPath: String?,
        commits: [String]?,
        gitClean: Bool? = nil,
        fixLfs: Bool? = nil,
        initializeSubmodules: Bool? = nil
    ) {
        self.languages = languages
        self.commits = commits
        self.git = GitCLIInputs(
            repoPath: repoPath,
            clean: gitClean,
            fixLFS: fixLfs,
            initializeSubmodules: initializeSubmodules
        )
    }

    public init(languages: [String]?, commits: [String]?, git: GitCLIInputs) {
        self.languages = languages
        self.commits = commits
        self.git = git
    }
}
