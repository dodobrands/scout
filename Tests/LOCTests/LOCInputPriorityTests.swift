import Common
import Foundation
import LOCSDK
import Testing

@testable import LOC

struct LOCInputPriorityTests {

    // MARK: - RepoPath Priority Tests

    @Test
    func `CLI repoPath overrides config repoPath`() {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: "/cli/path",
            commits: nil
        )
        let gitConfig = GitFileConfig(repoPath: "/config/path")
        let config = LOCConfig(configurations: nil, git: gitConfig)

        let input = LOCInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/cli/path")
    }

    @Test
    func `falls back to config repoPath when CLI repoPath is nil`() {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: nil
        )
        let gitConfig = GitFileConfig(repoPath: "/config/path")
        let config = LOCConfig(configurations: nil, git: gitConfig)

        let input = LOCInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/config/path")
    }

    @Test
    func `falls back to current directory when both CLI and config repoPath are nil`() {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: nil
        )
        let config = LOCConfig(configurations: nil, git: nil)

        let input = LOCInput(cli: cli, config: config)

        #expect(input.git.repoPath == FileManager.default.currentDirectoryPath)
    }

    // MARK: - Commits Priority Tests

    @Test
    func `CLI commits override default`() {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: ["abc123", "def456"]
        )

        let input = LOCInput(cli: cli, config: nil)

        #expect(input.commits == ["abc123", "def456"])
    }

    @Test
    func `falls back to HEAD when CLI commits is nil`() {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: nil
        )

        let input = LOCInput(cli: cli, config: nil)

        #expect(input.commits == ["HEAD"])
    }

    // MARK: - Languages/Configurations Priority Tests

    @Test
    func `CLI languages override config configurations`() {
        let cli = LOCCLIInputs(
            languages: ["Kotlin"],
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: nil
        )
        let locConfig = LOCConfig.LOCConfiguration(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: ["Vendor"]
        )
        let config = LOCConfig(configurations: [locConfig], git: nil)

        let input = LOCInput(cli: cli, config: config)

        #expect(input.configurations.count == 1)
        #expect(input.configurations[0].languages == ["Kotlin"])
        #expect(input.configurations[0].include == [])
        #expect(input.configurations[0].exclude == [])
    }

    @Test
    func `CLI languages with include and exclude`() {
        let cli = LOCCLIInputs(
            languages: ["Swift"],
            include: ["Sources", "App"],
            exclude: ["Tests"],
            repoPath: nil,
            commits: nil
        )

        let input = LOCInput(cli: cli, config: nil)

        #expect(input.configurations.count == 1)
        #expect(input.configurations[0].languages == ["Swift"])
        #expect(input.configurations[0].include == ["Sources", "App"])
        #expect(input.configurations[0].exclude == ["Tests"])
    }

    @Test
    func `configurations from config are used when CLI languages is nil`() {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: nil
        )
        let locConfig = LOCConfig.LOCConfiguration(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: ["Vendor"]
        )
        let config = LOCConfig(configurations: [locConfig], git: nil)

        let input = LOCInput(cli: cli, config: config)

        #expect(input.configurations.count == 1)
        #expect(input.configurations[0].languages == ["Swift"])
        #expect(input.configurations[0].include == ["Sources"])
        #expect(input.configurations[0].exclude == ["Vendor"])
    }

    @Test
    func `falls back to empty configurations when both nil`() {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: nil
        )

        let input = LOCInput(cli: cli, config: nil)

        #expect(input.configurations.isEmpty)
    }

    // MARK: - Git Flags Tests

    @Test
    func `git flags from CLI are applied`() {
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

        let input = LOCInput(cli: cli, config: nil)

        #expect(input.git.clean == true)
        #expect(input.git.fixLFS == true)
        #expect(input.git.initializeSubmodules == true)
    }

    // MARK: - Combined Priority Tests

    @Test
    func `full priority chain CLI then Config then Default`() {
        let cli = LOCCLIInputs(
            languages: nil,
            include: nil,
            exclude: nil,
            repoPath: nil,
            commits: ["abc123"]
        )
        let gitConfig = GitFileConfig(repoPath: "/from/config")
        let locConfig = LOCConfig.LOCConfiguration(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: []
        )
        let config = LOCConfig(configurations: [locConfig], git: gitConfig)

        let input = LOCInput(cli: cli, config: config)

        #expect(input.configurations.count == 1)  // from config
        #expect(input.git.repoPath == "/from/config")  // from config
        #expect(input.commits == ["abc123"])  // from CLI
    }
}
