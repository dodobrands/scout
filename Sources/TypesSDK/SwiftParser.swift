import Common
import Foundation
import SourceKittenFramework

/// Parsed Swift code object with name and inheritance information.
public struct ObjectFromCode: Sendable {
    public let name: String
    public let inheritedTypes: [String]

    public init(name: String, inheritedTypes: [String]) {
        self.name = name
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

        let parsedStructs: [ObjectFromCode] = substructure.compactMap { item in
            guard
                let name = item["key.name"] as? String,
                let inheritedTypes = item["key.inheritedtypes"] as? [[String: String]]
            else { return nil }

            let inheritances = inheritedTypes.compactMap { $0["key.name"] }

            return ObjectFromCode(
                name: name,
                inheritedTypes: inheritances
            )
        }

        return parsedStructs
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

        // Check indirect inheritance through parent types
        let child = objectFromCode.inheritedTypes.first { className in
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

        return child != nil
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
