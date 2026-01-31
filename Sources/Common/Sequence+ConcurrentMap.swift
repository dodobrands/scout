import Foundation

extension Sequence {
  public func asyncMap<T>(
    _ transform: @Sendable (Element) async throws -> T
  ) async rethrows -> [T] {
    var values = [T]()

    for element in self {
      try await values.append(transform(element))
    }

    return values
  }

  public func concurrentMap<T: Sendable>(
    _ transform: @Sendable @escaping (Element) async throws -> T
  ) async throws -> [T] where Element: Sendable {
    try await map { element in
      Task {
        try await transform(element)
      }
    }.asyncMap { task in
      try await task.value
    }
  }
}
