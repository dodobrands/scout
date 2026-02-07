import BuildSettingsSDK
import Foundation
import InlineSnapshotTesting
import Testing

/// Tests for BuildSettingsSDK.Output JSON encoding
@Suite("BuildSettingsOutput JSON")
struct BuildSettingsOutputTests {

    @Test func encodesNullForMissingParameters() {
        let output = BuildSettingsSDK.Output(
            commit: "abc123",
            date: "2025-01-15T10:30:00+03:00",
            results: [
                BuildSettingsSDK.ResultItem(
                    target: "MyApp",
                    settings: [
                        "MISSING_PARAM": nil,
                        "SWIFT_VERSION": "5.0",
                    ]
                )
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc123",
              "date" : "2025-01-15T10:30:00+03:00",
              "results" : [
                {
                  "settings" : {
                    "MISSING_PARAM" : null,
                    "SWIFT_VERSION" : "5.0"
                  },
                  "target" : "MyApp"
                }
              ]
            }
            """
        }
    }

    @Test func encodesAllNullParameters() {
        let output = BuildSettingsSDK.Output(
            commit: "abc123",
            date: "2025-01-15T10:30:00+03:00",
            results: [
                BuildSettingsSDK.ResultItem(
                    target: "MyApp",
                    settings: [
                        "PARAM1": nil,
                        "PARAM2": nil,
                    ]
                )
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc123",
              "date" : "2025-01-15T10:30:00+03:00",
              "results" : [
                {
                  "settings" : {
                    "PARAM1" : null,
                    "PARAM2" : null
                  },
                  "target" : "MyApp"
                }
              ]
            }
            """
        }
    }

    @Test func encodesArrayForMultipleCommits() {
        let outputs = [
            BuildSettingsSDK.Output(
                commit: "abc123",
                date: "2025-01-15T10:30:00+03:00",
                results: [
                    BuildSettingsSDK.ResultItem(target: "MyApp", settings: ["SWIFT_VERSION": "5.0"])
                ]
            ),
            BuildSettingsSDK.Output(
                commit: "def456",
                date: "2025-02-15T14:45:00+03:00",
                results: [
                    BuildSettingsSDK.ResultItem(target: "MyApp", settings: ["SWIFT_VERSION": "5.9"])
                ]
            ),
        ]

        assertInlineSnapshot(of: outputs, as: .json) {
            """
            [
              {
                "commit" : "abc123",
                "date" : "2025-01-15T10:30:00+03:00",
                "results" : [
                  {
                    "settings" : {
                      "SWIFT_VERSION" : "5.0"
                    },
                    "target" : "MyApp"
                  }
                ]
              },
              {
                "commit" : "def456",
                "date" : "2025-02-15T14:45:00+03:00",
                "results" : [
                  {
                    "settings" : {
                      "SWIFT_VERSION" : "5.9"
                    },
                    "target" : "MyApp"
                  }
                ]
              }
            ]
            """
        }
    }
}
