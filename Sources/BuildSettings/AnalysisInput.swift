extension BuildSettings {
    /// Input parameters for analysis without git operations.
    /// Used by internal extractBuildSettings function.
    struct AnalysisInput: Sendable {
        let repoPath: String
        let setupCommands: [SetupCommand]
        let project: String
        let configuration: String
        let continueOnMissingProject: Bool

        init(
            repoPath: String,
            setupCommands: [SetupCommand],
            project: String,
            configuration: String,
            continueOnMissingProject: Bool = false
        ) {
            self.repoPath = repoPath
            self.setupCommands = setupCommands
            self.project = project
            self.configuration = configuration
            self.continueOnMissingProject = continueOnMissingProject
        }
    }
}
