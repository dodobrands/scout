import Common
import FilesSDK

struct FilesSummary: JobSummaryFormattable {
    let outputs: [FilesSDK.Output]

    var description: String {
        guard !outputs.isEmpty else { return "" }
        var lines = ["File type counts:"]
        for output in outputs {
            let commit = output.commit.prefix(Git.shortHashLength)
            for result in output.results {
                lines.append("  - \(commit): \(result.filetype): \(result.files.count)")
            }
        }
        return lines.joined(separator: "\n")
    }

    var markdown: String {
        var md = "## CountFiles Summary\n\n"

        if !outputs.isEmpty {
            md += "### File Type Counts\n\n"
            md += "| Commit | File Type | Count |\n"
            md += "|--------|-----------|-------|\n"
            for output in outputs {
                let commit = output.commit.prefix(Git.shortHashLength)
                for result in output.results {
                    md += "| `\(commit)` | `.\(result.filetype)` | \(result.files.count) |\n"
                }
            }
            md += "\n"
        }

        return md
    }
}
