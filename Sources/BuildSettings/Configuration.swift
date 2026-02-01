import Common
import Foundation
import SystemPackage

/// Configuration for ExtractBuildSettings tool loaded from JSON file.
public struct ExtractBuildSettingsConfig: Sendable {
    /// Represents a single setup command with optional working directory.
    public struct SetupCommand: Sendable, Codable {
        /// Command to execute
        public let command: String

        /// Optional working directory relative to repo root (e.g., "DodoPizza").
        /// If not provided, command executes in repo root.
        public let workingDirectory: String?

        /// If true, analysis continues even if this command fails.
        public let optional: Bool?

        /// Initialize setup command
        public init(command: String, workingDirectory: String?, optional: Bool?) {
            self.command = command
            self.workingDirectory = workingDirectory
            self.optional = optional
        }
    }

    /// Commands to setup project, executed sequentially.
    public let setupCommands: [SetupCommand]?

    /// Build settings parameters to collect (e.g., ["SWIFT_VERSION"])
    public let buildSettingsParameters: [String]?

    /// Xcode workspace or project name (without extension)
    public let workspaceName: String?

    /// Build configuration name (e.g., "Debug", "Release")
    public let configuration: String?

    /// Git operations configuration
    public let git: GitConfiguration?

    /// Initialize configuration directly (for testing)
    public init(
        setupCommands: [SetupCommand]?,
        buildSettingsParameters: [String]?,
        workspaceName: String?,
        configuration: String?,
        git: GitConfiguration? = nil
    ) {
        self.setupCommands = setupCommands
        self.buildSettingsParameters = buildSettingsParameters
        self.workspaceName = workspaceName
        self.configuration = configuration
        self.git = git
    }

    /// Initialize configuration from JSON file.
    ///
    /// - Parameters:
    ///   - configFilePath: Path to JSON file with ExtractBuildSettings configuration (required)
    /// - Throws: `ExtractBuildSettingsConfigError` if JSON file is malformed or missing required fields
    public init(configFilePath: FilePath) async throws {
        let configPathString = configFilePath.string

        let configFileManager = FileManager.default
        guard configFileManager.fileExists(atPath: configPathString) else {
            throw ExtractBuildSettingsConfigError.missingFile(path: configPathString)
        }

        do {
            let fileURL = URL(filePath: configPathString)
            let fileData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let variables = try decoder.decode(Variables.self, from: fileData)
            self.setupCommands = variables.setupCommands
            self.buildSettingsParameters = variables.buildSettingsParameters
            self.workspaceName = variables.workspaceName
            self.configuration = variables.configuration
            self.git = variables.git
        } catch let decodingError as DecodingError {
            throw ExtractBuildSettingsConfigError.invalidJSON(
                path: configPathString,
                reason: decodingError.localizedDescription
            )
        } catch {
            throw ExtractBuildSettingsConfigError.readFailed(
                path: configPathString,
                reason: error.localizedDescription
            )
        }
    }

    private struct Variables: Codable {
        let setupCommands: [SetupCommand]?
        let buildSettingsParameters: [String]?
        let workspaceName: String?
        let configuration: String?
        let git: GitConfiguration?
    }
}

/// Errors related to ExtractBuildSettings configuration.
public enum ExtractBuildSettingsConfigError: Error {
    case missingFile(path: String)
    case invalidJSON(path: String, reason: String)
    case readFailed(path: String, reason: String)
}

extension ExtractBuildSettingsConfigError: LocalizedError {
    public var errorDescription: String? {
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
