import Foundation
import InlineSnapshotTesting
import PatternSDK
import Testing

/// Tests for PatternSDK.Output JSON encoding
@Suite
struct PatternOutputTests {

    @Test func encodesSingleCommit() {
        let output = PatternSDK.Output(
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
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc1234def5678",
              "date" : "2025-01-15T07:30:00Z",
              "results" : [
                {
                  "matches" : [
                    {
                      "file" : "Sources\\/ContentView.swift",
                      "line" : 1
                    }
                  ],
                  "pattern" : "import SwiftUI"
                },
                {
                  "matches" : [
                    {
                      "file" : "Sources\\/App.swift",
                      "line" : 1
                    },
                    {
                      "file" : "Sources\\/View.swift",
                      "line" : 1
                    }
                  ],
                  "pattern" : "import UIKit"
                }
              ]
            }
            """
        }
    }

    @Test func encodesMultipleCommits() {
        let outputs = [
            PatternSDK.Output(
                commit: "abc1234def5678",
                date: "2025-01-15T07:30:00Z",
                results: [
                    PatternSDK.ResultItem(
                        pattern: "import UIKit",
                        matches: [
                            PatternSDK.Match(file: "Sources/App.swift", line: 1)
                        ]
                    )
                ]
            ),
            PatternSDK.Output(
                commit: "def5678abc1234",
                date: "2025-02-15T11:45:00Z",
                results: [
                    PatternSDK.ResultItem(
                        pattern: "import UIKit",
                        matches: [
                            PatternSDK.Match(file: "Sources/App.swift", line: 1),
                            PatternSDK.Match(file: "Sources/NewView.swift", line: 1),
                        ]
                    )
                ]
            ),
        ]

        assertInlineSnapshot(of: outputs, as: .json) {
            """
            [
              {
                "commit" : "abc1234def5678",
                "date" : "2025-01-15T07:30:00Z",
                "results" : [
                  {
                    "matches" : [
                      {
                        "file" : "Sources\\/App.swift",
                        "line" : 1
                      }
                    ],
                    "pattern" : "import UIKit"
                  }
                ]
              },
              {
                "commit" : "def5678abc1234",
                "date" : "2025-02-15T11:45:00Z",
                "results" : [
                  {
                    "matches" : [
                      {
                        "file" : "Sources\\/App.swift",
                        "line" : 1
                      },
                      {
                        "file" : "Sources\\/NewView.swift",
                        "line" : 1
                      }
                    ],
                    "pattern" : "import UIKit"
                  }
                ]
              }
            ]
            """
        }
    }

    @Test func encodesEmptyResults() {
        let output = PatternSDK.Output(
            commit: "abc123",
            date: "2025-01-15T07:30:00Z",
            results: [
                PatternSDK.ResultItem(pattern: "import UIKit", matches: [])
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc123",
              "date" : "2025-01-15T07:30:00Z",
              "results" : [
                {
                  "matches" : [

                  ],
                  "pattern" : "import UIKit"
                }
              ]
            }
            """
        }
    }
}
