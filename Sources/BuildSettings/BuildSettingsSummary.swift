import BuildSettingsSDK
import Common

struct BuildSettingsSummary: JobSummaryFormattable {
    let outputs: [BuildSettingsSDK.Output]

    var description: String {
        guard !outputs.isEmpty else { return "" }
        var lines = ["Build settings:"]
        for output in outputs {
            let commit = output.commit.prefix(Git.shortHashLength)
            for result in output.results.sorted(by: { $0.target < $1.target }) {
                let settingsStr =
                    result.settings
                    .sorted(by: { $0.key < $1.key })
                    .map { "\($0.key): \($0.value ?? "null")" }
                    .joined(separator: ", ")
                lines.append("  - \(commit): \(result.target): \(settingsStr)")
            }
        }
        return lines.joined(separator: "\n")
    }

    var markdown: String {
        var md = "## BuildSettings Summary\n\n"

        if !outputs.isEmpty {
            md += "### Build Settings\n\n"
            md += "| Commit | Target | Settings |\n"
            md += "|--------|--------|----------|\n"
            for output in outputs {
                let commit = output.commit.prefix(Git.shortHashLength)
                for result in output.results.sorted(by: { $0.target < $1.target }) {
                    let settingsStr =
                        result.settings
                        .sorted(by: { $0.key < $1.key })
                        .map { "\($0.key): \($0.value ?? "null")" }
                        .joined(separator: ", ")
                    md += "| `\(commit)` | `\(result.target)` | \(settingsStr) |\n"
                }
            }
            md += "\n"
        }

        return md
    }
}
