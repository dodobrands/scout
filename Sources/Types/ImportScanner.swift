import Foundation

/// Extracts imported module names from Swift source files.
///
/// Used to decide which external modules' inheritance hierarchy needs resolving,
/// derived from the source itself rather than a hardcoded list.
enum ImportScanner {
    /// Collects the set of module names imported across the given Swift files.
    static func modules(in files: [URL]) -> Set<String> {
        var modules: Set<String> = []
        for file in files {
            guard let contents = try? String(contentsOf: file, encoding: .utf8) else { continue }
            for line in contents.split(whereSeparator: \.isNewline) {
                if let module = module(fromLine: line) {
                    modules.insert(module)
                }
            }
        }
        return modules
    }

    /// Returns the imported module name for a single line, or `nil` if it is not an import.
    ///
    /// Handles leading attributes (`@_exported import X`), declaration imports
    /// (`import class UIKit.UIView` → `UIKit`), and submodule paths (first component wins).
    static func module(fromLine line: Substring) -> String? {
        var tokens = line.split(whereSeparator: \.isWhitespace).map(String.init)

        while let first = tokens.first, first.hasPrefix("@") {
            tokens.removeFirst()
        }

        guard tokens.first == "import" else { return nil }
        tokens.removeFirst()

        let declarationKinds: Set<String> = [
            "class", "struct", "enum", "protocol", "typealias", "func", "var", "let",
        ]
        if let first = tokens.first, declarationKinds.contains(first) {
            tokens.removeFirst()
        }

        guard let path = tokens.first else { return nil }
        let identifier = path.prefix { $0.isLetter || $0.isNumber || $0 == "_" }
        return identifier.isEmpty ? nil : String(identifier)
    }
}
