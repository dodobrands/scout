import Foundation
import InlineSnapshotTesting
import Testing

@testable import LOC

/// Tests for LOCOutput JSON encoding
@Suite
struct LOCOutputTests {

    @Test func encodesSingleCommit() {
        let output = LOCOutput(
            commit: "abc1234def5678",
            date: "2025-01-15T10:30:00+03:00",
            results: [
                "LOC [Swift] [Sources]": 48500,
                "LOC [Swift, Objective-C] [LegacyModule]": 12000,
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc1234def5678",
              "date" : "2025-01-15T10:30:00+03:00",
              "results" : {
                "LOC [Swift, Objective-C] [LegacyModule]" : 12000,
                "LOC [Swift] [Sources]" : 48500
              }
            }
            """
        }
    }

    @Test func encodesMultipleCommits() {
        let outputs = [
            LOCOutput(
                commit: "abc1234def5678",
                date: "2025-01-15T10:30:00+03:00",
                results: [
                    "LOC [Swift] [Sources]": 48500
                ]
            ),
            LOCOutput(
                commit: "def5678abc1234",
                date: "2025-02-15T14:45:00+03:00",
                results: [
                    "LOC [Swift] [Sources]": 52000
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
                  "LOC [Swift] [Sources]" : 48500
                }
              },
              {
                "commit" : "def5678abc1234",
                "date" : "2025-02-15T14:45:00+03:00",
                "results" : {
                  "LOC [Swift] [Sources]" : 52000
                }
              }
            ]
            """
        }
    }

    @Test func encodesZeroLines() {
        let output = LOCOutput(
            commit: "abc123",
            date: "2025-01-15T10:30:00+03:00",
            results: [
                "LOC [Swift] [EmptyDir]": 0
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc123",
              "date" : "2025-01-15T10:30:00+03:00",
              "results" : {
                "LOC [Swift] [EmptyDir]" : 0
              }
            }
            """
        }
    }
}
