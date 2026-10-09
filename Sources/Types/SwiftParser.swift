import Foundation
import SwiftParser
import SwiftSyntax

/// Parser for Swift source files using swift-syntax.
struct SwiftParser {
    /// Parses Swift source files in parallel.
    /// - Returns: Parsed objects in file order, so the first declaration of a name stays first.
    func parseFiles(_ files: [URL]) async -> [ObjectFromCode] {
        await withTaskGroup(of: (Int, [ObjectFromCode]).self) { group in
            for (index, file) in files.enumerated() {
                group.addTask { (index, parseFile(from: file)) }
            }
            var parsed = [[ObjectFromCode]](repeating: [], count: files.count)
            for await (index, objects) in group {
                parsed[index] = objects
            }
            return parsed.flatMap { $0 }
        }
    }

    /// Parses a Swift source file and extracts type definitions.
    /// A file that cannot be read as UTF-8 yields no objects.
    /// - Parameter swiftFile: URL to the Swift source file
    /// - Returns: Array of parsed code objects
    func parseFile(from swiftFile: URL) -> [ObjectFromCode] {
        let filePath = swiftFile.path(percentEncoded: false)
        guard let data = FileManager.default.contents(atPath: filePath),
            let source = String(data: data, encoding: .utf8)
        else { return [] }
        let collector = DeclarationCollector(filePath: filePath)
        // The default nesting limit gives up on deeply nested expressions (generated code,
        // hand-built syntax trees) and leaves the rest of the file unparsed.
        var parser = Parser(source, maximumNestingLevel: 2048)
        collector.walk(SourceFileSyntax.parse(from: &parser))
        return collector.objects
    }

    /// Checks if a code object inherits from the specified base type.
    /// - Parameters:
    ///   - objectFromCode: The object to check
    ///   - inheritance: Base type pattern (use `<*>` suffix for generic matching)
    ///   - index: All parsed objects, indexed for indirect inheritance lookup
    /// - Returns: `true` if the object inherits from the base type
    func isInherited(
        objectFromCode: ObjectFromCode,
        from inheritance: String,
        index: ObjectIndex
    ) -> Bool {
        isInherited(
            objectFromCode: objectFromCode,
            from: inheritance,
            index: index,
            originIsValueType: objectFromCode.kind.isValueType,
            path: []
        )
    }

    /// - Parameter originIsValueType: Whether the type that started the lookup is a value type
    ///   (struct/enum). Value types conform to protocols but cannot subclass a class, so the
    ///   chain must never pass into a class node when the origin is a value type.
    /// - Parameter path: Objects already on the lookup path. A subclass may share its name
    ///   with a superclass from another module (`class A: Module.A`), so the chain is guarded
    ///   against resolving back into a node it has already passed.
    private func isInherited(
        objectFromCode: ObjectFromCode,
        from inheritance: String,
        index: ObjectIndex,
        originIsValueType: Bool,
        path: Set<String>
    ) -> Bool {
        var path = path
        guard path.insert(objectFromCode.identity).inserted else { return false }

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

            guard
                let parentObject = resolveParent(
                    named: baseTypeName,
                    index: index,
                    excluding: path
                )
            else {
                return false
            }

            // A value type (struct/enum) cannot subclass a class. If the origin is a value type
            // and the chain reaches a class node, this is a protocol conformance being misread
            // as class inheritance — reject it.
            if originIsValueType && parentObject.kind == .classType {
                return false
            }

            return isInherited(
                objectFromCode: parentObject,
                from: inheritance,
                index: index,
                originIsValueType: originIsValueType,
                path: path
            )
        }
    }

    /// Finds the declaration an inherited-type reference points to.
    ///
    /// - `Outer.Inner` resolves a nested type by its full name first.
    /// - Otherwise the reference resolves by its last component, so a module-qualified
    ///   `Module.Widget` finds `Widget`. Among several `Widget`s, one whose file lives under a
    ///   `Module` directory is preferred.
    /// - A nested (member) typealias such as `Component.View` is only reachable through its
    ///   qualified name, so it must not resolve a bare reference — otherwise a `struct S: View`
    ///   conformance to a protocol would be misrouted into that typealias's target hierarchy.
    private func resolveParent(
        named typeName: String,
        index: ObjectIndex,
        excluding path: Set<String>
    ) -> ObjectFromCode? {
        let isUnvisited = { (candidate: ObjectFromCode) in !path.contains(candidate.identity) }

        if typeName.contains("."),
            let nested = index.byFullName[typeName]?.first(where: isUnvisited)
        {
            return nested
        }

        let components = typeName.split(separator: ".")
        guard let name = components.last.map(String.init) else { return nil }
        let candidates = (index.byName[name] ?? []).lazy.filter { candidate in
            !(candidate.isTypealias && candidate.isNested) && isUnvisited(candidate)
        }

        if components.count > 1, let module = components.first,
            let fromModule = index.byModuleQualifiedName["\(module).\(name)"]?.first(
                where: isUnvisited
            )
        {
            return fromModule
        }

        return candidates.first
    }

    /// Checks if an inherited type matches the base type pattern.
    /// - `JsonAsyncRequest` matches only exact `JsonAsyncRequest` (no generics)
    /// - `JsonAsyncRequest<*>` matches `JsonAsyncRequest<T>`, `JsonAsyncRequest<SomeDTO>`, etc.
    /// - `Widget` matches `Widget` or `Module.Widget` or `Module.Nested.Widget`
    private func matchesBaseType(_ inheritedType: String, baseType: String) -> Bool {
        // Check for wildcard pattern: "JsonAsyncRequest<*>"
        if baseType.hasSuffix("<*>") {
            let baseWithoutWildcard = String(baseType.dropLast(3))
            // Match any generic variant: "JsonAsyncRequest<Something>"
            return inheritedType.hasPrefix("\(baseWithoutWildcard)<")
                || inheritedType.contains(".\(baseWithoutWildcard)<")
        }

        // Exact match
        if inheritedType == baseType {
            return true
        }

        // Match last component: "Module.Widget" matches "Widget"
        if inheritedType.hasSuffix(".\(baseType)") {
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

}
