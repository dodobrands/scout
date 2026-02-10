extension BuildSettings {
    /// A single build settings result item for a requested setting.
    public struct ResultItem: Sendable, Encodable {
        public let setting: String
        public let targets: [String: String?]

        public init(setting: String, targets: [String: String?]) {
            self.setting = setting
            self.targets = targets
        }
    }

    /// Output of build settings analysis for a single commit.
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
