import Common
import Foundation
import LOCSDK

extension LOCInput {
    /// Creates LOCInput by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    public init(cli: LOCCLIInputs, config: LOCConfig?) {
        let configurations =
            config?.configurations?.map {
                LOCConfiguration(
                    languages: $0.languages,
                    include: $0.include,
                    exclude: $0.exclude
                )
            } ?? []
        let commits = cli.commits ?? ["HEAD"]

        // Git configuration merges CLI > FileConfig > Default
        let gitConfig = GitConfiguration(cli: cli.git, fileConfig: config?.git)

        self.init(git: gitConfig, configurations: configurations, commits: commits)
    }
}
