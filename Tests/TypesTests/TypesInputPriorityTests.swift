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
        let config = TypesConfig(types: ["UIViewController"], git: nil)

        let input = TypesInput(cli: cli, config: config)

        #expect(input.types == ["UIView"])
    }

    @Test
    func `falls back to config types when CLI types is nil`() {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)
        let config = TypesConfig(types: ["UIViewController"], git: nil)

        let input = TypesInput(cli: cli, config: config)

        #expect(input.types == ["UIViewController"])
    }

    @Test
    func `falls back to empty array when both CLI and config types are nil`() {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)
        let config = TypesConfig(types: nil, git: nil)

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
        let gitConfig = GitFileConfig(repoPath: "/config/path")
        let config = TypesConfig(types: nil, git: gitConfig)

        let input = TypesInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/cli/path")
    }

    @Test
    func `falls back to config repoPath when CLI repoPath is nil`() {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)
        let gitConfig = GitFileConfig(repoPath: "/config/path")
        let config = TypesConfig(types: nil, git: gitConfig)

        let input = TypesInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/config/path")
    }

    @Test
    func `falls back to current directory when both CLI and config repoPath are nil`() {
        let cli = TypesCLIInputs(types: nil, repoPath: nil, commits: nil)
        let config = TypesConfig(types: nil, git: nil)

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

    // MARK: - Git Flags Priority Tests

    @Test
    func `CLI git flags override config git flags`() {
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
        let config = TypesConfig(types: nil, git: gitConfig)

        let input = TypesInput(cli: cli, config: config)

        #expect(input.git.clean == true)  // CLI
        #expect(input.git.fixLFS == false)  // CLI
        #expect(input.git.initializeSubmodules == true)  // CLI
    }

    @Test
    func `falls back to config git flags when CLI is nil`() {
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
        let config = TypesConfig(types: nil, git: gitConfig)

        let input = TypesInput(cli: cli, config: config)

        #expect(input.git.clean == true)  // from config
        #expect(input.git.fixLFS == true)  // from config
        #expect(input.git.initializeSubmodules == true)  // from config
    }

    @Test
    func `git flags default to false when both CLI and config are nil`() {
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
        let gitConfig = GitFileConfig(repoPath: "/from/config")
        let config = TypesConfig(types: ["Ignored"], git: gitConfig)

        let input = TypesInput(cli: cli, config: config)

        #expect(input.types == ["UIView", "View"])  // from CLI
        #expect(input.git.repoPath == "/from/config")  // from config
        #expect(input.commits == ["HEAD"])  // default
    }
}
