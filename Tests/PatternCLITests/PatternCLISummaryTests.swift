import InlineSnapshotTesting
import Pattern
import Testing

@testable import PatternCLI

struct PatternCLISummaryTests {

    @Test func `multiple commits`() {
        let summary = PatternCLISummary(
            outputs: [
                Pattern.Output(
                    commit: "abc1234def5678",
                    date: "2025-01-15T07:30:00Z",
                    results: [
                        Pattern.ResultItem(
                            pattern: "import SwiftUI",
                            matches: [
                                Pattern.Match(file: "Sources/ContentView.swift", line: 1)
                            ]
                        ),
                        Pattern.ResultItem(
                            pattern: "import UIKit",
                            matches: [
                                Pattern.Match(file: "Sources/App.swift", line: 1),
                                Pattern.Match(file: "Sources/View.swift", line: 1),
                            ]
                        ),
                    ]
                ),
                Pattern.Output(
                    commit: "def5678abc1234",
                    date: "2025-02-15T11:45:00Z",
                    results: [
                        Pattern.ResultItem(
                            pattern: "import UIKit",
                            matches: [
                                Pattern.Match(file: "Sources/App.swift", line: 1)
                            ]
                        )
                    ]
                ),
            ]
        )

        assertInlineSnapshot(of: summary, as: .description) {
            """
            # Pattern Matches

            | Commit | Pattern | Matches |
            |--------|---------|--------|
            | `abc1234` | `import SwiftUI` | 1 |
            | `abc1234` | `import UIKit` | 2 |
            | `def5678` | `import UIKit` | 1 |
            """
        }
    }

    @Test func `empty outputs`() {
        let summary = PatternCLISummary(outputs: [])

        assertInlineSnapshot(of: summary, as: .description) {
            """
            # Pattern Matches

            No results.
            """
        }
    }
}
