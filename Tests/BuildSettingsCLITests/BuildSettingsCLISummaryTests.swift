import BuildSettings
import InlineSnapshotTesting
import Testing

@testable import BuildSettingsCLI

@Suite
struct BuildSettingsCLISummaryTests {

    @Test func multipleCommits() {
        let summary = BuildSettingsCLISummary(
            outputs: [
                BuildSettings.Output(
                    commit: "abc1234def5678",
                    date: "2025-01-15T07:30:00Z",
                    results: [
                        BuildSettings.ResultItem(
                            setting: "IPHONEOS_DEPLOYMENT_TARGET",
                            targets: ["MyApp": "15.0"]
                        ),
                        BuildSettings.ResultItem(
                            setting: "SWIFT_VERSION",
                            targets: ["MyApp": "5.0", "MyFramework": "5.0"]
                        ),
                    ]
                ),
                BuildSettings.Output(
                    commit: "def5678abc1234",
                    date: "2025-02-15T11:45:00Z",
                    results: [
                        BuildSettings.ResultItem(
                            setting: "SWIFT_VERSION",
                            targets: ["MyApp": "5.9"]
                        )
                    ]
                ),
            ]
        )

        assertInlineSnapshot(of: summary, as: .description) {
            """
            # Build Settings

            | Commit | Setting | Targets |
            |--------|---------|---------|
            | `abc1234` | IPHONEOS_DEPLOYMENT_TARGET | MyApp: 15.0 |
            | `abc1234` | SWIFT_VERSION | MyApp: 5.0, MyFramework: 5.0 |
            | `def5678` | SWIFT_VERSION | MyApp: 5.9 |
            """
        }
    }

    @Test func nullTargetValue() {
        let summary = BuildSettingsCLISummary(
            outputs: [
                BuildSettings.Output(
                    commit: "abc1234def5678",
                    date: "2025-01-15T07:30:00Z",
                    results: [
                        BuildSettings.ResultItem(
                            setting: "SWIFT_VERSION",
                            targets: [
                                "MyApp": "5.0",
                                "MyFramework": nil,
                            ]
                        )
                    ]
                )
            ]
        )

        assertInlineSnapshot(of: summary, as: .description) {
            """
            # Build Settings

            | Commit | Setting | Targets |
            |--------|---------|---------|
            | `abc1234` | SWIFT_VERSION | MyApp: 5.0, MyFramework: null |
            """
        }
    }

    @Test func emptyTargets() {
        let summary = BuildSettingsCLISummary(
            outputs: [
                BuildSettings.Output(
                    commit: "abc1234def5678",
                    date: "2025-01-15T07:30:00Z",
                    results: [
                        BuildSettings.ResultItem(
                            setting: "SWIFT_VERSION",
                            targets: [:]
                        )
                    ]
                )
            ]
        )

        assertInlineSnapshot(of: summary, as: .description) {
            """
            # Build Settings

            | Commit | Setting | Targets |
            |--------|---------|---------|
            | `abc1234` | SWIFT_VERSION | — |
            """
        }
    }

    @Test func emptyOutputs() {
        let summary = BuildSettingsCLISummary(outputs: [])

        assertInlineSnapshot(of: summary, as: .description) {
            """
            # Build Settings

            No results.
            """
        }
    }
}
