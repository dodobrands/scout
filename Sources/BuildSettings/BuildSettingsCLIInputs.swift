import Common
import Foundation

/// Raw CLI inputs from ArgumentParser. All fields are optional.
struct BuildSettingsCLIInputs: Sendable {
    /// Build settings parameters to collect (e.g., ["SWIFT_VERSION", "IPHONEOS_DEPLOYMENT_TARGET"])
    let buildSettingsParameters: [String]?

    /// Commit hashes to analyze
    let commits: [String]?

    /// Git configuration from CLI flags
    let git: GitCLIInputs

    init(
        buildSettingsParameters: [String]?,
        repoPath: String?,
        commits: [String]?,
        gitClean: Bool? = nil,
        fixLfs: Bool? = nil,
        initializeSubmodules: Bool? = nil
    ) {
        self.buildSettingsParameters = buildSettingsParameters
        self.commits = commits
        self.git = GitCLIInputs(
            repoPath: repoPath,
            clean: gitClean,
            fixLFS: fixLfs,
            initializeSubmodules: initializeSubmodules
        )
    }
}
