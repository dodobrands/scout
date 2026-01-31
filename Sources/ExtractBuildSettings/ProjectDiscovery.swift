import Common
import Foundation
import Logging
import System

struct ProjectOrWorkspace {
    let path: String
    let isWorkspace: Bool
}

struct ProjectWithTargets {
    let path: String
    let targets: [String]
}

final class ProjectDiscovery {
    private static let logger = Logger(label: "mobile-code-metrics.ProjectDiscovery")

    static func findAllProjectsAndWorkspaces(in repoPath: URL) throws -> [ProjectOrWorkspace] {
        let fileManager = FileManager.default
        var projects: [ProjectOrWorkspace] = []

        guard
            let enumerator = fileManager.enumerator(
                at: repoPath,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles],
                errorHandler: nil
            )
        else {
            return []
        }

        while let element = enumerator.nextObject() as? URL {
            // Skip project.xcworkspace files inside .xcodeproj bundles
            let pathString = element.path(percentEncoded: false)
            if pathString.contains("/project.xcworkspace") {
                continue
            }

            if element.pathExtension == "xcworkspace" {
                projects.append(ProjectOrWorkspace(path: pathString, isWorkspace: true))
            } else if element.pathExtension == "xcodeproj" {
                projects.append(ProjectOrWorkspace(path: pathString, isWorkspace: false))
            }
        }

        return projects
    }

    static func getTargetsForAllProjects(
        foundProjectsAndWorkspaces: [ProjectOrWorkspace]
    ) async throws -> [ProjectWithTargets] {
        // Process all projects concurrently using concurrentMap
        return try await foundProjectsAndWorkspaces.concurrentMap { project in
            let targets = try await getTargetsFromProject(
                projectPath: project.path,
                isWorkspace: project.isWorkspace
            )
            return ProjectWithTargets(path: project.path, targets: targets)
        }
    }

    private static func getTargetsFromProject(
        projectPath: String,
        isWorkspace: Bool
    ) async throws -> [String] {
        // Execute xcodebuild -list -json for the project/workspace
        let projectDir = (projectPath as NSString).deletingLastPathComponent
        let projectName = (projectPath as NSString).lastPathComponent
        let projectDirPath = FilePath(projectDir)

        // Build xcodebuild arguments
        var arguments: [String] = ["-list", "-json"]
        if isWorkspace {
            arguments.append(contentsOf: ["-workspace", projectName])
        } else {
            arguments.append(contentsOf: ["-project", projectName])
        }

        logger.debug(
            "Executing xcodebuild -list",
            metadata: [
                "project": "\(projectName)",
                "isWorkspace": "\(isWorkspace)",
            ]
        )

        // Get list of targets using xcodebuild -list -json
        let jsonOutput = try await Shell.execute(
            "xcodebuild",
            arguments: arguments,
            workingDirectory: projectDirPath
        )

        // Parse JSON output
        guard let jsonData = jsonOutput.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else {
            logger.debug("Failed to parse JSON output for \(projectPath)")
            return []
        }

        // Extract targets from JSON
        var targets: [String] = []

        if let workspace = json["workspace"] as? [String: Any] {
            // Workspace format - check for projects with targets
            if let projects = workspace["projects"] as? [[String: Any]] {
                for project in projects {
                    if let projectTargets = project["targets"] as? [String] {
                        targets.append(contentsOf: projectTargets)
                    }
                }
            }
        } else if let project = json["project"] as? [String: Any] {
            // Project format - use targets only
            if let projectTargets = project["targets"] as? [String] {
                targets.append(contentsOf: projectTargets)
            }
        }

        logger.debug(
            "Found \(targets.count) targets in \(projectPath): \(targets.joined(separator: ", "))"
        )

        return targets.sorted()
    }
}
