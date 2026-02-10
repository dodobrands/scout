import InlineSnapshotTesting
import LOC
import Testing

@testable import LOCCLI

struct LOCCLISummaryTests {

    @Test func `multiple commits`() {
        let summary = LOCCLISummary(
            outputs: [
                LOC.Output(
                    commit: "abc1234def5678",
                    date: "2025-01-15T07:30:00Z",
                    results: [
                        LOC.ResultItem(metric: "Swift | Sources", linesOfCode: 48500),
                        LOC.ResultItem(
                            metric: "Swift, Objective-C | LegacyModule",
                            linesOfCode: 12000
                        ),
                    ]
                ),
                LOC.Output(
                    commit: "def5678abc1234",
                    date: "2025-02-15T11:45:00Z",
                    results: [
                        LOC.ResultItem(metric: "Swift | Sources", linesOfCode: 52000)
                    ]
                ),
            ]
        )

        assertInlineSnapshot(of: summary, as: .description) {
            """
            # Lines of Code

            | Commit | Configuration | LOC |
            |--------|---------------|-----|
            | `abc1234` | Swift \\| Sources | 48500 |
            | `abc1234` | Swift, Objective-C \\| LegacyModule | 12000 |
            | `def5678` | Swift \\| Sources | 52000 |
            """
        }
    }

    @Test func `empty outputs`() {
        let summary = LOCCLISummary(outputs: [])

        assertInlineSnapshot(of: summary, as: .description) {
            """
            # Lines of Code

            No results.
            """
        }
    }
}
