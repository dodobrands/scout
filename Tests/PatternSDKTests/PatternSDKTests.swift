import Common
import Foundation
import PatternSDK
import Testing

struct PatternSDKTests {
    let sut = PatternSDK()

    @Test
    func `When searching for TODO comments, should find all occurrences`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = PatternInput(
            git: gitConfig,
            metrics: [PatternMetricInput(pattern: "// TODO:")]
        )

        let result = try await sut.search(pattern: "// TODO:", input: input)

        #expect(result.pattern == "// TODO:")
        #expect(result.matches.count == 2)
    }

    @Test
    func `When searching for FIXME comments, should find all occurrences`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = PatternInput(
            git: gitConfig,
            metrics: [PatternMetricInput(pattern: "// FIXME:")]
        )

        let result = try await sut.search(pattern: "// FIXME:", input: input)

        #expect(result.matches.count == 2)
    }

    @Test
    func `When searching for periphery ignore, should find all annotations`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = PatternInput(
            git: gitConfig,
            metrics: [PatternMetricInput(pattern: "periphery:ignore")]
        )

        let result = try await sut.search(pattern: "periphery:ignore", input: input)

        #expect(result.matches.count == 2)
    }

    @Test
    func `When searching for non-existent pattern, should return empty result`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = PatternInput(
            git: gitConfig,
            metrics: [PatternMetricInput(pattern: "THIS_PATTERN_DOES_NOT_EXIST")]
        )

        let result = try await sut.search(pattern: "THIS_PATTERN_DOES_NOT_EXIST", input: input)

        #expect(result.matches.isEmpty)
    }

    @Test
    func `When match found, should return correct line number`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = PatternInput(
            git: gitConfig,
            metrics: [PatternMetricInput(pattern: "swiftlint:disable")]
        )

        let result = try await sut.search(pattern: "swiftlint:disable", input: input)

        #expect(result.matches.count == 1)
        let match = try #require(result.matches.first)
        #expect(match.line == 4)
    }

    @Test
    func `When pattern found multiple times, should return different line numbers`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = PatternInput(
            git: gitConfig,
            metrics: [PatternMetricInput(pattern: "// TODO:")]
        )

        let result = try await sut.search(pattern: "// TODO:", input: input)

        #expect(result.matches.count == 2)
        let lines = result.matches.map { $0.line }.sorted()
        #expect(lines == [7, 26])
    }

    @Test
    func `When searching for multiple patterns, should return results for each`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = PatternInput(
            git: gitConfig,
            metrics: [
                PatternMetricInput(pattern: "// TODO:"),
                PatternMetricInput(pattern: "// FIXME:"),
            ]
        )

        let results = try await sut.search(patterns: ["// TODO:", "// FIXME:"], input: input)

        #expect(results.count == 2)
        #expect(results[0].pattern == "// TODO:")
        #expect(results[0].matches.count == 2)
        #expect(results[1].pattern == "// FIXME:")
        #expect(results[1].matches.count == 2)
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
