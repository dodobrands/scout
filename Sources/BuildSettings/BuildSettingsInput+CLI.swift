import BuildSettingsSDK
import Common
import Foundation

extension SetupCommand {
    /// Initialize from file config SetupCommand
    init(_ fileConfig: BuildSettingsConfig.SetupCommand) {
        self.init(
            command: fileConfig.command,
            workingDirectory: fileConfig.workingDirectory,
            optional: fileConfig.optional ?? false
        )
    }
}

extension BuildSettingsInput {
    /// Creates BuildSettingsInput by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    init(cli: BuildSettingsCLIInputs, config: BuildSettingsConfig?) {
        let setupCommands = config?.setupCommands?.map(SetupCommand.init) ?? []
        let buildSettingsParameters =
            cli.buildSettingsParameters ?? config?.buildSettingsParameters ?? []
        let workspaceName = config?.workspaceName
        let configuration = config?.configuration ?? "Debug"
        let commits = cli.commits ?? ["HEAD"]

        // Git configuration merges CLI > FileConfig > Default
        let gitConfig = GitConfiguration(cli: cli.git, fileConfig: config?.git)

        self.init(
            git: gitConfig,
            setupCommands: setupCommands,
            buildSettingsParameters: buildSettingsParameters,
            workspaceName: workspaceName,
            configuration: configuration,
            commits: commits
        )
    }
}
