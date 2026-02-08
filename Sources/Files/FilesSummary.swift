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
        var lines = ["## CountFiles Summary"]

        if !outputs.isEmpty {
            lines.append("")
            lines.append("### File Type Counts")
            lines.append("")
            lines.append("| Commit | File Type | Count |")
            lines.append("|--------|-----------|-------|")
            for output in outputs {
                let commit = output.commit.prefix(Git.shortHashLength)
                for result in output.results {
                    lines.append("| `\(commit)` | `.\(result.filetype)` | \(result.files.count) |")
                }
            }
        }

        return lines.joined(separator: "\n")
    }
}
