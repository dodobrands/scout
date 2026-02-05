import Common
import Foundation
import SystemPackage

/// Configuration for CountLOC tool loaded from JSON file.
struct LOCConfig: Sendable {
    /// Default configuration file name
    static let defaultFileName = ".scout-loc.json"

    /// Single LOC configuration entry
    struct LOCConfiguration: Sendable, Decodable {
        /// Programming languages to count (array of strings)
        let languages: [String]

        /// Include paths (array of strings)
        let include: [String]

        /// Exclude paths (array of strings)
        let exclude: [String]
    }

    /// LOC configurations to process
    let configurations: [LOCConfiguration]?

    /// Git operations configuration (file layer - all fields optional)
    let git: GitFileConfig?

    /// Initialize configuration directly (for testing)
    init(configurations: [LOCConfiguration]?, git: GitFileConfig? = nil) {
        self.configurations = configurations
        self.git = git
    }

    /// Initialize configuration from JSON file at given path, or default path if nil.
    /// Returns nil if no config file exists.
    ///
    /// - Parameters:
    ///   - configPath: Optional path to JSON file. If nil, looks for default file
    /// - Throws: `LOCConfigError` if JSON file is malformed or missing required fields
    init?(configPath: String?) async throws {
        let path = configPath ?? Self.defaultFileName
        guard FileManager.default.fileExists(atPath: path) else {
            if configPath != nil {
                throw LOCConfigError.missingFile(path: path)
            }
            return nil
        }
        try await self.init(configFilePath: FilePath(path))
    }

    /// Initialize configuration from JSON file.
    ///
    /// - Parameters:
    ///   - configFilePath: Path to JSON file with CountLOC configuration (required)
    /// - Throws: `LOCConfigError` if JSON file is malformed or missing required fields
    init(configFilePath: FilePath) async throws {
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

    private struct Variables: Decodable {
        let configurations: [LOCConfiguration]?
        let git: GitFileConfig?
    }
}

/// Errors related to CountLOC configuration.
enum LOCConfigError: Error {
    case missingFile(path: String)
    case invalidJSON(path: String, reason: String)
    case readFailed(path: String, reason: String)
}

extension LOCConfigError: LocalizedError {
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
