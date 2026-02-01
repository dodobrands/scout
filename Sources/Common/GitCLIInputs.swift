import Foundation

/// Raw git CLI inputs from ArgumentParser. All fields are optional.
/// Used as first layer in three-layer input architecture.
package struct GitCLIInputs: Sendable {
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
