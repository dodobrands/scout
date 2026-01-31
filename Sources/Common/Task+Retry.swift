import Foundation

extension Task where Failure == Error {
  @discardableResult
  /// Create a retriable Task with max retry count
  /// - Parameters:
  ///   - priority: (Optional) Priority of the task
  ///   - maxRetryCount: max number of retries, default is 3
  ///   - retryDelay: delay between retries in seconds, default is 1
  ///   - operation: operation that needs to do which receive a `numberOfRetried` as it parameters
  /// - Returns: Retriable task
  public static func retrying(
    priority: TaskPriority? = nil,
    maxRetryCount: Int = 3,
    retryDelay: TimeInterval = 1,
    operation: @Sendable @escaping () async throws -> Success
  ) -> Task {
    Task(priority: priority) {
      for _ in 0..<maxRetryCount {
        try Task<Never, Never>.checkCancellation()
        do {
          return try await operation()
        } catch {
          try await Task<Never, Never>.sleep(for: .seconds(retryDelay))
          continue
        }
      }
      try Task<Never, Never>.checkCancellation()
      return try await operation()
    }
  }
}

extension Sequence {
  public func asyncForEach(
    _ operation: @Sendable @escaping (Element) async throws -> Void
  ) async rethrows {
    for element in self {
      try await operation(element)
    }
  }
}
