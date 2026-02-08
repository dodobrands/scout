import Common
import Foundation
import SystemPackage

/// A single pattern metric configuration with optional per-metric commits.
struct PatternMetric: Sendable, Decodable {
    /// Pattern to search for (e.g., "// TODO:")
    let pattern: String

    /// Commits to analyze for this pattern. If nil, uses HEAD. If empty, skips this metric.
    let commits: [String]?
}

/// Configuration for Search tool loaded from JSON file.
struct PatternCLIConfig: Sendable {
    /// Default configuration file name
    static let defaultFileName = ".scout-pattern.json"

    /// Metrics to analyze with optional per-metric commits
    let metrics: [PatternMetric]?

    /// File extensions to search in (e.g., ["swift", "m"])
    let extensions: [String]?

    /// Git operations configuration (file layer - all fields optional)
    let git: GitFileConfig?

    /// Initialize configuration directly (for testing)
    init(
        metrics: [PatternMetric]?,
        extensions: [String]? = nil,
        git: GitFileConfig? = nil
    ) {
        self.metrics = metrics
        self.extensions = extensions
        self.git = git
    }

    /// Initialize configuration from JSON file at given path, or default path if nil.
    /// Returns nil if no config file exists.
    ///
    /// - Parameters:
    ///   - configPath: Optional path to JSON file. If nil, looks for default file
    /// - Throws: `PatternCLIConfigError` if JSON file is malformed or missing required fields
    init?(configPath: String?) async throws {
        let path = configPath ?? Self.defaultFileName
        guard FileManager.default.fileExists(atPath: path) else {
            if configPath != nil {
                throw PatternCLIConfigError.missingFile(path: path)
            }
            return nil
        }
        try await self.init(configFilePath: FilePath(path))
    }

    /// Initialize configuration from JSON file.
    ///
    /// - Parameters:
    ///   - configFilePath: Path to JSON file with Search configuration (required)
    /// - Throws: `PatternCLIConfigError` if JSON file is malformed or missing required fields
    init(configFilePath: FilePath) async throws {
        let configPathString = configFilePath.string

        let configFileManager = FileManager.default
        guard configFileManager.fileExists(atPath: configPathString) else {
            throw PatternCLIConfigError.missingFile(path: configPathString)
        }

        do {
            let fileURL = URL(filePath: configPathString)
            let fileData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let variables = try decoder.decode(Variables.self, from: fileData)
            self.metrics = variables.metrics
            self.extensions = variables.extensions
            self.git = variables.git
        } catch let decodingError as DecodingError {
            throw PatternCLIConfigError.invalidJSON(
                path: configPathString,
                reason: decodingError.localizedDescription
            )
        } catch {
            throw PatternCLIConfigError.readFailed(
                path: configPathString,
                reason: error.localizedDescription
            )
        }
    }

    private struct Variables: Decodable {
        let metrics: [PatternMetric]?
        let extensions: [String]?
        let git: GitFileConfig?
    }
}

/// Errors related to Search configuration.
enum PatternCLIConfigError: Error {
    case missingFile(path: String)
    case invalidJSON(path: String, reason: String)
    case readFailed(path: String, reason: String)
}

extension PatternCLIConfigError: LocalizedError {
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
