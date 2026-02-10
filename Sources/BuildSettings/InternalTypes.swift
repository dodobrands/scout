/// Represents a discovered Xcode project (.xcodeproj).
struct DiscoveredProject: Sendable {
    let path: String
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
