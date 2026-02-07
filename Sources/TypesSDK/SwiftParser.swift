import Common
import Foundation
import SourceKittenFramework

/// Parsed Swift code object with name and inheritance information.
public struct ObjectFromCode: Sendable {
    /// Simple type name (e.g., "AddToCartEvent")
    public let name: String
    /// Full qualified type name including parent types (e.g., "Analytics.AddToCartEvent")
    public let fullName: String
    /// Path to the file containing this type
    public let filePath: String
    public let inheritedTypes: [String]

    public init(name: String, fullName: String, filePath: String, inheritedTypes: [String]) {
        self.name = name
        self.fullName = fullName
        self.filePath = filePath
        self.inheritedTypes = inheritedTypes
    }
}

/// Parser for Swift source files using SourceKitten.
struct SwiftParser {
    /// Parses a Swift source file and extracts type definitions.
    /// - Parameter swiftFile: URL to the Swift source file
    /// - Returns: Array of parsed code objects
    func parseFile(from swiftFile: URL) throws -> [ObjectFromCode] {
        guard let file = File(path: swiftFile.path(percentEncoded: false)) else { return [] }
        let structure = try Structure(file: file)
        guard let substructure = structure.dictionary["key.substructure"] as? [[String: Any]] else {
            throw ParseError.invalidStructure(key: "key.substructure")
        }

        let filePath = swiftFile.path(percentEncoded: false)
        return parseSubstructure(substructure, parentPath: nil, filePath: filePath)
    }

    /// Recursively parses substructure to extract all type definitions including nested types.
    /// - Parameters:
    ///   - substructure: Array of AST dictionaries to parse
    ///   - parentPath: Dot-separated path of parent type names (e.g., "Analytics" for nested types)
    ///   - filePath: Path to the source file
    private func parseSubstructure(
        _ substructure: [[String: Any]],
        parentPath: String?,
        filePath: String
    ) -> [ObjectFromCode] {
        var results: [ObjectFromCode] = []

        for item in substructure {
            let kind = item["key.kind"] as? String
            let name = item["key.name"] as? String

            // Check if this is a type definition (class, struct, enum, protocol)
            let isTypeDefinition = kind.map { isTypeKind($0) } ?? false

            if isTypeDefinition, let name = name {
                let inheritedTypes = item["key.inheritedtypes"] as? [[String: String]]
                let inheritances = inheritedTypes?.compactMap { $0["key.name"] } ?? []
                let fullName = parentPath.map { "\($0).\(name)" } ?? name

                // Only add to results if there are inherited types (existing behavior)
                if !inheritances.isEmpty {
                    results.append(
                        ObjectFromCode(
                            name: name,
                            fullName: fullName,
                            filePath: filePath,
                            inheritedTypes: inheritances
                        )
                    )
                }

                // Recursively parse nested substructure with updated parent path
                if let nestedSubstructure = item["key.substructure"] as? [[String: Any]] {
                    results.append(
                        contentsOf: parseSubstructure(
                            nestedSubstructure,
                            parentPath: fullName,
                            filePath: filePath
                        )
                    )
                }
            } else if kind == "source.lang.swift.decl.extension", let name = name {
                // Extensions update parent path to their extended type
                if let nestedSubstructure = item["key.substructure"] as? [[String: Any]] {
                    let extendedPath = parentPath.map { "\($0).\(name)" } ?? name
                    results.append(
                        contentsOf: parseSubstructure(
                            nestedSubstructure,
                            parentPath: extendedPath,
                            filePath: filePath
                        )
                    )
                }
            } else {
                // Recursively parse nested substructure without updating parent path
                if let nestedSubstructure = item["key.substructure"] as? [[String: Any]] {
                    results.append(
                        contentsOf: parseSubstructure(
                            nestedSubstructure,
                            parentPath: parentPath,
                            filePath: filePath
                        )
                    )
                }
            }
        }

        return results
    }

    /// Returns true if the kind represents a type definition (class, struct, enum, protocol).
    private func isTypeKind(_ kind: String) -> Bool {
        kind == "source.lang.swift.decl.class"
            || kind == "source.lang.swift.decl.struct"
            || kind == "source.lang.swift.decl.enum"
            || kind == "source.lang.swift.decl.protocol"
    }

    /// Checks if a code object inherits from the specified base type.
    /// - Parameters:
    ///   - objectFromCode: The object to check
    ///   - inheritance: Base type pattern (use `<*>` suffix for generic matching)
    ///   - allObjects: All parsed objects for indirect inheritance lookup
    /// - Returns: `true` if the object inherits from the base type
    func isInherited(
        objectFromCode: ObjectFromCode,
        from inheritance: String,
        allObjects: [ObjectFromCode]
    ) -> Bool {
        // Check direct inheritance (including generic types like "JsonAsyncRequest<SomeType>")
        if objectFromCode.inheritedTypes.contains(where: { inheritedType in
            matchesBaseType(inheritedType, baseType: inheritance)
        }) {
            return true
        }

        // Check indirect inheritance through ALL parent types (not just first)
        return objectFromCode.inheritedTypes.contains { className in
            // Extract base type name from generic type (e.g., "JsonAsyncRequest<DTO>" -> "JsonAsyncRequest")
            let baseTypeName = extractBaseTypeName(from: className)

            // Check if any parent object matches
            guard let parentObject = allObjects.first(where: { $0.name == baseTypeName }) else {
                return false
            }
            return isInherited(
                objectFromCode: parentObject,
                from: inheritance,
                allObjects: allObjects
            )
        }
    }

    /// Checks if an inherited type matches the base type pattern.
    /// - `JsonAsyncRequest` matches only exact `JsonAsyncRequest` (no generics)
    /// - `JsonAsyncRequest<*>` matches `JsonAsyncRequest<T>`, `JsonAsyncRequest<SomeDTO>`, etc.
    private func matchesBaseType(_ inheritedType: String, baseType: String) -> Bool {
        // Check for wildcard pattern: "JsonAsyncRequest<*>"
        if baseType.hasSuffix("<*>") {
            let baseWithoutWildcard = String(baseType.dropLast(3))
            // Match any generic variant: "JsonAsyncRequest<Something>"
            return inheritedType.hasPrefix("\(baseWithoutWildcard)<")
        }
        // Exact match only (no implicit generic matching)
        return inheritedType == baseType
    }

    /// Extracts base type name from a generic type string.
    /// For example, "JsonAsyncRequest<SomeDTO>" -> "JsonAsyncRequest"
    private func extractBaseTypeName(from typeName: String) -> String {
        if let genericStartIndex = typeName.firstIndex(of: "<") {
            return String(typeName[..<genericStartIndex])
        }
        return typeName
    }
}
