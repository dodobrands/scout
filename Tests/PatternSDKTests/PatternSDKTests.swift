import Foundation
import PatternSDK
import Testing

struct PatternSDKTests {
    let sut = PatternSDK()

    @Test
    func `When searching for TODO comments, should find all occurrences`() async throws {
        let samplesURL = try samplesDirectory()

        let result = try await sut.search(pattern: "// TODO:", in: samplesURL)

        #expect(result.pattern == "// TODO:")
        #expect(result.matches.count == 2)
    }

    @Test
    func `When searching for FIXME comments, should find all occurrences`() async throws {
        let samplesURL = try samplesDirectory()

        let result = try await sut.search(pattern: "// FIXME:", in: samplesURL)

        #expect(result.matches.count == 2)
    }

    @Test
    func `When searching for periphery ignore, should find all annotations`() async throws {
        let samplesURL = try samplesDirectory()

        let result = try await sut.search(pattern: "periphery:ignore", in: samplesURL)

        #expect(result.matches.count == 2)
    }

    @Test
    func `When searching for non-existent pattern, should return empty result`() async throws {
        let samplesURL = try samplesDirectory()

        let result = try await sut.search(pattern: "THIS_PATTERN_DOES_NOT_EXIST", in: samplesURL)

        #expect(result.matches.isEmpty)
    }

    @Test
    func `When match found, should return correct line number`() async throws {
        let samplesURL = try samplesDirectory()

        let result = try await sut.search(pattern: "swiftlint:disable", in: samplesURL)

        #expect(result.matches.count == 1)
        #expect(result.matches.first?.line == 4)
    }

    @Test
    func `When pattern found multiple times, should return different line numbers`() async throws {
        let samplesURL = try samplesDirectory()

        let result = try await sut.search(pattern: "// TODO:", in: samplesURL)

        #expect(result.matches.count == 2)
        let lines = result.matches.map { $0.line }.sorted()
        #expect(lines == [7, 26])
    }
}

private func samplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}
