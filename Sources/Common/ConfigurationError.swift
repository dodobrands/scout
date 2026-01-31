import Foundation

public enum ConfigurationError: Error {
  case missingKaitenToken
  case versionMismatch(ios: String, android: String)
}

extension ConfigurationError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .missingKaitenToken:
      return
        "Missing KAITEN_ROLLOUT_API_KEY environment variable. Add KAITEN_ROLLOUT_API_KEY secret into ENV"
    case .versionMismatch(let ios, let android):
      return
        "Different platform versions: iOS=\(ios), Android=\(android). Versions must match."
    }
  }
}
