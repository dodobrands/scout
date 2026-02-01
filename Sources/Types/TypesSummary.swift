import Common
import TypesSDK

struct TypesSummary: JobSummaryFormattable {
    let results: [TypesSDK.Result]

    var markdown: String {
        var md = "## CountTypes Summary\n\n"

        if !results.isEmpty {
            md += "### Type Counts\n\n"
            md += "| Commit | Type | Count |\n"
            md += "|--------|------|-------|\n"
            for result in results {
                let commit = result.commit.prefix(7)
                md += "| `\(commit)` | `\(result.typeName)` | \(result.types.count) |\n"
            }
            md += "\n"
        }

        return md
    }
}
