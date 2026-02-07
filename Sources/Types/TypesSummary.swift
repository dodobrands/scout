import Common
import TypesSDK

struct TypesSummary: JobSummaryFormattable {
    let outputs: [TypesSDK.Output]

    var markdown: String {
        var md = "## CountTypes Summary\n\n"

        if !outputs.isEmpty {
            md += "### Type Counts\n\n"
            md += "| Commit | Type | Count |\n"
            md += "|--------|------|-------|\n"
            for output in outputs {
                let commit = output.commit.prefix(7)
                for result in output.results {
                    md += "| `\(commit)` | `\(result.typeName)` | \(result.types.count) |\n"
                }
            }
            md += "\n"
        }

        return md
    }
}
