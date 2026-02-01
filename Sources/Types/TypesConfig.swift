import Common
import Foundation
import SystemPackage

/// Configuration for CountTypes tool loaded from JSON file.
public struct TypesConfig: Sendable {
    /// Types to count (e.g., ["UIView", "UIViewController", "View", "XCTestCase"])
    public let types: [String]?

    /// Git operations configuration (file layer - all fields optional)
    public let git: GitFileConfig?

    /// Initialize configuration directly (for testing)
    public init(types: [String]?, git: GitFileConfig? = nil) {
        self.types = types
        self.git = git
    }

    /// Initialize configuration from JSON file at given path, or default path if nil.
    /// Returns nil if no config file exists.
    ///
    /// - Parameters:
    ///   - configPath: Optional path to JSON file. If nil, looks for "count-types-config.json"
    /// - Throws: `TypesConfigError` if JSON file is malformed or missing required fields
    public init?(configPath: String?) async throws {
        let path = configPath ?? "count-types-config.json"
        guard FileManager.default.fileExists(atPath: path) else {
            if configPath != nil {
                throw TypesConfigError.missingFile(path: path)
            }
            return nil
        }
        try await self.init(configFilePath: FilePath(path))
    }

    /// Initialize configuration from JSON file.
    ///
    /// - Parameters:
    ///   - configFilePath: Path to JSON file with CountTypes configuration (required)
    /// - Throws: `TypesConfigError` if JSON file is malformed or missing required fields
    public init(configFilePath: FilePath) async throws {
        let configPathString = configFilePath.string

        let configFileManager = FileManager.default
        guard configFileManager.fileExists(atPath: configPathString) else {
            throw TypesConfigError.missingFile(path: configPathString)
        }

        do {
            let fileURL = URL(filePath: configPathString)
            let fileData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let variables = try decoder.decode(Variables.self, from: fileData)
            self.types = variables.types
            self.git = variables.git
        } catch let decodingError as DecodingError {
            throw TypesConfigError.invalidJSON(
                path: configPathString,
                reason: decodingError.localizedDescription
            )
        } catch {
            throw TypesConfigError.readFailed(
                path: configPathString,
                reason: error.localizedDescription
            )
        }
    }

    private struct Variables: Codable {
        let types: [String]?
        let git: GitFileConfig?
    }
}

/// Errors related to CountTypes configuration.
public enum TypesConfigError: Error {
    case missingFile(path: String)
    case invalidJSON(path: String, reason: String)
    case readFailed(path: String, reason: String)
}

extension TypesConfigError: LocalizedError {
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
