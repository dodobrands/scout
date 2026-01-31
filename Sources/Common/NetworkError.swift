import Foundation

public enum NetworkError: Error {
  case invalidURLComponents(url: URL)
  case cannotBuildURL(from: URLComponents)
  case missingURLComponent(component: String)
}

extension NetworkError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .invalidURLComponents(let url):
      return "Cannot create URLComponents from URL: \(url.absoluteString)"
    case .cannotBuildURL(from: let components):
      return "Cannot build URL from URLComponents: \(components)"
    case .missingURLComponent(let component):
      return "Missing required URL component: \(component)"
    }
  }
}
