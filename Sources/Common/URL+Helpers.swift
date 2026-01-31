import Foundation

extension URLRequest {
    public func appendingHeaders(_ headers: [String: String]) -> Self {
        var request = self
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }

    public func withMethod(_ method: String) -> Self {
        var request = self
        request.httpMethod = method
        return request
    }

    /// Sets the HTTP method for the request.
    ///
    /// - Parameter method: HTTP method enum value
    /// - Returns: Modified request with the specified HTTP method
    public func withMethod(_ method: HTTPMethod) -> Self {
        withMethod(method.rawValue)
    }

    public func withTimeout(_ timeout: TimeInterval) -> Self {
        var request = self
        request.timeoutInterval = timeout
        return request
    }

    public func withBody(_ body: Encodable) throws -> Self {
        var request = self
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }
}

extension URLComponents {
    public func appendingPath(_ path: String) -> Self {
        var components = self
        components.path = components.path.appending(path.prependingSlashIfNeeded)
        return components
    }

    public func appendingQueryItems(_ items: [URLQueryItem]) -> Self {
        var components = self
        components.queryItems = items
        return components
    }
}

extension URLRequest {
    public func appendingBearerAuthHeader(_ token: String) -> Self {
        appendingHeaders(
            ["Authorization": "Bearer \(token)"]
        )
    }

    public var appendingApplicationJsonContentTypeHeader: Self {
        appendingHeaders(["Content-Type": "application/json"])
    }
}

extension String {
    var prependingSlashIfNeeded: String {
        hasPrefix("/") ? self : "/" + self
    }
}

extension URLResponse {
    public enum Error: Swift.Error {
        case responseIsNotHTTPURLResponse(type: String)
    }
}
