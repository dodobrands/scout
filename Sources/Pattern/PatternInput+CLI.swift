import Common
import Foundation
import PatternSDK

extension PatternInput {
    /// Creates PatternInput by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    init(cli: PatternCLIInputs, config: PatternConfig?) {
        let patterns = cli.patterns ?? config?.patterns ?? []
        let extensions = cli.extensions ?? config?.extensions ?? ["swift"]
        let commits = cli.commits ?? ["HEAD"]

        // Git configuration merges CLI > FileConfig > Default
        let gitConfig = GitConfiguration(cli: cli.git, fileConfig: config?.git)

        self.init(git: gitConfig, patterns: patterns, extensions: extensions, commits: commits)
    }
}
