extension Pattern {
    /// Input parameters for analysis without git operations.
    /// Used by internal search function.
    struct AnalysisInput: Sendable {
        let repoPath: String
        let extensions: [String]
        let pattern: String
    }
}
