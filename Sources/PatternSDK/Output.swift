extension PatternSDK {
    /// A single match of a pattern in a file.
    public struct Match: Sendable, Encodable {
        public let file: String
        public let line: Int

        public init(file: String, line: Int) {
            self.file = file
            self.line = line
        }
    }

    /// A single pattern result item.
    public struct ResultItem: Sendable, Encodable {
        public let pattern: String
        public let matches: [Match]

        public init(pattern: String, matches: [Match]) {
            self.pattern = pattern
            self.matches = matches
        }
    }

    /// Output of pattern analysis for a single commit.
    public struct Output: Sendable, Encodable {
        public let commit: String
        public let date: String
        public let results: [ResultItem]

        public init(commit: String, date: String, results: [ResultItem]) {
            self.commit = commit
            self.date = date
            self.results = results
        }
    }

    /// Result of pattern search operation.
    public struct Result: Sendable, Encodable {
        public let pattern: String
        public let matches: [Match]

        public init(pattern: String, matches: [Match]) {
            self.pattern = pattern
            self.matches = matches
        }
    }
}
