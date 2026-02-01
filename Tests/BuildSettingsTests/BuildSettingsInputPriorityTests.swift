import BuildSettings
import BuildSettingsSDK
import Common
import Foundation
import Testing

/// Tests for BuildSettingsInput priority: CLI > Config > Default
@Suite("BuildSettingsInput Priority")
struct BuildSettingsInputPriorityTests {

    // MARK: - repoPath priority

    @Test func `CLI repoPath overrides config repoPath`() {
        let cli = BuildSettingsCLIInputs(
            repoPath: "/cli/path",
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = ExtractBuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: nil,
            workspaceName: nil,
            configuration: nil,
            git: GitConfiguration(repoPath: "/config/path")
        )

        let input = BuildSettingsInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/cli/path")
    }

    @Test func `falls back to config repoPath when CLI is nil`() {
        let cli = BuildSettingsCLIInputs(
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = ExtractBuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: nil,
            workspaceName: nil,
            configuration: nil,
            git: GitConfiguration(repoPath: "/config/path")
        )

        let input = BuildSettingsInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/config/path")
    }

    @Test func `falls back to current directory when both repoPath nil`() {
        let cli = BuildSettingsCLIInputs(
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )

        let input = BuildSettingsInput(cli: cli, config: nil)

        #expect(input.git.repoPath == FileManager.default.currentDirectoryPath)
    }

    // MARK: - commits priority

    @Test func `CLI commits override default`() {
        let cli = BuildSettingsCLIInputs(
            repoPath: nil,
            commits: ["abc123", "def456"],
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )

        let input = BuildSettingsInput(cli: cli, config: nil)

        #expect(input.commits == ["abc123", "def456"])
    }

    @Test func `falls back to HEAD when CLI commits nil`() {
        let cli = BuildSettingsCLIInputs(
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )

        let input = BuildSettingsInput(cli: cli, config: nil)

        #expect(input.commits == ["HEAD"])
    }

    // MARK: - configuration priority

    @Test func `config configuration is used`() {
        let cli = BuildSettingsCLIInputs(
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = ExtractBuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: nil,
            workspaceName: nil,
            configuration: "Release",
            git: nil
        )

        let input = BuildSettingsInput(cli: cli, config: config)

        #expect(input.configuration == "Release")
    }

    @Test func `falls back to Debug when configuration nil`() {
        let cli = BuildSettingsCLIInputs(
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )

        let input = BuildSettingsInput(cli: cli, config: nil)

        #expect(input.configuration == "Debug")
    }

    // MARK: - setupCommands from config

    @Test func `setupCommands from config are converted`() {
        let cli = BuildSettingsCLIInputs(
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let setupCommand = ExtractBuildSettingsConfig.SetupCommand(
            command: "bundle install",
            workingDirectory: "ios",
            optional: true
        )
        let config = ExtractBuildSettingsConfig(
            setupCommands: [setupCommand],
            buildSettingsParameters: nil,
            workspaceName: nil,
            configuration: nil,
            git: nil
        )

        let input = BuildSettingsInput(cli: cli, config: config)

        #expect(input.setupCommands.count == 1)
        #expect(input.setupCommands[0].command == "bundle install")
        #expect(input.setupCommands[0].workingDirectory == "ios")
        #expect(input.setupCommands[0].optional == true)
    }

    @Test func `setupCommands defaults to empty array when config nil`() {
        let cli = BuildSettingsCLIInputs(
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )

        let input = BuildSettingsInput(cli: cli, config: nil)

        #expect(input.setupCommands.isEmpty)
    }

    // MARK: - buildSettingsParameters from config

    @Test func `buildSettingsParameters from config are used`() {
        let cli = BuildSettingsCLIInputs(
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = ExtractBuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: ["SWIFT_VERSION", "TARGETED_DEVICE_FAMILY"],
            workspaceName: nil,
            configuration: nil,
            git: nil
        )

        let input = BuildSettingsInput(cli: cli, config: config)

        #expect(input.buildSettingsParameters == ["SWIFT_VERSION", "TARGETED_DEVICE_FAMILY"])
    }

    @Test func `buildSettingsParameters defaults to empty when config nil`() {
        let cli = BuildSettingsCLIInputs(
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )

        let input = BuildSettingsInput(cli: cli, config: nil)

        #expect(input.buildSettingsParameters.isEmpty)
    }

    // MARK: - git flags from CLI

    @Test func `git flags from CLI are applied`() {
        let cli = BuildSettingsCLIInputs(
            repoPath: "/test/path",
            commits: nil,
            gitClean: true,
            fixLfs: true,
            initializeSubmodules: true
        )

        let input = BuildSettingsInput(cli: cli, config: nil)

        #expect(input.git.clean == true)
        #expect(input.git.fixLFS == true)
        #expect(input.git.initializeSubmodules == true)
    }

    @Test func `git flags default to false`() {
        let cli = BuildSettingsCLIInputs(
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )

        let input = BuildSettingsInput(cli: cli, config: nil)

        #expect(input.git.clean == false)
        #expect(input.git.fixLFS == false)
        #expect(input.git.initializeSubmodules == false)
    }
}
