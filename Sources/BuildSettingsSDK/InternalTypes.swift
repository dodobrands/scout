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
