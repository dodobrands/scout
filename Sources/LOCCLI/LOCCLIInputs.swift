import Common
import Foundation

/// Raw CLI inputs from ArgumentParser. All fields are optional.
struct LOCCLIInputs: Sendable {
    /// Programming languages to count (e.g., ["Swift", "Objective-C"])
    let languages: [String]?

    /// Paths to include
    let include: [String]?

    /// Paths to exclude
    let exclude: [String]?

    /// Commit hashes to analyze
    let commits: [String]?

    /// Template for metric identifier with placeholders (%langs%, %include%, %exclude%)
    let nameTemplate: String?

    /// Git configuration from CLI flags
    let git: GitCLIInputs

    init(
        languages: [String]?,
        include: [String]?,
        exclude: [String]?,
        repoPath: String?,
        commits: [String]?,
        nameTemplate: String? = nil,
        gitClean: Bool? = nil,
        fixLfs: Bool? = nil,
        initializeSubmodules: Bool? = nil
    ) {
        self.languages = languages
        self.include = include
        self.exclude = exclude
        self.commits = commits
        self.nameTemplate = nameTemplate
        self.git = GitCLIInputs(
            repoPath: repoPath,
            clean: gitClean,
            fixLFS: fixLfs,
            initializeSubmodules: initializeSubmodules
        )
    }
}
