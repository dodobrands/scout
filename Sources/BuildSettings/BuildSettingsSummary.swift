import BuildSettingsSDK
import Common

struct BuildSettingsSummary: JobSummaryFormattable {
    let outputs: [BuildSettingsSDK.Output]

    var description: String { markdown }

    var markdown: String {
        var lines = ["## BuildSettings Summary"]

        if !outputs.isEmpty {
            lines.append("")
            lines.append("### Build Settings")
            lines.append("")
            lines.append("| Commit | Target | Settings |")
            lines.append("|--------|--------|----------|")
            for output in outputs {
                let commit = output.commit.prefix(Git.shortHashLength)
                for result in output.results.sorted(by: { $0.target < $1.target }) {
                    let settingsStr =
                        result.settings
                        .sorted(by: { $0.key < $1.key })
                        .map { "\($0.key): \($0.value ?? "null")" }
                        .joined(separator: ", ")
                    lines.append("| `\(commit)` | `\(result.target)` | \(settingsStr) |")
                }
            }
        }

        return lines.joined(separator: "\n")
    }
}
