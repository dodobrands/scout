import BuildSettingsSDK
import InlineSnapshotTesting
import Testing

@testable import BuildSettingsCLI

@Suite
struct BuildSettingsCLISummaryTests {

    @Test func multipleCommits() {
        let summary = BuildSettingsCLISummary(
            outputs: [
                BuildSettingsSDK.Output(
                    commit: "abc1234def5678",
                    date: "2025-01-15T07:30:00Z",
                    results: [
                        BuildSettingsSDK.ResultItem(
                            target: "MyApp",
                            settings: [
                                "SWIFT_VERSION": "5.0",
                                "IPHONEOS_DEPLOYMENT_TARGET": "15.0",
                            ]
                        ),
                        BuildSettingsSDK.ResultItem(
                            target: "MyFramework",
                            settings: ["SWIFT_VERSION": "5.0"]
                        ),
                    ]
                ),
                BuildSettingsSDK.Output(
                    commit: "def5678abc1234",
                    date: "2025-02-15T11:45:00Z",
                    results: [
                        BuildSettingsSDK.ResultItem(
                            target: "MyApp",
                            settings: ["SWIFT_VERSION": "5.9"]
                        )
                    ]
                ),
            ]
        )

        assertInlineSnapshot(of: summary, as: .description) {
            """
            # Build Settings

            | Commit | Target | Settings |
            |--------|--------|----------|
            | `abc1234` | `MyApp` | IPHONEOS_DEPLOYMENT_TARGET: 15.0, SWIFT_VERSION: 5.0 |
            | `abc1234` | `MyFramework` | SWIFT_VERSION: 5.0 |
            | `def5678` | `MyApp` | SWIFT_VERSION: 5.9 |
            """
        }
    }

    @Test func nullSettings() {
        let summary = BuildSettingsCLISummary(
            outputs: [
                BuildSettingsSDK.Output(
                    commit: "abc1234def5678",
                    date: "2025-01-15T07:30:00Z",
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
            ]
        )

        assertInlineSnapshot(of: summary, as: .description) {
            """
            # Build Settings

            | Commit | Target | Settings |
            |--------|--------|----------|
            | `abc1234` | `MyApp` | MISSING_PARAM: null, SWIFT_VERSION: 5.0 |
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
