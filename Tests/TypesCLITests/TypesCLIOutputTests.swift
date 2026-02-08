import Foundation
import InlineSnapshotTesting
import Testing
import Types

/// Tests for Types.Output JSON encoding
@Suite
struct TypesCLIOutputTests {

    @Test func encodesSingleCommit() {
        let output = Types.Output(
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
                            fullName: "Components.HeaderView",
                            path: "Sources/Components/HeaderView.swift"
                        ),
                    ]
                ),
                Types.ResultItem(
                    typeName: "UIViewController",
                    types: [
                        Types.TypeInfo(
                            name: "HomeViewController",
                            fullName: "HomeViewController",
                            path: "Sources/Screens/HomeViewController.swift"
                        )
                    ]
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
                  "typeName" : "UIView",
                  "types" : [
                    {
                      "fullName" : "CustomButton",
                      "name" : "CustomButton",
                      "path" : "Sources\\/UI\\/CustomButton.swift"
                    },
                    {
                      "fullName" : "Components.HeaderView",
                      "name" : "HeaderView",
                      "path" : "Sources\\/Components\\/HeaderView.swift"
                    }
                  ]
                },
                {
                  "typeName" : "UIViewController",
                  "types" : [
                    {
                      "fullName" : "HomeViewController",
                      "name" : "HomeViewController",
                      "path" : "Sources\\/Screens\\/HomeViewController.swift"
                    }
                  ]
                }
              ]
            }
            """
        }
    }

    @Test func encodesMultipleCommits() {
        let outputs = [
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
                            )
                        ]
                    )
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
                            ),
                            Types.TypeInfo(
                                name: "NewView",
                                fullName: "NewView",
                                path: "Sources/UI/NewView.swift"
                            ),
                        ]
                    )
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
                    "typeName" : "UIView",
                    "types" : [
                      {
                        "fullName" : "CustomButton",
                        "name" : "CustomButton",
                        "path" : "Sources\\/UI\\/CustomButton.swift"
                      }
                    ]
                  }
                ]
              },
              {
                "commit" : "def5678abc1234",
                "date" : "2025-02-15T11:45:00Z",
                "results" : [
                  {
                    "typeName" : "UIView",
                    "types" : [
                      {
                        "fullName" : "CustomButton",
                        "name" : "CustomButton",
                        "path" : "Sources\\/UI\\/CustomButton.swift"
                      },
                      {
                        "fullName" : "NewView",
                        "name" : "NewView",
                        "path" : "Sources\\/UI\\/NewView.swift"
                      }
                    ]
                  }
                ]
              }
            ]
            """
        }
    }

    @Test func encodesEmptyResults() {
        let output = Types.Output(
            commit: "abc123",
            date: "2025-01-15T07:30:00Z",
            results: [
                Types.ResultItem(typeName: "UIView", types: [])
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc123",
              "date" : "2025-01-15T07:30:00Z",
              "results" : [
                {
                  "typeName" : "UIView",
                  "types" : [

                  ]
                }
              ]
            }
            """
        }
    }
}
