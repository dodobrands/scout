extension Pattern {
    /// Input parameters for analysis without git operations.
    /// Used by internal search function.
    struct AnalysisInput: Sendable {
        let repoPath: String
        let extensions: [String]
        let pattern: String
        let isRegex: Bool

        init(repoPath: String, extensions: [String], pattern: String, isRegex: Bool = false) {
            self.repoPath = repoPath
            self.extensions = extensions
            self.pattern = pattern
            self.isRegex = isRegex
        }
    }
}
