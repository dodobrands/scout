/// Represents an Xcode project or workspace.
struct ProjectOrWorkspace: Sendable {
    let path: String
    let isWorkspace: Bool

    /// Determines whether the given path points to an Xcode workspace.
    /// Handles trailing slashes that `URL.appendingPathComponent` adds for directories,
    /// since `.xcworkspace` is a directory bundle.
    static func isWorkspace(path: String) -> Bool {
        if path.hasSuffix("/") {
            return String(path.dropLast()).hasSuffix(".xcworkspace")
        }
        return path.hasSuffix(".xcworkspace")
    }
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
