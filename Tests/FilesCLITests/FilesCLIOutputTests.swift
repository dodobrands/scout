import Files
import Foundation
import InlineSnapshotTesting
import Testing

/// Tests for Files.Output JSON encoding
@Suite
struct FilesCLIOutputTests {

    @Test func encodesSingleCommit() {
        let output = Files.Output(
            commit: "abc1234def5678",
            date: "2025-01-15T07:30:00Z",
            results: [
                Files.ResultItem(
                    filetype: "storyboard",
                    files: ["Main.storyboard", "Launch.storyboard"]
                ),
                Files.ResultItem(
                    filetype: "swift",
                    files: ["Sources/App.swift", "Sources/Model.swift"]
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
                  "files" : [
                    "Main.storyboard",
                    "Launch.storyboard"
                  ],
                  "filetype" : "storyboard"
                },
                {
                  "files" : [
                    "Sources\\/App.swift",
                    "Sources\\/Model.swift"
                  ],
                  "filetype" : "swift"
                }
              ]
            }
            """
        }
    }

    @Test func encodesMultipleCommits() {
        let outputs = [
            Files.Output(
                commit: "abc1234def5678",
                date: "2025-01-15T07:30:00Z",
                results: [
                    Files.ResultItem(filetype: "storyboard", files: ["Main.storyboard"]),
                    Files.ResultItem(filetype: "swift", files: ["Sources/App.swift"]),
                ]
            ),
            Files.Output(
                commit: "def5678abc1234",
                date: "2025-02-15T11:45:00Z",
                results: [
                    Files.ResultItem(filetype: "storyboard", files: ["Main.storyboard"]),
                    Files.ResultItem(
                        filetype: "swift",
                        files: ["Sources/App.swift", "Sources/NewFeature.swift"]
                    ),
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
                    "files" : [
                      "Main.storyboard"
                    ],
                    "filetype" : "storyboard"
                  },
                  {
                    "files" : [
                      "Sources\\/App.swift"
                    ],
                    "filetype" : "swift"
                  }
                ]
              },
              {
                "commit" : "def5678abc1234",
                "date" : "2025-02-15T11:45:00Z",
                "results" : [
                  {
                    "files" : [
                      "Main.storyboard"
                    ],
                    "filetype" : "storyboard"
                  },
                  {
                    "files" : [
                      "Sources\\/App.swift",
                      "Sources\\/NewFeature.swift"
                    ],
                    "filetype" : "swift"
                  }
                ]
              }
            ]
            """
        }
    }

    @Test func encodesEmptyResults() {
        let output = Files.Output(
            commit: "abc123",
            date: "2025-01-15T07:30:00Z",
            results: [
                Files.ResultItem(filetype: "swift", files: [])
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc123",
              "date" : "2025-01-15T07:30:00Z",
              "results" : [
                {
                  "files" : [

                  ],
                  "filetype" : "swift"
                }
              ]
            }
            """
        }
    }
}
