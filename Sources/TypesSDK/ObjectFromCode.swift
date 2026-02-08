/// Parsed Swift code object with name and inheritance information.
struct ObjectFromCode: Sendable {
    /// Simple type name (e.g., "AddToCartEvent")
    let name: String
    /// Full qualified type name including parent types (e.g., "Analytics.AddToCartEvent")
    let fullName: String
    /// Path to the file containing this type
    let filePath: String
    let inheritedTypes: [String]
}
