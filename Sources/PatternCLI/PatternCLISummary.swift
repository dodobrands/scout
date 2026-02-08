import Common
import PatternSDK

struct PatternCLISummary: JobSummaryFormattable {
    let outputs: [PatternSDK.Output]

    var description: String { markdown }

    var markdown: String {
        var lines = ["# Pattern Matches"]

        guard !outputs.isEmpty else {
            lines.append("")
            lines.append("No results.")
            return lines.joined(separator: "\n")
        }

        lines.append("")
        lines.append("| Commit | Pattern | Matches |")
        lines.append("|--------|---------|--------|")
        for output in outputs {
            let commit = output.commit.prefix(Git.shortHashLength)
            for result in output.results {
                lines.append(
                    "| `\(commit)` | `\(result.pattern)` | \(result.matches.count) |"
                )
            }
        }

        return lines.joined(separator: "\n")
    }
}
