import Foundation
import InlineSnapshotTesting
import Testing
import TypesSDK

/// Tests for TypesSDK.Output JSON encoding
@Suite
struct TypesCLIOutputTests {

    @Test func encodesSingleCommit() {
        let output = TypesSDK.Output(
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
                            fullName: "Components.HeaderView",
                            path: "Sources/Components/HeaderView.swift"
                        ),
                    ]
                ),
                TypesSDK.ResultItem(
                    typeName: "UIViewController",
                    types: [
                        TypesSDK.TypeInfo(
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
                            )
                        ]
                    )
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
                            ),
                            TypesSDK.TypeInfo(
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
        let output = TypesSDK.Output(
            commit: "abc123",
            date: "2025-01-15T07:30:00Z",
            results: [
                TypesSDK.ResultItem(typeName: "UIView", types: [])
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
