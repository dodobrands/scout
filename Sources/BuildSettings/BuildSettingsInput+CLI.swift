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

/// Error when required configuration is missing.
enum BuildSettingsInputError: Error, LocalizedError {
    case missingProject

    var errorDescription: String? {
        switch self {
        case .missingProject:
            return "project is required (via --project or in configuration file)"
        }
    }
}

extension BuildSettingsInput {
    /// Creates BuildSettingsInput by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    /// - Throws: `BuildSettingsInputError.missingProject` if project not provided
    init(cli: BuildSettingsCLIInputs, config: BuildSettingsConfig?) throws {
        guard let project = cli.project ?? config?.project else {
            throw BuildSettingsInputError.missingProject
        }

        let setupCommands = config?.setupCommands?.map(SetupCommand.init) ?? []
        let buildSettingsParameters =
            cli.buildSettingsParameters ?? config?.buildSettingsParameters ?? []
        let configuration = config?.configuration ?? "Debug"
        let commits = cli.commits ?? ["HEAD"]

        // Git configuration merges CLI > FileConfig > Default
        let gitConfig = GitConfiguration(cli: cli.git, fileConfig: config?.git)

        self.init(
            git: gitConfig,
            setupCommands: setupCommands,
            buildSettingsParameters: buildSettingsParameters,
            project: project,
            configuration: configuration,
            commits: commits
        )
    }
}
