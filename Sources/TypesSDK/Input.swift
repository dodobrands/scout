import Common

extension TypesSDK {
    /// A single type metric with its commits to analyze.
    public struct MetricInput: Sendable, CommitResolvable {
        /// Type name to count (e.g., "UIView")
        public let type: String

        /// Commits to analyze for this type
        public let commits: [String]

        public init(type: String, commits: [String] = ["HEAD"]) {
            self.type = type
            self.commits = commits
        }

        public func withResolvedCommits(_ commits: [String]) -> MetricInput {
            MetricInput(type: type, commits: commits)
        }
    }

    /// Input parameters for TypesSDK operations.
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
