/// Declaration kind of a parsed Swift type.
enum TypeKind: Sendable, Equatable {
    case classType
    case structType
    case enumType
    case protocolType
    case typealiasType

    /// Value types (struct, enum) cannot inherit from a class.
    var isValueType: Bool {
        self == .structType || self == .enumType
    }
}

/// Parsed Swift code object with name and inheritance information.
struct ObjectFromCode: Sendable {
    /// Simple type name (e.g., "AddToCartEvent")
    let name: String
    /// Full qualified type name including parent types (e.g., "Analytics.AddToCartEvent")
    let fullName: String
    /// Path to the file containing this type
    let filePath: String
    let inheritedTypes: [String]
    /// Declaration kind (class, struct, enum, protocol, typealias).
    let kind: TypeKind

    /// Whether this object represents a typealias rather than a concrete type definition.
    var isTypealias: Bool { kind == .typealiasType }

    /// Whether this object is nested inside another type (e.g. `Component.View`),
    /// and therefore only reachable through its qualified name.
    var isNested: Bool { fullName != name }

    init(
        name: String,
        fullName: String,
        filePath: String,
        inheritedTypes: [String],
        kind: TypeKind
    ) {
        self.name = name
        self.fullName = fullName
        self.filePath = filePath
        self.inheritedTypes = inheritedTypes
        self.kind = kind
    }
}
