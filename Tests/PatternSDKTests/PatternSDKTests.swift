import Common
import Foundation
import Testing

@testable import PatternSDK

struct PatternSDKTests {
    let sut = PatternSDK()

    @Test
    func `When searching for TODO comments, should find all occurrences`() throws {
        let samplesURL = try samplesDirectory()

        let result = try sut.search(
            pattern: "// TODO:",
            extensions: ["swift"],
            repoPath: samplesURL
        )

        #expect(result.pattern == "// TODO:")
        #expect(result.matches.count == 2)
    }

    @Test
    func `When searching for FIXME comments, should find all occurrences`() throws {
        let samplesURL = try samplesDirectory()

        let result = try sut.search(
            pattern: "// FIXME:",
            extensions: ["swift"],
            repoPath: samplesURL
        )

        #expect(result.matches.count == 2)
    }

    @Test
    func `When searching for periphery ignore, should find all annotations`() throws {
        let samplesURL = try samplesDirectory()

        let result = try sut.search(
            pattern: "periphery:ignore",
            extensions: ["swift"],
            repoPath: samplesURL
        )

        #expect(result.matches.count == 2)
    }

    @Test
    func `When searching for non-existent pattern, should return empty result`() throws {
        let samplesURL = try samplesDirectory()

        let result = try sut.search(
            pattern: "THIS_PATTERN_DOES_NOT_EXIST",
            extensions: ["swift"],
            repoPath: samplesURL
        )

        #expect(result.matches.isEmpty)
    }

    @Test
    func `When match found, should return correct line number`() throws {
        let samplesURL = try samplesDirectory()

        let result = try sut.search(
            pattern: "swiftlint:disable",
            extensions: ["swift"],
            repoPath: samplesURL
        )

        #expect(result.matches.count == 1)
        let match = try #require(result.matches.first)
        #expect(match.line == 4)
    }

    @Test
    func `When pattern found multiple times, should return different line numbers`() throws {
        let samplesURL = try samplesDirectory()

        let result = try sut.search(
            pattern: "// TODO:",
            extensions: ["swift"],
            repoPath: samplesURL
        )

        #expect(result.matches.count == 2)
        let lines = result.matches.map { $0.line }.sorted()
        #expect(lines == [7, 26])
    }

    @Test
    func `When searching for multiple patterns, should return results for each`() throws {
        let samplesURL = try samplesDirectory()

        let todoResult = try sut.search(
            pattern: "// TODO:",
            extensions: ["swift"],
            repoPath: samplesURL
        )
        let fixmeResult = try sut.search(
            pattern: "// FIXME:",
            extensions: ["swift"],
            repoPath: samplesURL
        )

        #expect(todoResult.pattern == "// TODO:")
        #expect(todoResult.matches.count == 2)
        #expect(fixmeResult.pattern == "// FIXME:")
        #expect(fixmeResult.matches.count == 2)
    }
}

private func samplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}
