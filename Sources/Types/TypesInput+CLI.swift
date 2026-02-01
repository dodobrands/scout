import Common
import Foundation
import TypesSDK

extension TypesInput {
    /// Creates TypesInput by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    public init(cli: TypesCLIInputs, config: CountTypesConfig?) {
        let repoPath =
            cli.repoPath ?? config?.git?.repoPath ?? FileManager.default.currentDirectoryPath
        let types = cli.types ?? config?.types ?? []
        let commits = cli.commits ?? ["HEAD"]

        let gitConfig = GitConfiguration(
            repoPath: repoPath,
            clean: cli.gitClean,
            fixLFS: cli.fixLfs,
            initializeSubmodules: cli.initializeSubmodules
        )

        self.init(git: gitConfig, types: types, commits: commits)
    }
}
