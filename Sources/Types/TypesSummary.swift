import Common
import TypesSDK

struct TypesSummary: JobSummaryFormattable {
    let outputs: [TypesSDK.Output]

    var description: String { markdown }

    var markdown: String {
        var lines = ["# Type Counts"]

        guard !outputs.isEmpty else {
            lines.append("")
            lines.append("No results.")
            return lines.joined(separator: "\n")
        }

        lines.append("")
        lines.append("| Commit | Type | Count |")
        lines.append("|--------|------|-------|")
        for output in outputs {
            let commit = output.commit.prefix(Git.shortHashLength)
            for result in output.results {
                lines.append("| `\(commit)` | `\(result.typeName)` | \(result.types.count) |")
            }
        }

        return lines.joined(separator: "\n")
    }
}
