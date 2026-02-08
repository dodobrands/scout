import InlineSnapshotTesting
import LOCSDK
import Testing

@testable import LOC

@Suite
struct LOCSummaryTests {

    @Test func markdownWithMultipleCommits() {
        let summary = LOCSummary(
            outputs: [
                LOCSDK.Output(
                    commit: "abc1234def5678",
                    date: "2025-01-15T07:30:00Z",
                    results: [
                        LOCSDK.ResultItem(metric: "Swift | Sources", linesOfCode: 48500),
                        LOCSDK.ResultItem(
                            metric: "Swift, Objective-C | LegacyModule",
                            linesOfCode: 12000
                        ),
                    ]
                ),
                LOCSDK.Output(
                    commit: "def5678abc1234",
                    date: "2025-02-15T11:45:00Z",
                    results: [
                        LOCSDK.ResultItem(metric: "Swift | Sources", linesOfCode: 52000)
                    ]
                ),
            ]
        )

        assertInlineSnapshot(of: summary.markdown, as: .lines) {
            """
            ## CountLOC Summary

            ### Lines of Code Counts

            | Commit | Configuration | LOC |
            |--------|---------------|-----|
            | `abc1234` | Swift | Sources | 48500 |
            | `abc1234` | Swift, Objective-C | LegacyModule | 12000 |
            | `def5678` | Swift | Sources | 52000 |
            """
        }
    }

    @Test func descriptionWithMultipleCommits() {
        let summary = LOCSummary(
            outputs: [
                LOCSDK.Output(
                    commit: "abc1234def5678",
                    date: "2025-01-15T07:30:00Z",
                    results: [
                        LOCSDK.ResultItem(metric: "Swift | Sources", linesOfCode: 48500)
                    ]
                ),
                LOCSDK.Output(
                    commit: "def5678abc1234",
                    date: "2025-02-15T11:45:00Z",
                    results: [
                        LOCSDK.ResultItem(metric: "Swift | Sources", linesOfCode: 52000)
                    ]
                ),
            ]
        )

        assertInlineSnapshot(of: summary, as: .description) {
            """
            Lines of code counts:
              - abc1234: Swift | Sources: 48500
              - def5678: Swift | Sources: 52000
            """
        }
    }

    @Test func emptyOutputs() {
        let summary = LOCSummary(outputs: [])

        assertInlineSnapshot(of: summary.markdown, as: .lines) {
            """
            ## CountLOC Summary
            """
        }

        assertInlineSnapshot(of: summary, as: .description) {
            """

            """
        }
    }
}
