import Foundation
import Testing

@testable import BuildSettings

struct BuildSettingsTests {
    let sut = BuildSettings()

    @Test
    func `When extracting build settings, should return targets with settings`() async throws {
        let samplesURL = try samplesDirectory()
        let input = BuildSettings.AnalysisInput(
            repoPath: samplesURL.path,
            setupCommands: [],
            project: "TestApp.xcodeproj",
            configuration: "Debug"
        )

        let result = try await sut.extractBuildSettings(input: input)

        #expect(result.count == 1)
        let target = try #require(result.first)
        #expect(target.target == "TestApp")
        #expect(target.buildSettings["PRODUCT_BUNDLE_IDENTIFIER"] == "com.test.TestApp")
        #expect(target.buildSettings["SWIFT_VERSION"] == "5.0")
    }

    @Test
    func `When setup command fails, should throw error`() async throws {
        let samplesURL = try samplesDirectory()
        let failingCommand = BuildSettings.SetupCommand(command: "/usr/bin/false")
        let input = BuildSettings.AnalysisInput(
            repoPath: samplesURL.path,
            setupCommands: [failingCommand],
            project: "TestApp.xcodeproj",
            configuration: "Debug"
        )

        await #expect(throws: BuildSettings.AnalysisError.self) {
            _ = try await sut.extractBuildSettings(input: input)
        }
    }

    @Test
    func `When setup command fails with commit, error should contain commit`() async throws {
        let samplesURL = try samplesDirectory()
        let failingCommand = BuildSettings.SetupCommand(command: "/usr/bin/false")
        let input = BuildSettings.AnalysisInput(
            repoPath: samplesURL.path,
            setupCommands: [failingCommand],
            project: "TestApp.xcodeproj",
            configuration: "Debug"
        )
        let commit = "abc123"

        do {
            _ = try await sut.extractBuildSettings(input: input, commit: commit)
            Issue.record("Expected error to be thrown")
        } catch {
            let description = error.localizedDescription
            #expect(description.contains(commit))
        }
    }

    @Test
    func `When project not found, should return empty results`() async throws {
        let samplesURL = try samplesDirectory()
        let input = BuildSettings.AnalysisInput(
            repoPath: samplesURL.path,
            setupCommands: [],
            project: "NonExistent.xcodeproj",
            configuration: "Debug"
        )

        let result = try await sut.extractBuildSettings(input: input)

        #expect(result.isEmpty)
    }

    @Test
    func `When optional setup command fails, should continue`() async throws {
        let samplesURL = try samplesDirectory()
        let optionalFailingCommand = BuildSettings.SetupCommand(
            command: "/usr/bin/false",
            optional: true
        )
        let input = BuildSettings.AnalysisInput(
            repoPath: samplesURL.path,
            setupCommands: [optionalFailingCommand],
            project: "TestApp.xcodeproj",
            configuration: "Debug"
        )

        let result = try await sut.extractBuildSettings(input: input)

        #expect(result.count == 1)
    }
}

private func samplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}
