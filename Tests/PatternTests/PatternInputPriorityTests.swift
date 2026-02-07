import Common
import Foundation
import PatternSDK
import Testing

@testable import Pattern

struct PatternInputPriorityTests {

    // MARK: - Patterns Priority Tests

    @Test
    func `CLI patterns override config patterns`() {
        let cli = PatternCLIInputs(
            patterns: ["TODO:"],
            repoPath: nil,
            commits: nil,
            extensions: nil
        )
        let config = PatternConfig(
            metrics: [PatternMetric(pattern: "FIXME:", commits: nil)],
            extensions: nil,
            git: nil
        )

        let cliConfig = PatternCLIConfig(cli: cli, config: config)

        #expect(cliConfig.metrics.map { $0.pattern } == ["TODO:"])
    }

    @Test
    func `falls back to config patterns when CLI patterns is nil`() {
        let cli = PatternCLIInputs(patterns: nil, repoPath: nil, commits: nil, extensions: nil)
        let config = PatternConfig(
            metrics: [PatternMetric(pattern: "FIXME:", commits: nil)],
            extensions: nil,
            git: nil
        )

        let cliConfig = PatternCLIConfig(cli: cli, config: config)

        #expect(cliConfig.metrics.map { $0.pattern } == ["FIXME:"])
    }

    @Test
    func `falls back to empty array when both CLI and config patterns are nil`() {
        let cli = PatternCLIInputs(patterns: nil, repoPath: nil, commits: nil, extensions: nil)
        let config = PatternConfig(metrics: nil, extensions: nil, git: nil)

        let cliConfig = PatternCLIConfig(cli: cli, config: config)

        #expect(cliConfig.metrics.isEmpty)
    }

    // MARK: - Extensions Priority Tests

    @Test
    func `CLI extensions override config extensions`() {
        let cli = PatternCLIInputs(
            patterns: nil,
            repoPath: nil,
            commits: nil,
            extensions: ["m", "h"]
        )
        let config = PatternConfig(metrics: nil, extensions: ["swift"], git: nil)

        let cliConfig = PatternCLIConfig(cli: cli, config: config)

        #expect(cliConfig.extensions == ["m", "h"])
    }

    @Test
    func `falls back to config extensions when CLI extensions is nil`() {
        let cli = PatternCLIInputs(patterns: nil, repoPath: nil, commits: nil, extensions: nil)
        let config = PatternConfig(metrics: nil, extensions: ["m", "h"], git: nil)

        let cliConfig = PatternCLIConfig(cli: cli, config: config)

        #expect(cliConfig.extensions == ["m", "h"])
    }

    @Test
    func `falls back to swift when both CLI and config extensions are nil`() {
        let cli = PatternCLIInputs(patterns: nil, repoPath: nil, commits: nil, extensions: nil)
        let config = PatternConfig(metrics: nil, extensions: nil, git: nil)

        let cliConfig = PatternCLIConfig(cli: cli, config: config)

        #expect(cliConfig.extensions == ["swift"])
    }

    // MARK: - RepoPath Priority Tests

    @Test
    func `CLI repoPath overrides config repoPath`() {
        let cli = PatternCLIInputs(
            patterns: nil,
            repoPath: "/cli/path",
            commits: nil,
            extensions: nil
        )
        let gitConfig = GitFileConfig(repoPath: "/config/path")
        let config = PatternConfig(metrics: nil, extensions: nil, git: gitConfig)

        let cliConfig = PatternCLIConfig(cli: cli, config: config)

        #expect(cliConfig.git.repoPath == "/cli/path")
    }

    @Test
    func `falls back to config repoPath when CLI repoPath is nil`() {
        let cli = PatternCLIInputs(patterns: nil, repoPath: nil, commits: nil, extensions: nil)
        let gitConfig = GitFileConfig(repoPath: "/config/path")
        let config = PatternConfig(metrics: nil, extensions: nil, git: gitConfig)

        let cliConfig = PatternCLIConfig(cli: cli, config: config)

        #expect(cliConfig.git.repoPath == "/config/path")
    }

    // MARK: - Commits Priority Tests

    @Test
    func `CLI commits override default`() throws {
        let cli = PatternCLIInputs(
            patterns: ["TODO:"],
            repoPath: nil,
            commits: ["abc123"],
            extensions: nil
        )

        let cliConfig = PatternCLIConfig(cli: cli, config: nil)

        let metric = try #require(cliConfig.metrics.first)
        #expect(metric.commits == ["abc123"])
    }

    @Test
    func `falls back to HEAD when CLI commits is nil`() throws {
        let cli = PatternCLIInputs(
            patterns: ["TODO:"],
            repoPath: nil,
            commits: nil,
            extensions: nil
        )

        let cliConfig = PatternCLIConfig(cli: cli, config: nil)

        let metric = try #require(cliConfig.metrics.first)
        #expect(metric.commits == ["HEAD"])
    }

    // MARK: - Per-Metric Commits Tests

    @Test
    func `config metrics use per-metric commits`() throws {
        let cli = PatternCLIInputs(patterns: nil, repoPath: nil, commits: nil, extensions: nil)
        let config = PatternConfig(
            metrics: [
                PatternMetric(pattern: "TODO:", commits: ["abc123", "def456"]),
                PatternMetric(pattern: "FIXME:", commits: ["ghi789"]),
            ],
            extensions: nil,
            git: nil
        )

        let cliConfig = PatternCLIConfig(cli: cli, config: config)

        #expect(cliConfig.metrics.count == 2)
        let metric0 = try #require(cliConfig.metrics[safe: 0])
        let metric1 = try #require(cliConfig.metrics[safe: 1])
        #expect(metric0.pattern == "TODO:")
        #expect(metric0.commits == ["abc123", "def456"])
        #expect(metric1.pattern == "FIXME:")
        #expect(metric1.commits == ["ghi789"])
    }

    @Test
    func `CLI commits override all config per-metric commits`() throws {
        let cli = PatternCLIInputs(
            patterns: nil,
            repoPath: nil,
            commits: ["override123"],
            extensions: nil
        )
        let config = PatternConfig(
            metrics: [
                PatternMetric(pattern: "TODO:", commits: ["abc123"]),
                PatternMetric(pattern: "FIXME:", commits: ["def456"]),
            ],
            extensions: nil,
            git: nil
        )

        let cliConfig = PatternCLIConfig(cli: cli, config: config)

        #expect(cliConfig.metrics.count == 2)
        let metric0 = try #require(cliConfig.metrics[safe: 0])
        let metric1 = try #require(cliConfig.metrics[safe: 1])
        #expect(metric0.commits == ["override123"])
        #expect(metric1.commits == ["override123"])
    }

    @Test
    func `config metrics with nil commits default to HEAD`() throws {
        let cli = PatternCLIInputs(patterns: nil, repoPath: nil, commits: nil, extensions: nil)
        let config = PatternConfig(
            metrics: [
                PatternMetric(pattern: "TODO:", commits: nil)
            ],
            extensions: nil,
            git: nil
        )

        let cliConfig = PatternCLIConfig(cli: cli, config: config)

        let metric = try #require(cliConfig.metrics.first)
        #expect(metric.commits == ["HEAD"])
    }

    @Test
    func `config metrics with empty commits array are skipped`() throws {
        let cli = PatternCLIInputs(patterns: nil, repoPath: nil, commits: nil, extensions: nil)
        let config = PatternConfig(
            metrics: [
                PatternMetric(pattern: "TODO:", commits: ["abc123"]),
                PatternMetric(pattern: "SKIP:", commits: []),
                PatternMetric(pattern: "FIXME:", commits: nil),
            ],
            extensions: nil,
            git: nil
        )

        let cliConfig = PatternCLIConfig(cli: cli, config: config)

        #expect(cliConfig.metrics.count == 2)
        #expect(cliConfig.metrics.map { $0.pattern } == ["TODO:", "FIXME:"])
    }

    // MARK: - Git Flags Tests

    @Test
    func `git flags from CLI are applied`() {
        let cli = PatternCLIInputs(
            patterns: nil,
            repoPath: nil,
            commits: nil,
            extensions: nil,
            gitClean: true,
            fixLfs: true,
            initializeSubmodules: true
        )

        let cliConfig = PatternCLIConfig(cli: cli, config: nil)

        #expect(cliConfig.git.clean == true)
        #expect(cliConfig.git.fixLFS == true)
        #expect(cliConfig.git.initializeSubmodules == true)
    }

    // MARK: - Combined Priority Tests

    @Test
    func `full priority chain CLI then Config then Default`() throws {
        let cli = PatternCLIInputs(
            patterns: ["TODO:"],
            repoPath: nil,
            commits: nil,
            extensions: nil
        )
        let gitConfig = GitFileConfig(repoPath: "/from/config")
        let config = PatternConfig(
            metrics: [PatternMetric(pattern: "Ignored", commits: nil)],
            extensions: ["m"],
            git: gitConfig
        )

        let cliConfig = PatternCLIConfig(cli: cli, config: config)

        #expect(cliConfig.metrics.map { $0.pattern } == ["TODO:"])  // from CLI
        #expect(cliConfig.git.repoPath == "/from/config")  // from config
        #expect(cliConfig.extensions == ["m"])  // from config
        let metric = try #require(cliConfig.metrics.first)
        #expect(metric.commits == ["HEAD"])  // default
    }
}
