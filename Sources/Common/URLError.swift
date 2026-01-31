import Foundation

public enum URLError: Swift.Error {
  case emptyURL(parameter: String)
  case invalidURL(parameter: String, value: String)

  public var localizedDescription: String {
    switch self {
    case .emptyURL(let parameter):
      return "URL parameter '\(parameter)' cannot be empty"
    case .invalidURL(let parameter, let value):
      return "Invalid URL for parameter '\(parameter)': '\(value)'"
    }
  }
}
