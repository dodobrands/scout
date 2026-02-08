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

        /// Template for metric identifier with placeholders (%langs%, %include%, %exclude%)
        public let nameTemplate: String

        /// Default template for metric identifiers
        public static let defaultNameTemplate = "%langs% | %include%"

        public init(
            languages: [String],
            include: [String],
            exclude: [String],
            commits: [String] = ["HEAD"],
            nameTemplate: String? = nil
        ) {
            self.languages = languages
            self.include = include
            self.exclude = exclude
            self.commits = commits
            self.nameTemplate = nameTemplate ?? Self.defaultNameTemplate
        }

        public func withResolvedCommits(_ commits: [String]) -> MetricInput {
            MetricInput(
                languages: languages,
                include: include,
                exclude: exclude,
                commits: commits,
                nameTemplate: nameTemplate
            )
        }

        /// Returns a unique metric identifier for output
        public var metricIdentifier: String {
            var result = nameTemplate

            // Replace %langs% placeholder
            let langsValue = languages.isEmpty ? "Unknown" : languages.joined(separator: ", ")
            result = result.replacingOccurrences(of: "%langs%", with: langsValue)

            // Replace %include% placeholder
            let includeValue = include.isEmpty ? "." : include.joined(separator: ", ")
            result = result.replacingOccurrences(of: "%include%", with: includeValue)

            // Replace %exclude% placeholder
            let excludeValue = exclude.joined(separator: ", ")
            result = result.replacingOccurrences(of: "%exclude%", with: excludeValue)

            return result
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
