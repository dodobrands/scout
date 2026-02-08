import Foundation
import Testing

@testable import LOC

struct LOCTests {
    let sut = LOC()

    @Test
    func `When counting Swift LOC, should return correct count`() async throws {
        let samplesURL = try samplesDirectory()
        let metricInput = LOC.MetricInput(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: []
        )
        let input = LOC.AnalysisInput(
            repoPath: samplesURL.path,
            languages: metricInput.languages,
            include: metricInput.include,
            exclude: metricInput.exclude,
            metricIdentifier: metricInput.metricIdentifier
        )

        let result = try await sut.countLOC(input: input)

        #expect(result.linesOfCode == 16)
    }

    @Test
    func `When exclude path specified, should not count excluded folders`() async throws {
        let samplesURL = try samplesDirectory()
        let metricInput = LOC.MetricInput(
            languages: ["Swift"],
            include: ["Sources", "Vendor"],
            exclude: ["Vendor"]
        )
        let input = LOC.AnalysisInput(
            repoPath: samplesURL.path,
            languages: metricInput.languages,
            include: metricInput.include,
            exclude: metricInput.exclude,
            metricIdentifier: metricInput.metricIdentifier
        )

        let result = try await sut.countLOC(input: input)

        #expect(result.linesOfCode == 16)
    }

    @Test
    func `When multiple folders in include, should count all`() async throws {
        let samplesURL = try samplesDirectory()
        let metricInput = LOC.MetricInput(
            languages: ["Swift"],
            include: ["Sources", "Vendor"],
            exclude: []
        )
        let input = LOC.AnalysisInput(
            repoPath: samplesURL.path,
            languages: metricInput.languages,
            include: metricInput.include,
            exclude: metricInput.exclude,
            metricIdentifier: metricInput.metricIdentifier
        )

        let result = try await sut.countLOC(input: input)

        #expect(result.linesOfCode == 22)
    }

    @Test
    func `When include path does not exist, should return zero`() async throws {
        let samplesURL = try samplesDirectory()
        let metricInput = LOC.MetricInput(
            languages: ["Swift"],
            include: ["NonExistentFolder"],
            exclude: []
        )
        let input = LOC.AnalysisInput(
            repoPath: samplesURL.path,
            languages: metricInput.languages,
            include: metricInput.include,
            exclude: metricInput.exclude,
            metricIdentifier: metricInput.metricIdentifier
        )

        let result = try await sut.countLOC(input: input)

        #expect(result.linesOfCode == 0)
    }

    @Test
    func `When language has no files, should return zero`() async throws {
        let samplesURL = try samplesDirectory()
        let metricInput = LOC.MetricInput(languages: ["Rust"], include: ["Sources"], exclude: [])
        let input = LOC.AnalysisInput(
            repoPath: samplesURL.path,
            languages: metricInput.languages,
            include: metricInput.include,
            exclude: metricInput.exclude,
            metricIdentifier: metricInput.metricIdentifier
        )

        let result = try await sut.countLOC(input: input)

        #expect(result.linesOfCode == 0)
    }

    @Test
    func `When counting multiple configurations, should return results for each`() async throws {
        let samplesURL = try samplesDirectory()
        let metric1 = LOC.MetricInput(languages: ["Swift"], include: ["Sources"], exclude: [])
        let metric2 = LOC.MetricInput(languages: ["Swift"], include: ["Vendor"], exclude: [])

        let input1 = LOC.AnalysisInput(
            repoPath: samplesURL.path,
            languages: metric1.languages,
            include: metric1.include,
            exclude: metric1.exclude,
            metricIdentifier: metric1.metricIdentifier
        )
        let input2 = LOC.AnalysisInput(
            repoPath: samplesURL.path,
            languages: metric2.languages,
            include: metric2.include,
            exclude: metric2.exclude,
            metricIdentifier: metric2.metricIdentifier
        )

        let result1 = try await sut.countLOC(input: input1)
        let result2 = try await sut.countLOC(input: input2)

        #expect(result1.linesOfCode == 16)
        #expect(result2.linesOfCode == 6)
    }
}

private func samplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}
