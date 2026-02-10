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
        case noProjectsFound(include: [String], commit: String)

        public var errorDescription: String? {
            switch self {
            case .setupCommandFailed(let command, let commit, let error):
                return "Setup command '\(command)' failed at commit \(commit): \(error)"
            case .buildSettingsExtractionFailed(let commit, let error):
                return "Build settings extraction failed at commit \(commit): \(error)"
            case .checkoutFailed(let hash, let error):
                return "Failed to checkout \(hash): \(error)"
            case .noProjectsFound(let include, let commit):
                return
                    "No .xcodeproj found matching patterns \(include) for commit \(commit)"
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

        let discoveredProjects = ProjectDiscovery.discoverProjects(
            in: repoPath,
            include: input.projects.include,
            exclude: input.projects.exclude
        )

        if discoveredProjects.isEmpty {
            if input.projects.continueOnMissing {
                Self.logger.warning(
                    "No projects found matching include patterns, skipping",
                    metadata: [
                        "include": "\(input.projects.include)",
                        "exclude": "\(input.projects.exclude)",
                        "commit": "\(commit)",
                    ]
                )
                return []
            }
            throw AnalysisError.noProjectsFound(
                include: input.projects.include,
                commit: commit
            )
        }

        let projectPaths = discoveredProjects.map(\.path).joined(separator: ", ")
        Self.logger.debug(
            "Discovered \(discoveredProjects.count) project(s)",
            metadata: ["commit": "\(commit)", "projects": "\(projectPaths)"]
        )

        let projectsWithTargets = try await getTargetsForAllProjects(
            discoveredProjects: discoveredProjects
        )
        let targetsWithBuildSettings = try await getBuildSettingsForAllTargets(
            projectsWithTargets: projectsWithTargets,
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
        let commitToSettings = resolvedMetrics.groupedByCommit()

        for (hash, metrics) in commitToSettings {
            try Task.checkCancellation()

            let requestedSettings = metrics.map(\.setting)
            Self.logger.debug("Processing commit: \(hash)")

            do {
                try await Git.checkout(hash: hash, git: input.git)

                let analysisInput = AnalysisInput(
                    repoPath: input.git.repoPath,
                    setupCommands: input.setupCommands,
                    projects: input.projects,
                    configuration: input.configuration
                )

                let targets: [TargetWithBuildSettings]
                do {
                    targets = try await extractBuildSettings(
                        input: analysisInput,
                        commit: hash
                    )
                } catch let error as AnalysisError {
                    throw error
                } catch {
                    throw AnalysisError.buildSettingsExtractionFailed(
                        commit: hash,
                        error: error.localizedDescription
                    )
                }

                let resultItems = requestedSettings.map { setting in
                    var targetValues: [String: String?] = [:]
                    for target in targets {
                        targetValues[target.target] = target.buildSettings[setting]
                    }
                    return ResultItem(setting: setting, targets: targetValues)
                }

                let date = try await Git.commitDate(for: hash, in: repoPath)
                onOutput(Output(commit: hash, date: date, results: resultItems))
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                Self.logger.warning(
                    "Skipping commit due to error",
                    metadata: [
                        "commit": "\(hash)",
                        "error": "\(error.localizedDescription)",
                    ]
                )

                let emptyResults = requestedSettings.map {
                    ResultItem(setting: $0, targets: [:])
                }
                let date = try await Git.commitDate(for: hash, in: repoPath)
                onOutput(Output(commit: hash, date: date, results: emptyResults))
            }
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

            let metadata: Logger.Metadata = [
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

    // MARK: - Target Discovery

    private func getTargetsForAllProjects(
        discoveredProjects: [DiscoveredProject]
    ) async throws -> [ProjectWithTargets] {
        return try await discoveredProjects.concurrentMap { project in
            let targets = try await self.getTargetsFromProject(projectPath: project.path)
            return ProjectWithTargets(path: project.path, targets: targets)
        }
    }

    private func getTargetsFromProject(
        projectPath: String
    ) async throws -> [String] {
        let projectDir = (projectPath as NSString).deletingLastPathComponent
        let projectName = (projectPath as NSString).lastPathComponent
        let projectDirPath = FilePath(projectDir)

        let arguments: [String] = ["-list", "-json", "-project", projectName]

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

        if let project = json["project"] as? [String: Any],
            let projectTargets = project["targets"] as? [String]
        {
            return projectTargets.sorted()
        }

        return []
    }

    // MARK: - Build Settings Extraction

    private func getBuildSettingsForAllTargets(
        projectsWithTargets: [ProjectWithTargets],
        configuration: String
    ) async throws -> [TargetWithBuildSettings] {
        var allTargets: [(target: String, projectPath: String)] = []
        for projectWithTargets in projectsWithTargets {
            for target in projectWithTargets.targets {
                allTargets.append((target: target, projectPath: projectWithTargets.path))
            }
        }

        return try await allTargets.concurrentMap { targetInfo in
            let buildSettings = try await self.getBuildSettingsForTarget(
                target: targetInfo.target,
                projectPath: targetInfo.projectPath,
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
        configuration: String
    ) async throws -> [String: String] {
        let projectDir = (projectPath as NSString).deletingLastPathComponent
        let projectName = (projectPath as NSString).lastPathComponent
        let projectDirPath = FilePath(projectDir)

        let arguments: [String] = [
            "-showBuildSettings",
            "-target", target,
            "-json",
            "-configuration", configuration,
            "-project", projectName,
        ]

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
