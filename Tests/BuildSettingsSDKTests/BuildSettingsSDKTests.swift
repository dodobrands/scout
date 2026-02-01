import BuildSettingsSDK
import Foundation
import Testing

struct BuildSettingsSDKTests {
    let sut = BuildSettingsSDK()

    @Test
    func `When extracting build settings, should return targets with settings`() async throws {
        let samplesURL = try samplesDirectory()

        let result = try await sut.extractBuildSettings(
            in: samplesURL,
            setupCommands: [],
            configuration: "Debug"
        )

        #expect(result.count == 1)
        let target = try #require(result.first)
        #expect(target.target == "TestApp")
        #expect(target.buildSettings["PRODUCT_BUNDLE_IDENTIFIER"] == "com.test.TestApp")
        #expect(target.buildSettings["SWIFT_VERSION"] == "5.0")
    }
}

private func samplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}
