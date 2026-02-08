import FilesSDK
import Foundation
import InlineSnapshotTesting
import Testing

/// Tests for FilesSDK.Output JSON encoding
@Suite
struct FilesOutputTests {

    @Test func encodesSingleCommit() {
        let output = FilesSDK.Output(
            commit: "abc1234def5678",
            date: "2025-01-15T07:30:00Z",
            results: [
                FilesSDK.ResultItem(
                    filetype: "storyboard",
                    files: ["Main.storyboard", "Launch.storyboard"]
                ),
                FilesSDK.ResultItem(
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
            FilesSDK.Output(
                commit: "abc1234def5678",
                date: "2025-01-15T07:30:00Z",
                results: [
                    FilesSDK.ResultItem(filetype: "storyboard", files: ["Main.storyboard"]),
                    FilesSDK.ResultItem(filetype: "swift", files: ["Sources/App.swift"]),
                ]
            ),
            FilesSDK.Output(
                commit: "def5678abc1234",
                date: "2025-02-15T11:45:00Z",
                results: [
                    FilesSDK.ResultItem(filetype: "storyboard", files: ["Main.storyboard"]),
                    FilesSDK.ResultItem(
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
        let output = FilesSDK.Output(
            commit: "abc123",
            date: "2025-01-15T07:30:00Z",
            results: [
                FilesSDK.ResultItem(filetype: "swift", files: [])
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
