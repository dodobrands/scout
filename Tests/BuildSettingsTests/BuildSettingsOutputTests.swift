import Foundation
import InlineSnapshotTesting
import Testing

@testable import BuildSettings

/// Tests for BuildSettingsOutput JSON encoding
@Suite("BuildSettingsOutput JSON")
struct BuildSettingsOutputTests {

    @Test func encodesNullForMissingParameters() {
        let output = BuildSettingsOutput(
            commit: "abc123",
            date: "2025-01-15T10:30:00+03:00",
            results: [
                "MyApp": [
                    "SWIFT_VERSION": "5.0",
                    "MISSING_PARAM": nil,
                ]
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc123",
              "date" : "2025-01-15T10:30:00+03:00",
              "results" : {
                "MyApp" : {
                  "MISSING_PARAM" : null,
                  "SWIFT_VERSION" : "5.0"
                }
              }
            }
            """
        }
    }

    @Test func encodesAllNullParameters() {
        let output = BuildSettingsOutput(
            commit: "abc123",
            date: "2025-01-15T10:30:00+03:00",
            results: [
                "MyApp": [
                    "PARAM1": nil,
                    "PARAM2": nil,
                ]
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc123",
              "date" : "2025-01-15T10:30:00+03:00",
              "results" : {
                "MyApp" : {
                  "PARAM1" : null,
                  "PARAM2" : null
                }
              }
            }
            """
        }
    }

    @Test func encodesArrayForMultipleCommits() {
        let outputs = [
            BuildSettingsOutput(
                commit: "abc123",
                date: "2025-01-15T10:30:00+03:00",
                results: ["MyApp": ["SWIFT_VERSION": "5.0"]]
            ),
            BuildSettingsOutput(
                commit: "def456",
                date: "2025-02-15T14:45:00+03:00",
                results: ["MyApp": ["SWIFT_VERSION": "5.9"]]
            ),
        ]

        assertInlineSnapshot(of: outputs, as: .json) {
            """
            [
              {
                "commit" : "abc123",
                "date" : "2025-01-15T10:30:00+03:00",
                "results" : {
                  "MyApp" : {
                    "SWIFT_VERSION" : "5.0"
                  }
                }
              },
              {
                "commit" : "def456",
                "date" : "2025-02-15T14:45:00+03:00",
                "results" : {
                  "MyApp" : {
                    "SWIFT_VERSION" : "5.9"
                  }
                }
              }
            ]
            """
        }
    }
}
