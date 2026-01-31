import Common
import Foundation
import SourceKittenFramework

public class CodeReader {
    public init() {}

    public func parseFile(
        from swiftFile: URL
    ) throws -> [ObjectFromCode] {
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

    public func readImports(from swiftFile: URL) throws -> Set<String> {
        let fileContent = try String(
            contentsOfFile: swiftFile.path(percentEncoded: false),
            encoding: .utf8
        )

        // Define a regular expression to match import statements
        let regex = try NSRegularExpression(
            pattern: "^\\s*(?:@testable\\s)?import\\s+([A-Za-z0-9_]+)",
            options: [.anchorsMatchLines]
        )

        // Find matches in the file content
        let matches = regex.matches(
            in: fileContent,
            options: [],
            range: NSRange(location: 0, length: fileContent.utf16.count)
        )

        // Extract import statements
        let importsList = matches.compactMap { match -> String? in
            guard let range = Range(match.range(at: 1), in: fileContent) else { return nil }
            return String(fileContent[range])
        }

        return Set(importsList)
    }

    public func isInherited(
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

            // First check if the base type itself matches (for direct generic inheritance)
            if matchesBaseType(baseTypeName, baseType: inheritance) {
                return true
            }

            // Then check if any parent object matches
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

    /// Checks if an inherited type matches the base type, handling generic types.
    /// For example, "JsonAsyncRequest<SomeDTO>" matches "JsonAsyncRequest"
    private func matchesBaseType(_ inheritedType: String, baseType: String) -> Bool {
        // Exact match
        if inheritedType == baseType {
            return true
        }
        // Generic type match: "JsonAsyncRequest<Something>" matches "JsonAsyncRequest"
        if inheritedType.hasPrefix("\(baseType)<") {
            return true
        }
        return false
    }

    /// Extracts base type name from a generic type string.
    /// For example, "JsonAsyncRequest<SomeDTO>" -> "JsonAsyncRequest"
    private func extractBaseTypeName(from typeName: String) -> String {
        if let genericStartIndex = typeName.firstIndex(of: "<") {
            return String(typeName[..<genericStartIndex])
        }
        return typeName
    }

    public func linesOfCode(at path: URL, language: String) async throws -> String {
        let clocOutput = try await Shell.execute(
            "cloc",
            arguments: ["--quiet", "--include-lang=\(language)", path.path(percentEncoded: false)]
        )
        let lines = clocOutput.split(separator: "\n")
        for line in lines {
            if line.contains(language) {
                let parts = line.split(whereSeparator: { $0.isWhitespace })
                if parts.count >= 5 {
                    return String(parts[4])
                }
            }
        }
        return "0"
    }
}

public struct ObjectFromCode {
    public let name: String
    public let inheritedTypes: [String]
    
    public init(name: String, inheritedTypes: [String]) {
        self.name = name
        self.inheritedTypes = inheritedTypes
    }
}
