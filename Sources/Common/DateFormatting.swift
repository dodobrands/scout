import Foundation

extension ISO8601DateFormatter {
    /// Shared ISO 8601 date formatter (UTC, `.withInternetDateTime`).
    ///
    /// Reuse this instance instead of creating new `ISO8601DateFormatter` objects.
    nonisolated(unsafe) package static let utc: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
