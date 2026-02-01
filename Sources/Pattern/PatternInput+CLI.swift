import Common
import Foundation
import PatternSDK

extension PatternInput {
    /// Creates PatternInput by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    public init(cli: PatternCLIInputs, config: SearchConfig?) {
        let repoPath =
            cli.repoPath ?? config?.git?.repoPath ?? FileManager.default.currentDirectoryPath
        let patterns = cli.patterns ?? config?.patterns ?? []
        let extensions = cli.extensions ?? config?.extensions ?? ["swift"]
        let commits = cli.commits ?? ["HEAD"]

        let gitConfig = GitConfiguration(
            repoPath: repoPath,
            clean: cli.gitClean,
            fixLFS: cli.fixLfs,
            initializeSubmodules: cli.initializeSubmodules
        )

        self.init(git: gitConfig, patterns: patterns, extensions: extensions, commits: commits)
    }
}
