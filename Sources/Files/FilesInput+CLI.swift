import Common
import FilesSDK
import Foundation

/// Intermediate config for CLI that holds metrics with their commit arrays.
/// This is merged from CLI args and file config, then converted to FilesSDK.Input per commit.
struct FilesCLIConfig {
    let git: GitConfiguration
    let metrics: [FilesSDK.MetricInput]

    /// Creates FilesCLIConfig by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    init(cli: FilesCLIInputs, config: FilesConfig?) {
        // Git configuration merges CLI > FileConfig > Default
        let gitConfig = GitConfiguration(cli: cli.git, fileConfig: config?.git)

        // Build metrics from CLI or config
        let metrics: [FilesSDK.MetricInput]

        if let cliFiletypes = cli.filetypes, !cliFiletypes.isEmpty {
            // CLI filetypes provided - all use same commits (from CLI or default HEAD)
            let commits = cli.commits ?? ["HEAD"]
            metrics = cliFiletypes.map { FilesSDK.MetricInput(extension: $0, commits: commits) }
        } else if let configMetrics = config?.metrics {
            // Config metrics - each has its own commits, CLI --commits overrides all
            if let cliCommits = cli.commits {
                // CLI commits override all config commits
                metrics = configMetrics.compactMap { metric in
                    // Skip metrics with empty commits array
                    if let commits = metric.commits, commits.isEmpty {
                        return nil
                    }
                    return FilesSDK.MetricInput(extension: metric.extension, commits: cliCommits)
                }
            } else {
                // Use per-metric commits from config
                metrics = configMetrics.compactMap { metric in
                    // Skip metrics with empty commits array
                    if let commits = metric.commits, commits.isEmpty {
                        return nil
                    }
                    let commits = metric.commits ?? ["HEAD"]
                    return FilesSDK.MetricInput(extension: metric.extension, commits: commits)
                }
            }
        } else {
            metrics = []
        }

        self.git = gitConfig
        self.metrics = metrics
    }
}
