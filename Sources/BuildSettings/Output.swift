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

    /// The targets one Xcode project declares.
    ///
    /// Target names alone do not say which module a target belongs to: `CartTests`
    /// and `CartUI` sit next to `Cart` in `Modules/Cart`, while `MenuSearch` is its
    /// own module rather than a part of `Menu`. Only the project knows.
    public struct ProjectTargets: Sendable, Encodable {
        /// Path to the `.xcodeproj`, relative to the repository root.
        public let path: String
        /// Target names declared by this project, sorted.
        public let targets: [String]

        public init(path: String, targets: [String]) {
            self.path = path
            self.targets = targets
        }
    }

    /// Output of build settings analysis for a single commit.
    public struct Output: Sendable, Encodable {
        public let commit: String
        public let date: String
        /// Which project declares which target, stated once per commit.
        public let projects: [ProjectTargets]
        public let results: [ResultItem]

        public init(
            commit: String,
            date: String,
            projects: [ProjectTargets] = [],
            results: [ResultItem]
        ) {
            self.commit = commit
            self.date = date
            self.projects = projects
            self.results = results
        }
    }
}
