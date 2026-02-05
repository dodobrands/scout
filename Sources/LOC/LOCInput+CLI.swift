import Common
import Foundation
import LOCSDK

extension LOCConfiguration {
    /// Initialize from file config LOCConfiguration
    init(_ fileConfig: LOCConfig.LOCConfiguration) {
        self.init(
            languages: fileConfig.languages,
            include: fileConfig.include,
            exclude: fileConfig.exclude
        )
    }
}

extension LOCInput {
    /// Creates LOCInput by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    init(cli: LOCCLIInputs, config: LOCConfig?) {
        // CLI languages create a single configuration; include/exclude default to empty
        let configurations: [LOCConfiguration]
        if let cliLanguages = cli.languages {
            configurations = [
                LOCConfiguration(
                    languages: cliLanguages,
                    include: cli.include ?? [],
                    exclude: cli.exclude ?? []
                )
            ]
        } else {
            configurations = config?.configurations?.map(LOCConfiguration.init) ?? []
        }

        let commits = cli.commits ?? ["HEAD"]

        // Git configuration merges CLI > FileConfig > Default
        let gitConfig = GitConfiguration(cli: cli.git, fileConfig: config?.git)

        self.init(git: gitConfig, configurations: configurations, commits: commits)
    }
}
