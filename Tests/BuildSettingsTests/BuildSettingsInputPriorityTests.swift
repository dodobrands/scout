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
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )

        #expect(throws: BuildSettingsInputError.missingProject) {
            _ = try BuildSettingsInput(cli: cli, config: nil)
        }
    }

    // MARK: - repoPath priority

    @Test func `CLI repoPath overrides config repoPath`() throws {
        let cli = BuildSettingsCLIInputs(
            buildSettingsParameters: nil,
            repoPath: "/cli/path",
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: GitFileConfig(repoPath: "/config/path")
        )

        let input = try BuildSettingsInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/cli/path")
    }

    @Test func `falls back to config repoPath when CLI is nil`() throws {
        let cli = BuildSettingsCLIInputs(
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: GitFileConfig(repoPath: "/config/path")
        )

        let input = try BuildSettingsInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/config/path")
    }

    @Test func `falls back to current directory when both repoPath nil`() throws {
        let cli = BuildSettingsCLIInputs(
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let input = try BuildSettingsInput(cli: cli, config: config)

        #expect(input.git.repoPath == FileManager.default.currentDirectoryPath)
    }

    // MARK: - commits priority

    @Test func `CLI commits override default`() throws {
        let cli = BuildSettingsCLIInputs(
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: ["abc123", "def456"],
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let input = try BuildSettingsInput(cli: cli, config: config)

        #expect(input.commits == ["abc123", "def456"])
    }

    @Test func `falls back to HEAD when CLI commits nil`() throws {
        let cli = BuildSettingsCLIInputs(
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let input = try BuildSettingsInput(cli: cli, config: config)

        #expect(input.commits == ["HEAD"])
    }

    // MARK: - configuration priority

    @Test func `config configuration is used`() throws {
        let cli = BuildSettingsCLIInputs(
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: nil,
            project: "App.xcworkspace",
            configuration: "Release",
            git: nil
        )

        let input = try BuildSettingsInput(cli: cli, config: config)

        #expect(input.configuration == "Release")
    }

    @Test func `falls back to Debug when configuration nil`() throws {
        let cli = BuildSettingsCLIInputs(
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let input = try BuildSettingsInput(cli: cli, config: config)

        #expect(input.configuration == "Debug")
    }

    // MARK: - setupCommands from config

    @Test func `setupCommands from config are converted`() throws {
        let cli = BuildSettingsCLIInputs(
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
            buildSettingsParameters: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let input = try BuildSettingsInput(cli: cli, config: config)

        #expect(input.setupCommands.count == 1)
        #expect(input.setupCommands[0].command == "bundle install")
        #expect(input.setupCommands[0].workingDirectory == "ios")
        #expect(input.setupCommands[0].optional == true)
    }

    @Test func `setupCommands defaults to empty array when config setupCommands nil`() throws {
        let cli = BuildSettingsCLIInputs(
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let input = try BuildSettingsInput(cli: cli, config: config)

        #expect(input.setupCommands.isEmpty)
    }

    // MARK: - buildSettingsParameters priority

    @Test func `CLI buildSettingsParameters override config buildSettingsParameters`() throws {
        let cli = BuildSettingsCLIInputs(
            buildSettingsParameters: ["CLI_PARAM"],
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: ["CONFIG_PARAM"],
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let input = try BuildSettingsInput(cli: cli, config: config)

        #expect(input.buildSettingsParameters == ["CLI_PARAM"])
    }

    @Test func `buildSettingsParameters from config are used when CLI is nil`() throws {
        let cli = BuildSettingsCLIInputs(
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: ["SWIFT_VERSION", "TARGETED_DEVICE_FAMILY"],
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let input = try BuildSettingsInput(cli: cli, config: config)

        #expect(input.buildSettingsParameters == ["SWIFT_VERSION", "TARGETED_DEVICE_FAMILY"])
    }

    @Test func `buildSettingsParameters defaults to empty when both nil`() throws {
        let cli = BuildSettingsCLIInputs(
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let input = try BuildSettingsInput(cli: cli, config: config)

        #expect(input.buildSettingsParameters.isEmpty)
    }

    // MARK: - git flags from CLI

    @Test func `git flags from CLI are applied`() throws {
        let cli = BuildSettingsCLIInputs(
            buildSettingsParameters: nil,
            repoPath: "/test/path",
            commits: nil,
            gitClean: true,
            fixLfs: true,
            initializeSubmodules: true
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let input = try BuildSettingsInput(cli: cli, config: config)

        #expect(input.git.clean == true)
        #expect(input.git.fixLFS == true)
        #expect(input.git.initializeSubmodules == true)
    }

    @Test func `git flags default to false`() throws {
        let cli = BuildSettingsCLIInputs(
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: nil,
            project: "App.xcworkspace",
            configuration: nil,
            git: nil
        )

        let input = try BuildSettingsInput(cli: cli, config: config)

        #expect(input.git.clean == false)
        #expect(input.git.fixLFS == false)
        #expect(input.git.initializeSubmodules == false)
    }

    // MARK: - project is passed through

    @Test func `project from config is passed to input`() throws {
        let cli = BuildSettingsCLIInputs(
            buildSettingsParameters: nil,
            repoPath: nil,
            commits: nil,
            gitClean: false,
            fixLfs: false,
            initializeSubmodules: false
        )
        let config = BuildSettingsConfig(
            setupCommands: nil,
            buildSettingsParameters: nil,
            project: "MyApp.xcworkspace",
            configuration: nil,
            git: nil
        )

        let input = try BuildSettingsInput(cli: cli, config: config)

        #expect(input.project == "MyApp.xcworkspace")
    }
}
