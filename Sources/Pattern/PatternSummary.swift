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
        var md = "## Search Summary\n\n"

        if !outputs.isEmpty {
            md += "### Pattern Matches\n\n"
            md += "| Commit | Pattern | Matches |\n"
            md += "|--------|---------|--------|\n"
            for output in outputs {
                let commit = output.commit.prefix(Git.shortHashLength)
                for result in output.results {
                    md += "| `\(commit)` | `\(result.pattern)` | \(result.matches.count) |\n"
                }
            }
            md += "\n"
        }

        return md
    }
}
