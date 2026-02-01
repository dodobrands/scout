import BuildSettingsSDK
import Common
import Foundation

extension BuildSettingsInput {
    /// Creates BuildSettingsInput by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    public init(cli: BuildSettingsCLIInputs, config: ExtractBuildSettingsConfig?) {
        let repoPath =
            cli.repoPath ?? config?.git?.repoPath ?? FileManager.default.currentDirectoryPath
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

        let gitConfig = GitConfiguration(
            repoPath: repoPath,
            clean: cli.gitClean,
            fixLFS: cli.fixLfs,
            initializeSubmodules: cli.initializeSubmodules
        )

        self.init(
            git: gitConfig,
            setupCommands: setupCommands,
            buildSettingsParameters: buildSettingsParameters,
            configuration: configuration,
            commits: commits
        )
    }
}
