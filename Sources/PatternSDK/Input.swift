import Common

extension PatternSDK {
    /// A single pattern metric with its commits to analyze.
    public struct MetricInput: Sendable, CommitResolvable {
        /// Pattern to search for (e.g., "// TODO:")
        public let pattern: String

        /// Commits to analyze for this pattern
        public let commits: [String]

        public init(pattern: String, commits: [String] = ["HEAD"]) {
            self.pattern = pattern
            self.commits = commits
        }

        public func withResolvedCommits(_ commits: [String]) -> MetricInput {
            MetricInput(pattern: pattern, commits: commits)
        }
    }

    /// Input parameters for analysis without git operations.
    /// Used by internal search function.
    struct AnalysisInput: Sendable {
        let repoPath: String
        let extensions: [String]
        let pattern: String
    }

    /// Input parameters for PatternSDK operations.
    public struct Input: Sendable {
        public let git: GitConfiguration
        public let metrics: [MetricInput]
        public let extensions: [String]

        public init(
            git: GitConfiguration,
            metrics: [MetricInput],
            extensions: [String] = ["swift"]
        ) {
            self.git = git
            self.metrics = metrics
            self.extensions = extensions
        }
    }
}
