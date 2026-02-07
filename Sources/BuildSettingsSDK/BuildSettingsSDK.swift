import Common
import Foundation
import Logging
import System

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

    /// Extracts build settings from Xcode projects in the repository.
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Array of targets with their build settings
    public func extractBuildSettings(input: Input) async throws -> [TargetWithBuildSettings] {
        let repoPath = URL(filePath: input.git.repoPath)

        try await GitFix.prepareRepository(git: input.git)

        try await executeSetupCommands(input.setupCommands, in: repoPath)

        let foundProjectsAndWorkspaces = try resolveProject(
            path: input.project,
            repoPath: repoPath
        )

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

    /// Extracts build settings for a specific commit.
    private func extractBuildSettingsForCommit(
        _ commit: String,
        input: Input
    ) async throws -> [ResultItem] {
        let targets: [TargetWithBuildSettings]
        do {
            targets = try await extractBuildSettings(input: input)
        } catch let error as AnalysisError {
            throw error
        } catch {
            throw AnalysisError.buildSettingsExtractionFailed(error: error.localizedDescription)
        }

        let requestedSettings = Set(
            input.metrics.filter { $0.commits.contains(commit) }.map { $0.setting }
        )
        return targets.map { target in
            let filteredSettings = target.buildSettings
                .filter { requestedSettings.contains($0.key) }
                .mapValues { Optional($0) }
            return ResultItem(target: target.target, settings: filteredSettings)
        }
    }

    /// Analyzes all commits from metrics and returns outputs for each.
    /// Groups metrics by commit to minimize checkouts.
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Array of outputs, one for each unique commit
    public func analyze(input: Input) async throws -> [Output] {
        let repoPath = URL(filePath: input.git.repoPath)

        // Resolve HEAD commits to actual hashes
        let resolvedMetrics = try await input.metrics.resolvingHeadCommits(
            repoPath: input.git.repoPath
        )

        // Group metrics by commit to minimize checkouts
        var commitToSettings: [String: [String]] = [:]
        for metric in resolvedMetrics {
            for commit in metric.commits {
                commitToSettings[commit, default: []].append(metric.setting)
            }
        }

        var outputs: [Output] = []
        for (hash, _) in commitToSettings {
            Self.logger.debug("Processing commit: \(hash)")

            do {
                try await Shell.execute(
                    "git",
                    arguments: ["checkout", hash],
                    workingDirectory: FilePath(repoPath.path(percentEncoded: false))
                )
            } catch {
                throw AnalysisError.checkoutFailed(
                    hash: hash,
                    error: error.localizedDescription
                )
            }

            let resultItems = try await extractBuildSettingsForCommit(hash, input: input)
            let date = try await Git.commitDate(for: hash, in: repoPath)

            outputs.append(Output(commit: hash, date: date, results: resultItems))
        }

        return outputs
    }

    /// Checks out a commit and extracts build settings.
    /// - Parameter input: Input parameters for the operation including commit hash
    /// - Returns: Output with commit info, date, and results
    @available(*, deprecated, message: "Use analyze(input:) instead")
    public func analyzeCommit(commit: String, input: Input) async throws -> Output {
        let repoPath = URL(filePath: input.git.repoPath)

        do {
            try await Shell.execute(
                "git",
                arguments: ["checkout", commit],
                workingDirectory: FilePath(repoPath.path(percentEncoded: false))
            )
        } catch {
            throw AnalysisError.checkoutFailed(
                hash: commit,
                error: error.localizedDescription
            )
        }

        let targets: [TargetWithBuildSettings]
        do {
            targets = try await extractBuildSettings(input: input)
        } catch let error as AnalysisError {
            throw error
        } catch {
            throw AnalysisError.buildSettingsExtractionFailed(error: error.localizedDescription)
        }

        let date = try await Git.commitDate(for: commit, in: repoPath)

        let requestedSettings = Set(input.metrics.map { $0.setting })
        let resultItems = targets.map { target in
            let filteredSettings = target.buildSettings
                .filter { requestedSettings.contains($0.key) }
                .mapValues { Optional($0) }
            return ResultItem(target: target.target, settings: filteredSettings)
        }

        return Output(commit: commit, date: date, results: resultItems)
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

    private func resolveProject(
        path: String,
        repoPath: URL
    ) throws -> [ProjectOrWorkspace] {
        let fileManager = FileManager.default

        // Resolve path: if relative, join with repoPath; if absolute, use as-is
        let resolvedPath: String
        if path.hasPrefix("/") {
            resolvedPath = path
        } else {
            resolvedPath = repoPath.appendingPathComponent(path).path(percentEncoded: false)
        }

        guard fileManager.fileExists(atPath: resolvedPath) else {
            Self.logger.warning(
                "Project or workspace not found",
                metadata: ["path": "\(resolvedPath)"]
            )
            return []
        }

        let isWorkspace = resolvedPath.hasSuffix(".xcworkspace")
        return [ProjectOrWorkspace(path: resolvedPath, isWorkspace: isWorkspace)]
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
