import BuildSettings
import Common

struct BuildSettingsCLISummary: JobSummaryFormattable {
    let outputs: [BuildSettings.Output]

    var description: String { markdown }

    var markdown: String {
        var lines = ["# Build Settings"]

        guard !outputs.isEmpty else {
            lines.append("")
            lines.append("No results.")
            return lines.joined(separator: "\n")
        }

        lines.append("")
        lines.append("| Commit | Setting | Targets |")
        lines.append("|--------|---------|---------|")
        for output in outputs {
            let commit = output.commit.prefix(Git.shortHashLength)
            for result in output.results.sorted(by: { $0.setting < $1.setting }) {
                let targetsStr =
                    result.targets
                    .sorted(by: { $0.key < $1.key })
                    .map { "\($0.key): \($0.value ?? "null")" }
                    .joined(separator: ", ")
                let displayTargets = targetsStr.isEmpty ? "—" : targetsStr
                lines.append("| `\(commit)` | \(result.setting) | \(displayTargets) |")
            }
        }

        return lines.joined(separator: "\n")
    }
}
