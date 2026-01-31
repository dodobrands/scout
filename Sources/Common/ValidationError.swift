import Foundation

public enum ValidationError: Error {
    case invalidURL(parameter: String, value: String)
    case invalidEnum(rawValue: String, type: String)
}

extension ValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let parameter, let value):
            return "Invalid URL for parameter '\(parameter)': \(value)"
        case .invalidEnum(let rawValue, let type):
            return "Invalid enum value '\(rawValue)' for type '\(type)'"
        }
    }
}
