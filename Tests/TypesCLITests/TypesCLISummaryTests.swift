import InlineSnapshotTesting
import Testing
import Types

@testable import TypesCLI

struct TypesCLISummaryTests {

    @Test func `multiple commits`() {
        let summary = TypesCLISummary(
            outputs: [
                Types.Output(
                    commit: "abc1234def5678",
                    date: "2025-01-15T07:30:00Z",
                    results: [
                        Types.ResultItem(
                            typeName: "UIView",
                            types: [
                                Types.TypeInfo(
                                    name: "CustomButton",
                                    fullName: "CustomButton",
                                    path: "Sources/UI/CustomButton.swift"
                                ),
                                Types.TypeInfo(
                                    name: "HeaderView",
                                    fullName: "HeaderView",
                                    path: "Sources/UI/HeaderView.swift"
                                ),
                            ]
                        ),
                        Types.ResultItem(
                            typeName: "UIViewController",
                            types: [
                                Types.TypeInfo(
                                    name: "HomeVC",
                                    fullName: "HomeVC",
                                    path: "Sources/HomeVC.swift"
                                )
                            ]
                        ),
                    ]
                ),
                Types.Output(
                    commit: "def5678abc1234",
                    date: "2025-02-15T11:45:00Z",
                    results: [
                        Types.ResultItem(
                            typeName: "UIView",
                            types: [
                                Types.TypeInfo(
                                    name: "CustomButton",
                                    fullName: "CustomButton",
                                    path: "Sources/UI/CustomButton.swift"
                                )
                            ]
                        )
                    ]
                ),
            ]
        )

        assertInlineSnapshot(of: summary, as: .description) {
            """
            # Type Counts

            | Commit | Type | Count |
            |--------|------|-------|
            | `abc1234` | `UIView` | 2 |
            | `abc1234` | `UIViewController` | 1 |
            | `def5678` | `UIView` | 1 |
            """
        }
    }

    @Test func `empty outputs`() {
        let summary = TypesCLISummary(outputs: [])

        assertInlineSnapshot(of: summary, as: .description) {
            """
            # Type Counts

            No results.
            """
        }
    }
}
