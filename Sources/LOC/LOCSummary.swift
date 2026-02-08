import Common
import LOCSDK

struct LOCSummary: JobSummaryFormattable {
    let outputs: [LOCSDK.Output]

    var description: String { markdown }

    var markdown: String {
        var lines = ["## CountLOC Summary"]

        if !outputs.isEmpty {
            lines.append("")
            lines.append("### Lines of Code Counts")
            lines.append("")
            lines.append("| Commit | Configuration | LOC |")
            lines.append("|--------|---------------|-----|")
            for output in outputs {
                let commit = output.commit.prefix(Git.shortHashLength)
                for result in output.results {
                    lines.append("| `\(commit)` | \(result.metric) | \(result.linesOfCode) |")
                }
            }
        }

        return lines.joined(separator: "\n")
    }
}
