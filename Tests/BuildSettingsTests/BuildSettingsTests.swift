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
            project: BuildSettings.Project(path: "TestApp.xcodeproj"),
            configuration: "Debug"
        )

        let result = try await sut.extractBuildSettings(input: input, commit: "test-commit")

        let target = try #require(result.first)
        #expect(target.target == "TestApp")
        #expect(target.buildSettings["PRODUCT_BUNDLE_IDENTIFIER"] == "com.test.TestApp")
        #expect(target.buildSettings["SWIFT_VERSION"] == "5.0")
    }

    @Test
    func `When project not found and continueOnMissingProject, should return empty`() async throws {
        let samplesURL = try samplesDirectory()
        let input = BuildSettings.AnalysisInput(
            repoPath: samplesURL.path,
            setupCommands: [],
            project: BuildSettings.Project(
                path: "NonExistent.xcodeproj",
                continueOnMissing: true
            ),
            configuration: "Debug"
        )

        let result = try await sut.extractBuildSettings(input: input, commit: "test-commit")

        #expect(result.isEmpty)
    }

    @Test
    func `When project not found and not continueOnMissingProject, should throw`() async throws {
        let samplesURL = try samplesDirectory()
        let input = BuildSettings.AnalysisInput(
            repoPath: samplesURL.path,
            setupCommands: [],
            project: BuildSettings.Project(path: "NonExistent.xcodeproj"),
            configuration: "Debug"
        )

        await #expect(throws: BuildSettings.AnalysisError.self) {
            _ = try await sut.extractBuildSettings(input: input, commit: "test-commit")
        }
    }

    @Test(arguments: [
        ("App.xcworkspace", true),
        ("App.xcworkspace/", true),
        ("App.xcodeproj", false),
        ("App.xcodeproj/", false),
        ("/absolute/path/App.xcworkspace", true),
        ("/absolute/path/App.xcworkspace/", true),
        ("/absolute/path/App.xcodeproj", false),
    ])
    func `isWorkspace detection`(path: String, expected: Bool) {
        #expect(ProjectOrWorkspace.isWorkspace(path: path) == expected)
    }

    @Test
    func `When setup command fails, should throw error`() async throws {
        let samplesURL = try samplesDirectory()
        let failingCommand = BuildSettings.SetupCommand(command: "/usr/bin/false")
        let input = BuildSettings.AnalysisInput(
            repoPath: samplesURL.path,
            setupCommands: [failingCommand],
            project: BuildSettings.Project(path: "TestApp.xcodeproj"),
            configuration: "Debug"
        )

        await #expect(throws: BuildSettings.AnalysisError.self) {
            _ = try await sut.extractBuildSettings(input: input, commit: "test-commit")
        }
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
            project: BuildSettings.Project(path: "TestApp.xcodeproj"),
            configuration: "Debug"
        )

        let result = try await sut.extractBuildSettings(input: input, commit: "test-commit")

        #expect(result.count == 1)
    }
}

private func samplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}
