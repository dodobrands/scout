import Common
import Foundation
import Logging
import System

// MARK: - Public Types

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
public struct TargetWithBuildSettings: Sendable, Codable {
    public let target: String
    public let buildSettings: [String: String]

    public init(target: String, buildSettings: [String: String]) {
        self.target = target
        self.buildSettings = buildSettings
    }
}

// MARK: - BuildSettingsSDK

/// Represents a setup command to execute before analysis.
public struct SetupCommand: Sendable {
    public let command: String
    public let workingDirectory: String?
    public let optional: Bool

    public init(command: String, workingDirectory: String? = nil, optional: Bool = false) {
        self.command = command
        self.workingDirectory = workingDirectory
        self.optional = optional
    }
}

/// Input parameters for BuildSettingsSDK operations.
public struct BuildSettingsInput: Sendable {
    public let git: GitConfiguration
    public let setupCommands: [SetupCommand]
    public let configuration: String

    public init(
        git: GitConfiguration,
        setupCommands: [SetupCommand],
        configuration: String
    ) {
        self.git = git
        self.setupCommands = setupCommands
        self.configuration = configuration
    }
}

/// SDK for extracting build settings from Xcode projects.
public struct BuildSettingsSDK: Sendable {
    private static let logger = Logger(label: "scout.BuildSettingsSDK")

    public init() {}

    /// Error that can occur during analysis.
    public enum AnalysisError: Error, LocalizedError {
        case setupCommandFailed(command: String, error: String)
        case buildSettingsExtractionFailed(error: String)
        case checkoutFailed(hash: String, error: String)

        public var errorDescription: String? {
            switch self {
            case .setupCommandFailed(let command, let error):
                return "Setup command '\(command)' failed: \(error)"
            case .buildSettingsExtractionFailed(let error):
                return "Build settings extraction failed: \(error)"
            case .checkoutFailed(let hash, let error):
                return "Failed to checkout \(hash): \(error)"
            }
        }
    }

    /// Result of build settings extraction - array of targets with their build settings.
    public typealias Result = [TargetWithBuildSettings]

    /// Extracts build settings from Xcode projects in the repository.
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Array of targets with their build settings
    public func extractBuildSettings(input: BuildSettingsInput) async throws -> Result {
        let repoPath = URL(filePath: input.git.repoPath)

        try await GitFix.prepareRepository(git: input.git)

        try await executeSetupCommands(input.setupCommands, in: repoPath)

        let foundProjectsAndWorkspaces = try findAllProjectsAndWorkspaces(in: repoPath)
        let projectsWithTargets = try await getTargetsForAllProjects(
            foundProjectsAndWorkspaces: foundProjectsAndWorkspaces
        )
        let targetsWithBuildSettings = try await getBuildSettingsForAllTargets(
            projectsWithTargets: projectsWithTargets,
            foundProjectsAndWorkspaces: foundProjectsAndWorkspaces,
            configuration: input.configuration
        )

        return targetsWithBuildSettings
    }

    /// Checks out a commit and extracts build settings.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - input: Input parameters for the operation
    /// - Returns: Array of targets with their build settings
    public func analyzeCommit(
        hash: String,
        input: BuildSettingsInput
    ) async throws -> Result {
        let repoPath = URL(filePath: input.git.repoPath)

        do {
            try await Shell.execute(
                "git",
                arguments: ["checkout", hash],
                workingDirectory: FilePath(repoPath.path(percentEncoded: false))
            )
        } catch {
            throw AnalysisError.checkoutFailed(hash: hash, error: error.localizedDescription)
        }

        do {
            return try await extractBuildSettings(input: input)
        } catch let error as AnalysisError {
            throw error
        } catch {
            throw AnalysisError.buildSettingsExtractionFailed(error: error.localizedDescription)
        }
    }

    // MARK: - Setup Commands

    private func executeSetupCommands(
        _ commands: [SetupCommand],
        in repoPath: URL
    ) async throws {
        for setupCommand in commands {
            let workingDirPath: FilePath
            if let dir = setupCommand.workingDirectory {
                let workingDirURL = repoPath.appendingPathComponent(dir, isDirectory: true)
                workingDirPath = FilePath(workingDirURL.path(percentEncoded: false))
            } else {
                workingDirPath = FilePath(repoPath.path(percentEncoded: false))
            }

            Self.logger.info(
                "Executing setup command",
                metadata: [
                    "command": "\(setupCommand.command)",
                    "workingDirectory": "\(workingDirPath.string)",
                ]
            )

            do {
                _ = try await Shell.execute(
                    "/bin/bash",
                    arguments: ["-c", setupCommand.command],
                    workingDirectory: workingDirPath
                )
            } catch {
                if setupCommand.optional {
                    Self.logger.warning(
                        "Optional setup command failed, continuing",
                        metadata: [
                            "command": "\(setupCommand.command)",
                            "error": "\(error.localizedDescription)",
                        ]
                    )
                } else {
                    throw AnalysisError.setupCommandFailed(
                        command: setupCommand.command,
                        error: error.localizedDescription
                    )
                }
            }
        }
    }

    // MARK: - Project Discovery

    private func findAllProjectsAndWorkspaces(in repoPath: URL) throws -> [ProjectOrWorkspace] {
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

    private func getTargetsForAllProjects(
        foundProjectsAndWorkspaces: [ProjectOrWorkspace]
    ) async throws -> [ProjectWithTargets] {
        return try await foundProjectsAndWorkspaces.concurrentMap { project in
            let targets = try await self.getTargetsFromProject(
                projectPath: project.path,
                isWorkspace: project.isWorkspace
            )
            return ProjectWithTargets(path: project.path, targets: targets)
        }
    }

    private func getTargetsFromProject(
        projectPath: String,
        isWorkspace: Bool
    ) async throws -> [String] {
        let projectDir = (projectPath as NSString).deletingLastPathComponent
        let projectName = (projectPath as NSString).lastPathComponent
        let projectDirPath = FilePath(projectDir)

        var arguments: [String] = ["-list", "-json"]
        if isWorkspace {
            arguments.append(contentsOf: ["-workspace", projectName])
        } else {
            arguments.append(contentsOf: ["-project", projectName])
        }

        let jsonOutput = try await Shell.execute(
            "xcodebuild",
            arguments: arguments,
            workingDirectory: projectDirPath
        )

        guard let jsonData = jsonOutput.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else {
            return []
        }

        var targets: [String] = []

        if let workspace = json["workspace"] as? [String: Any] {
            if let projects = workspace["projects"] as? [[String: Any]] {
                for project in projects {
                    if let projectTargets = project["targets"] as? [String] {
                        targets.append(contentsOf: projectTargets)
                    }
                }
            }
        } else if let project = json["project"] as? [String: Any] {
            if let projectTargets = project["targets"] as? [String] {
                targets.append(contentsOf: projectTargets)
            }
        }

        return targets.sorted()
    }

    // MARK: - Build Settings Extraction

    private func getBuildSettingsForAllTargets(
        projectsWithTargets: [ProjectWithTargets],
        foundProjectsAndWorkspaces: [ProjectOrWorkspace],
        configuration: String
    ) async throws -> [TargetWithBuildSettings] {
        var projectInfoMap: [String: ProjectOrWorkspace] = [:]
        for project in foundProjectsAndWorkspaces {
            projectInfoMap[project.path] = project
        }

        var allTargets: [(target: String, projectPath: String, isWorkspace: Bool)] = []
        for projectWithTargets in projectsWithTargets {
            guard let projectInfo = projectInfoMap[projectWithTargets.path] else {
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

        return try await allTargets.concurrentMap { targetInfo in
            let buildSettings = try await self.getBuildSettingsForTarget(
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

    private func getBuildSettingsForTarget(
        target: String,
        projectPath: String,
        isWorkspace: Bool,
        configuration: String
    ) async throws -> [String: String] {
        let projectDir = (projectPath as NSString).deletingLastPathComponent
        let projectName = (projectPath as NSString).lastPathComponent
        let projectDirPath = FilePath(projectDir)

        var arguments: [String] = [
            "-showBuildSettings",
            "-target", target,
            "-json",
            "-configuration", configuration,
        ]

        if isWorkspace {
            arguments.append(contentsOf: ["-workspace", projectName])
        } else {
            arguments.append(contentsOf: ["-project", projectName])
        }

        let jsonOutput = try await Shell.execute(
            "xcodebuild",
            arguments: arguments,
            workingDirectory: projectDirPath
        )

        guard let jsonData = jsonOutput.data(using: .utf8),
            let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]
        else {
            return [:]
        }

        var buildSettings: [String: String] = [:]

        for targetInfo in jsonArray {
            if let targetName = targetInfo["target"] as? String,
                targetName == target,
                let settings = targetInfo["buildSettings"] as? [String: Any]
            {
                for (key, value) in settings {
                    if let stringValue = value as? String {
                        buildSettings[key] = stringValue
                    } else {
                        buildSettings[key] = String(describing: value)
                    }
                }
                break
            }
        }

        return buildSettings
    }
}
