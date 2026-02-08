extension LOC {
    /// A single LOC result item.
    public struct ResultItem: Sendable, Encodable {
        public let metric: String
        public let linesOfCode: Int

        public init(metric: String, linesOfCode: Int) {
            self.metric = metric
            self.linesOfCode = linesOfCode
        }
    }

    /// Output of LOC analysis for a single commit.
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
}
