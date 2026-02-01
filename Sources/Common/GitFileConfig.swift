import Foundation

/// Git configuration loaded from JSON file. All fields are optional.
/// Used as second layer in three-layer input architecture.
package struct GitFileConfig: Sendable, Codable {
    /// Path to repository with sources
    public let repoPath: String?

    /// Run `git clean -ffdx && git reset --hard HEAD` before analysis
    public let clean: Bool?

    /// Fix broken LFS pointers by committing modified files after checkout
    public let fixLFS: Bool?

    /// Initialize and update git submodules
    public let initializeSubmodules: Bool?

    public init(
        repoPath: String? = nil,
        clean: Bool? = nil,
        fixLFS: Bool? = nil,
        initializeSubmodules: Bool? = nil
    ) {
        self.repoPath = repoPath
        self.clean = clean
        self.fixLFS = fixLFS
        self.initializeSubmodules = initializeSubmodules
    }
}
