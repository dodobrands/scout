import Common
import Foundation

/// Raw CLI inputs from ArgumentParser. All fields are optional.
struct BuildSettingsCLIInputs: Sendable {
    /// Path to Xcode workspace or project
    let project: String?

    /// Build settings parameters to collect (e.g., ["SWIFT_VERSION", "IPHONEOS_DEPLOYMENT_TARGET"])
    let buildSettingsParameters: [String]?

    /// Commit hashes to analyze
    let commits: [String]?

    /// Git configuration from CLI flags
    let git: GitCLIInputs

    /// Continue analysis when project/workspace is not found at a commit
    let continueOnMissingProject: Bool?

    init(
        project: String?,
        buildSettingsParameters: [String]?,
        repoPath: String?,
        commits: [String]?,
        gitClean: Bool? = nil,
        fixLfs: Bool? = nil,
        initializeSubmodules: Bool? = nil,
        continueOnMissingProject: Bool? = nil
    ) {
        self.project = project
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
