import Common
import FilesSDK
import Foundation
import Testing

@testable import Files

struct FilesInputPriorityTests {

    // MARK: - Filetypes Priority Tests

    @Test
    func `CLI filetypes override config filetypes`() {
        let cli = FilesCLIInputs(filetypes: ["swift"], repoPath: nil, commits: nil)
        let config = FilesConfig(filetypes: ["storyboard"], git: nil)

        let input = FilesInput(cli: cli, config: config)

        #expect(input.filetypes == ["swift"])
    }

    @Test
    func `falls back to config filetypes when CLI filetypes is nil`() {
        let cli = FilesCLIInputs(filetypes: nil, repoPath: nil, commits: nil)
        let config = FilesConfig(filetypes: ["storyboard"], git: nil)

        let input = FilesInput(cli: cli, config: config)

        #expect(input.filetypes == ["storyboard"])
    }

    @Test
    func `falls back to empty array when both CLI and config filetypes are nil`() {
        let cli = FilesCLIInputs(filetypes: nil, repoPath: nil, commits: nil)
        let config = FilesConfig(filetypes: nil, git: nil)

        let input = FilesInput(cli: cli, config: config)

        #expect(input.filetypes == [])
    }

    @Test
    func `CLI filetypes work without config`() {
        let cli = FilesCLIInputs(filetypes: ["xib"], repoPath: nil, commits: nil)

        let input = FilesInput(cli: cli, config: nil)

        #expect(input.filetypes == ["xib"])
    }

    // MARK: - RepoPath Priority Tests

    @Test
    func `CLI repoPath overrides config repoPath`() {
        let cli = FilesCLIInputs(filetypes: nil, repoPath: "/cli/path", commits: nil)
        let gitConfig = GitFileConfig(repoPath: "/config/path")
        let config = FilesConfig(filetypes: nil, git: gitConfig)

        let input = FilesInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/cli/path")
    }

    @Test
    func `falls back to config repoPath when CLI repoPath is nil`() {
        let cli = FilesCLIInputs(filetypes: nil, repoPath: nil, commits: nil)
        let gitConfig = GitFileConfig(repoPath: "/config/path")
        let config = FilesConfig(filetypes: nil, git: gitConfig)

        let input = FilesInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/config/path")
    }

    @Test
    func `falls back to current directory when both CLI and config repoPath are nil`() {
        let cli = FilesCLIInputs(filetypes: nil, repoPath: nil, commits: nil)
        let config = FilesConfig(filetypes: nil, git: nil)

        let input = FilesInput(cli: cli, config: config)

        #expect(input.git.repoPath == FileManager.default.currentDirectoryPath)
    }

    // MARK: - Commits Priority Tests

    @Test
    func `CLI commits override default`() {
        let cli = FilesCLIInputs(filetypes: nil, repoPath: nil, commits: ["abc123", "def456"])

        let input = FilesInput(cli: cli, config: nil)

        #expect(input.commits == ["abc123", "def456"])
    }

    @Test
    func `falls back to HEAD when CLI commits is nil`() {
        let cli = FilesCLIInputs(filetypes: nil, repoPath: nil, commits: nil)

        let input = FilesInput(cli: cli, config: nil)

        #expect(input.commits == ["HEAD"])
    }

    // MARK: - Git Flags Tests

    @Test
    func `git flags from CLI are applied`() {
        let cli = FilesCLIInputs(
            filetypes: nil,
            repoPath: nil,
            commits: nil,
            gitClean: true,
            fixLfs: true,
            initializeSubmodules: true
        )

        let input = FilesInput(cli: cli, config: nil)

        #expect(input.git.clean == true)
        #expect(input.git.fixLFS == true)
        #expect(input.git.initializeSubmodules == true)
    }

    // MARK: - Combined Priority Tests

    @Test
    func `full priority chain CLI then Config then Default`() {
        let cli = FilesCLIInputs(filetypes: ["swift", "xib"], repoPath: nil, commits: nil)
        let gitConfig = GitFileConfig(repoPath: "/from/config")
        let config = FilesConfig(filetypes: ["Ignored"], git: gitConfig)

        let input = FilesInput(cli: cli, config: config)

        #expect(input.filetypes == ["swift", "xib"])  // from CLI
        #expect(input.git.repoPath == "/from/config")  // from config
        #expect(input.commits == ["HEAD"])  // default
    }
}
