import Foundation
import SystemPackage

/// Configuration for Search tool loaded from JSON file.
public struct SearchConfig: Sendable {
    /// Patterns to search for (e.g., ["// periphery:ignore", "TODO:"])
    public let patterns: [String]

    /// File extensions to search in (e.g., ["swift", "m"])
    public let extensions: [String]

    /// Initialize configuration directly (for testing)
    public init(patterns: [String], extensions: [String] = ["swift"]) {
        self.patterns = patterns
        self.extensions = extensions
    }

    /// Initialize configuration from JSON file.
    ///
    /// - Parameters:
    ///   - configFilePath: Path to JSON file with Search configuration (required)
    /// - Throws: `SearchConfigError` if JSON file is malformed or missing required fields
    public init(configFilePath: FilePath) async throws {
        let configPathString = configFilePath.string

        let configFileManager = FileManager.default
        guard configFileManager.fileExists(atPath: configPathString) else {
            throw SearchConfigError.missingFile(path: configPathString)
        }

        do {
            let fileURL = URL(filePath: configPathString)
            let fileData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let variables = try decoder.decode(Variables.self, from: fileData)
            self.patterns = variables.patterns
            self.extensions = variables.extensions ?? ["swift"]
        } catch let decodingError as DecodingError {
            throw SearchConfigError.invalidJSON(
                path: configPathString,
                reason: decodingError.localizedDescription
            )
        } catch {
            throw SearchConfigError.readFailed(
                path: configPathString,
                reason: error.localizedDescription
            )
        }
    }

    private struct Variables: Codable {
        let patterns: [String]
        let extensions: [String]?
    }
}

/// Errors related to Search configuration.
public enum SearchConfigError: Error {
    case missingFile(path: String)
    case invalidJSON(path: String, reason: String)
    case readFailed(path: String, reason: String)
}

extension SearchConfigError: LocalizedError {
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
