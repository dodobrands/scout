import Foundation
import Testing

@testable import BuildSettingsSDK

struct BuildSettingsSDKTests {
    let sut = BuildSettingsSDK()

    @Test
    func `When extracting build settings, should return targets with settings`() async throws {
        let samplesURL = try samplesDirectory()
        let input = BuildSettingsSDK.AnalysisInput(
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
        let failingCommand = BuildSettingsSDK.SetupCommand(command: "exit 1")
        let input = BuildSettingsSDK.AnalysisInput(
            repoPath: samplesURL.path,
            setupCommands: [failingCommand],
            project: "TestApp.xcodeproj",
            configuration: "Debug"
        )

        await #expect(throws: BuildSettingsSDK.AnalysisError.self) {
            _ = try await sut.extractBuildSettings(input: input)
        }
    }

    @Test
    func `When optional setup command fails, should continue`() async throws {
        let samplesURL = try samplesDirectory()
        let optionalFailingCommand = BuildSettingsSDK.SetupCommand(
            command: "exit 1",
            optional: true
        )
        let input = BuildSettingsSDK.AnalysisInput(
            repoPath: samplesURL.path,
            setupCommands: [optionalFailingCommand],
            project: "TestApp.xcodeproj",
            configuration: "Debug"
        )

        let result = try await sut.extractBuildSettings(input: input)

        #expect(result.count == 1)
    }
    @Test
    func snapshot() async throws {
        let samplesURL = try samplesDirectory()
        let input = BuildSettingsSDK.AnalysisInput(
            repoPath: samplesURL.path,
            setupCommands: [],
            project: "TestApp.xcodeproj",
            configuration: "Debug"
        )

        let result = try await sut.extractBuildSettings(input: input)

        #expect(result.count == 1)
        let target = try #require(result.first)
        #expect(
            target
                == TargetWithBuildSettings(
                    target: "TestApp",
                    buildSettings: target.buildSettings
                )
        )
        #expect(target.buildSettings["PRODUCT_BUNDLE_IDENTIFIER"] == "com.test.TestApp")
        #expect(target.buildSettings["SWIFT_VERSION"] == "5.0")
        #expect(target.buildSettings["PRODUCT_NAME"] == "TestApp")
    }
}

private func samplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}
