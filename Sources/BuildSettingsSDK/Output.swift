/// Represents an Xcode project or workspace.
struct ProjectOrWorkspace: Sendable {
    let path: String
    let isWorkspace: Bool
}

/// Represents a project with its targets.
struct ProjectWithTargets: Sendable {
    let path: String
    let targets: [String]
}

/// Represents a target with its build settings.
struct TargetWithBuildSettings: Sendable, Encodable {
    let target: String
    let buildSettings: [String: String]
}

extension BuildSettingsSDK {
    /// A single build settings result item for a target.
    public struct ResultItem: Sendable, Encodable {
        public let target: String
        public let settings: [String: String?]

        public init(target: String, settings: [String: String?]) {
            self.target = target
            self.settings = settings
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
