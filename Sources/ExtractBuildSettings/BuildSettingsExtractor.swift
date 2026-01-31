import Common
import Foundation
import Logging
import System

struct TargetWithBuildSettings {
  let target: String
  let buildSettings: [String: String]
}

final class BuildSettingsExtractor {
  private static let logger = Logger(label: "mobile-code-metrics.BuildSettingsExtractor")

  static func getBuildSettingsForAllTargets(
    projectsWithTargets: [ProjectWithTargets],
    foundProjectsAndWorkspaces: [ProjectOrWorkspace],
    configuration: String
  ) async throws -> [TargetWithBuildSettings] {
    // Create map for quick lookup
    var projectInfoMap: [String: ProjectOrWorkspace] = [:]
    for project in foundProjectsAndWorkspaces {
      projectInfoMap[project.path] = project
    }

    // Collect all targets from all projects
    var allTargets: [(target: String, projectPath: String, isWorkspace: Bool)] = []
    for projectWithTargets in projectsWithTargets {
      guard let projectInfo = projectInfoMap[projectWithTargets.path] else {
        logger.warning("Project info not found for path: \(projectWithTargets.path)")
        continue
      }

      for target in projectWithTargets.targets {
        allTargets.append(
          (
            target: target,
            projectPath: projectWithTargets.path,
            isWorkspace: projectInfo.isWorkspace
          )
        )
      }
    }

    // Process all targets concurrently using concurrentMap
    return try await allTargets.concurrentMap { targetInfo in
      let buildSettings = try await getBuildSettingsForTarget(
        target: targetInfo.target,
        projectPath: targetInfo.projectPath,
        isWorkspace: targetInfo.isWorkspace,
        configuration: configuration
      )
      return TargetWithBuildSettings(
        target: targetInfo.target,
        buildSettings: buildSettings
      )
    }
  }

  private static func getBuildSettingsForTarget(
    target: String,
    projectPath: String,
    isWorkspace: Bool,
    configuration: String
  ) async throws -> [String: String] {
    let projectDir = (projectPath as NSString).deletingLastPathComponent
    let projectName = (projectPath as NSString).lastPathComponent
    let projectDirPath = FilePath(projectDir)

    // Build xcodebuild arguments
    var arguments: [String] = [
      "-showBuildSettings",
      "-target", target,
      "-json",
      "-configuration", configuration,
    ]

    if isWorkspace {
      // For workspace, use -workspace flag
      arguments.append(contentsOf: ["-workspace", projectName])
    } else {
      // For project, use -project flag
      arguments.append(contentsOf: ["-project", projectName])
    }

    logger.debug(
      "Executing xcodebuild",
      metadata: [
        "target": "\(target)",
        "configuration": "\(configuration)",
        "project": "\(projectName)",
        "isWorkspace": "\(isWorkspace)",
      ]
    )

    // Execute command and parse JSON output
    let jsonOutput = try await Shell.execute(
      "xcodebuild",
      arguments: arguments,
      workingDirectory: projectDirPath
    )

    // Parse JSON output
    guard let jsonData = jsonOutput.data(using: .utf8),
      let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]
    else {
      logger.debug("Failed to parse JSON output for target \(target) in \(projectPath)")
      return [:]
    }

    // Extract build settings from JSON
    // JSON format: [{"target": "TargetName", "buildSettings": {"KEY": "value", ...}}, ...]
    var buildSettings: [String: String] = [:]

    for targetInfo in jsonArray {
      if let targetName = targetInfo["target"] as? String,
        targetName == target,
        let settings = targetInfo["buildSettings"] as? [String: Any]
      {
        // Convert [String: Any] to [String: String]
        for (key, value) in settings {
          if let stringValue = value as? String {
            buildSettings[key] = stringValue
          } else {
            // Convert any other type to string
            buildSettings[key] = String(describing: value)
          }
        }
        break
      }
    }

    logger.debug("Found \(buildSettings.count) build settings for target \(target)")

    return buildSettings
  }
}
