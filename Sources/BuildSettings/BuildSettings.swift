import Common
import Foundation
import Logging
import System

/// SDK for extracting build settings from Xcode projects.
public struct BuildSettings: Sendable {
    private static let logger = Logger(label: "scout.BuildSettings")

    public init() {}

    /// Error that can occur during analysis.
    public enum AnalysisError: Error, LocalizedError {
        case setupCommandFailed(command: String, commit: String, error: String)
        case buildSettingsExtractionFailed(commit: String, error: String)
        case checkoutFailed(hash: String, error: String)

        public var errorDescription: String? {
            switch self {
            case .setupCommandFailed(let command, let commit, let error):
                return "Setup command '\(command)' failed at commit \(commit): \(error)"
            case .buildSettingsExtractionFailed(let commit, let error):
                return "Build settings extraction failed at commit \(commit): \(error)"
            case .checkoutFailed(let hash, let error):
                return "Failed to checkout \(hash): \(error)"
            }
        }
    }

    /// Extracts build settings from Xcode projects in the repository.
    /// Performs analysis on current repository state without git operations.
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Array of targets with their build settings
    func extractBuildSettings(
        input: AnalysisInput,
        commit: String
    ) async throws -> [TargetWithBuildSettings] {
        let repoPath = URL(filePath: input.repoPath)

        try await executeSetupCommands(input.setupCommands, in: repoPath, commit: commit)

        let foundProjectsAndWorkspaces = try resolveProject(
            path: input.project,
            repoPath: repoPath,
            commit: commit
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

    /// Analyzes all commits from metrics and yields outputs incrementally.
    /// Groups metrics by commit to minimize checkouts.
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Async stream of outputs, one for each unique commit
    public func analyze(input: Input) -> AsyncThrowingStream<Output, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await performAnalysis(input: input) { output in
                        continuation.yield(output)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func performAnalysis(
        input: Input,
        onOutput: (Output) -> Void
    ) async throws {
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

        for (hash, requestedSettings) in commitToSettings {
            try Task.checkCancellation()

            Self.logger.debug("Processing commit: \(hash)")

            do {
                try await Git.checkout(hash: hash, git: input.git)
            } catch {
                throw AnalysisError.checkoutFailed(
                    hash: hash,
                    error: error.localizedDescription
                )
            }

            let analysisInput = AnalysisInput(
                repoPath: input.git.repoPath,
                setupCommands: input.setupCommands,
                project: input.project,
                configuration: input.configuration
            )

            let targets: [TargetWithBuildSettings]
            do {
                targets = try await extractBuildSettings(input: analysisInput, commit: hash)
            } catch let error as AnalysisError {
                throw error
            } catch {
                throw AnalysisError.buildSettingsExtractionFailed(
                    commit: hash,
                    error: error.localizedDescription
                )
            }

            let requestedSettingsSet = Set(requestedSettings)
            let resultItems = targets.map { target in
                let filteredSettings = target.buildSettings
                    .filter { requestedSettingsSet.contains($0.key) }
                    .mapValues { Optional($0) }
                return ResultItem(target: target.target, settings: filteredSettings)
            }

            let date = try await Git.commitDate(for: hash, in: repoPath)
            onOutput(Output(commit: hash, date: date, results: resultItems))
        }
    }

    // MARK: - Setup Commands

    private func executeSetupCommands(
        _ commands: [SetupCommand],
        in repoPath: URL,
        commit: String
    ) async throws {
        for setupCommand in commands {
            let workingDirPath: FilePath
            if let dir = setupCommand.workingDirectory {
                let workingDirURL = repoPath.appendingPathComponent(dir, isDirectory: true)
                workingDirPath = FilePath(workingDirURL.path(percentEncoded: false))
            } else {
                workingDirPath = FilePath(repoPath.path(percentEncoded: false))
            }

            var metadata: Logger.Metadata = [
                "command": "\(setupCommand.command)",
                "workingDirectory": "\(workingDirPath.string)",
                "commit": "\(commit)",
            ]

            Self.logger.info("Executing setup command", metadata: metadata)

            do {
                let prepared = try CommandParser.prepareExecution(setupCommand.command)
                _ = try await Shell.execute(
                    prepared.executable,
                    arguments: prepared.arguments,
                    workingDirectory: workingDirPath
                )
            } catch let error as CommandParserError {
                throw AnalysisError.setupCommandFailed(
                    command: setupCommand.command,
                    commit: commit,
                    error: error.localizedDescription
                )
            } catch {
                if setupCommand.optional {
                    Self.logger.warning(
                        "Optional setup command failed, continuing",
                        metadata: [
                            "command": "\(setupCommand.command)",
                            "error": "\(error.localizedDescription)",
                            "commit": "\(commit)",
                        ]
                    )
                } else {
                    throw AnalysisError.setupCommandFailed(
                        command: setupCommand.command,
                        commit: commit,
                        error: error.localizedDescription
                    )
                }
            }
        }
    }

    // MARK: - Project Discovery

    private func resolveProject(
        path: String,
        repoPath: URL,
        commit: String
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
                "Project or workspace not found, skipping",
                metadata: [
                    "path": "\(resolvedPath)",
                    "commit": "\(commit)",
                ]
            )
            return []
        }

        // Strip trailing slash that URL.appendingPathComponent adds for directories.
        // .xcworkspace is a directory bundle, so the path may end with "/".
        let normalizedPath =
            resolvedPath.hasSuffix("/") ? String(resolvedPath.dropLast()) : resolvedPath
        let isWorkspace = ProjectOrWorkspace.isWorkspace(path: resolvedPath)
        return [ProjectOrWorkspace(path: normalizedPath, isWorkspace: isWorkspace)]
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
