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

    @Option(name: [.long, .short], help: "Path to repository (default: current directory)")
    public var repoPath: String?

    @Option(
        name: [.long, .short],
        help: "Path to Xcode workspace (.xcworkspace) or project (.xcodeproj)"
    )
    public var project: String?

    @Option(help: "Path to configuration JSON file")
    public var config: String?

    @Argument(
        help:
            "Build settings parameters to extract (e.g., SWIFT_VERSION IPHONEOS_DEPLOYMENT_TARGET)"
    )
    public var buildSettingsParameters: [String] = []

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

        let fileConfig = try await BuildSettingsConfig(configPath: config)
        let input = try await buildInput(fileConfig: fileConfig)

        let commitCount = Set(input.metrics.flatMap { $0.commits }).count
        Self.logger.info(
            "Will analyze \(commitCount) commit(s) for \(input.metrics.count) metric(s)"
        )

        let sdk = BuildSettingsSDK()
        var outputs: [BuildSettingsSDK.Output] = []

        do {
            outputs = try await sdk.analyze(input: input)
        } catch let error as BuildSettingsSDK.AnalysisError {
            Self.logger.warning(
                "Analysis failed",
                metadata: ["error": "\(error.localizedDescription)"]
            )
        }

        for output in outputs {
            Self.logger.notice(
                "Extracted build settings for \(output.results.count) targets at \(output.commit)"
            )
        }

        if let outputPath = output {
            try outputs.writeJSON(to: outputPath)
        }

        let summary = BuildSettingsSummary(outputs: outputs)
        GitHubActionsLogHandler.writeSummary(summary)

        Self.logger.notice("Summary: analyzed \(outputs.count) commit(s)")
    }

    private func buildInput(fileConfig: BuildSettingsConfig?) async throws -> BuildSettingsSDK.Input
    {
        let gitConfig = GitConfiguration(
            cli: GitCLIInputs(
                repoPath: repoPath,
                clean: gitClean ? true : nil,
                fixLFS: fixLfs ? true : nil,
                initializeSubmodules: initializeSubmodules ? true : nil
            ),
            fileConfig: fileConfig?.git
        )

        let repoPathURL =
            try URL(string: gitConfig.repoPath)
            ?! URLError.invalidURL(parameter: "repoPath", value: gitConfig.repoPath)

        // Resolve project path
        let resolvedProject: String
        if let project {
            resolvedProject = project
        } else if let configProject = fileConfig?.project {
            resolvedProject = configProject
        } else {
            throw ValidationError("Project path is required")
        }

        // Resolve configuration
        let configuration = fileConfig?.configuration ?? "Release"

        // Build setup commands
        let setupCommands: [SetupCommand] =
            fileConfig?.setupCommands?.map {
                SetupCommand(
                    command: $0.command,
                    workingDirectory: $0.workingDirectory,
                    optional: $0.optional ?? false
                )
            } ?? []

        // Build metrics from CLI args or config file
        var metrics: [BuildSettingsSDK.MetricInput] = []
        if !buildSettingsParameters.isEmpty {
            let commitList = commits.isEmpty ? ["HEAD"] : commits
            metrics = buildSettingsParameters.map {
                BuildSettingsSDK.MetricInput(setting: $0, commits: commitList)
            }
        } else if let configMetrics = fileConfig?.metrics {
            metrics = configMetrics.map {
                BuildSettingsSDK.MetricInput(setting: $0.setting, commits: $0.commits ?? ["HEAD"])
            }
        }

        // Resolve HEAD commits
        let resolvedMetrics = try await metrics.resolvingHeadCommits(repoPath: repoPathURL.path)

        return BuildSettingsSDK.Input(
            git: gitConfig,
            setupCommands: setupCommands,
            metrics: resolvedMetrics,
            project: resolvedProject,
            configuration: configuration
        )
    }
}
