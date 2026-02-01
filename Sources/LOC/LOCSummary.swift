import Common
import LOCSDK

struct LOCSummary: JobSummaryFormattable {
    let results: [LOCSDK.Result]

    var markdown: String {
        var md = "## CountLOC Summary\n\n"

        if !results.isEmpty {
            md += "### Lines of Code Counts\n\n"
            md += "| Commit | Configuration | LOC |\n"
            md += "|--------|---------------|-----|\n"
            for result in results {
                let commit = result.commit.prefix(7)
                md += "| `\(commit)` | \(result.metric) | \(result.linesOfCode) |\n"
            }
            md += "\n"
        }

        return md
    }
}
