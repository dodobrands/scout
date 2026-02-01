import Foundation

/// Git operations configuration shared across all tools.
public struct GitConfiguration: Sendable, Codable {
    /// Path to repository with sources (default: current directory)
    public let repoPath: String

    /// Run `git clean -ffdx && git reset --hard HEAD` before analysis
    public let clean: Bool

    /// Fix broken LFS pointers by committing modified files after checkout
    public let fixLFS: Bool

    /// Initialize and update git submodules
    public let initializeSubmodules: Bool

    public init(
        repoPath: String = FileManager.default.currentDirectoryPath,
        clean: Bool = false,
        fixLFS: Bool = false,
        initializeSubmodules: Bool = false
    ) {
        self.repoPath = repoPath
        self.clean = clean
        self.fixLFS = fixLFS
        self.initializeSubmodules = initializeSubmodules
    }

    /// Default configuration with all options disabled
    public static let `default` = GitConfiguration()

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.repoPath =
            try container.decodeIfPresent(String.self, forKey: .repoPath)
            ?? FileManager.default.currentDirectoryPath
        self.clean = try container.decodeIfPresent(Bool.self, forKey: .clean) ?? false
        self.fixLFS = try container.decodeIfPresent(Bool.self, forKey: .fixLFS) ?? false
        self.initializeSubmodules =
            try container.decodeIfPresent(
                Bool.self,
                forKey: .initializeSubmodules
            ) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case repoPath, clean, fixLFS, initializeSubmodules
    }
}
