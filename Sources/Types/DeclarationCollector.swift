import SwiftSyntax

extension SwiftParser {
    /// Collects type declarations with an inheritance clause, and typealiases, from one file's
    /// syntax tree. Nested types get dotted full names; extensions extend the path with the
    /// extended type, so `extension A { class B: C {} }` yields `A.B`. Local types inside
    /// function bodies and closures are collected too.
    final class DeclarationCollector: SyntaxVisitor {
        private let filePath: String
        private var path: [String] = []
        private(set) var objects: [ObjectFromCode] = []

        init(filePath: String) {
            self.filePath = filePath
            super.init(viewMode: .sourceAccurate)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            enter(name: node.name, inheritance: node.inheritanceClause, kind: .classType)
        }
        override func visitPost(_ node: ClassDeclSyntax) { path.removeLast() }

        // Actors are reference types and inherit like classes.
        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            enter(name: node.name, inheritance: node.inheritanceClause, kind: .classType)
        }
        override func visitPost(_ node: ActorDeclSyntax) { path.removeLast() }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            enter(name: node.name, inheritance: node.inheritanceClause, kind: .structType)
        }
        override func visitPost(_ node: StructDeclSyntax) { path.removeLast() }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            enter(name: node.name, inheritance: node.inheritanceClause, kind: .enumType)
        }
        override func visitPost(_ node: EnumDeclSyntax) { path.removeLast() }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            enter(name: node.name, inheritance: node.inheritanceClause, kind: .protocolType)
        }
        override func visitPost(_ node: ProtocolDeclSyntax) { path.removeLast() }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            path.append(qualified(node.extendedType.trimmedDescription))
            return .visitChildren
        }
        override func visitPost(_ node: ExtensionDeclSyntax) { path.removeLast() }

        override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
            let target = node.initializer.value.trimmedDescription
            if !target.isEmpty {
                objects.append(
                    ObjectFromCode(
                        name: Self.unescaped(node.name),
                        fullName: qualified(Self.unescaped(node.name)),
                        filePath: filePath,
                        inheritedTypes: [target],
                        kind: .typealiasType
                    )
                )
            }
            return .visitChildren
        }

        private func enter(
            name token: TokenSyntax,
            inheritance: InheritanceClauseSyntax?,
            kind: TypeKind
        ) -> SyntaxVisitorContinueKind {
            let name = Self.unescaped(token)
            let fullName = qualified(name)
            let inheritedTypes =
                inheritance?.inheritedTypes.map { $0.type.trimmedDescription } ?? []
            if !inheritedTypes.isEmpty {
                objects.append(
                    ObjectFromCode(
                        name: name,
                        fullName: fullName,
                        filePath: filePath,
                        inheritedTypes: inheritedTypes,
                        kind: kind
                    )
                )
            }
            path.append(fullName)
            return .visitChildren
        }

        private func qualified(_ name: String) -> String {
            path.last.map { "\($0).\(name)" } ?? name
        }

        /// The declared name without backticks: `` `Type` `` is `Type`.
        private static func unescaped(_ token: TokenSyntax) -> String {
            token.identifier?.name ?? token.text
        }
    }
}
