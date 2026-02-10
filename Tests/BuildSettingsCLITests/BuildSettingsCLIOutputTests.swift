import BuildSettings
import Foundation
import InlineSnapshotTesting
import Testing

/// Tests for BuildSettings.Output JSON encoding
@Suite("BuildSettingsCLIOutput JSON")
struct BuildSettingsCLIOutputTests {

    @Test func encodesNullForMissingSetting() {
        let output = BuildSettings.Output(
            commit: "abc123",
            date: "2025-01-15T07:30:00Z",
            results: [
                BuildSettings.ResultItem(
                    setting: "SWIFT_VERSION",
                    targets: [
                        "MyApp": "5.0",
                        "MyAppTests": nil,
                    ]
                )
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc123",
              "date" : "2025-01-15T07:30:00Z",
              "results" : [
                {
                  "setting" : "SWIFT_VERSION",
                  "targets" : {
                    "MyApp" : "5.0",
                    "MyAppTests" : null
                  }
                }
              ]
            }
            """
        }
    }

    @Test func encodesEmptyTargets() {
        let output = BuildSettings.Output(
            commit: "abc123",
            date: "2025-01-15T07:30:00Z",
            results: [
                BuildSettings.ResultItem(
                    setting: "SWIFT_VERSION",
                    targets: [:]
                ),
                BuildSettings.ResultItem(
                    setting: "SWIFT_STRICT_CONCURRENCY",
                    targets: [:]
                ),
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc123",
              "date" : "2025-01-15T07:30:00Z",
              "results" : [
                {
                  "setting" : "SWIFT_VERSION",
                  "targets" : {

                  }
                },
                {
                  "setting" : "SWIFT_STRICT_CONCURRENCY",
                  "targets" : {

                  }
                }
              ]
            }
            """
        }
    }

    @Test func encodesArrayForMultipleCommits() {
        let outputs = [
            BuildSettings.Output(
                commit: "abc123",
                date: "2025-01-15T07:30:00Z",
                results: [
                    BuildSettings.ResultItem(
                        setting: "SWIFT_VERSION",
                        targets: ["MyApp": "5.0"]
                    )
                ]
            ),
            BuildSettings.Output(
                commit: "def456",
                date: "2025-02-15T11:45:00Z",
                results: [
                    BuildSettings.ResultItem(
                        setting: "SWIFT_VERSION",
                        targets: ["MyApp": "5.9"]
                    )
                ]
            ),
        ]

        assertInlineSnapshot(of: outputs, as: .json) {
            """
            [
              {
                "commit" : "abc123",
                "date" : "2025-01-15T07:30:00Z",
                "results" : [
                  {
                    "setting" : "SWIFT_VERSION",
                    "targets" : {
                      "MyApp" : "5.0"
                    }
                  }
                ]
              },
              {
                "commit" : "def456",
                "date" : "2025-02-15T11:45:00Z",
                "results" : [
                  {
                    "setting" : "SWIFT_VERSION",
                    "targets" : {
                      "MyApp" : "5.9"
                    }
                  }
                ]
              }
            ]
            """
        }
    }
}
