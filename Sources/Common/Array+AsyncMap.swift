import Foundation

extension Array {
    public func asyncMap<T>(_ transform: @escaping (Element) async throws -> T) async rethrows
        -> [T]
    {
        var results: [T] = []
        for element in self {
            try await results.append(transform(element))
        }
        return results
    }

    public func asyncFlatMap<T>(_ transform: @escaping (Element) async throws -> [T]) async rethrows
        -> [T]
    {
        var results: [T] = []
        for element in self {
            try await results.append(contentsOf: transform(element))
        }
        return results
    }
}
