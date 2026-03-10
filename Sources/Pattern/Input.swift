import Common

extension Pattern {
    /// A single pattern metric with its commits to analyze.
    public struct MetricInput: Sendable, CommitResolvable {
        /// Pattern to search for (e.g., "// TODO:")
        public let pattern: String

        /// Whether to use regex matching instead of literal string matching
        public let isRegex: Bool

        /// Commits to analyze for this pattern
        public let commits: [String]

        public init(pattern: String, isRegex: Bool = false, commits: [String] = ["HEAD"]) {
            self.pattern = pattern
            self.isRegex = isRegex
            self.commits = commits
        }

        public func withResolvedCommits(_ commits: [String]) -> MetricInput {
            MetricInput(pattern: pattern, isRegex: isRegex, commits: commits)
        }
    }

    /// Input parameters for Pattern operations.
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
