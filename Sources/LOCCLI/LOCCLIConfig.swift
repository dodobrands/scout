import Common
import Foundation
import SystemPackage

/// A single LOC metric configuration with optional per-metric commits.
struct LOCMetric: Sendable, Decodable {
    /// Programming languages to count (array of strings)
    let languages: [String]

    /// Include paths (array of strings)
    let include: [String]

    /// Exclude paths (array of strings)
    let exclude: [String]

    /// Commits to analyze for this metric. If nil, uses HEAD. If empty, skips this metric.
    let commits: [String]?

    /// Template for metric identifier with placeholders (%langs%, %include%, %exclude%)
    let nameTemplate: String?
}

/// Configuration for CountLOC tool loaded from JSON file.
struct LOCCLIConfig: Sendable {
    /// Default configuration file name
    static let defaultFileName = ".scout-loc.json"

    /// LOC metrics to process with optional per-metric commits
    let metrics: [LOCMetric]?

    /// Git operations configuration (file layer - all fields optional)
    let git: GitFileConfig?

    /// Initialize configuration directly (for testing)
    init(metrics: [LOCMetric]?, git: GitFileConfig? = nil) {
        self.metrics = metrics
        self.git = git
    }

    /// Initialize configuration from JSON file at given path, or default path if nil.
    /// Returns nil if no config file exists.
    ///
    /// - Parameters:
    ///   - configPath: Optional path to JSON file. If nil, looks for default file
    /// - Throws: `LOCCLIConfigError` if JSON file is malformed or missing required fields
    init?(configPath: String?) async throws {
        let path = configPath ?? Self.defaultFileName
        guard FileManager.default.fileExists(atPath: path) else {
            if configPath != nil {
                throw LOCCLIConfigError.missingFile(path: path)
            }
            return nil
        }
        try await self.init(configFilePath: FilePath(path))
    }

    /// Initialize configuration from JSON file.
    ///
    /// - Parameters:
    ///   - configFilePath: Path to JSON file with CountLOC configuration (required)
    /// - Throws: `LOCCLIConfigError` if JSON file is malformed or missing required fields
    init(configFilePath: FilePath) async throws {
        let configPathString = configFilePath.string

        let configFileManager = FileManager.default
        guard configFileManager.fileExists(atPath: configPathString) else {
            throw LOCCLIConfigError.missingFile(path: configPathString)
        }

        do {
            let fileURL = URL(filePath: configPathString)
            let fileData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let variables = try decoder.decode(Variables.self, from: fileData)
            self.metrics = variables.metrics
            self.git = variables.git
        } catch let decodingError as DecodingError {
            throw LOCCLIConfigError.invalidJSON(
                path: configPathString,
                reason: decodingError.localizedDescription
            )
        } catch {
            throw LOCCLIConfigError.readFailed(
                path: configPathString,
                reason: error.localizedDescription
            )
        }
    }

    private struct Variables: Decodable {
        let metrics: [LOCMetric]?
        let git: GitFileConfig?
    }
}

/// Errors related to CountLOC configuration.
enum LOCCLIConfigError: Error {
    case missingFile(path: String)
    case invalidJSON(path: String, reason: String)
    case readFailed(path: String, reason: String)
}

extension LOCCLIConfigError: LocalizedError {
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
