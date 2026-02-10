import Common

extension BuildSettings {
    /// Configuration for discovering Xcode projects (.xcodeproj) via glob patterns.
    public struct ProjectsConfig: Sendable {
        /// Glob patterns to include (e.g., `["**/*.xcodeproj"]`)
        public let include: [String]

        /// Glob patterns to exclude (e.g., `["Pods/**"]`)
        public let exclude: [String]

        /// Continue analysis when no projects are found at a commit
        public let continueOnMissing: Bool

        public init(
            include: [String],
            exclude: [String] = [],
            continueOnMissing: Bool = false
        ) {
            self.include = include
            self.exclude = exclude
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
        public let projects: ProjectsConfig
        public let configuration: String

        public init(
            git: GitConfiguration,
            setupCommands: [SetupCommand],
            metrics: [MetricInput] = [],
            projects: ProjectsConfig,
            configuration: String
        ) {
            self.git = git
            self.setupCommands = setupCommands
            self.metrics = metrics
            self.projects = projects
            self.configuration = configuration
        }
    }
}
