import Foundation
import Logging

/// Writer that saves results incrementally to JSON file after each append.
/// This prevents data loss if the process is interrupted (e.g., CI timeout).
public final class IncrementalJSONWriter<T: Encodable> {
    private let path: String
    private var results: [T] = []
    private let logger = Logger(label: "scout.IncrementalJSONWriter")

    public init(path: String) {
        self.path = path
    }

    /// Appends a result and immediately saves to file.
    public func append(_ result: T) throws {
        results.append(result)
        try save()
        logger.debug(
            "Results saved incrementally",
            metadata: ["path": "\(path)", "count": "\(results.count)"]
        )
    }

    /// Returns all accumulated results.
    public var allResults: [T] {
        results
    }

    private func save() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(results)
        try data.write(to: URL(fileURLWithPath: path))
    }
}
