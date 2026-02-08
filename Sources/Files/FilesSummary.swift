import Common
import FilesSDK

struct FilesSummary: JobSummaryFormattable {
    let outputs: [FilesSDK.Output]

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
