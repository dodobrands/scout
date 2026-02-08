import Foundation

extension Files {
    /// A single files result item.
    public struct ResultItem: Sendable, Encodable {
        public let filetype: String
        public let files: [String]

        public init(filetype: String, files: [String]) {
            self.filetype = filetype
            self.files = files
        }
    }

    /// Output of files analysis for a single commit.
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

    /// Result of file counting operation.
    public struct Result: Sendable, Encodable {
        public let commit: String
        public let filetype: String
        public let files: [String]

        public init(commit: String = "", filetype: String, files: [URL]) {
            self.commit = commit
            self.filetype = filetype
            self.files = files.map { $0.path }
        }

        public init(commit: String, filetype: String, files: [String]) {
            self.commit = commit
            self.filetype = filetype
            self.files = files
        }
    }
}
