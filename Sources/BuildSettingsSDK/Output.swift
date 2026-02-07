/// Represents an Xcode project or workspace.
public struct ProjectOrWorkspace: Sendable {
    public let path: String
    public let isWorkspace: Bool

    public init(path: String, isWorkspace: Bool) {
        self.path = path
        self.isWorkspace = isWorkspace
    }
}

/// Represents a project with its targets.
public struct ProjectWithTargets: Sendable {
    public let path: String
    public let targets: [String]

    public init(path: String, targets: [String]) {
        self.path = path
        self.targets = targets
    }
}

/// Represents a target with its build settings.
public struct TargetWithBuildSettings: Sendable, Encodable {
    public let target: String
    public let buildSettings: [String: String]

    public init(target: String, buildSettings: [String: String]) {
        self.target = target
        self.buildSettings = buildSettings
    }
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
