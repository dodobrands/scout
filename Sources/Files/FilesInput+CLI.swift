import Common
import FilesSDK
import Foundation

extension FilesInput {
    /// Creates FilesInput by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    public init(cli: FilesCLIInputs, config: CountFilesConfig?) {
        let repoPath =
            cli.repoPath ?? config?.git?.repoPath ?? FileManager.default.currentDirectoryPath
        let filetypes = cli.filetypes ?? config?.filetypes ?? []
        let commits = cli.commits ?? ["HEAD"]

        let gitConfig = GitConfiguration(
            repoPath: repoPath,
            clean: cli.gitClean,
            fixLFS: cli.fixLfs,
            initializeSubmodules: cli.initializeSubmodules
        )

        self.init(git: gitConfig, filetypes: filetypes, commits: commits)
    }
}
