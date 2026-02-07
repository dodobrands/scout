import Common
import Foundation
import Testing

@testable import LOCSDK

struct LOCSDKTests {
    let sut = LOCSDK()

    @Test
    func `When counting Swift LOC, should return correct count`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = LOCSDK.Input(
            git: gitConfig,
            metrics: [LOCSDK.MetricInput(languages: ["Swift"], include: ["Sources"], exclude: [])]
        )

        let outputs = try await sut.analyze(input: input)

        let output = try #require(outputs[safe: 0])
        let result = try #require(output.results[safe: 0])
        #expect(result.linesOfCode == 16)
    }

    @Test
    func `When exclude path specified, should not count excluded folders`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = LOCSDK.Input(
            git: gitConfig,
            metrics: [
                LOCSDK.MetricInput(
                    languages: ["Swift"],
                    include: ["Sources", "Vendor"],
                    exclude: ["Vendor"]
                )
            ]
        )

        let outputs = try await sut.analyze(input: input)

        let output = try #require(outputs[safe: 0])
        let result = try #require(output.results[safe: 0])
        #expect(result.linesOfCode == 16)
    }

    @Test
    func `When multiple folders in include, should count all`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = LOCSDK.Input(
            git: gitConfig,
            metrics: [
                LOCSDK.MetricInput(
                    languages: ["Swift"],
                    include: ["Sources", "Vendor"],
                    exclude: []
                )
            ]
        )

        let outputs = try await sut.analyze(input: input)

        let output = try #require(outputs[safe: 0])
        let result = try #require(output.results[safe: 0])
        #expect(result.linesOfCode == 22)
    }

    @Test
    func `When include path does not exist, should return zero`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = LOCSDK.Input(
            git: gitConfig,
            metrics: [
                LOCSDK.MetricInput(
                    languages: ["Swift"],
                    include: ["NonExistentFolder"],
                    exclude: []
                )
            ]
        )

        let outputs = try await sut.analyze(input: input)

        let output = try #require(outputs[safe: 0])
        let result = try #require(output.results[safe: 0])
        #expect(result.linesOfCode == 0)
    }

    @Test
    func `When language has no files, should return zero`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = LOCSDK.Input(
            git: gitConfig,
            metrics: [LOCSDK.MetricInput(languages: ["Rust"], include: ["Sources"], exclude: [])]
        )

        let outputs = try await sut.analyze(input: input)

        let output = try #require(outputs[safe: 0])
        let result = try #require(output.results[safe: 0])
        #expect(result.linesOfCode == 0)
    }

    @Test
    func `When counting multiple configurations, should return results for each`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = LOCSDK.Input(
            git: gitConfig,
            metrics: [
                LOCSDK.MetricInput(languages: ["Swift"], include: ["Sources"], exclude: []),
                LOCSDK.MetricInput(languages: ["Swift"], include: ["Vendor"], exclude: []),
            ]
        )

        let outputs = try await sut.analyze(input: input)

        let output = try #require(outputs[safe: 0])
        #expect(output.results.count == 2)
        let result0 = try #require(output.results[safe: 0])
        let result1 = try #require(output.results[safe: 1])
        #expect(result0.linesOfCode == 16)
        #expect(result1.linesOfCode == 6)
    }
}

private func samplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}

extension GitConfiguration {
    static func test(repoPath: String) -> GitConfiguration {
        GitConfiguration(
            repoPath: repoPath,
            clean: false,
            fixLFS: false,
            initializeSubmodules: false
        )
    }
}
