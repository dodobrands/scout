extension TypesSDK {
    /// Input parameters for analysis without git operations.
    /// Used by internal countTypes function.
    struct AnalysisInput: Sendable {
        let repoPath: String
        let typeName: String
    }
}
