import Common
import PatternSDK

struct PatternSummary: JobSummaryFormattable {
    let outputs: [PatternSDK.Output]

    var description: String {
        guard !outputs.isEmpty else { return "" }
        var lines = ["Pattern matches:"]
        for output in outputs {
            let commit = output.commit.prefix(Git.shortHashLength)
            for result in output.results {
                lines.append("  - \(commit): \(result.pattern): \(result.matches.count)")
            }
        }
        return lines.joined(separator: "\n")
    }

    var markdown: String {
        var lines = ["## Search Summary"]

        if !outputs.isEmpty {
            lines.append("")
            lines.append("### Pattern Matches")
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
        }

        return lines.joined(separator: "\n")
    }
}
