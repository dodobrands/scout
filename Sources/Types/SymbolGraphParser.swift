import Foundation

/// Parses a Swift symbol graph (produced by `swift-symbolgraph-extract`) into class
/// inheritance edges expressed as `ObjectFromCode`.
///
/// Only `inheritsFrom` relationships are used, so protocol conformances (`conformsTo`)
/// never masquerade as class inheritance.
enum SymbolGraphParser {
    private struct SymbolGraph: Decodable {
        struct Symbol: Decodable {
            struct Identifier: Decodable { let precise: String }
            struct Names: Decodable { let title: String }
            let identifier: Identifier
            let names: Names
        }

        struct Relationship: Decodable {
            let kind: String
            let source: String
            let target: String
        }

        let symbols: [Symbol]
        let relationships: [Relationship]
    }

    /// Decodes symbol graph JSON and returns one `ObjectFromCode` per `inheritsFrom` edge.
    static func objects(fromSymbolGraphJSON data: Data) throws -> [ObjectFromCode] {
        let graph = try JSONDecoder().decode(SymbolGraph.self, from: data)

        let titleByUSR = Dictionary(
            graph.symbols.map { ($0.identifier.precise, $0.names.title) },
            uniquingKeysWith: { first, _ in first }
        )

        return graph.relationships
            .filter { $0.kind == "inheritsFrom" }
            .compactMap { relationship in
                guard let subclass = titleByUSR[relationship.source] else { return nil }
                let superclass =
                    titleByUSR[relationship.target] ?? name(fromUSR: relationship.target)
                return ObjectFromCode(
                    name: subclass,
                    fullName: subclass,
                    filePath: "<symbolgraph>",
                    inheritedTypes: [superclass],
                    kind: .classType
                )
            }
    }

    /// Derives a readable type name from a USR when no symbol declares it.
    /// For example, `c:objc(cs)NSObject` → `NSObject`.
    private static func name(fromUSR usr: String) -> String {
        if let range = usr.range(of: "(cs)") {
            return String(usr[range.upperBound...])
        }
        return usr
    }
}
