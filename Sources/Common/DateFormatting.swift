import Foundation

/// Shared ISO 8601 date formatter (UTC).
///
/// Reuse this instance instead of creating new `ISO8601DateFormatter` objects.
/// Thread-safe for concurrent read access since format options are set once at initialization.
nonisolated(unsafe) package let iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()
