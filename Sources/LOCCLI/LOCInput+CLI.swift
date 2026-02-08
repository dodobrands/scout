import Common
import Foundation
import LOC

extension LOC.Input {
    /// Creates Input by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// HEAD commits are resolved inside SDK.analyze(), not here.
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    init(cli: LOCCLIInputs, config: LOCCLIConfig?) {
        // Git configuration merges CLI > FileConfig > Default
        let gitConfig = GitConfiguration(cli: cli.git, fileConfig: config?.git)

        // Build metrics from CLI or config
        let metrics: [LOC.MetricInput]

        if let cliLanguages = cli.languages, !cliLanguages.isEmpty {
            // CLI languages provided - create single metric with CLI commits
            let commits = cli.commits ?? ["HEAD"]
            let metric = LOC.MetricInput(
                languages: cliLanguages,
                include: cli.include ?? [],
                exclude: cli.exclude ?? [],
                commits: commits,
                nameTemplate: cli.nameTemplate
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
                    return LOC.MetricInput(
                        languages: metric.languages,
                        include: metric.include,
                        exclude: metric.exclude,
                        commits: cliCommits,
                        nameTemplate: cli.nameTemplate ?? metric.nameTemplate
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
                    return LOC.MetricInput(
                        languages: metric.languages,
                        include: metric.include,
                        exclude: metric.exclude,
                        commits: commits,
                        nameTemplate: cli.nameTemplate ?? metric.nameTemplate
                    )
                }
            }
        } else {
            metrics = []
        }

        self.init(git: gitConfig, metrics: metrics)
    }
}
