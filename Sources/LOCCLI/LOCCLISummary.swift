import Common
import LOC

struct LOCCLISummary: JobSummaryFormattable {
    let outputs: [LOC.Output]

    var description: String { markdown }

    var markdown: String {
        var lines = ["# Lines of Code"]

        guard !outputs.isEmpty else {
            lines.append("")
            lines.append("No results.")
            return lines.joined(separator: "\n")
        }

        lines.append("")
        lines.append("| Commit | Configuration | LOC |")
        lines.append("|--------|---------------|-----|")
        for output in outputs {
            let commit = output.commit.prefix(Git.shortHashLength)
            for result in output.results {
                let metric = result.metric.replacingOccurrences(of: "|", with: "\\|")
                lines.append("| `\(commit)` | \(metric) | \(result.linesOfCode) |")
            }
        }

        return lines.joined(separator: "\n")
    }
}
