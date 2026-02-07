import Foundation
import InlineSnapshotTesting
import Testing
import TypesSDK

@testable import Types

/// Tests for TypesOutput JSON encoding
@Suite("TypesOutput JSON")
struct TypesOutputTests {

    @Test func encodesSingleCommit() {
        let output = TypesOutput(
            commit: "abc1234def5678",
            date: "2025-01-15T10:30:00+03:00",
            results: [
                "UIView": [
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
                ],
                "UIViewController": [
                    TypesSDK.TypeInfo(
                        name: "HomeViewController",
                        fullName: "HomeViewController",
                        path: "Sources/Screens/HomeViewController.swift"
                    )
                ],
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc1234def5678",
              "date" : "2025-01-15T10:30:00+03:00",
              "results" : {
                "UIView" : [
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
                ],
                "UIViewController" : [
                  {
                    "fullName" : "HomeViewController",
                    "name" : "HomeViewController",
                    "path" : "Sources\\/Screens\\/HomeViewController.swift"
                  }
                ]
              }
            }
            """
        }
    }

    @Test func encodesMultipleCommits() {
        let outputs = [
            TypesOutput(
                commit: "abc1234def5678",
                date: "2025-01-15T10:30:00+03:00",
                results: [
                    "UIView": [
                        TypesSDK.TypeInfo(
                            name: "CustomButton",
                            fullName: "CustomButton",
                            path: "Sources/UI/CustomButton.swift"
                        )
                    ]
                ]
            ),
            TypesOutput(
                commit: "def5678abc1234",
                date: "2025-02-15T14:45:00+03:00",
                results: [
                    "UIView": [
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
                ]
            ),
        ]

        assertInlineSnapshot(of: outputs, as: .json) {
            """
            [
              {
                "commit" : "abc1234def5678",
                "date" : "2025-01-15T10:30:00+03:00",
                "results" : {
                  "UIView" : [
                    {
                      "fullName" : "CustomButton",
                      "name" : "CustomButton",
                      "path" : "Sources\\/UI\\/CustomButton.swift"
                    }
                  ]
                }
              },
              {
                "commit" : "def5678abc1234",
                "date" : "2025-02-15T14:45:00+03:00",
                "results" : {
                  "UIView" : [
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
              }
            ]
            """
        }
    }

    @Test func encodesEmptyResults() {
        let output = TypesOutput(
            commit: "abc123",
            date: "2025-01-15T10:30:00+03:00",
            results: [
                "UIView": []
            ]
        )

        assertInlineSnapshot(of: output, as: .json) {
            """
            {
              "commit" : "abc123",
              "date" : "2025-01-15T10:30:00+03:00",
              "results" : {
                "UIView" : [

                ]
              }
            }
            """
        }
    }
}
