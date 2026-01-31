import Foundation
import Logging

extension Logger.Metadata {
    /// Merges data from a dictionary [String: Any] into Logger.Metadata.
    /// Converts values to appropriate Logger.Metadata.Value types:
    /// - String arrays are joined with space separator
    /// - Other values are converted to strings
    ///
    /// - Parameter dictionary: Dictionary with string keys and any values
    /// - Parameter uniquingKeysWith: Closure to resolve conflicts when keys overlap.
    ///   Defaults to keeping existing values (old value wins).
    public mutating func merge(
        from dictionary: [String: Any],
        uniquingKeysWith: (Logger.Metadata.Value, Logger.Metadata.Value) -> Logger.Metadata.Value =
            { old, _ in old }
    ) {
        let dictionaryMetadata: Logger.Metadata = Dictionary(
            uniqueKeysWithValues: dictionary.map { key, value in
                let stringValue: String
                if let array = value as? [String] {
                    stringValue = array.joined(separator: " ")
                } else {
                    stringValue = "\(value)"
                }
                return (key, .string(stringValue))
            }
        )
        merge(dictionaryMetadata, uniquingKeysWith: uniquingKeysWith)
    }
}
