import ArgumentParser
import BuildSettingsSDK
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

    @Option(name: [.long, .short], help: "Path to repository (default: current directory)")
    public var repoPath: String = FileManager.default.currentDirectoryPath

    @Option(help: "Path to configuration JSON file")
    public var config: String?

    @Option(
        name: [.long, .short],
        parsing: .upToNextOption,
        help: "Commit hashes to analyze (default: HEAD)"
    )
    public var commits: [String] = []

    @Option(name: [.long, .short], help: "Path to save JSON results")
    public var output: String?

    @Flag(name: [.long, .short])
    public var verbose: Bool = false

    @Flag(
        help: "Clean working directory before analysis (git clean -ffdx && git reset --hard HEAD)"
    )
    public var gitClean: Bool = false

    @Flag(help: "Fix broken LFS pointers by committing modified files after checkout")
    public var fixLfs: Bool = false

    @Flag(help: "Initialize submodules (reset and update to correct commits)")
    public var initializeSubmodules: Bool = false

    static let logger = Logger(label: "scout.ExtractBuildSettings")

    public func run() async throws {
        LoggingSetup.setup(verbose: verbose)

        let configFilePath = SystemPackage.FilePath(
            config ?? "extract-build-settings-extractConfig.json"
        )
        let extractConfig = try await ExtractBuildSettingsConfig(configFilePath: configFilePath)

        let repoPathURL =
            try URL(string: repoPath) ?! URLError.invalidURL(parameter: "repoPath", value: repoPath)

        let commitHashes: [String]
        if !commits.isEmpty {
            commitHashes = commits
        } else {
            let head = try await Git.headCommit(in: repoPathURL)
            commitHashes = [head]
            Self.logger.info("No commits specified, using HEAD: \(head)")
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

        let sdk = BuildSettingsSDK()
        let sdkSetupCommands = extractConfig.setupCommands.map {
            SetupCommand(
                command: $0.command,
                workingDirectory: $0.workingDirectory,
                optional: $0.optional ?? false
            )
        }

        for hash in commitHashes {
            Self.logger.info(
                "Starting analysis for commit",
                metadata: ["hash": "\(hash)"]
            )

            let input = BuildSettingsInput(
                repoPath: repoPathURL,
                setupCommands: sdkSetupCommands,
                configuration: extractConfig.configuration,
                gitClean: gitClean,
                fixLFS: fixLfs,
                initializeSubmodules: initializeSubmodules
            )

            let result: BuildSettingsSDK.Result
            do {
                result = try await sdk.analyzeCommit(hash: hash, input: input)
            } catch let error as BuildSettingsSDK.AnalysisError {
                Self.logger.warning(
                    "Skipping commit due to analysis failure",
                    metadata: [
                        "hash": "\(hash)",
                        "error": "\(error.localizedDescription)",
                    ]
                )
                continue
            }

            for parameter in extractConfig.buildSettingsParameters {
                var targetValues: [String: String] = [:]
                for targetWithSettings in result {
                    if let value = targetWithSettings.buildSettings[parameter] {
                        targetValues[targetWithSettings.target] = value
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

            if let output {
                try saveResults(result, to: output)
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

        GitHubActionsLogHandler.writeSummary(summary)
    }

    private func saveResults(_ results: BuildSettingsSDK.Result, to path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(results)
        try data.write(to: URL(fileURLWithPath: path))
        Self.logger.info("Results saved to \(path)")
    }
}
