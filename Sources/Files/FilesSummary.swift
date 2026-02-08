import Common
import FilesSDK

struct FilesSummary: JobSummaryFormattable {
    let outputs: [FilesSDK.Output]

    var description: String { markdown }

    var markdown: String {
        var lines = ["# File Counts"]

        if !outputs.isEmpty {
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
