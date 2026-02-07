import Common
import Foundation
import Testing

@testable import PatternSDK

struct PatternSDKTests {
    let sut = PatternSDK()

    @Test
    func `When searching for TODO comments, should find all occurrences`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = PatternSDK.Input(

            git: gitConfig,
            metrics: [PatternSDK.MetricInput(pattern: "// TODO:")]
        )

        let results = try await sut.search(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.pattern == "// TODO:")
        #expect(result.matches.count == 2)
    }

    @Test
    func `When searching for FIXME comments, should find all occurrences`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = PatternSDK.Input(

            git: gitConfig,
            metrics: [PatternSDK.MetricInput(pattern: "// FIXME:")]
        )

        let results = try await sut.search(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.matches.count == 2)
    }

    @Test
    func `When searching for periphery ignore, should find all annotations`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = PatternSDK.Input(

            git: gitConfig,
            metrics: [PatternSDK.MetricInput(pattern: "periphery:ignore")]
        )

        let results = try await sut.search(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.matches.count == 2)
    }

    @Test
    func `When searching for non-existent pattern, should return empty result`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = PatternSDK.Input(

            git: gitConfig,
            metrics: [PatternSDK.MetricInput(pattern: "THIS_PATTERN_DOES_NOT_EXIST")]
        )

        let results = try await sut.search(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.matches.isEmpty)
    }

    @Test
    func `When match found, should return correct line number`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = PatternSDK.Input(

            git: gitConfig,
            metrics: [PatternSDK.MetricInput(pattern: "swiftlint:disable")]
        )

        let results = try await sut.search(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.matches.count == 1)
        let match = try #require(result.matches.first)
        #expect(match.line == 4)
    }

    @Test
    func `When pattern found multiple times, should return different line numbers`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = PatternSDK.Input(

            git: gitConfig,
            metrics: [PatternSDK.MetricInput(pattern: "// TODO:")]
        )

        let results = try await sut.search(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.matches.count == 2)
        let lines = result.matches.map { $0.line }.sorted()
        #expect(lines == [7, 26])
    }

    @Test
    func `When searching for multiple patterns, should return results for each`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = PatternSDK.Input(

            git: gitConfig,
            metrics: [
                PatternSDK.MetricInput(pattern: "// TODO:"),
                PatternSDK.MetricInput(pattern: "// FIXME:"),
            ]
        )

        let results = try await sut.search(input: input)

        #expect(results.count == 2)
        let result0 = try #require(results[safe: 0])
        let result1 = try #require(results[safe: 1])
        #expect(result0.pattern == "// TODO:")
        #expect(result0.matches.count == 2)
        #expect(result1.pattern == "// FIXME:")
        #expect(result1.matches.count == 2)
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
