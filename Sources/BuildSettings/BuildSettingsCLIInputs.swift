import Common
import Foundation

/// Raw CLI inputs from ArgumentParser. All fields are optional.
struct BuildSettingsCLIInputs: Sendable {
    /// Build settings parameters to collect (e.g., ["SWIFT_VERSION", "IPHONEOS_DEPLOYMENT_TARGET"])
    public let buildSettingsParameters: [String]?

    /// Commit hashes to analyze
    public let commits: [String]?

    /// Git configuration from CLI flags
    public let git: GitCLIInputs

    public init(
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

    public init(buildSettingsParameters: [String]?, commits: [String]?, git: GitCLIInputs) {
        self.buildSettingsParameters = buildSettingsParameters
        self.commits = commits
        self.git = git
    }
}
