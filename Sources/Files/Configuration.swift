import Common
import Foundation
import SystemPackage

/// Configuration for CountFiles tool loaded from JSON file.
public struct CountFilesConfig: Sendable {
    /// File extensions to count (without dot, e.g., ["storyboard", "xib"])
    public let filetypes: [String]

    /// Git operations configuration
    public let git: GitConfiguration

    /// Initialize configuration directly (for testing)
    public init(filetypes: [String], git: GitConfiguration = .default) {
        self.filetypes = filetypes
        self.git = git
    }

    /// Initialize configuration from JSON file.
    ///
    /// - Parameters:
    ///   - configFilePath: Path to JSON file with CountFiles configuration (required)
    /// - Throws: `CountFilesConfigError` if JSON file is malformed or missing required fields
    public init(configFilePath: FilePath) async throws {
        let configPathString = configFilePath.string

        let configFileManager = FileManager.default
        guard configFileManager.fileExists(atPath: configPathString) else {
            throw CountFilesConfigError.missingFile(path: configPathString)
        }

        do {
            let fileURL = URL(filePath: configPathString)
            let fileData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let variables = try decoder.decode(Variables.self, from: fileData)
            self.filetypes = variables.filetypes
            self.git = variables.git ?? .default
        } catch let decodingError as DecodingError {
            throw CountFilesConfigError.invalidJSON(
                path: configPathString,
                reason: decodingError.localizedDescription
            )
        } catch {
            throw CountFilesConfigError.readFailed(
                path: configPathString,
                reason: error.localizedDescription
            )
        }
    }

    private struct Variables: Codable {
        let filetypes: [String]
        let git: GitConfiguration?
    }
}

/// Errors related to CountFiles configuration.
public enum CountFilesConfigError: Error {
    case missingFile(path: String)
    case invalidJSON(path: String, reason: String)
    case readFailed(path: String, reason: String)
}

extension CountFilesConfigError: LocalizedError {
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
