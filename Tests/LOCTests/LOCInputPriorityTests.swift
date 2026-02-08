import Common
import Foundation
import LOCSDK
import Testing

@testable import LOC

struct LOCInputPriorityTests {

    // MARK: - RepoPath Priority Tests

    @Test
    func `CLI repoPath overrides config repoPath`() throws {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: "/cli/path",
            commits: nil
        )
        let gitConfig = GitFileConfig(repoPath: "/config/path")
        let config = LOCConfig(metrics: nil, git: gitConfig)

        let input = LOCSDK.Input(cli: cli, config: config)

        #expect(input.git.repoPath == "/cli/path")
    }

    @Test
    func `falls back to config repoPath when CLI repoPath is nil`() throws {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: nil
        )
        let gitConfig = GitFileConfig(repoPath: "/config/path")
        let config = LOCConfig(metrics: nil, git: gitConfig)

        let input = LOCSDK.Input(cli: cli, config: config)

        #expect(input.git.repoPath == "/config/path")
    }

    @Test
    func `falls back to current directory when both repoPath nil`() throws {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: nil
        )
        let config = LOCConfig(metrics: nil, git: nil)

        let input = LOCSDK.Input(cli: cli, config: config)

        #expect(input.git.repoPath == FileManager.default.currentDirectoryPath)
    }

    // MARK: - Commits Priority Tests

    @Test
    func `CLI commits override default`() throws {
        let cli = LOCCLIInputs(
            languages: ["Swift"],
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: ["abc123", "def456"]
        )

        let input = LOCSDK.Input(cli: cli, config: nil)

        let metric = try #require(input.metrics.first)
        #expect(metric.commits == ["abc123", "def456"])
    }

    @Test
    func `falls back to HEAD when CLI commits is nil`() throws {
        let cli = LOCCLIInputs(
            languages: ["Swift"],
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: nil
        )

        let input = LOCSDK.Input(cli: cli, config: nil)

        let metric = try #require(input.metrics.first)
        #expect(metric.commits == ["HEAD"])
    }

    // MARK: - Languages/Metrics Priority Tests

    @Test
    func `CLI languages override config metrics`() throws {
        let cli = LOCCLIInputs(
            languages: ["Kotlin"],
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: nil
        )
        let locMetric = LOCMetric(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: ["Vendor"],
            commits: nil
        )
        let config = LOCConfig(metrics: [locMetric], git: nil)

        let input = LOCSDK.Input(cli: cli, config: config)

        #expect(input.metrics.count == 1)
        let metric = try #require(input.metrics[safe: 0])
        #expect(metric.languages == ["Kotlin"])
        #expect(metric.include == [])
        #expect(metric.exclude == [])
    }

    @Test
    func `CLI languages with include and exclude`() throws {
        let cli = LOCCLIInputs(
            languages: ["Swift"],
            include: ["Sources", "App"],
            exclude: ["Tests"],
            repoPath: nil,
            commits: nil
        )

        let input = LOCSDK.Input(cli: cli, config: nil)

        #expect(input.metrics.count == 1)
        let metric = try #require(input.metrics[safe: 0])
        #expect(metric.languages == ["Swift"])
        #expect(metric.include == ["Sources", "App"])
        #expect(metric.exclude == ["Tests"])
    }

    @Test
    func `metrics from config are used when CLI languages is nil`() throws {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: nil
        )
        let locMetric = LOCMetric(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: ["Vendor"],
            commits: nil
        )
        let config = LOCConfig(metrics: [locMetric], git: nil)

        let input = LOCSDK.Input(cli: cli, config: config)

        #expect(input.metrics.count == 1)
        let metric = try #require(input.metrics[safe: 0])
        #expect(metric.languages == ["Swift"])
        #expect(metric.include == ["Sources"])
        #expect(metric.exclude == ["Vendor"])
    }

    @Test
    func `falls back to empty metrics when both nil`() throws {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: nil
        )

        let input = LOCSDK.Input(cli: cli, config: nil)

        #expect(input.metrics.isEmpty)
    }

    // MARK: - Per-Metric Commits Tests

    @Test
    func `config metrics use per-metric commits`() throws {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: nil
        )
        let config = LOCConfig(
            metrics: [
                LOCMetric(
                    languages: ["Swift"],
                    include: ["Sources"],
                    exclude: [],
                    commits: ["abc123", "def456"]
                ),
                LOCMetric(
                    languages: ["Objective-C"],
                    include: ["Legacy"],
                    exclude: [],
                    commits: ["ghi789"]
                ),
            ],
            git: nil
        )

        let input = LOCSDK.Input(cli: cli, config: config)

        #expect(input.metrics.count == 2)
        let metric0 = try #require(input.metrics[safe: 0])
        let metric1 = try #require(input.metrics[safe: 1])
        #expect(metric0.languages == ["Swift"])
        #expect(metric0.commits == ["abc123", "def456"])
        #expect(metric1.languages == ["Objective-C"])
        #expect(metric1.commits == ["ghi789"])
    }

    @Test
    func `CLI commits override all config per-metric commits`() throws {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: ["override123"]
        )
        let config = LOCConfig(
            metrics: [
                LOCMetric(
                    languages: ["Swift"],
                    include: ["Sources"],
                    exclude: [],
                    commits: ["abc123"]
                ),
                LOCMetric(
                    languages: ["Objective-C"],
                    include: ["Legacy"],
                    exclude: [],
                    commits: ["def456"]
                ),
            ],
            git: nil
        )

        let input = LOCSDK.Input(cli: cli, config: config)

        #expect(input.metrics.count == 2)
        let metric0 = try #require(input.metrics[safe: 0])
        let metric1 = try #require(input.metrics[safe: 1])
        #expect(metric0.commits == ["override123"])
        #expect(metric1.commits == ["override123"])
    }

    @Test
    func `config metrics with nil commits default to HEAD`() throws {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: nil
        )
        let config = LOCConfig(
            metrics: [
                LOCMetric(
                    languages: ["Swift"],
                    include: ["Sources"],
                    exclude: [],
                    commits: nil
                )
            ],
            git: nil
        )

        let input = LOCSDK.Input(cli: cli, config: config)

        let metric = try #require(input.metrics.first)
        #expect(metric.commits == ["HEAD"])
    }

    @Test
    func `config metrics with empty commits array are skipped`() throws {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: nil
        )
        let config = LOCConfig(
            metrics: [
                LOCMetric(
                    languages: ["Swift"],
                    include: ["Sources"],
                    exclude: [],
                    commits: ["abc123"]
                ),
                LOCMetric(
                    languages: ["Kotlin"],
                    include: ["Android"],
                    exclude: [],
                    commits: []
                ),
                LOCMetric(
                    languages: ["Objective-C"],
                    include: ["Legacy"],
                    exclude: [],
                    commits: nil
                ),
            ],
            git: nil
        )

        let input = LOCSDK.Input(cli: cli, config: config)

        #expect(input.metrics.count == 2)
        #expect(input.metrics.map { $0.languages } == [["Swift"], ["Objective-C"]])
    }

    // MARK: - Git Flags Tests

    @Test
    func `git flags from CLI are applied`() throws {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: nil,
            gitClean: true,
            fixLfs: true,
            initializeSubmodules: true
        )

        let input = LOCSDK.Input(cli: cli, config: nil)

        #expect(input.git.clean == true)
        #expect(input.git.fixLFS == true)
        #expect(input.git.initializeSubmodules == true)
    }

    // MARK: - Combined Priority Tests

    @Test
    func `full priority chain CLI then Config then Default`() throws {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: ["abc123"]
        )
        let gitConfig = GitFileConfig(repoPath: "/from/config")
        let locMetric = LOCMetric(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: [],
            commits: nil
        )
        let config = LOCConfig(metrics: [locMetric], git: gitConfig)

        let input = LOCSDK.Input(cli: cli, config: config)

        #expect(input.metrics.count == 1)  // from config
        #expect(input.git.repoPath == "/from/config")  // from config
        let metric = try #require(input.metrics.first)
        #expect(metric.commits == ["abc123"])  // from CLI
    }
}
