import Files
import InlineSnapshotTesting
import Testing

@testable import FilesCLI

struct FilesCLISummaryTests {

    @Test func `multiple commits`() {
        let summary = FilesCLISummary(
            outputs: [
                Files.Output(
                    commit: "abc1234def5678",
                    date: "2025-01-15T07:30:00Z",
                    results: [
                        Files.ResultItem(
                            filetype: "storyboard",
                            files: ["Main.storyboard", "Launch.storyboard"]
                        ),
                        Files.ResultItem(
                            filetype: "swift",
                            files: ["Sources/App.swift"]
                        ),
                    ]
                ),
                Files.Output(
                    commit: "def5678abc1234",
                    date: "2025-02-15T11:45:00Z",
                    results: [
                        Files.ResultItem(
                            filetype: "swift",
                            files: ["Sources/App.swift", "Sources/New.swift"]
                        )
                    ]
                ),
            ]
        )

        assertInlineSnapshot(of: summary, as: .description) {
            """
            # File Counts

            | Commit | File Type | Count |
            |--------|-----------|-------|
            | `abc1234` | `.storyboard` | 2 |
            | `abc1234` | `.swift` | 1 |
            | `def5678` | `.swift` | 2 |
            """
        }
    }

    @Test func `empty outputs`() {
        let summary = FilesCLISummary(outputs: [])

        assertInlineSnapshot(of: summary, as: .description) {
            """
            # File Counts

            No results.
            """
        }
    }
}
