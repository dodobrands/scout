import Common

extension BuildSettings {
    /// Project configuration for build settings analysis.
    public struct Project: Sendable {
        /// Path to Xcode workspace (.xcworkspace) or project (.xcodeproj)
        public let path: String

        /// Continue analysis when project is not found at a commit
        public let continueOnMissing: Bool

        public init(path: String, continueOnMissing: Bool = false) {
            self.path = path
            self.continueOnMissing = continueOnMissing
        }
    }

    /// A single build setting metric with its commits to analyze.
    public struct MetricInput: Sendable, CommitResolvable {
        /// Build setting name (e.g., "SWIFT_VERSION")
        public let setting: String

        /// Commits to analyze for this setting
        public let commits: [String]

        public init(setting: String, commits: [String] = ["HEAD"]) {
            self.setting = setting
            self.commits = commits
        }

        public func withResolvedCommits(_ commits: [String]) -> MetricInput {
            MetricInput(setting: setting, commits: commits)
        }
    }

    /// Input parameters for BuildSettings operations.
    public struct Input: Sendable {
        public let git: GitConfiguration
        public let setupCommands: [SetupCommand]
        public let metrics: [MetricInput]
        public let project: Project
        public let configuration: String

        public init(
            git: GitConfiguration,
            setupCommands: [SetupCommand],
            metrics: [MetricInput] = [],
            project: Project,
            configuration: String
        ) {
            self.git = git
            self.setupCommands = setupCommands
            self.metrics = metrics
            self.project = project
            self.configuration = configuration
        }
    }
}
