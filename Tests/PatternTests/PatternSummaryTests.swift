import InlineSnapshotTesting
import PatternSDK
import Testing

@testable import Pattern

@Suite
struct PatternSummaryTests {

    @Test func markdownWithMultipleCommits() {
        let summary = PatternSummary(
            outputs: [
                PatternSDK.Output(
                    commit: "abc1234def5678",
                    date: "2025-01-15T07:30:00Z",
                    results: [
                        PatternSDK.ResultItem(
                            pattern: "import SwiftUI",
                            matches: [
                                PatternSDK.Match(file: "Sources/ContentView.swift", line: 1)
                            ]
                        ),
                        PatternSDK.ResultItem(
                            pattern: "import UIKit",
                            matches: [
                                PatternSDK.Match(file: "Sources/App.swift", line: 1),
                                PatternSDK.Match(file: "Sources/View.swift", line: 1),
                            ]
                        ),
                    ]
                ),
                PatternSDK.Output(
                    commit: "def5678abc1234",
                    date: "2025-02-15T11:45:00Z",
                    results: [
                        PatternSDK.ResultItem(
                            pattern: "import UIKit",
                            matches: [
                                PatternSDK.Match(file: "Sources/App.swift", line: 1)
                            ]
                        )
                    ]
                ),
            ]
        )

        assertInlineSnapshot(of: summary.markdown, as: .lines) {
            """
            ## Search Summary

            ### Pattern Matches

            | Commit | Pattern | Matches |
            |--------|---------|--------|
            | `abc1234` | `import SwiftUI` | 1 |
            | `abc1234` | `import UIKit` | 2 |
            | `def5678` | `import UIKit` | 1 |


            """
        }
    }

    @Test func descriptionWithMultipleCommits() {
        let summary = PatternSummary(
            outputs: [
                PatternSDK.Output(
                    commit: "abc1234def5678",
                    date: "2025-01-15T07:30:00Z",
                    results: [
                        PatternSDK.ResultItem(
                            pattern: "import SwiftUI",
                            matches: [
                                PatternSDK.Match(file: "Sources/ContentView.swift", line: 1)
                            ]
                        ),
                        PatternSDK.ResultItem(
                            pattern: "import UIKit",
                            matches: [
                                PatternSDK.Match(file: "Sources/App.swift", line: 1),
                                PatternSDK.Match(file: "Sources/View.swift", line: 1),
                            ]
                        ),
                    ]
                ),
                PatternSDK.Output(
                    commit: "def5678abc1234",
                    date: "2025-02-15T11:45:00Z",
                    results: [
                        PatternSDK.ResultItem(
                            pattern: "import UIKit",
                            matches: [
                                PatternSDK.Match(file: "Sources/App.swift", line: 1)
                            ]
                        )
                    ]
                ),
            ]
        )

        assertInlineSnapshot(of: summary, as: .description) {
            """
            Pattern matches:
              - abc1234: import SwiftUI: 1
              - abc1234: import UIKit: 2
              - def5678: import UIKit: 1
            """
        }
    }

    @Test func emptyOutputs() {
        let summary = PatternSummary(outputs: [])

        assertInlineSnapshot(of: summary.markdown, as: .lines) {
            """
            ## Search Summary


            """
        }

        assertInlineSnapshot(of: summary, as: .description) {
            """

            """
        }
    }
}
