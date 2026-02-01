import Foundation

package enum URLError: Swift.Error, LocalizedError {
    case invalidURL(parameter: String, value: String)

    package var errorDescription: String? {
        switch self {
        case .invalidURL(let parameter, let value):
            return "Invalid URL for parameter '\(parameter)': '\(value)'"
        }
    }
}
