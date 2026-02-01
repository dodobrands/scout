import Common
import Foundation
import SystemPackage

/// Configuration for ExtractBuildSettings tool loaded from JSON file.
struct BuildSettingsConfig: Sendable {
    /// Default configuration file name
    static let defaultFileName = ".scout-build-settings.json"

    /// Represents a single setup command with optional working directory.
    struct SetupCommand: Sendable, Decodable {
        /// Command to execute
        public let command: String

        /// Optional working directory relative to repo root (e.g., "project").
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

    /// Git operations configuration (file layer - all fields optional)
    public let git: GitFileConfig?

    /// Initialize configuration directly (for testing)
    public init(
        setupCommands: [SetupCommand]?,
        buildSettingsParameters: [String]?,
        workspaceName: String?,
        configuration: String?,
        git: GitFileConfig? = nil
    ) {
        self.setupCommands = setupCommands
        self.buildSettingsParameters = buildSettingsParameters
        self.workspaceName = workspaceName
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
    public init(configFilePath: FilePath) async throws {
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
            self.buildSettingsParameters = variables.buildSettingsParameters
            self.workspaceName = variables.workspaceName
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
        let buildSettingsParameters: [String]?
        let workspaceName: String?
        let configuration: String?
        let git: GitFileConfig?
    }
}

/// Errors related to ExtractBuildSettings configuration.
public enum BuildSettingsConfigError: Error {
    case missingFile(path: String)
    case invalidJSON(path: String, reason: String)
    case readFailed(path: String, reason: String)
}

extension BuildSettingsConfigError: LocalizedError {
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
