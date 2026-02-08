import Common
import Foundation
import Testing
import TypesSDK

@testable import Types

struct TypesInputPriorityTests {

    // MARK: - Metrics Priority Tests

    @Test
    func `CLI types create metrics with CLI commits`() throws {
        let cli = TypesCLIInputs(types: ["UIView"], repoPath: nil, commits: ["abc123"])

        let input = TypesSDK.Input(cli: cli, config: nil)

        #expect(input.metrics.count == 1)
        let metric = try #require(input.metrics[safe: 0])
        #expect(metric.type == "UIView")
        #expect(metric.commits == ["abc123"])
    }

    @Test
    func `CLI types use HEAD when commits not specified`() throws {
        let cli = TypesCLIInputs(types: ["UIView"], repoPath: nil, commits: nil)

        let input = TypesSDK.Input(cli: cli, config: nil)

        #expect(input.metrics.count == 1)
        let metric = try #require(input.metrics[safe: 0])
        #expect(metric.type == "UIView")
        #expect(metric.commits == ["HEAD"])
    }

    @Test
    func `falls back to config metrics when CLI types is nil`() throws {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)
        let config = TypesConfig(
            metrics: [TypeMetric(type: "UIViewController", commits: ["def456"])],
            git: nil
        )

        let input = TypesSDK.Input(cli: cli, config: config)

        #expect(input.metrics.count == 1)
        let metric = try #require(input.metrics[safe: 0])
        #expect(metric.type == "UIViewController")
        #expect(metric.commits == ["def456"])
    }

    @Test
    func `config metrics without commits use HEAD`() throws {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)
        let config = TypesConfig(
            metrics: [TypeMetric(type: "UIView", commits: nil)],
            git: nil
        )

        let input = TypesSDK.Input(cli: cli, config: config)

        #expect(input.metrics.count == 1)
        let metric = try #require(input.metrics[safe: 0])
        #expect(metric.commits == ["HEAD"])
    }

    @Test
    func `CLI commits override all config per-metric commits`() throws {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: ["cli-commit"])
        let config = TypesConfig(
            metrics: [
                TypeMetric(type: "UIView", commits: ["config-commit1"]),
                TypeMetric(type: "View", commits: ["config-commit2"]),
            ],
            git: nil
        )

        let input = TypesSDK.Input(cli: cli, config: config)

        #expect(input.metrics.count == 2)
        let metric0 = try #require(input.metrics[safe: 0])
        let metric1 = try #require(input.metrics[safe: 1])
        #expect(metric0.commits == ["cli-commit"])
        #expect(metric1.commits == ["cli-commit"])
    }

    @Test
    func `config metrics with empty commits array are skipped`() throws {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)
        let config = TypesConfig(
            metrics: [
                TypeMetric(type: "UIView", commits: ["abc123"]),
                TypeMetric(type: "SkippedType", commits: []),
                TypeMetric(type: "View", commits: nil),
            ],
            git: nil
        )

        let input = TypesSDK.Input(cli: cli, config: config)

        #expect(input.metrics.count == 2)
        let metric0 = try #require(input.metrics[safe: 0])
        let metric1 = try #require(input.metrics[safe: 1])
        #expect(metric0.type == "UIView")
        #expect(metric1.type == "View")
    }

    @Test
    func `falls back to empty array when both CLI and config types are nil`() throws {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)
        let config = TypesConfig(metrics: nil, git: nil)

        let input = TypesSDK.Input(cli: cli, config: config)

        #expect(input.metrics.isEmpty)
    }

    // MARK: - RepoPath Priority Tests

    @Test
    func `CLI repoPath overrides config repoPath`() throws {
        let cli = TypesCLIInputs(types: nil, repoPath: "/cli/path", commits: nil)
        let gitConfig = GitFileConfig(repoPath: "/config/path")
        let config = TypesConfig(metrics: nil, git: gitConfig)

        let input = TypesSDK.Input(cli: cli, config: config)

        #expect(input.git.repoPath == "/cli/path")
    }

    @Test
    func `falls back to config repoPath when CLI repoPath is nil`() throws {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)
        let gitConfig = GitFileConfig(repoPath: "/config/path")
        let config = TypesConfig(metrics: nil, git: gitConfig)

        let input = TypesSDK.Input(cli: cli, config: config)

        #expect(input.git.repoPath == "/config/path")
    }

    @Test
    func `falls back to current directory when both repoPath nil`() throws {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)
        let config = TypesConfig(metrics: nil, git: nil)

        let input = TypesSDK.Input(cli: cli, config: config)

        #expect(input.git.repoPath == FileManager.default.currentDirectoryPath)
    }

    // MARK: - Git Flags Priority Tests

    @Test
    func `CLI git flags override config git flags`() throws {
        let cli = TypesCLIInputs(
            types: nil,
            repoPath: nil,
            commits: nil,
            gitClean: true,
            fixLfs: false,
            initializeSubmodules: true
        )
        let gitConfig = GitFileConfig(
            repoPath: "/config/path",
            clean: false,
            fixLFS: true,
            initializeSubmodules: false
        )
        let config = TypesConfig(metrics: nil, git: gitConfig)

        let input = TypesSDK.Input(cli: cli, config: config)

        #expect(input.git.clean == true)  // CLI
        #expect(input.git.fixLFS == false)  // CLI
        #expect(input.git.initializeSubmodules == true)  // CLI
    }

    @Test
    func `falls back to config git flags when CLI is nil`() throws {
        let cli = TypesCLIInputs(
            types: nil,
            repoPath: nil,
            commits: nil,
            gitClean: nil,
            fixLfs: nil,
            initializeSubmodules: nil
        )
        let gitConfig = GitFileConfig(
            repoPath: "/config/path",
            clean: true,
            fixLFS: true,
            initializeSubmodules: true
        )
        let config = TypesConfig(metrics: nil, git: gitConfig)

        let input = TypesSDK.Input(cli: cli, config: config)

        #expect(input.git.clean == true)  // from config
        #expect(input.git.fixLFS == true)  // from config
        #expect(input.git.initializeSubmodules == true)  // from config
    }

    @Test
    func `git flags default to false when both CLI and config are nil`() throws {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)

        let input = TypesSDK.Input(cli: cli, config: nil)

        #expect(input.git.clean == false)
        #expect(input.git.fixLFS == false)
        #expect(input.git.initializeSubmodules == false)
    }

    // MARK: - Combined Priority Tests

    @Test
    func `full priority chain CLI then Config then Default`() throws {
        // CLI has types, config has repoPath
        let cli = TypesCLIInputs(types: ["UIView", "View"], repoPath: nil, commits: nil)
        let gitConfig = GitFileConfig(repoPath: "/from/config")
        let config = TypesConfig(
            metrics: [TypeMetric(type: "Ignored", commits: nil)],
            git: gitConfig
        )

        let input = TypesSDK.Input(cli: cli, config: config)

        #expect(input.metrics.count == 2)  // from CLI
        let metric0 = try #require(input.metrics[safe: 0])
        let metric1 = try #require(input.metrics[safe: 1])
        #expect(metric0.type == "UIView")
        #expect(metric1.type == "View")
        #expect(input.git.repoPath == "/from/config")  // from config
        #expect(metric0.commits == ["HEAD"])  // default
    }
}
