/// Parsed Swift code object with name and inheritance information.
struct ObjectFromCode: Sendable {
    /// Simple type name (e.g., "AddToCartEvent")
    let name: String
    /// Full qualified type name including parent types (e.g., "Analytics.AddToCartEvent")
    let fullName: String
    /// Path to the file containing this type
    let filePath: String
    let inheritedTypes: [String]
    /// Whether this object represents a typealias rather than a concrete type definition.
    let isTypealias: Bool

    init(
        name: String,
        fullName: String,
        filePath: String,
        inheritedTypes: [String],
        isTypealias: Bool = false
    ) {
        self.name = name
        self.fullName = fullName
        self.filePath = filePath
        self.inheritedTypes = inheritedTypes
        self.isTypealias = isTypealias
    }
}
