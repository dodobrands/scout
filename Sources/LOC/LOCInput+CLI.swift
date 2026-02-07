import Common
import Foundation
import LOCSDK

/// Intermediate config for CLI that holds metrics with their commit arrays.
/// This is merged from CLI args and file config, then converted to LOCSDK.Input per commit.
struct LOCCLIConfig {
    let git: GitConfiguration
    let metrics: [LOCSDK.MetricInput]

    /// Creates LOCCLIConfig by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    init(cli: LOCCLIInputs, config: LOCConfig?) {
        // Git configuration merges CLI > FileConfig > Default
        let gitConfig = GitConfiguration(cli: cli.git, fileConfig: config?.git)

        // Build metrics from CLI or config
        let metrics: [LOCSDK.MetricInput]

        if let cliLanguages = cli.languages, !cliLanguages.isEmpty {
            // CLI languages provided - create single metric with CLI commits
            let commits = cli.commits ?? ["HEAD"]
            let metric = LOCSDK.MetricInput(
                languages: cliLanguages,
                include: cli.include ?? [],
                exclude: cli.exclude ?? [],
                commits: commits
            )
            metrics = [metric]
        } else if let configMetrics = config?.metrics {
            // Config metrics - each has its own commits, CLI --commits overrides all
            if let cliCommits = cli.commits {
                // CLI commits override all config commits
                metrics = configMetrics.compactMap { metric in
                    // Skip metrics with empty commits array
                    if let commits = metric.commits, commits.isEmpty {
                        return nil
                    }
                    return LOCSDK.MetricInput(
                        languages: metric.languages,
                        include: metric.include,
                        exclude: metric.exclude,
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
                    return LOCSDK.MetricInput(
                        languages: metric.languages,
                        include: metric.include,
                        exclude: metric.exclude,
                        commits: commits
                    )
                }
            }
        } else {
            metrics = []
        }

        self.git = gitConfig
        self.metrics = metrics
    }
}
