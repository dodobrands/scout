import Foundation
import InlineSnapshotTesting
import Testing

@testable import Files

/// Tests for FilesOutput JSON encoding
@Suite
struct FilesOutputTests {

    @Test func encodesSingleCommit() {
        let output = FilesOutput(
            commit: "abc1234def5678",
            date: "2025-01-15T10:30:00+03:00",
            results: [
                "swift": ["Sources/App.swift", "Sources/Model.swift"],
                "storyboard": ["Main.storyboard", "Launch.storyboard"],
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc1234def5678",
              "date" : "2025-01-15T10:30:00+03:00",
              "results" : {
                "storyboard" : [
                  "Main.storyboard",
                  "Launch.storyboard"
                ],
                "swift" : [
                  "Sources\\/App.swift",
                  "Sources\\/Model.swift"
                ]
              }
            }
            """
        }
    }

    @Test func encodesMultipleCommits() {
        let outputs = [
            FilesOutput(
                commit: "abc1234def5678",
                date: "2025-01-15T10:30:00+03:00",
                results: [
                    "swift": ["Sources/App.swift"],
                    "storyboard": ["Main.storyboard"],
                ]
            ),
            FilesOutput(
                commit: "def5678abc1234",
                date: "2025-02-15T14:45:00+03:00",
                results: [
                    "swift": ["Sources/App.swift", "Sources/NewFeature.swift"],
                    "storyboard": ["Main.storyboard"],
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
                  "storyboard" : [
                    "Main.storyboard"
                  ],
                  "swift" : [
                    "Sources\\/App.swift"
                  ]
                }
              },
              {
                "commit" : "def5678abc1234",
                "date" : "2025-02-15T14:45:00+03:00",
                "results" : {
                  "storyboard" : [
                    "Main.storyboard"
                  ],
                  "swift" : [
                    "Sources\\/App.swift",
                    "Sources\\/NewFeature.swift"
                  ]
                }
              }
            ]
            """
        }
    }

    @Test func encodesEmptyResults() {
        let output = FilesOutput(
            commit: "abc123",
            date: "2025-01-15T10:30:00+03:00",
            results: [
                "swift": []
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc123",
              "date" : "2025-01-15T10:30:00+03:00",
              "results" : {
                "swift" : [

                ]
              }
            }
            """
        }
    }
}
