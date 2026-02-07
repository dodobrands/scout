import Common
import Foundation
import TypesSDK

/// Intermediate config for CLI that holds metrics with their commit arrays.
/// This is merged from CLI args and file config, then converted to TypesSDK.Input per commit.
struct TypesCLIConfig {
    let git: GitConfiguration
    let metrics: [TypesSDK.MetricInput]

    /// Creates TypesCLIConfig by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    init(cli: TypesCLIInputs, config: TypesConfig?) {
        // Git configuration merges CLI > FileConfig > Default
        let gitConfig = GitConfiguration(cli: cli.git, fileConfig: config?.git)

        // Build metrics from CLI or config
        let metrics: [TypesSDK.MetricInput]

        if let cliTypes = cli.types, !cliTypes.isEmpty {
            // CLI types provided - all use same commits (from CLI or default HEAD)
            let commits = cli.commits ?? ["HEAD"]
            metrics = cliTypes.map { TypesSDK.MetricInput(type: $0, commits: commits) }
        } else if let configMetrics = config?.metrics {
            // Config metrics - each has its own commits, CLI --commits overrides all
            if let cliCommits = cli.commits {
                // CLI commits override all config commits
                metrics = configMetrics.compactMap { metric in
                    // Skip metrics with empty commits array
                    if let commits = metric.commits, commits.isEmpty {
                        return nil
                    }
                    return TypesSDK.MetricInput(type: metric.type, commits: cliCommits)
                }
            } else {
                // Use per-metric commits from config
                metrics = configMetrics.compactMap { metric in
                    // Skip metrics with empty commits array
                    if let commits = metric.commits, commits.isEmpty {
                        return nil
                    }
                    let commits = metric.commits ?? ["HEAD"]
                    return TypesSDK.MetricInput(type: metric.type, commits: commits)
                }
            }
        } else {
            metrics = []
        }

        self.git = gitConfig
        self.metrics = metrics
    }
}
