import BuildSettingsSDK
import Common

struct BuildSettingsSummary: JobSummaryFormattable {
    let outputs: [BuildSettingsSDK.Output]

    var markdown: String {
        var md = "## BuildSettings Summary\n\n"

        for output in outputs {
            md += "### Commit \(output.commit.prefix(7)) (\(output.date))\n\n"
            md += "| Target | Settings |\n"
            md += "|--------|----------|\n"
            for result in output.results.sorted(by: { $0.target < $1.target }) {
                let settingsStr =
                    result.settings
                    .sorted(by: { $0.key < $1.key })
                    .map { "\($0.key): \($0.value ?? "null")" }
                    .joined(separator: ", ")
                md += "| `\(result.target)` | \(settingsStr) |\n"
            }
            md += "\n"
        }

        return md
    }
}
