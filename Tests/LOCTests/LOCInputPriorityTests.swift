import Common
import Foundation
import LOC
import LOCSDK
import Testing

struct LOCInputPriorityTests {

    // MARK: - RepoPath Priority Tests

    @Test
    func `CLI repoPath overrides config repoPath`() {
        let cli = LOCCLIInputs(repoPath: "/cli/path", commits: nil)
        let gitConfig = GitConfiguration(repoPath: "/config/path")
        let config = CountLOCConfig(configurations: nil, git: gitConfig)

        let input = LOCInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/cli/path")
    }

    @Test
    func `falls back to config repoPath when CLI repoPath is nil`() {
        let cli = LOCCLIInputs(repoPath: nil, commits: nil)
        let gitConfig = GitConfiguration(repoPath: "/config/path")
        let config = CountLOCConfig(configurations: nil, git: gitConfig)

        let input = LOCInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/config/path")
    }

    @Test
    func `falls back to current directory when both CLI and config repoPath are nil`() {
        let cli = LOCCLIInputs(repoPath: nil, commits: nil)
        let config = CountLOCConfig(configurations: nil, git: nil)

        let input = LOCInput(cli: cli, config: config)

        #expect(input.git.repoPath == FileManager.default.currentDirectoryPath)
    }

    // MARK: - Commits Priority Tests

    @Test
    func `CLI commits override default`() {
        let cli = LOCCLIInputs(repoPath: nil, commits: ["abc123", "def456"])

        let input = LOCInput(cli: cli, config: nil)

        #expect(input.commits == ["abc123", "def456"])
    }

    @Test
    func `falls back to HEAD when CLI commits is nil`() {
        let cli = LOCCLIInputs(repoPath: nil, commits: nil)

        let input = LOCInput(cli: cli, config: nil)

        #expect(input.commits == ["HEAD"])
    }

    // MARK: - Configurations Priority Tests

    @Test
    func `configurations from config are used`() {
        let cli = LOCCLIInputs(repoPath: nil, commits: nil)
        let locConfig = CountLOCConfig.LOCConfiguration(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: ["Vendor"]
        )
        let config = CountLOCConfig(configurations: [locConfig], git: nil)

        let input = LOCInput(cli: cli, config: config)

        #expect(input.configurations.count == 1)
        #expect(input.configurations[0].languages == ["Swift"])
        #expect(input.configurations[0].include == ["Sources"])
        #expect(input.configurations[0].exclude == ["Vendor"])
    }

    @Test
    func `falls back to empty configurations when config is nil`() {
        let cli = LOCCLIInputs(repoPath: nil, commits: nil)

        let input = LOCInput(cli: cli, config: nil)

        #expect(input.configurations.isEmpty)
    }

    // MARK: - Git Flags Tests

    @Test
    func `git flags from CLI are applied`() {
        let cli = LOCCLIInputs(
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
        let cli = LOCCLIInputs(repoPath: nil, commits: ["abc123"])
        let gitConfig = GitConfiguration(repoPath: "/from/config")
        let locConfig = CountLOCConfig.LOCConfiguration(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: []
        )
        let config = CountLOCConfig(configurations: [locConfig], git: gitConfig)

        let input = LOCInput(cli: cli, config: config)

        #expect(input.configurations.count == 1)  // from config
        #expect(input.git.repoPath == "/from/config")  // from config
        #expect(input.commits == ["abc123"])  // from CLI
    }
}
