import Foundation
import SystemPackage

/// Configuration for CountTypes tool loaded from JSON file.
public struct CountTypesConfig: Sendable {
  /// Types to count (e.g., ["UIView", "UIViewController", "View", "XCTestCase"])
  public let types: [String]

  /// Initialize configuration directly (for testing)
  public init(types: [String]) {
    self.types = types
  }

  /// Initialize configuration from JSON file.
  ///
  /// - Parameters:
  ///   - configFilePath: Path to JSON file with CountTypes configuration (required)
  /// - Throws: `CountTypesConfigError` if JSON file is malformed or missing required fields
  public init(configFilePath: FilePath) async throws {
    let configPathString = configFilePath.string

    let configFileManager = FileManager.default
    guard configFileManager.fileExists(atPath: configPathString) else {
      throw CountTypesConfigError.missingFile(path: configPathString)
    }

    do {
      let fileURL = URL(filePath: configPathString)
      let fileData = try Data(contentsOf: fileURL)
      let decoder = JSONDecoder()
      let variables = try decoder.decode(Variables.self, from: fileData)
      self.types = variables.types
    } catch let decodingError as DecodingError {
      throw CountTypesConfigError.invalidJSON(
        path: configPathString,
        reason: decodingError.localizedDescription
      )
    } catch {
      throw CountTypesConfigError.readFailed(
        path: configPathString,
        reason: error.localizedDescription
      )
    }
  }

  private struct Variables: Codable {
    let types: [String]
  }
}

/// Errors related to CountTypes configuration.
public enum CountTypesConfigError: Error {
  case missingFile(path: String)
  case invalidJSON(path: String, reason: String)
  case readFailed(path: String, reason: String)
}

extension CountTypesConfigError: LocalizedError {
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
