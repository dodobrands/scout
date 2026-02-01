import Foundation

/// Git operations configuration shared across all tools.
/// This is the resolved configuration with all values set (no optionals).
public struct GitConfiguration: Sendable {
    /// Path to repository with sources
    public let repoPath: String

    /// Run `git clean -ffdx && git reset --hard HEAD` before analysis
    public let clean: Bool

    /// Fix broken LFS pointers by committing modified files after checkout
    public let fixLFS: Bool

    /// Initialize and update git submodules
    public let initializeSubmodules: Bool

    /// Direct initializer - all fields required
    public init(
        repoPath: String,
        clean: Bool,
        fixLFS: Bool,
        initializeSubmodules: Bool
    ) {
        self.repoPath = repoPath
        self.clean = clean
        self.fixLFS = fixLFS
        self.initializeSubmodules = initializeSubmodules
    }

    /// Merge initializer: CLI > FileConfig > Default
    /// This is the single place where defaults are applied.
    package init(cli: GitCLIInputs, fileConfig: GitFileConfig?) {
        self.repoPath =
            cli.repoPath
            ?? fileConfig?.repoPath
            ?? FileManager.default.currentDirectoryPath
        self.clean = cli.clean ?? fileConfig?.clean ?? false
        self.fixLFS = cli.fixLFS ?? fileConfig?.fixLFS ?? false
        self.initializeSubmodules =
            cli.initializeSubmodules
            ?? fileConfig?.initializeSubmodules
            ?? false
    }
}
