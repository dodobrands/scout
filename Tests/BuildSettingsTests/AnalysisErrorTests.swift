import Testing

@testable import BuildSettings

struct AnalysisErrorTests {
    @Test
    func `When setup command fails without commit, description should not contain commit`() {
        let error = BuildSettings.AnalysisError.setupCommandFailed(
            command: "pod install",
            commit: nil,
            error: "exit code 1"
        )

        #expect(error.errorDescription == "Setup command 'pod install' failed: exit code 1")
    }

    @Test
    func `When setup command fails with commit, description should contain commit`() {
        let error = BuildSettings.AnalysisError.setupCommandFailed(
            command: "pod install",
            commit: "abc123",
            error: "exit code 1"
        )

        #expect(
            error.errorDescription
                == "Setup command 'pod install' failed at commit abc123: exit code 1"
        )
    }

    @Test
    func `When extraction fails without commit, description should not contain commit`() {
        let error = BuildSettings.AnalysisError.buildSettingsExtractionFailed(
            commit: nil,
            error: "xcodebuild failed"
        )

        #expect(error.errorDescription == "Build settings extraction failed: xcodebuild failed")
    }

    @Test
    func `When extraction fails with commit, description should contain commit`() {
        let error = BuildSettings.AnalysisError.buildSettingsExtractionFailed(
            commit: "def456",
            error: "xcodebuild failed"
        )

        #expect(
            error.errorDescription
                == "Build settings extraction failed at commit def456: xcodebuild failed"
        )
    }
}
