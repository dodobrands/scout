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

extension BuildSettingsSDK.Input {
    /// Creates Input by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// This is the synchronous version that does NOT resolve HEAD commits.
    /// Use `init(cli:config:resolvingCommits:)` for the async version with HEAD resolution.
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
        let configuration = config?.configuration ?? "Debug"

        // Git configuration merges CLI > FileConfig > Default
        let gitConfig = GitConfiguration(cli: cli.git, fileConfig: config?.git)

        // Build metrics from CLI or config
        let metrics: [BuildSettingsSDK.MetricInput]

        if let cliParameters = cli.buildSettingsParameters, !cliParameters.isEmpty {
            // CLI parameters provided - all use same commits (from CLI or default HEAD)
            let commits = cli.commits ?? ["HEAD"]
            metrics = cliParameters.map {
                BuildSettingsSDK.MetricInput(setting: $0, commits: commits)
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
                    return BuildSettingsSDK.MetricInput(
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
                    return BuildSettingsSDK.MetricInput(setting: metric.setting, commits: commits)
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
            configuration: configuration
        )
    }

    /// Creates Input by merging CLI and file config with priority: CLI > Config > Default,
    /// and resolves HEAD commits to actual commit hashes.
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    ///   - resolvingCommits: Pass `true` to resolve HEAD commits using git.repoPath
    /// - Throws: `BuildSettingsInputError.missingProject` if project not provided
    init(
        cli: BuildSettingsCLIInputs,
        config: BuildSettingsConfig?,
        resolvingCommits: Bool
    ) async throws {
        // Use synchronous init for merging logic
        let input = try BuildSettingsSDK.Input(cli: cli, config: config)

        if resolvingCommits {
            // Resolve HEAD commits using repoPath from merged git config
            let resolvedMetrics = try await input.metrics.resolvingHeadCommits(
                repoPath: input.git.repoPath
            )
            self.init(
                git: input.git,
                setupCommands: input.setupCommands,
                metrics: resolvedMetrics,
                project: input.project,
                configuration: input.configuration
            )
        } else {
            self = input
        }
    }
}
