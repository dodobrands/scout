import ArgumentParser
import Common
import Foundation
import Logging
import System
import SystemPackage

public struct BuildSettings: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "build-settings",
        abstract: "Extract build settings from Xcode projects"
    )

    struct Summary: JobSummaryFormattable {
        let parameterResults: [(parameter: String, targetCount: Int)]

        var markdown: String {
            var md = "## ExtractBuildSettings Summary\n\n"

            if !parameterResults.isEmpty {
                md += "### Build Settings Parameters\n\n"
                md += "| Parameter | Target Count |\n"
                md += "|-----------|--------------|\n"
                for result in parameterResults {
                    md += "| `\(result.parameter)` | \(result.targetCount) |\n"
                }
                md += "\n"
            }

            return md
        }
    }

    @Option(name: [.long, .short], help: "Path to repository")
    public var repoPath: String

    @Option(name: .long, help: "Path to configuration JSON file")
    public var config: String?

    @Option(name: [.long, .short], help: "Comma-separated list of commit hashes to analyze")
    public var commits: String

    @Flag(name: [.long, .short])
    public var verbose: Bool = false

    @Flag(
        name: [.long, .customShort("I")],
        help: "Initialize submodules (reset and update to correct commits)"
    )
    public var initializeSubmodules: Bool = false

    static let logger = Logger(label: "mobile-code-metrics.ExtractBuildSettings")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)

        let configFilePath = SystemPackage.FilePath(
            config ?? "extract-build-settings-extractConfig.json"
        )
        let extractConfig = try await ExtractBuildSettingsConfig(configFilePath: configFilePath)

        let repoPathURL =
            try URL(string: repoPath) ?! URLError.invalidURL(parameter: "repoPath", value: repoPath)

        let commitHashes = commits.split(separator: ",").map {
            String($0.trimmingCharacters(in: .whitespaces))
        }

        var parameterResults: [(parameter: String, targetCount: Int)] = []

        Self.logger.info(
            "Will analyze \(commitHashes.count) commits for \(extractConfig.buildSettingsParameters.count) parameter(s)",
            metadata: [
                "commits": .array(commitHashes.map { Logger.MetadataValue.string($0) }),
                "parameters": .array(
                    extractConfig.buildSettingsParameters.map { Logger.MetadataValue.string($0) }
                ),
            ]
        )

        for hash in commitHashes {
            var targetsWithBuildSettings: [TargetWithBuildSettings] = []
            var analysisFailed = false
            var analysisError: Error?

            do {
                try await Shell.execute(
                    "git",
                    arguments: ["checkout", hash],
                    workingDirectory: System.FilePath(repoPathURL.path(percentEncoded: false))
                )
                await fixGitIssuesSafely(in: repoPathURL, commitHash: hash)

                do {
                    try await SetupCommandExecutor.execute(
                        extractConfig.setupCommands,
                        in: repoPathURL
                    )
                } catch let error as SetupCommandExecutionError {
                    let errorDescription = error.errorDescription ?? error.localizedDescription
                    var errorMetadata: Logger.Metadata = [
                        "hash": "\(hash)",
                        "failedCommand": "\(error.command.command)",
                        "workingDirectory": "\(error.command.workingDirectory ?? "repo root")",
                        "error": "\(errorDescription)",
                        "errorType": "\(type(of: error.underlyingError))",
                    ]

                    if let shellError = error.underlyingError as? ShellError {
                        errorMetadata.merge(from: shellError.errorUserInfo) { _, new in new }
                    }

                    Self.logger.error(
                        "Setup command failed, will skip this commit",
                        metadata: errorMetadata
                    )
                    analysisFailed = true
                    analysisError = error
                } catch {
                    let errorDescription =
                        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    let errorMetadata: Logger.Metadata = [
                        "hash": "\(hash)",
                        "error": "\(errorDescription)",
                        "errorType": "\(type(of: error))",
                    ]

                    Self.logger.error(
                        "Setup command failed, will skip this commit",
                        metadata: errorMetadata
                    )
                    analysisFailed = true
                    analysisError = error
                }

                if !analysisFailed {
                    Self.logger.info(
                        "Starting metric collection",
                        metadata: [
                            "hash": "\(hash)",
                            "parameters": .array(
                                extractConfig.buildSettingsParameters.map {
                                    Logger.MetadataValue.string($0)
                                }
                            ),
                        ]
                    )
                    do {
                        Self.logger.info(
                            "Starting project discovery",
                            metadata: [
                                "hash": "\(hash)"
                            ]
                        )
                        let projectsDiscoveryStart = Date()
                        let foundProjectsAndWorkspaces =
                            try ProjectDiscovery.findAllProjectsAndWorkspaces(
                                in: repoPathURL
                            )
                        let projectsDiscoveryDuration = Date().timeIntervalSince(
                            projectsDiscoveryStart
                        )
                        Self.logger.info(
                            "Completed project discovery",
                            metadata: [
                                "hash": "\(hash)",
                                "projectsCount": "\(foundProjectsAndWorkspaces.count)",
                                "durationSeconds": "\(projectsDiscoveryDuration.formatted())",
                            ]
                        )

                        Self.logger.info(
                            "Starting targets collection",
                            metadata: [
                                "hash": "\(hash)",
                                "projectsCount": "\(foundProjectsAndWorkspaces.count)",
                            ]
                        )
                        let targetsCollectionStart = Date()
                        let projectsWithTargets =
                            try await ProjectDiscovery.getTargetsForAllProjects(
                                foundProjectsAndWorkspaces: foundProjectsAndWorkspaces
                            )
                        let targetsCollectionDuration = Date().timeIntervalSince(
                            targetsCollectionStart
                        )
                        let totalTargetsCount = projectsWithTargets.reduce(0) {
                            $0 + $1.targets.count
                        }
                        Self.logger.info(
                            "Completed targets collection",
                            metadata: [
                                "hash": "\(hash)",
                                "totalTargetsCount": "\(totalTargetsCount)",
                                "durationSeconds": "\(targetsCollectionDuration.formatted())",
                            ]
                        )

                        Self.logger.info(
                            "Starting build settings extraction",
                            metadata: [
                                "hash": "\(hash)",
                                "totalTargetsCount": "\(totalTargetsCount)",
                                "configuration": "\(extractConfig.configuration)",
                            ]
                        )
                        let buildSettingsStart = Date()
                        targetsWithBuildSettings =
                            try await BuildSettingsExtractor
                            .getBuildSettingsForAllTargets(
                                projectsWithTargets: projectsWithTargets,
                                foundProjectsAndWorkspaces: foundProjectsAndWorkspaces,
                                configuration: extractConfig.configuration
                            )
                        let buildSettingsDuration = Date().timeIntervalSince(buildSettingsStart)
                        Self.logger.info(
                            "Completed build settings extraction",
                            metadata: [
                                "hash": "\(hash)",
                                "targetsWithSettingsCount": "\(targetsWithBuildSettings.count)",
                                "durationSeconds": "\(buildSettingsDuration.formatted())",
                            ]
                        )
                    } catch {
                        let errorDescription =
                            (error as? LocalizedError)?.errorDescription
                            ?? error.localizedDescription
                        var errorMetadata: Logger.Metadata = [
                            "hash": "\(hash)",
                            "error": "\(errorDescription)",
                            "errorType": "\(type(of: error))",
                        ]

                        if let shellError = error as? ShellError {
                            switch shellError {
                            case .executionFailed(
                                let executable,
                                let arguments,
                                let underlyingError
                            ):
                                errorMetadata["executable"] = "\(executable)"
                                errorMetadata["arguments"] = "\(arguments.joined(separator: " "))"
                                errorMetadata["underlyingError"] = "\(underlyingError)"
                            case .processFailed(
                                let executable,
                                let arguments,
                                let exitCode,
                                let errorOutput
                            ):
                                let exitCodeString: String
                                if case .exited(let code) = exitCode {
                                    exitCodeString = "\(code)"
                                } else {
                                    exitCodeString = "\(exitCode)"
                                }
                                errorMetadata["executable"] = "\(executable)"
                                errorMetadata["arguments"] = "\(arguments.joined(separator: " "))"
                                errorMetadata["exitCode"] = "\(exitCodeString)"
                                errorMetadata["errorOutput"] = "\(errorOutput)"
                            }
                        }

                        Self.logger.error(
                            "Failed to extract build settings, will skip this commit",
                            metadata: errorMetadata
                        )
                        analysisFailed = true
                        analysisError = error
                    }
                }
            } catch {
                let errorDescription = error.errorDescription ?? error.localizedDescription
                var errorMetadata: Logger.Metadata = [
                    "hash": "\(hash)",
                    "error": "\(errorDescription)",
                    "errorType": "\(type(of: error))",
                ]

                errorMetadata.merge(from: error.errorUserInfo) { _, new in new }

                Self.logger.error(
                    "Failed to checkout or analyze commit, will skip this commit",
                    metadata: errorMetadata
                )
                analysisFailed = true
                analysisError = error
            }

            await fixGitIssuesSafely(in: repoPathURL, commitHash: hash)

            if analysisFailed {
                let errorDesc =
                    analysisError.map {
                        ($0 as? LocalizedError)?.errorDescription
                            ?? $0.localizedDescription
                    } ?? "unknown"
                Self.logger.warning(
                    "Skipping commit due to analysis failure",
                    metadata: [
                        "hash": "\(hash)",
                        "error": "\(errorDesc)",
                    ]
                )
                continue
            }

            for parameter in extractConfig.buildSettingsParameters {
                var targetValues: [String: String] = [:]
                for targetWithSettings in targetsWithBuildSettings {
                    if let value = targetWithSettings.buildSettings[parameter] {
                        let target = targetWithSettings.target
                        targetValues[target] = value
                    }
                }

                Self.logger.notice(
                    "Extracted build settings",
                    metadata: [
                        "hash": "\(hash)",
                        "parameter": "\(parameter)",
                        "targetsCount": "\(targetValues.count)",
                    ]
                )

                if let existingIndex = parameterResults.firstIndex(where: {
                    $0.parameter == parameter
                }) {
                    parameterResults[existingIndex] = (parameter, targetValues.count)
                } else {
                    parameterResults.append((parameter, targetValues.count))
                }
            }
        }

        let summary = Summary(parameterResults: parameterResults)
        logSummary(summary)
    }

    private func logSummary(_ summary: Summary) {
        if !summary.parameterResults.isEmpty {
            Self.logger.info("Build settings parameter counts:")
            for result in summary.parameterResults {
                Self.logger.info("  - \(result.parameter): \(result.targetCount) targets")
            }
        }

        writeJobSummary(summary)
    }

    private func writeJobSummary(_ summary: Summary) {
        GitHubActionsLogHandler.writeSummary(summary)
    }

    private func fixGitIssuesSafely(
        in repoPathURL: URL,
        commitHash: String? = nil
    ) async {
        do {
            try await GitFix.fixGitIssues(
                in: repoPathURL,
                initializeSubmodules: initializeSubmodules
            )
        } catch {
            var metadata: Logger.Metadata = [
                "error": "\(error.localizedDescription)"
            ]
            if let commitHash {
                metadata["hash"] = "\(commitHash)"
            }
            Self.logger.warning(
                "Failed to fix git issues",
                metadata: metadata
            )
        }
    }
}
