extension SwiftParser {
    /// Lookup tables over the analysis pool, built once per commit so that resolving a parent
    /// is a dictionary lookup rather than a scan of every source, package and SDK type.
    /// Buckets keep the pool's order, so the first match still wins: sources, then package
    /// checkouts, then the SDK.
    struct ObjectIndex: Sendable {
        let byName: [String: [ObjectFromCode]]
        let byFullName: [String: [ObjectFromCode]]

        init(_ objects: [ObjectFromCode]) {
            byName = Dictionary(grouping: objects, by: \.name)
            byFullName = Dictionary(grouping: objects, by: \.fullName)
        }
    }
}
