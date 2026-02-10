import Common
import Foundation

/// Raw CLI inputs from ArgumentParser. All fields are optional.
struct BuildSettingsCLIInputs: Sendable {
    /// Glob patterns to include for project discovery
    let include: [String]?

    /// Glob patterns to exclude from project discovery
    let exclude: [String]?

    /// Build settings parameters to collect (e.g., ["SWIFT_VERSION", "IPHONEOS_DEPLOYMENT_TARGET"])
    let buildSettingsParameters: [String]?

    /// Commit hashes to analyze
    let commits: [String]?

    /// Git configuration from CLI flags
    let git: GitCLIInputs

    /// Continue analysis when no projects are found at a commit
    let continueOnMissingProject: Bool?

    init(
        include: [String]?,
        exclude: [String]?,
        buildSettingsParameters: [String]?,
        repoPath: String?,
        commits: [String]?,
        gitClean: Bool? = nil,
        fixLfs: Bool? = nil,
        initializeSubmodules: Bool? = nil,
        continueOnMissingProject: Bool? = nil
    ) {
        self.include = include
        self.exclude = exclude
        self.buildSettingsParameters = buildSettingsParameters
        self.commits = commits
        self.git = GitCLIInputs(
            repoPath: repoPath,
            clean: gitClean,
            fixLFS: fixLfs,
            initializeSubmodules: initializeSubmodules
        )
        self.continueOnMissingProject = continueOnMissingProject
    }
}
