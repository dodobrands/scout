import Common
import Foundation
import TypesSDK

extension TypesInput {
    /// Creates TypesInput by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    init(cli: TypesCLIInputs, config: TypesConfig?) {
        let types = cli.types ?? config?.types ?? []
        let commits = cli.commits ?? ["HEAD"]

        // Git configuration merges CLI > FileConfig > Default
        let gitConfig = GitConfiguration(cli: cli.git, fileConfig: config?.git)

        self.init(git: gitConfig, types: types, commits: commits)
    }
}
