import Foundation

package enum ParseError: Error {
    case invalidJSON(data: Data, underlyingError: Error?, responseString: String?)
    case invalidDateFormat(string: String, format: String)
    case missingKey(key: String, in: [String: Sendable])
    case invalidType(key: String, expected: String, actual: String)
    case invalidStructure(key: String)
}

extension ParseError: LocalizedError {
    package var errorDescription: String? {
        switch self {
        case .invalidJSON(let data, let underlyingError, let responseString):
            var description = "Invalid JSON data (size: \(data.count) bytes)"
            if let error = underlyingError {
                description += ". Underlying error: \(error.localizedDescription)"
                if let nsError = error as NSError? {
                    description += " (domain: \(nsError.domain), code: \(nsError.code))"
                }
            }
            if let response = responseString {
                let preview = String(response.prefix(500))
                description += ". Response preview: \(preview)"
            }
            return description
        case .invalidDateFormat(let string, let format):
            return "Invalid date format. String: '\(string)', expected format: '\(format)'"
        case .missingKey(let key, _):
            return "Missing required key '\(key)' in dictionary"
        case .invalidType(let key, let expected, let actual):
            return "Invalid type for key '\(key)': expected '\(expected)', got '\(actual)'"
        case .invalidStructure(let key):
            return "Invalid structure: missing or invalid '\(key)'"
        }
    }
}
