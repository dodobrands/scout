#if canImport(os)
    import os
#endif

/// Signpost intervals around analysis phases, for Instruments (Points of Interest).
/// Record with `xctrace record --template 'Time Profiler' --launch -- scout …`.
/// Signposts cost next to nothing when nothing records them; on Linux they are no-ops.
package enum Signposts {
    #if canImport(os)
        private static let signposter = OSSignposter(
            subsystem: "com.dodobrands.scout",
            category: .pointsOfInterest
        )
    #endif

    package static func interval<T>(
        _ name: StaticString,
        _ detail: String = "",
        _ body: () throws -> T
    ) rethrows -> T {
        #if canImport(os)
            let state = signposter.beginInterval(
                name,
                id: signposter.makeSignpostID(),
                "\(detail, privacy: .public)"
            )
            defer { signposter.endInterval(name, state) }
        #endif
        return try body()
    }

    // `isolation` lets the body run on the caller's actor; it is never read directly.
    // periphery:ignore:parameters isolation
    package static func interval<T>(
        _ name: StaticString,
        _ detail: String = "",
        isolation: isolated (any Actor)? = #isolation,
        _ body: () async throws -> T
    ) async rethrows -> T {
        #if canImport(os)
            let state = signposter.beginInterval(
                name,
                id: signposter.makeSignpostID(),
                "\(detail, privacy: .public)"
            )
            defer { signposter.endInterval(name, state) }
        #endif
        return try await body()
    }
}
