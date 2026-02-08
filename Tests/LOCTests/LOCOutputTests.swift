import Foundation
import InlineSnapshotTesting
import LOCSDK
import Testing

/// Tests for LOCSDK.Output JSON encoding
@Suite
struct LOCOutputTests {

    @Test func encodesSingleCommit() {
        let output = LOCSDK.Output(
            commit: "abc1234def5678",
            date: "2025-01-15T07:30:00Z",
            results: [
                LOCSDK.ResultItem(
                    metric: "Swift, Objective-C | LegacyModule",
                    linesOfCode: 12000
                ),
                LOCSDK.ResultItem(metric: "Swift | Sources", linesOfCode: 48500),
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc1234def5678",
              "date" : "2025-01-15T07:30:00Z",
              "results" : [
                {
                  "linesOfCode" : 12000,
                  "metric" : "Swift, Objective-C | LegacyModule"
                },
                {
                  "linesOfCode" : 48500,
                  "metric" : "Swift | Sources"
                }
              ]
            }
            """
        }
    }

    @Test func encodesMultipleCommits() {
        let outputs = [
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

        assertInlineSnapshot(of: outputs, as: .json) {
            """
            [
              {
                "commit" : "abc1234def5678",
                "date" : "2025-01-15T07:30:00Z",
                "results" : [
                  {
                    "linesOfCode" : 48500,
                    "metric" : "Swift | Sources"
                  }
                ]
              },
              {
                "commit" : "def5678abc1234",
                "date" : "2025-02-15T11:45:00Z",
                "results" : [
                  {
                    "linesOfCode" : 52000,
                    "metric" : "Swift | Sources"
                  }
                ]
              }
            ]
            """
        }
    }

    @Test func encodesZeroLines() {
        let output = LOCSDK.Output(
            commit: "abc123",
            date: "2025-01-15T07:30:00Z",
            results: [
                LOCSDK.ResultItem(metric: "Swift | EmptyDir", linesOfCode: 0)
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc123",
              "date" : "2025-01-15T07:30:00Z",
              "results" : [
                {
                  "linesOfCode" : 0,
                  "metric" : "Swift | EmptyDir"
                }
              ]
            }
            """
        }
    }
}
