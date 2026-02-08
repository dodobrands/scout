import Common

extension Files {
    /// A single file extension metric with its commits to analyze.
    public struct MetricInput: Sendable, CommitResolvable {
        /// File extension to count (e.g., "swift", "storyboard")
        public let `extension`: String

        /// Commits to analyze for this extension
        public let commits: [String]

        public init(extension: String, commits: [String] = ["HEAD"]) {
            self.extension = `extension`
            self.commits = commits
        }

        public func withResolvedCommits(_ commits: [String]) -> MetricInput {
            MetricInput(extension: `extension`, commits: commits)
        }
    }

    /// Input parameters for Files operations.
    public struct Input: Sendable {
        public let git: GitConfiguration
        public let metrics: [MetricInput]

        public init(
            git: GitConfiguration,
            metrics: [MetricInput]
        ) {
            self.git = git
            self.metrics = metrics
        }
    }
}
