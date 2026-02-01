import Common

struct BuildSettingsSummary: JobSummaryFormattable {
    let results: [BuildSettingsOutput]

    var markdown: String {
        var md = "## BuildSettings Summary\n\n"

        for output in results {
            md += "### Commit \(output.commit.prefix(7)) (\(output.date))\n\n"
            md += "| Target | Settings |\n"
            md += "|--------|----------|\n"
            for (target, settings) in output.results.sorted(by: { $0.key < $1.key }) {
                let settingsStr =
                    settings
                    .sorted(by: { $0.key < $1.key })
                    .map { "\($0.key): \($0.value ?? "null")" }
                    .joined(separator: ", ")
                md += "| `\(target)` | \(settingsStr) |\n"
            }
            md += "\n"
        }

        return md
    }
}
