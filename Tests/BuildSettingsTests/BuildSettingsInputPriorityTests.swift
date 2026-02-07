import BuildSettingsSDK
import Common
import Foundation
import Testing

@testable import BuildSettings

/// Tests for BuildSettingsInput priority: CLI > Config > Default
@Suite("BuildSettingsInput Priority")
struct BuildSettingsInputPriorityTests {

    // MARK: - project required

    @Test func `throws error when project is missing`() {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )

        #expect(throws: BuildSettingsInputError.missingProject) {
            _ = try BuildSettingsCLIConfig(cli: cli, config: nil)
        }
    }

    // MARK: - repoPath priority

    @Test func `CLI repoPath overrides config repoPath`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: "/cli/path",
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: GitFileConfig(repoPath: "/config/path")
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(cliConfig.git.repoPath == "/cli/path")
    }

    @Test func `falls back to config repoPath when CLI is nil`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: GitFileConfig(repoPath: "/config/path")
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(cliConfig.git.repoPath == "/config/path")
    }

    @Test func `falls back to current directory when both repoPath nil`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(cliConfig.git.repoPath == FileManager.default.currentDirectoryPath)
    }

    // MARK: - commits priority

    @Test func `CLI commits override default`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: ["SWIFT_VERSION"],
            repoPath: nil,
            commits: ["abc123", "def456"],
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        let metric = try #require(cliConfig.metrics.first)
        #expect(metric.commits == ["abc123", "def456"])
    }

    @Test func `falls back to HEAD when CLI commits nil`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: ["SWIFT_VERSION"],
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        let metric = try #require(cliConfig.metrics.first)
        #expect(metric.commits == ["HEAD"])
    }

    // MARK: - configuration priority

    @Test func `config configuration is used`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: nil,
            project: "App.xcworkspace",
            configuration: "Release",
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(cliConfig.configuration == "Release")
    }

    @Test func `falls back to Debug when configuration nil`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(cliConfig.configuration == "Debug")
    }

    // MARK: - setupCommands from config

    @Test func `setupCommands from config are converted`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let setupCommand = BuildSettingsConfig.SetupCommand(
            command: "bundle install",
            workingDirectory: "ios",
            optional: true
        )
        let config = BuildSettingsConfig(
            setupCommands: [setupCommand],
            metrics: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(cliConfig.setupCommands.count == 1)
        let command = try #require(cliConfig.setupCommands[safe: 0])
        #expect(command.command == "bundle install")
        #expect(command.workingDirectory == "ios")
        #expect(command.optional == true)
    }

    @Test func `setupCommands defaults to empty array when config setupCommands nil`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(cliConfig.setupCommands.isEmpty)
    }

    // MARK: - metrics priority

    @Test func `CLI buildSettingsParameters override config metrics`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: ["CLI_PARAM"],
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: [SettingMetric(setting: "CONFIG_PARAM", commits: nil)],
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(cliConfig.metrics.map { $0.setting } == ["CLI_PARAM"])
    }

    @Test func `metrics from config are used when CLI is nil`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: [
                SettingMetric(setting: "SWIFT_VERSION", commits: nil),
                SettingMetric(setting: "TARGETED_DEVICE_FAMILY", commits: nil),
            ],
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(
            cliConfig.metrics.map { $0.setting } == ["SWIFT_VERSION", "TARGETED_DEVICE_FAMILY"]
        )
    }

    @Test func `metrics defaults to empty when both nil`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(cliConfig.metrics.isEmpty)
    }

    // MARK: - Per-Metric Commits Tests

    @Test func `config metrics use per-metric commits`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: [
                SettingMetric(setting: "SWIFT_VERSION", commits: ["abc123", "def456"]),
                SettingMetric(setting: "DEPLOYMENT_TARGET", commits: ["ghi789"]),
            ],
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(cliConfig.metrics.count == 2)
        let metric0 = try #require(cliConfig.metrics[safe: 0])
        let metric1 = try #require(cliConfig.metrics[safe: 1])
        #expect(metric0.setting == "SWIFT_VERSION")
        #expect(metric0.commits == ["abc123", "def456"])
        #expect(metric1.setting == "DEPLOYMENT_TARGET")
        #expect(metric1.commits == ["ghi789"])
    }

    @Test func `CLI commits override all config per-metric commits`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: ["override123"],
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: [
                SettingMetric(setting: "SWIFT_VERSION", commits: ["abc123"]),
                SettingMetric(setting: "DEPLOYMENT_TARGET", commits: ["def456"]),
            ],
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(cliConfig.metrics.count == 2)
        let metric0 = try #require(cliConfig.metrics[safe: 0])
        let metric1 = try #require(cliConfig.metrics[safe: 1])
        #expect(metric0.commits == ["override123"])
        #expect(metric1.commits == ["override123"])
    }

    @Test func `config metrics with nil commits default to HEAD`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: [SettingMetric(setting: "SWIFT_VERSION", commits: nil)],
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        let metric = try #require(cliConfig.metrics.first)
        #expect(metric.commits == ["HEAD"])
    }

    @Test func `config metrics with empty commits array are skipped`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: [
                SettingMetric(setting: "SWIFT_VERSION", commits: ["abc123"]),
                SettingMetric(setting: "EXCLUDED_SETTING", commits: []),
                SettingMetric(setting: "DEPLOYMENT_TARGET", commits: nil),
            ],
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(cliConfig.metrics.count == 2)
        #expect(cliConfig.metrics.map { $0.setting } == ["SWIFT_VERSION", "DEPLOYMENT_TARGET"])
    }

    // MARK: - git flags from CLI

    @Test func `git flags from CLI are applied`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: "/test/path",
            commits: nil,
            gitClean: true,
            fixLfs: true,
            initializeSubmodules: true
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(cliConfig.git.clean == true)
        #expect(cliConfig.git.fixLFS == true)
        #expect(cliConfig.git.initializeSubmodules == true)
    }

    @Test func `git flags default to false`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(cliConfig.git.clean == false)
        #expect(cliConfig.git.fixLFS == false)
        #expect(cliConfig.git.initializeSubmodules == false)
    }

    // MARK: - project is passed through

    @Test func `project from config is passed to input`() throws {
        let cli = BuildSettingsCLIInputs(
            project: nil,
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: nil,
            project: "MyApp.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(cliConfig.project == "MyApp.xcworkspace")
    }

    @Test func `CLI project overrides config project`() throws {
        let cli = BuildSettingsCLIInputs(
            project: "CLIApp.xcodeproj",
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            metrics: nil,
            project: "ConfigApp.xcworkspace",
            configuration: nil,
            git: nil
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: config)

        #expect(cliConfig.project == "CLIApp.xcodeproj")
    }

    @Test func `CLI project works without config`() throws {
        let cli = BuildSettingsCLIInputs(
            project: "MyApp.xcworkspace",
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )

        let cliConfig = try BuildSettingsCLIConfig(cli: cli, config: nil)

        #expect(cliConfig.project == "MyApp.xcworkspace")
    }
}
