import Foundation
import Synchronization

/// Thread-safe ISO 8601 date formatter (UTC).
///
/// Wraps `ISO8601DateFormatter` in a `Mutex` to ensure safe concurrent access.
package final class ISO8601UTCDateFormatter: Sendable {
    private let mutex: Mutex<ISO8601DateFormatter>

    package init() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        mutex = Mutex(formatter)
    }

    package func string(from date: Date) -> String {
        mutex.withLock { $0.string(from: date) }
    }

    package func date(from string: String) -> Date? {
        mutex.withLock { $0.date(from: string) }
    }

    /// Shared instance for use across the app.
    package static let utc = ISO8601UTCDateFormatter()
}
