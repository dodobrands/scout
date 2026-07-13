/// Provides class-inheritance hierarchy for types that live outside the analyzed source
/// (e.g. UIKit's `UICollectionViewCell : UIView`), so inheritance chains can be resolved
/// past the source boundary.
protocol ExternalHierarchyProvider: Sendable {
    /// Returns external `subclass -> [superclass]` class-inheritance edges for the given
    /// imported modules, expressed as `ObjectFromCode` entries (kind `.classType`) that can
    /// be merged into the parsed-source pool.
    /// - Parameter modules: Module names imported by the analyzed source (e.g. `["UIKit"]`).
    func externalObjects(forModules modules: Set<String>) async throws -> [ObjectFromCode]
}
