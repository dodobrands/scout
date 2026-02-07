import Common

/// Represents a setup command to execute before analysis.
public struct SetupCommand: Sendable {
    public let command: String
    public let workingDirectory: String?
    public let optional: Bool

    public init(command: String, workingDirectory: String? = nil, optional: Bool = false) {
        self.command = command
        self.workingDirectory = workingDirectory
        self.optional = optional
    }
}

extension BuildSettingsSDK {
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

    /// Input parameters for analysis without git operations.
    /// Used by internal extractBuildSettings function.
    public struct AnalysisInput: Sendable {
        public let repoPath: String
        public let setupCommands: [SetupCommand]
        public let project: String
        public let configuration: String

        public init(
            repoPath: String,
            setupCommands: [SetupCommand],
            project: String,
            configuration: String
        ) {
            self.repoPath = repoPath
            self.setupCommands = setupCommands
            self.project = project
            self.configuration = configuration
        }
    }

    /// Input parameters for BuildSettingsSDK operations.
    public struct Input: Sendable {
        public let git: GitConfiguration
        public let setupCommands: [SetupCommand]
        public let metrics: [MetricInput]
        public let project: String
        public let configuration: String

        public init(
            git: GitConfiguration,
            setupCommands: [SetupCommand],
            metrics: [MetricInput] = [],
            project: String,
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
