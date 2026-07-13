@testable import Types

/// Test double for `ExternalHierarchyProvider` that returns a fixed set of
/// `subclass -> superclass` class-inheritance edges without touching the SDK.
struct StubHierarchyProvider: ExternalHierarchyProvider {
    /// Maps a subclass name to its direct superclass name.
    var edges: [String: String] = [:]

    func externalObjects(forModules modules: Set<String>) async throws -> [ObjectFromCode] {
        edges.map { subclass, superclass in
            ObjectFromCode(
                name: subclass,
                fullName: subclass,
                filePath: "<stub>",
                inheritedTypes: [superclass],
                kind: .classType
            )
        }
    }
}
