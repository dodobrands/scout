import InlineSnapshotTesting
import Testing
import TypesSDK

@testable import Types

@Suite
struct TypesSummaryTests {

    @Test func multipleCommits() {
        let summary = TypesSummary(
            outputs: [
                TypesSDK.Output(
                    commit: "abc1234def5678",
                    date: "2025-01-15T07:30:00Z",
                    results: [
                        TypesSDK.ResultItem(
                            typeName: "UIView",
                            types: [
                                TypesSDK.TypeInfo(
                                    name: "CustomButton",
                                    fullName: "CustomButton",
                                    path: "Sources/UI/CustomButton.swift"
                                ),
                                TypesSDK.TypeInfo(
                                    name: "HeaderView",
                                    fullName: "HeaderView",
                                    path: "Sources/UI/HeaderView.swift"
                                ),
                            ]
                        ),
                        TypesSDK.ResultItem(
                            typeName: "UIViewController",
                            types: [
                                TypesSDK.TypeInfo(
                                    name: "HomeVC",
                                    fullName: "HomeVC",
                                    path: "Sources/HomeVC.swift"
                                )
                            ]
                        ),
                    ]
                ),
                TypesSDK.Output(
                    commit: "def5678abc1234",
                    date: "2025-02-15T11:45:00Z",
                    results: [
                        TypesSDK.ResultItem(
                            typeName: "UIView",
                            types: [
                                TypesSDK.TypeInfo(
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
            ## CountTypes Summary

            ### Type Counts

            | Commit | Type | Count |
            |--------|------|-------|
            | `abc1234` | `UIView` | 2 |
            | `abc1234` | `UIViewController` | 1 |
            | `def5678` | `UIView` | 1 |
            """
        }
    }

    @Test func emptyOutputs() {
        let summary = TypesSummary(outputs: [])

        assertInlineSnapshot(of: summary, as: .description) {
            """
            ## CountTypes Summary
            """
        }
    }
}
