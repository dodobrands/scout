import Foundation
import Testing

@testable import BuildSettings

/// Tests for BuildSettingsOutput JSON encoding
@Suite("BuildSettingsOutput JSON")
struct BuildSettingsOutputTests {

    @Test func `encodes null for missing parameters`() throws {
        let output = BuildSettingsOutput(
            commit: "abc123",
            date: "2025-01-15",
            results: [
                "MyApp": [
                    "SWIFT_VERSION": "5.0",
                    "MISSING_PARAM": nil,
                ]
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(output)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"MISSING_PARAM\":null"))
        #expect(json.contains("\"SWIFT_VERSION\":\"5.0\""))
    }

    @Test func `encodes empty results for target with no matching parameters`() throws {
        let output = BuildSettingsOutput(
            commit: "abc123",
            date: "2025-01-15",
            results: [
                "MyApp": [
                    "PARAM1": nil,
                    "PARAM2": nil,
                ]
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(output)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"PARAM1\":null"))
        #expect(json.contains("\"PARAM2\":null"))
    }

    @Test func `encodes array format for multiple commits`() throws {
        let outputs = [
            BuildSettingsOutput(
                commit: "abc123",
                date: "2025-01-15",
                results: ["MyApp": ["SWIFT_VERSION": "5.0"]]
            ),
            BuildSettingsOutput(
                commit: "def456",
                date: "2025-02-15",
                results: ["MyApp": ["SWIFT_VERSION": "5.9"]]
            ),
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(outputs)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.hasPrefix("["))
        #expect(json.hasSuffix("]"))
        #expect(json.contains("abc123"))
        #expect(json.contains("def456"))
    }
}
