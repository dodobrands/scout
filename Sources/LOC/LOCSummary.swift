import Common
import LOCSDK

struct LOCSummary: JobSummaryFormattable {
    let outputs: [LOCSDK.Output]

    var markdown: String {
        var md = "## CountLOC Summary\n\n"

        if !outputs.isEmpty {
            md += "### Lines of Code Counts\n\n"
            md += "| Commit | Configuration | LOC |\n"
            md += "|--------|---------------|-----|\n"
            for output in outputs {
                let commit = output.commit.prefix(Git.shortHashLength)
                for result in output.results {
                    md += "| `\(commit)` | \(result.metric) | \(result.linesOfCode) |\n"
                }
            }
            md += "\n"
        }

        return md
    }
}
