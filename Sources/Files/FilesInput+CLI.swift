import Common
import FilesSDK
import Foundation

extension FilesInput {
    /// Creates FilesInput by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    init(cli: FilesCLIInputs, config: FilesConfig?) {
        let filetypes = cli.filetypes ?? config?.filetypes ?? []
        let commits = cli.commits ?? ["HEAD"]

        // Git configuration merges CLI > FileConfig > Default
        let gitConfig = GitConfiguration(cli: cli.git, fileConfig: config?.git)

        self.init(git: gitConfig, filetypes: filetypes, commits: commits)
    }
}
