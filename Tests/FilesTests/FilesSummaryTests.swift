import FilesSDK
import InlineSnapshotTesting
import Testing

@testable import Files

@Suite
struct FilesSummaryTests {

    @Test func markdownWithMultipleCommits() {
        let summary = FilesSummary(
            outputs: [
                FilesSDK.Output(
                    commit: "abc1234def5678",
                    date: "2025-01-15T07:30:00Z",
                    results: [
                        FilesSDK.ResultItem(
                            filetype: "storyboard",
                            files: ["Main.storyboard", "Launch.storyboard"]
                        ),
                        FilesSDK.ResultItem(
                            filetype: "swift",
                            files: ["Sources/App.swift"]
                        ),
                    ]
                ),
                FilesSDK.Output(
                    commit: "def5678abc1234",
                    date: "2025-02-15T11:45:00Z",
                    results: [
                        FilesSDK.ResultItem(
                            filetype: "swift",
                            files: ["Sources/App.swift", "Sources/New.swift"]
                        )
                    ]
                ),
            ]
        )

        assertInlineSnapshot(of: summary.markdown, as: .lines) {
            """
            ## CountFiles Summary

            ### File Type Counts

            | Commit | File Type | Count |
            |--------|-----------|-------|
            | `abc1234` | `.storyboard` | 2 |
            | `abc1234` | `.swift` | 1 |
            | `def5678` | `.swift` | 2 |
            """
        }
    }

    @Test func descriptionWithMultipleCommits() {
        let summary = FilesSummary(
            outputs: [
                FilesSDK.Output(
                    commit: "abc1234def5678",
                    date: "2025-01-15T07:30:00Z",
                    results: [
                        FilesSDK.ResultItem(
                            filetype: "storyboard",
                            files: ["Main.storyboard", "Launch.storyboard"]
                        ),
                        FilesSDK.ResultItem(
                            filetype: "swift",
                            files: ["Sources/App.swift"]
                        ),
                    ]
                ),
                FilesSDK.Output(
                    commit: "def5678abc1234",
                    date: "2025-02-15T11:45:00Z",
                    results: [
                        FilesSDK.ResultItem(
                            filetype: "swift",
                            files: ["Sources/App.swift", "Sources/New.swift"]
                        )
                    ]
                ),
            ]
        )

        assertInlineSnapshot(of: summary, as: .description) {
            """
            File type counts:
              - abc1234: storyboard: 2
              - abc1234: swift: 1
              - def5678: swift: 2
            """
        }
    }

    @Test func emptyOutputs() {
        let summary = FilesSummary(outputs: [])

        assertInlineSnapshot(of: summary.markdown, as: .lines) {
            """
            ## CountFiles Summary
            """
        }

        assertInlineSnapshot(of: summary, as: .description) {
            """

            """
        }
    }
}
