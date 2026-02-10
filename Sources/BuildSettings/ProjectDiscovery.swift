import Common
import Foundation
import Logging

/// Discovers Xcode projects (.xcodeproj) in a directory using glob include/exclude patterns.
struct ProjectDiscovery: Sendable {
    private static let logger = Logger(label: "scout.ProjectDiscovery")

    /// Discovers `.xcodeproj` bundles matching include patterns and not matching exclude patterns.
    ///
    /// - Parameters:
    ///   - repoPath: Root directory to search in
    ///   - include: Glob patterns for paths to include (relative to `repoPath`)
    ///   - exclude: Glob patterns for paths to exclude (relative to `repoPath`)
    /// - Returns: Array of discovered projects sorted by path
    static func discoverProjects(
        in repoPath: URL,
        include: [String],
        exclude: [String]
    ) -> [DiscoveredProject] {
        let fileManager = FileManager.default
        let repoPathString = repoPath.path(percentEncoded: false)

        guard
            let enumerator = fileManager.enumerator(
                at: repoPath,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles],
                errorHandler: nil
            )
        else {
            return []
        }

        var projects: [DiscoveredProject] = []

        while let element = enumerator.nextObject() as? URL {
            guard element.pathExtension == "xcodeproj" else {
                continue
            }

            let fullPath = element.path(percentEncoded: false)

            // Skip project.xcworkspace inside .xcodeproj bundles
            if fullPath.contains("/project.xcworkspace") {
                continue
            }

            // Get relative path from repoPath
            let relativePath = relativePath(fullPath: fullPath, repoPath: repoPathString)

            // Check include patterns
            guard GlobMatcher.matchesAny(path: relativePath, patterns: include) else {
                continue
            }

            // Check exclude patterns
            if GlobMatcher.matchesAny(path: relativePath, patterns: exclude) {
                continue
            }

            // Strip trailing slash
            let normalizedPath =
                fullPath.hasSuffix("/") ? String(fullPath.dropLast()) : fullPath
            projects.append(DiscoveredProject(path: normalizedPath))

            logger.debug(
                "Discovered project",
                metadata: ["path": "\(relativePath)"]
            )

            // Don't descend into .xcodeproj bundles
            enumerator.skipDescendants()
        }

        return projects.sorted { $0.path < $1.path }
    }

    private static func relativePath(fullPath: String, repoPath: String) -> String {
        let base = repoPath.hasSuffix("/") ? repoPath : repoPath + "/"
        if fullPath.hasPrefix(base) {
            return String(fullPath.dropFirst(base.count))
        }
        return fullPath
    }
}
