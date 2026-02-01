import BuildSettingsSDK
import Common
import Foundation

extension BuildSettingsInput {
    /// Creates BuildSettingsInput by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    public init(cli: BuildSettingsCLIInputs, config: BuildSettingsConfig?) {
        let setupCommands =
            config?.setupCommands?.map {
                SetupCommand(
                    command: $0.command,
                    workingDirectory: $0.workingDirectory,
                    optional: $0.optional ?? false
                )
            } ?? []
        let buildSettingsParameters = config?.buildSettingsParameters ?? []
        let configuration = config?.configuration ?? "Debug"
        let commits = cli.commits ?? ["HEAD"]

        // Git configuration merges CLI > FileConfig > Default
        let gitConfig = GitConfiguration(cli: cli.git, fileConfig: config?.git)

        self.init(
            git: gitConfig,
            setupCommands: setupCommands,
            buildSettingsParameters: buildSettingsParameters,
            configuration: configuration,
            commits: commits
        )
    }
}
