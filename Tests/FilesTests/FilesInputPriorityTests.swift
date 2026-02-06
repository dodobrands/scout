import Common
import FilesSDK
import Foundation
import Testing

@testable import Files

struct FilesInputPriorityTests {

    // MARK: - Metrics Priority Tests

    @Test
    func `CLI filetypes create metrics with CLI commits`() {
        let cli = FilesCLIInputs(filetypes: ["swift"], repoPath: nil, commits: ["abc123"])

        let input = FilesInput(cli: cli, config: nil)

        #expect(input.metrics.count == 1)
        #expect(input.metrics[0].extension == "swift")
        #expect(input.metrics[0].commits == ["abc123"])
    }

    @Test
    func `CLI filetypes use HEAD when commits not specified`() {
        let cli = FilesCLIInputs(filetypes: ["swift"], repoPath: nil, commits: nil)

        let input = FilesInput(cli: cli, config: nil)

        #expect(input.metrics.count == 1)
        #expect(input.metrics[0].extension == "swift")
        #expect(input.metrics[0].commits == ["HEAD"])
    }

    @Test
    func `falls back to config metrics when CLI filetypes is nil`() {
        let cli = FilesCLIInputs(filetypes: nil, repoPath: nil, commits: nil)
        let config = FilesConfig(
            metrics: [FileMetric(extension: "storyboard", commits: ["def456"])],
            git: nil
        )

        let input = FilesInput(cli: cli, config: config)

        #expect(input.metrics.count == 1)
        #expect(input.metrics[0].extension == "storyboard")
        #expect(input.metrics[0].commits == ["def456"])
    }

    @Test
    func `config metrics without commits use HEAD`() {
        let cli = FilesCLIInputs(filetypes: nil, repoPath: nil, commits: nil)
        let config = FilesConfig(
            metrics: [FileMetric(extension: "swift", commits: nil)],
            git: nil
        )

        let input = FilesInput(cli: cli, config: config)

        #expect(input.metrics.count == 1)
        #expect(input.metrics[0].commits == ["HEAD"])
    }

    @Test
    func `CLI commits override all config per-metric commits`() {
        let cli = FilesCLIInputs(filetypes: nil, repoPath: nil, commits: ["cli-commit"])
        let config = FilesConfig(
            metrics: [
                FileMetric(extension: "swift", commits: ["config-commit1"]),
                FileMetric(extension: "xib", commits: ["config-commit2"]),
            ],
            git: nil
        )

        let input = FilesInput(cli: cli, config: config)

        #expect(input.metrics.count == 2)
        #expect(input.metrics[0].commits == ["cli-commit"])
        #expect(input.metrics[1].commits == ["cli-commit"])
    }

    @Test
    func `config metrics with empty commits array are skipped`() {
        let cli = FilesCLIInputs(filetypes: nil, repoPath: nil, commits: nil)
        let config = FilesConfig(
            metrics: [
                FileMetric(extension: "swift", commits: ["abc123"]),
                FileMetric(extension: "skipped", commits: []),
                FileMetric(extension: "xib", commits: nil),
            ],
            git: nil
        )

        let input = FilesInput(cli: cli, config: config)

        #expect(input.metrics.count == 2)
        #expect(input.metrics[0].extension == "swift")
        #expect(input.metrics[1].extension == "xib")
    }

    @Test
    func `falls back to empty array when both CLI and config filetypes are nil`() {
        let cli = FilesCLIInputs(filetypes: nil, repoPath: nil, commits: nil)
        let config = FilesConfig(metrics: nil, git: nil)

        let input = FilesInput(cli: cli, config: config)

        #expect(input.metrics.isEmpty)
    }

    // MARK: - RepoPath Priority Tests

    @Test
    func `CLI repoPath overrides config repoPath`() {
        let cli = FilesCLIInputs(filetypes: nil, repoPath: "/cli/path", commits: nil)
        let gitConfig = GitFileConfig(repoPath: "/config/path")
        let config = FilesConfig(metrics: nil, git: gitConfig)

        let input = FilesInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/cli/path")
    }

    @Test
    func `falls back to config repoPath when CLI repoPath is nil`() {
        let cli = FilesCLIInputs(filetypes: nil, repoPath: nil, commits: nil)
        let gitConfig = GitFileConfig(repoPath: "/config/path")
        let config = FilesConfig(metrics: nil, git: gitConfig)

        let input = FilesInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/config/path")
    }

    @Test
    func `falls back to current directory when both CLI and config repoPath are nil`() {
        let cli = FilesCLIInputs(filetypes: nil, repoPath: nil, commits: nil)
        let config = FilesConfig(metrics: nil, git: nil)

        let input = FilesInput(cli: cli, config: config)

        #expect(input.git.repoPath == FileManager.default.currentDirectoryPath)
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
        let config = FilesConfig(
            metrics: [FileMetric(extension: "Ignored", commits: nil)],
            git: gitConfig
        )

        let input = FilesInput(cli: cli, config: config)

        #expect(input.metrics.count == 2)  // from CLI
        #expect(input.metrics[0].extension == "swift")
        #expect(input.metrics[1].extension == "xib")
        #expect(input.git.repoPath == "/from/config")  // from config
        #expect(input.metrics[0].commits == ["HEAD"])  // default
    }
}
