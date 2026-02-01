import Common
import Foundation
import PatternSDK
import Testing

@testable import Pattern

struct PatternInputPriorityTests {

    // MARK: - Patterns Priority Tests

    @Test
    func `CLI patterns override config patterns`() {
        let cli = PatternCLIInputs(
            patterns: ["TODO:"],
            repoPath: nil,
            commits: nil,
            extensions: nil
        )
        let config = PatternConfig(patterns: ["FIXME:"], extensions: nil, git: nil)

        let input = PatternInput(cli: cli, config: config)

        #expect(input.patterns == ["TODO:"])
    }

    @Test
    func `falls back to config patterns when CLI patterns is nil`() {
        let cli = PatternCLIInputs(patterns: nil, repoPath: nil, commits: nil, extensions: nil)
        let config = PatternConfig(patterns: ["FIXME:"], extensions: nil, git: nil)

        let input = PatternInput(cli: cli, config: config)

        #expect(input.patterns == ["FIXME:"])
    }

    @Test
    func `falls back to empty array when both CLI and config patterns are nil`() {
        let cli = PatternCLIInputs(patterns: nil, repoPath: nil, commits: nil, extensions: nil)
        let config = PatternConfig(patterns: nil, extensions: nil, git: nil)

        let input = PatternInput(cli: cli, config: config)

        #expect(input.patterns == [])
    }

    // MARK: - Extensions Priority Tests

    @Test
    func `CLI extensions override config extensions`() {
        let cli = PatternCLIInputs(
            patterns: nil,
            repoPath: nil,
            commits: nil,
            extensions: ["m", "h"]
        )
        let config = PatternConfig(patterns: nil, extensions: ["swift"], git: nil)

        let input = PatternInput(cli: cli, config: config)

        #expect(input.extensions == ["m", "h"])
    }

    @Test
    func `falls back to config extensions when CLI extensions is nil`() {
        let cli = PatternCLIInputs(patterns: nil, repoPath: nil, commits: nil, extensions: nil)
        let config = PatternConfig(patterns: nil, extensions: ["m", "h"], git: nil)

        let input = PatternInput(cli: cli, config: config)

        #expect(input.extensions == ["m", "h"])
    }

    @Test
    func `falls back to swift when both CLI and config extensions are nil`() {
        let cli = PatternCLIInputs(patterns: nil, repoPath: nil, commits: nil, extensions: nil)
        let config = PatternConfig(patterns: nil, extensions: nil, git: nil)

        let input = PatternInput(cli: cli, config: config)

        #expect(input.extensions == ["swift"])
    }

    // MARK: - RepoPath Priority Tests

    @Test
    func `CLI repoPath overrides config repoPath`() {
        let cli = PatternCLIInputs(
            patterns: nil,
            repoPath: "/cli/path",
            commits: nil,
            extensions: nil
        )
        let gitConfig = GitFileConfig(repoPath: "/config/path")
        let config = PatternConfig(patterns: nil, extensions: nil, git: gitConfig)

        let input = PatternInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/cli/path")
    }

    @Test
    func `falls back to config repoPath when CLI repoPath is nil`() {
        let cli = PatternCLIInputs(patterns: nil, repoPath: nil, commits: nil, extensions: nil)
        let gitConfig = GitFileConfig(repoPath: "/config/path")
        let config = PatternConfig(patterns: nil, extensions: nil, git: gitConfig)

        let input = PatternInput(cli: cli, config: config)

        #expect(input.git.repoPath == "/config/path")
    }

    // MARK: - Commits Priority Tests

    @Test
    func `CLI commits override default`() {
        let cli = PatternCLIInputs(
            patterns: nil,
            repoPath: nil,
            commits: ["abc123"],
            extensions: nil
        )

        let input = PatternInput(cli: cli, config: nil)

        #expect(input.commits == ["abc123"])
    }

    @Test
    func `falls back to HEAD when CLI commits is nil`() {
        let cli = PatternCLIInputs(patterns: nil, repoPath: nil, commits: nil, extensions: nil)

        let input = PatternInput(cli: cli, config: nil)

        #expect(input.commits == ["HEAD"])
    }

    // MARK: - Git Flags Tests

    @Test
    func `git flags from CLI are applied`() {
        let cli = PatternCLIInputs(
            patterns: nil,
            repoPath: nil,
            commits: nil,
            extensions: nil,
            gitClean: true,
            fixLfs: true,
            initializeSubmodules: true
        )

        let input = PatternInput(cli: cli, config: nil)

        #expect(input.git.clean == true)
        #expect(input.git.fixLFS == true)
        #expect(input.git.initializeSubmodules == true)
    }

    // MARK: - Combined Priority Tests

    @Test
    func `full priority chain CLI then Config then Default`() {
        let cli = PatternCLIInputs(
            patterns: ["TODO:"],
            repoPath: nil,
            commits: nil,
            extensions: nil
        )
        let gitConfig = GitFileConfig(repoPath: "/from/config")
        let config = PatternConfig(patterns: ["Ignored"], extensions: ["m"], git: gitConfig)

        let input = PatternInput(cli: cli, config: config)

        #expect(input.patterns == ["TODO:"])  // from CLI
        #expect(input.git.repoPath == "/from/config")  // from config
        #expect(input.extensions == ["m"])  // from config
        #expect(input.commits == ["HEAD"])  // default
    }
}
