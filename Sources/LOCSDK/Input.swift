import Common

extension LOCSDK {
    /// A single LOC metric with its commits to analyze.
    public struct MetricInput: Sendable, CommitResolvable {
        /// Languages to count
        public let languages: [String]

        /// Paths to include
        public let include: [String]

        /// Paths to exclude
        public let exclude: [String]

        /// Commits to analyze for this metric
        public let commits: [String]

        public init(
            languages: [String],
            include: [String],
            exclude: [String],
            commits: [String] = ["HEAD"]
        ) {
            self.languages = languages
            self.include = include
            self.exclude = exclude
            self.commits = commits
        }

        public func withResolvedCommits(_ commits: [String]) -> MetricInput {
            MetricInput(languages: languages, include: include, exclude: exclude, commits: commits)
        }

        /// Returns a unique metric identifier for output
        public var metricIdentifier: String {
            "LOC \(languages) \(include)"
        }
    }

    /// Input parameters for LOCSDK operations.
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
