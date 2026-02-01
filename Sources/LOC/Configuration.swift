import Common
import Foundation
import SystemPackage

/// Configuration for CountLOC tool loaded from JSON file.
public struct LOCConfig: Sendable {
    /// Single LOC configuration entry
    public struct LOCConfiguration: Sendable, Codable {
        /// Programming languages to count (array of strings)
        public let languages: [String]

        /// Include paths (array of strings)
        public let include: [String]

        /// Exclude paths (array of strings)
        public let exclude: [String]

        /// Initialize LOC configuration
        public init(languages: [String], include: [String], exclude: [String]) {
            self.languages = languages
            self.include = include
            self.exclude = exclude
        }
    }

    /// LOC configurations to process
    public let configurations: [LOCConfiguration]?

    /// Git operations configuration (file layer - all fields optional)
    public let git: GitFileConfig?

    /// Initialize configuration directly (for testing)
    public init(configurations: [LOCConfiguration]?, git: GitFileConfig? = nil) {
        self.configurations = configurations
        self.git = git
    }

    /// Initialize configuration from JSON file.
    ///
    /// - Parameters:
    ///   - configFilePath: Path to JSON file with CountLOC configuration (required)
    /// - Throws: `LOCConfigError` if JSON file is malformed or missing required fields
    public init(configFilePath: FilePath) async throws {
        let configPathString = configFilePath.string

        let configFileManager = FileManager.default
        guard configFileManager.fileExists(atPath: configPathString) else {
            throw LOCConfigError.missingFile(path: configPathString)
        }

        do {
            let fileURL = URL(filePath: configPathString)
            let fileData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let variables = try decoder.decode(Variables.self, from: fileData)
            self.configurations = variables.configurations
            self.git = variables.git
        } catch let decodingError as DecodingError {
            throw LOCConfigError.invalidJSON(
                path: configPathString,
                reason: decodingError.localizedDescription
            )
        } catch {
            throw LOCConfigError.readFailed(
                path: configPathString,
                reason: error.localizedDescription
            )
        }
    }

    private struct Variables: Codable {
        let configurations: [LOCConfiguration]?
        let git: GitFileConfig?
    }
}

/// Errors related to CountLOC configuration.
public enum LOCConfigError: Error {
    case missingFile(path: String)
    case invalidJSON(path: String, reason: String)
    case readFailed(path: String, reason: String)
}

extension LOCConfigError: LocalizedError {
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
