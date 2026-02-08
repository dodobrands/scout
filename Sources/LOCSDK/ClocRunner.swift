import Common
import Foundation

/// Helper for counting lines of code using cloc.
struct ClocRunner {
    /// Counts lines of code at the specified path for a given language.
    /// - Parameters:
    ///   - path: Path to analyze
    ///   - language: Programming language to count
    /// - Returns: Lines of code as string
    func linesOfCode(at path: URL, language: String) async throws -> String {
        let clocOutput = try await Shell.execute(
            "cloc",
            arguments: ["--quiet", "--include-lang=\(language)", path.path(percentEncoded: false)]
        )
        let lines = clocOutput.split(separator: "\n")
        for line in lines {
            if line.contains(language) {
                let parts = line.split(whereSeparator: { $0.isWhitespace })
                if let codePart = parts[safe: 4] {
                    return String(codePart)
                }
            }
        }
        return "0"
    }
}
