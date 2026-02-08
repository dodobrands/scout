import Common
import TypesSDK

struct TypesSummary: JobSummaryFormattable {
    let outputs: [TypesSDK.Output]

    var description: String {
        guard !outputs.isEmpty else { return "" }
        var lines = ["Type counts:"]
        for output in outputs {
            let commit = output.commit.prefix(Git.shortHashLength)
            for result in output.results {
                lines.append("  - \(commit): \(result.typeName): \(result.types.count)")
            }
        }
        return lines.joined(separator: "\n")
    }

    var markdown: String {
        var lines = ["## CountTypes Summary"]

        if !outputs.isEmpty {
            lines.append("")
            lines.append("### Type Counts")
            lines.append("")
            lines.append("| Commit | Type | Count |")
            lines.append("|--------|------|-------|")
            for output in outputs {
                let commit = output.commit.prefix(Git.shortHashLength)
                for result in output.results {
                    lines.append("| `\(commit)` | `\(result.typeName)` | \(result.types.count) |")
                }
            }
        }

        return lines.joined(separator: "\n")
    }
}
