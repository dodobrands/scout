import Common
import Foundation
import PatternSDK

extension PatternSDK.Input {
    /// Creates Input by merging CLI and file config with priority: CLI > Config > Default
    ///
    /// This is the synchronous version that does NOT resolve HEAD commits.
    /// Use `init(cli:config:resolvingCommits:)` for the async version with HEAD resolution.
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    init(cli: PatternCLIInputs, config: PatternConfig?) {
        let extensions = cli.extensions ?? config?.extensions ?? ["swift"]

        // Git configuration merges CLI > FileConfig > Default
        let gitConfig = GitConfiguration(cli: cli.git, fileConfig: config?.git)

        // Build metrics from CLI or config
        let metrics: [PatternSDK.MetricInput]

        if let cliPatterns = cli.patterns, !cliPatterns.isEmpty {
            // CLI patterns provided - all use same commits (from CLI or default HEAD)
            let commits = cli.commits ?? ["HEAD"]
            metrics = cliPatterns.map { PatternSDK.MetricInput(pattern: $0, commits: commits) }
        } else if let configMetrics = config?.metrics {
            // Config metrics - each has its own commits, CLI --commits overrides all
            if let cliCommits = cli.commits {
                // CLI commits override all config commits
                metrics = configMetrics.compactMap { metric in
                    // Skip metrics with empty commits array
                    if let commits = metric.commits, commits.isEmpty {
                        return nil
                    }
                    return PatternSDK.MetricInput(pattern: metric.pattern, commits: cliCommits)
                }
            } else {
                // Use per-metric commits from config
                metrics = configMetrics.compactMap { metric in
                    // Skip metrics with empty commits array
                    if let commits = metric.commits, commits.isEmpty {
                        return nil
                    }
                    let commits = metric.commits ?? ["HEAD"]
                    return PatternSDK.MetricInput(pattern: metric.pattern, commits: commits)
                }
            }
        } else {
            metrics = []
        }

        self.init(git: gitConfig, metrics: metrics, extensions: extensions)
    }

    /// Creates Input by merging CLI and file config with priority: CLI > Config > Default,
    /// and resolves HEAD commits to actual commit hashes.
    ///
    /// - Parameters:
    ///   - cli: Raw CLI inputs from ArgumentParser
    ///   - config: Configuration loaded from JSON file (optional)
    ///   - resolvingCommits: Pass `true` to resolve HEAD commits using git.repoPath
    init(cli: PatternCLIInputs, config: PatternConfig?, resolvingCommits: Bool) async throws {
        // Use synchronous init for merging logic
        let input = PatternSDK.Input(cli: cli, config: config)

        if resolvingCommits {
            // Resolve HEAD commits using repoPath from merged git config
            let resolvedMetrics = try await input.metrics.resolvingHeadCommits(
                repoPath: input.git.repoPath
            )
            self.init(git: input.git, metrics: resolvedMetrics, extensions: input.extensions)
        } else {
            self = input
        }
    }
}
