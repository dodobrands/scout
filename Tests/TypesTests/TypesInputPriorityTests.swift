import Common
import Foundation
import Testing
import Types
import TypesSDK

struct TypesInputPriorityTests {

    // MARK: - Types Priority Tests

    @Test
    func `CLI types override config types`() {
        let cli = TypesCLIInputs(types: ["UIView"], repoPath: nil, commits: nil)
        let config = CountTypesConfig(types: ["UIViewController"], git: nil)

        let input = TypesInput(cli: cli, config: config)

        #expect(input.types == ["UIView"])
    }

    @Test
    func `falls back to config types when CLI types is nil`() {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)
        let config = CountTypesConfig(types: ["UIViewController"], git: nil)

        let input = TypesInput(cli: cli, config: config)

        #expect(input.types == ["UIViewController"])
    }

    @Test
    func `falls back to empty array when both CLI and config types are nil`() {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)
        let config = CountTypesConfig(types: nil, git: nil)

        let input = TypesInput(cli: cli, config: config)

        #expect(input.types == [])
    }

    @Test
    func `CLI types work without config`() {
        let cli = TypesCLIInputs(types: ["View"], repoPath: nil, commits: nil)

        let input = TypesInput(cli: cli, config: nil)

        #expect(input.types == ["View"])
    }

    // MARK: - RepoPath Priority Tests

    @Test
    func `CLI repoPath overrides config repoPath`() {
        let cli = TypesCLIInputs(types: nil, repoPath: "/cli/path", commits: nil)
        let gitConfig = GitConfiguration(repoPath: "/config/path")
        let config = CountTypesConfig(types: nil, git: gitConfig)

        let input = TypesInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/cli/path")
    }

    @Test
    func `falls back to config repoPath when CLI repoPath is nil`() {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)
        let gitConfig = GitConfiguration(repoPath: "/config/path")
        let config = CountTypesConfig(types: nil, git: gitConfig)

        let input = TypesInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/config/path")
    }

    @Test
    func `falls back to current directory when both CLI and config repoPath are nil`() {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)
        let config = CountTypesConfig(types: nil, git: nil)

        let input = TypesInput(cli: cli, config: config)

        #expect(input.git.repoPath == FileManager.default.currentDirectoryPath)
    }

    // MARK: - Commits Priority Tests

    @Test
    func `CLI commits override default`() {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: ["abc123", "def456"])

        let input = TypesInput(cli: cli, config: nil)

        #expect(input.commits == ["abc123", "def456"])
    }

    @Test
    func `falls back to HEAD when CLI commits is nil`() {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)

        let input = TypesInput(cli: cli, config: nil)

        #expect(input.commits == ["HEAD"])
    }

    // MARK: - Git Flags Tests

    @Test
    func `git flags from CLI are applied`() {
        let cli = TypesCLIInputs(
            types: nil,
            repoPath: nil,
            commits: nil,
            gitClean: true,
            fixLfs: true,
            initializeSubmodules: true
        )

        let input = TypesInput(cli: cli, config: nil)

        #expect(input.git.clean == true)
        #expect(input.git.fixLFS == true)
        #expect(input.git.initializeSubmodules == true)
    }

    @Test
    func `git flags default to false`() {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)

        let input = TypesInput(cli: cli, config: nil)

        #expect(input.git.clean == false)
        #expect(input.git.fixLFS == false)
        #expect(input.git.initializeSubmodules == false)
    }

    // MARK: - Combined Priority Tests

    @Test
    func `full priority chain CLI then Config then Default`() {
        // CLI has types, config has repoPath, commits use default
        let cli = TypesCLIInputs(types: ["UIView", "View"], repoPath: nil, commits: nil)
        let gitConfig = GitConfiguration(repoPath: "/from/config")
        let config = CountTypesConfig(types: ["Ignored"], git: gitConfig)

        let input = TypesInput(cli: cli, config: config)

        #expect(input.types == ["UIView", "View"])  // from CLI
        #expect(input.git.repoPath == "/from/config")  // from config
        #expect(input.commits == ["HEAD"])  // default
    }
}
