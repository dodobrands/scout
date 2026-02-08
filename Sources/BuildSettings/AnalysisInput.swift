extension BuildSettings {
    /// Input parameters for analysis without git operations.
    /// Used by internal extractBuildSettings function.
    struct AnalysisInput: Sendable {
        let repoPath: String
        let setupCommands: [SetupCommand]
        let project: String
        let configuration: String
    }
}
