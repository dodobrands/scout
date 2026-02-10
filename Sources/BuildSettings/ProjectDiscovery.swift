import Foundation
import Glob
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
    ) async throws -> [DiscoveredProject] {
        let includePatterns = try include.map { try Glob.Pattern($0) }
        let excludePatterns = try exclude.map { try Glob.Pattern($0) }
        let repoPathString = repoPath.path(percentEncoded: false)

        let results = try await Glob.search(
            directory: repoPath,
            include: includePatterns,
            exclude: excludePatterns
        )

        var projects: [DiscoveredProject] = []
        for try await url in results {
            guard url.pathExtension == "xcodeproj" else {
                continue
            }

            let fullPath = url.path(percentEncoded: false)
            let normalizedPath =
                fullPath.hasSuffix("/") ? String(fullPath.dropLast()) : fullPath
            projects.append(DiscoveredProject(path: normalizedPath))

            let relativePath = relativePath(fullPath: fullPath, repoPath: repoPathString)
            logger.debug(
                "Discovered project",
                metadata: ["path": "\(relativePath)"]
            )
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
