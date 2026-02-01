import Foundation

extension Sequence {
    package func concurrentMap<T: Sendable>(
        _ transform: @Sendable @escaping (Element) async throws -> T
    ) async throws -> [T] where Element: Sendable {
        var values = [T]()
        for task in map({ element in Task { try await transform(element) } }) {
            try await values.append(task.value)
        }
        return values
    }
}
