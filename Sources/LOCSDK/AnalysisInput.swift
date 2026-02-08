extension LOCSDK {
    /// Input parameters for analysis without git operations.
    /// Used by internal countLOC function.
    struct AnalysisInput: Sendable {
        let repoPath: String
        let languages: [String]
        let include: [String]
        let exclude: [String]
        let metricIdentifier: String
    }
}
