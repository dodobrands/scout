extension FilesSDK {
    /// Input parameters for analysis without git operations.
    /// Used by internal countFiles function.
    struct AnalysisInput: Sendable {
        let repoPath: String
        let `extension`: String
    }
}
