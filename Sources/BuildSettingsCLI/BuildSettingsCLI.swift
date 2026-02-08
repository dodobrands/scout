import ArgumentParser
import BuildSettings
import Common
import Foundation
import Logging
import System
import SystemPackage

public struct BuildSettingsCLI: AsyncParsableCommand {
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

        // Load config from file
        let fileConfig = try await BuildSettingsCLIConfig(configPath: config)

        // Build CLI inputs
        let cliInputs = BuildSettingsCLIInputs(
            project: project,
            buildSettingsParameters: buildSettingsParameters.nilIfEmpty,
            repoPath: repoPath,
            commits: commits.nilIfEmpty,
            gitClean: gitClean ? true : nil,
            fixLfs: fixLfs ? true : nil,
            initializeSubmodules: initializeSubmodules ? true : nil
        )

        // Merge CLI > Config > Default (HEAD commits resolved in SDK.analyze)
        let input = try BuildSettings.Input(cli: cliInputs, config: fileConfig)

        let commitCount = Set(input.metrics.flatMap { $0.commits }).count
        Self.logger.info(
            "Will analyze \(commitCount) commit(s) for \(input.metrics.count) metric(s)"
        )

        let sdk = BuildSettings()
        var outputs: [BuildSettings.Output] = []

        do {
            for try await output in sdk.analyze(input: input) {
                Self.logger.notice(
                    "Extracted build settings for \(output.results.count) targets at \(output.commit)"
                )
                outputs.append(output)

                if let outputPath = self.output {
                    try outputs.writeJSON(to: outputPath)
                }
            }
        } catch let error as BuildSettings.AnalysisError {
            Self.logger.warning(
                "Analysis failed",
                metadata: ["error": "\(error.localizedDescription)"]
            )
            // Write partial results collected before the error
            if let outputPath = self.output {
                try outputs.writeJSON(to: outputPath)
            }
        }

        let summary = BuildSettingsCLISummary(outputs: outputs)
        if !summary.outputs.isEmpty {
            Self.logger.info("\(summary)")
        }
        GitHubActionsLogHandler.writeSummary(summary)

        Self.logger.notice("Summary: analyzed \(outputs.count) commit(s)")
    }
}
