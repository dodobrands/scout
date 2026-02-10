import BuildSettings
import Common
import Foundation

extension BuildSettings.SetupCommand {
    /// Initialize from file config SetupCommand
    init(_ fileConfig: BuildSettingsCLIConfig.SetupCommand) {
        self.init(
            command: fileConfig.command,
            workingDirectory: fileConfig.workingDirectory,
            optional: fileConfig.optional ?? false
        )
    }
}

/// Error when required configuration is missing.
enum BuildSettingsCLIInputError: Error, LocalizedError {
    case missingProject

    var errorDescription: String? {
        switch self {
        case .missingProject:
            return "project is required (via --project or in configuration file)"
        }
    }
}

extension BuildSettings.Input {
    /// Creates Input by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// HEAD commits are resolved inside SDK.analyze(), not here.
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    /// - Throws: `BuildSettingsCLIInputError.missingProject` if project not provided
    init(cli: BuildSettingsCLIInputs, config: BuildSettingsCLIConfig?) throws {
        guard let project = cli.project ?? config?.project else {
            throw BuildSettingsCLIInputError.missingProject
        }

        let setupCommands = config?.setupCommands?.map(BuildSettings.SetupCommand.init) ?? []
        let configuration = config?.configuration ?? "Debug"

        // Git configuration merges CLI > FileConfig > Default
        let gitConfig = GitConfiguration(cli: cli.git, fileConfig: config?.git)
        let continueOnMissingProject =
            cli.continueOnMissingProject ?? config?.continueOnMissingProject ?? false

        // Build metrics from CLI or config
        let metrics: [BuildSettings.MetricInput]

        if let cliParameters = cli.buildSettingsParameters, !cliParameters.isEmpty {
            // CLI parameters provided - all use same commits (from CLI or default HEAD)
            let commits = cli.commits ?? ["HEAD"]
            metrics = cliParameters.map {
                BuildSettings.MetricInput(setting: $0, commits: commits)
            }
        } else if let configMetrics = config?.metrics {
            // Config metrics - each has its own commits, CLI --commits overrides all
            if let cliCommits = cli.commits {
                // CLI commits override all config commits
                metrics = configMetrics.compactMap { metric in
                    // Skip metrics with empty commits array
                    if let commits = metric.commits, commits.isEmpty {
                        return nil
                    }
                    return BuildSettings.MetricInput(
                        setting: metric.setting,
                        commits: cliCommits
                    )
                }
            } else {
                // Use per-metric commits from config
                metrics = configMetrics.compactMap { metric in
                    // Skip metrics with empty commits array
                    if let commits = metric.commits, commits.isEmpty {
                        return nil
                    }
                    let commits = metric.commits ?? ["HEAD"]
                    return BuildSettings.MetricInput(setting: metric.setting, commits: commits)
                }
            }
        } else {
            metrics = []
        }

        self.init(
            git: gitConfig,
            setupCommands: setupCommands,
            metrics: metrics,
            project: project,
            configuration: configuration,
            continueOnMissingProject: continueOnMissingProject
        )
    }
}
