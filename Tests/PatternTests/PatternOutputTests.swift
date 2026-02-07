import Foundation
import InlineSnapshotTesting
import PatternSDK
import Testing

@testable import Pattern

/// Tests for PatternOutput JSON encoding
@Suite("PatternOutput JSON")
struct PatternOutputTests {

    @Test func encodesSingleCommit() {
        let output = PatternOutput(
            commit: "abc1234def5678",
            date: "2025-01-15T10:30:00+03:00",
            results: [
                "import UIKit": [
                    PatternSDK.Match(file: "Sources/App.swift", line: 1),
                    PatternSDK.Match(file: "Sources/View.swift", line: 1),
                ],
                "import SwiftUI": [
                    PatternSDK.Match(file: "Sources/ContentView.swift", line: 1)
                ],
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc1234def5678",
              "date" : "2025-01-15T10:30:00+03:00",
              "results" : {
                "import SwiftUI" : [
                  {
                    "file" : "Sources\\/ContentView.swift",
                    "line" : 1
                  }
                ],
                "import UIKit" : [
                  {
                    "file" : "Sources\\/App.swift",
                    "line" : 1
                  },
                  {
                    "file" : "Sources\\/View.swift",
                    "line" : 1
                  }
                ]
              }
            }
            """
        }
    }

    @Test func encodesMultipleCommits() {
        let outputs = [
            PatternOutput(
                commit: "abc1234def5678",
                date: "2025-01-15T10:30:00+03:00",
                results: [
                    "import UIKit": [
                        PatternSDK.Match(file: "Sources/App.swift", line: 1)
                    ]
                ]
            ),
            PatternOutput(
                commit: "def5678abc1234",
                date: "2025-02-15T14:45:00+03:00",
                results: [
                    "import UIKit": [
                        PatternSDK.Match(file: "Sources/App.swift", line: 1),
                        PatternSDK.Match(file: "Sources/NewView.swift", line: 1),
                    ]
                ]
            ),
        ]

        assertInlineSnapshot(of: outputs, as: .json) {
            """
            [
              {
                "commit" : "abc1234def5678",
                "date" : "2025-01-15T10:30:00+03:00",
                "results" : {
                  "import UIKit" : [
                    {
                      "file" : "Sources\\/App.swift",
                      "line" : 1
                    }
                  ]
                }
              },
              {
                "commit" : "def5678abc1234",
                "date" : "2025-02-15T14:45:00+03:00",
                "results" : {
                  "import UIKit" : [
                    {
                      "file" : "Sources\\/App.swift",
                      "line" : 1
                    },
                    {
                      "file" : "Sources\\/NewView.swift",
                      "line" : 1
                    }
                  ]
                }
              }
            ]
            """
        }
    }

    @Test func encodesEmptyResults() {
        let output = PatternOutput(
            commit: "abc123",
            date: "2025-01-15T10:30:00+03:00",
            results: [
                "import UIKit": []
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc123",
              "date" : "2025-01-15T10:30:00+03:00",
              "results" : {
                "import UIKit" : [

                ]
              }
            }
            """
        }
    }
}
