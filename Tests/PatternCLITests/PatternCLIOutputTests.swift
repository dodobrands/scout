import Foundation
import InlineSnapshotTesting
import Pattern
import Testing

/// Tests for Pattern.Output JSON encoding
struct PatternCLIOutputTests {

    @Test func `encodes single commit`() {
        let output = Pattern.Output(
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

    @Test func `encodes multiple commits`() {
        let outputs = [
            Pattern.Output(
                commit: "abc1234def5678",
                date: "2025-01-15T07:30:00Z",
                results: [
                    Pattern.ResultItem(
                        pattern: "import UIKit",
                        matches: [
                            Pattern.Match(file: "Sources/App.swift", line: 1)
                        ]
                    )
                ]
            ),
            Pattern.Output(
                commit: "def5678abc1234",
                date: "2025-02-15T11:45:00Z",
                results: [
                    Pattern.ResultItem(
                        pattern: "import UIKit",
                        matches: [
                            Pattern.Match(file: "Sources/App.swift", line: 1),
                            Pattern.Match(file: "Sources/NewView.swift", line: 1),
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

    @Test func `encodes empty results`() {
        let output = Pattern.Output(
            commit: "abc123",
            date: "2025-01-15T07:30:00Z",
            results: [
                Pattern.ResultItem(pattern: "import UIKit", matches: [])
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
