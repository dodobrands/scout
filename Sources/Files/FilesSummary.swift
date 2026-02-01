import Common
import FilesSDK

struct FilesSummary: JobSummaryFormattable {
    let results: [FilesSDK.Result]

    var markdown: String {
        var md = "## CountFiles Summary\n\n"

        if !results.isEmpty {
            md += "### File Type Counts\n\n"
            md += "| Commit | File Type | Count |\n"
            md += "|--------|-----------|-------|\n"
            for result in results {
                let commit = result.commit.prefix(7)
                md += "| `\(commit)` | `.\(result.filetype)` | \(result.files.count) |\n"
            }
            md += "\n"
        }

        return md
    }
}
