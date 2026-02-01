import Common
import Foundation
import LOCSDK

extension LOCInput {
    /// Creates LOCInput by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    public init(cli: LOCCLIInputs, config: CountLOCConfig?) {
        let repoPath =
            cli.repoPath ?? config?.git?.repoPath ?? FileManager.default.currentDirectoryPath
        let configurations =
            config?.configurations?.map {
                LOCConfiguration(
                    languages: $0.languages,
                    include: $0.include,
                    exclude: $0.exclude
                )
            } ?? []
        let commits = cli.commits ?? ["HEAD"]

        let gitConfig = GitConfiguration(
            repoPath: repoPath,
            clean: cli.gitClean,
            fixLFS: cli.fixLfs,
            initializeSubmodules: cli.initializeSubmodules
        )

        self.init(git: gitConfig, configurations: configurations, commits: commits)
    }
}
