import Common
import Foundation
import SystemPackage

/// A single build setting metric configuration with optional per-metric commits.
struct SettingMetric: Sendable, Decodable {
    /// Build setting name (e.g., "SWIFT_VERSION")
    let setting: String

    /// Commits to analyze for this setting. If nil, uses HEAD. If empty, skips this metric.
    let commits: [String]?
}

/// Configuration for ExtractBuildSettings tool loaded from JSON file.
struct BuildSettingsConfig: Sendable {
    /// Default configuration file name
    static let defaultFileName = ".scout-build-settings.json"

    /// Represents a single setup command with optional working directory.
    struct SetupCommand: Sendable, Decodable {
        /// Command to execute
        let command: String

        /// Optional working directory relative to repo root (e.g., "project").
        /// If not provided, command executes in repo root.
        let workingDirectory: String?

        /// If true, analysis continues even if this command fails.
        let optional: Bool?
    }

    /// Commands to setup project, executed sequentially.
    let setupCommands: [SetupCommand]?

    /// Build settings metrics to collect with optional per-metric commits
    let metrics: [SettingMetric]?

    /// Path to Xcode workspace (.xcworkspace) or project (.xcodeproj).
    /// Can be relative to repo root or absolute.
    let project: String?

    /// Build configuration name (e.g., "Debug", "Release")
    let configuration: String?

    /// Git operations configuration (file layer - all fields optional)
    let git: GitFileConfig?

    /// Initialize configuration directly (for testing)
    init(
        setupCommands: [SetupCommand]?,
        metrics: [SettingMetric]?,
        project: String?,
        configuration: String?,
        git: GitFileConfig? = nil
    ) {
        self.setupCommands = setupCommands
        self.metrics = metrics
        self.project = project
        self.configuration = configuration
        self.git = git
    }

    /// Initialize configuration from JSON file at given path, or default path if nil.
    /// Returns nil if no config file exists.
    ///
    /// - Parameters:
    ///   - configPath: Optional path to JSON file. If nil, looks for default file
    /// - Throws: `BuildSettingsConfigError` if JSON file is malformed or missing required fields
    init?(configPath: String?) async throws {
        let path = configPath ?? Self.defaultFileName
        guard FileManager.default.fileExists(atPath: path) else {
            if configPath != nil {
                throw BuildSettingsConfigError.missingFile(path: path)
            }
            return nil
        }
        try await self.init(configFilePath: FilePath(path))
    }

    /// Initialize configuration from JSON file.
    ///
    /// - Parameters:
    ///   - configFilePath: Path to JSON file with ExtractBuildSettings configuration (required)
    /// - Throws: `BuildSettingsConfigError` if JSON file is malformed or missing required fields
    init(configFilePath: FilePath) async throws {
        let configPathString = configFilePath.string

        let configFileManager = FileManager.default
        guard configFileManager.fileExists(atPath: configPathString) else {
            throw BuildSettingsConfigError.missingFile(path: configPathString)
        }

        do {
            let fileURL = URL(filePath: configPathString)
            let fileData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let variables = try decoder.decode(Variables.self, from: fileData)
            self.setupCommands = variables.setupCommands
            self.metrics = variables.metrics
            self.project = variables.project
            self.configuration = variables.configuration
            self.git = variables.git
        } catch let decodingError as DecodingError {
            throw BuildSettingsConfigError.invalidJSON(
                path: configPathString,
                reason: decodingError.localizedDescription
            )
        } catch {
            throw BuildSettingsConfigError.readFailed(
                path: configPathString,
                reason: error.localizedDescription
            )
        }
    }

    private struct Variables: Decodable {
        let setupCommands: [SetupCommand]?
        let metrics: [SettingMetric]?
        let project: String?
        let configuration: String?
        let git: GitFileConfig?
    }
}

/// Errors related to ExtractBuildSettings configuration.
enum BuildSettingsConfigError: Error {
    case missingFile(path: String)
    case invalidJSON(path: String, reason: String)
    case readFailed(path: String, reason: String)
}

extension BuildSettingsConfigError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingFile(let path):
            return "Configuration file not found at: \(path)"
        case .invalidJSON(let path, let reason):
            return "Failed to parse JSON file at \(path): \(reason)"
        case .readFailed(let path, let reason):
            return "Failed to read file at \(path): \(reason)"
        }
    }
}
