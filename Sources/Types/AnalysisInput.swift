extension Types {
    /// Input parameters for analysis without git operations.
    /// Used by internal countTypes function. All base types of one commit are analyzed
    /// together, so the sources are parsed once rather than once per type.
    struct AnalysisInput: Sendable {
        let repoPath: String
        let typeNames: [String]
    }
}
