import Foundation
import Testing

@testable import LOCSDK

struct LOCSDKTests {
    let sut = LOCSDK()

    @Test
    func `When counting Swift LOC, should return correct count`() async throws {
        let samplesURL = try samplesDirectory()
        let metric = LOCSDK.MetricInput(languages: ["Swift"], include: ["Sources"], exclude: [])

        let result = try await sut.countLOC(metric: metric, repoPath: samplesURL)

        #expect(result.linesOfCode == 16)
    }

    @Test
    func `When exclude path specified, should not count excluded folders`() async throws {
        let samplesURL = try samplesDirectory()
        let metric = LOCSDK.MetricInput(
            languages: ["Swift"],
            include: ["Sources", "Vendor"],
            exclude: ["Vendor"]
        )

        let result = try await sut.countLOC(metric: metric, repoPath: samplesURL)

        #expect(result.linesOfCode == 16)
    }

    @Test
    func `When multiple folders in include, should count all`() async throws {
        let samplesURL = try samplesDirectory()
        let metric = LOCSDK.MetricInput(
            languages: ["Swift"],
            include: ["Sources", "Vendor"],
            exclude: []
        )

        let result = try await sut.countLOC(metric: metric, repoPath: samplesURL)

        #expect(result.linesOfCode == 22)
    }

    @Test
    func `When include path does not exist, should return zero`() async throws {
        let samplesURL = try samplesDirectory()
        let metric = LOCSDK.MetricInput(
            languages: ["Swift"],
            include: ["NonExistentFolder"],
            exclude: []
        )

        let result = try await sut.countLOC(metric: metric, repoPath: samplesURL)

        #expect(result.linesOfCode == 0)
    }

    @Test
    func `When language has no files, should return zero`() async throws {
        let samplesURL = try samplesDirectory()
        let metric = LOCSDK.MetricInput(languages: ["Rust"], include: ["Sources"], exclude: [])

        let result = try await sut.countLOC(metric: metric, repoPath: samplesURL)

        #expect(result.linesOfCode == 0)
    }

    @Test
    func `When counting multiple configurations, should return results for each`() async throws {
        let samplesURL = try samplesDirectory()
        let metric1 = LOCSDK.MetricInput(languages: ["Swift"], include: ["Sources"], exclude: [])
        let metric2 = LOCSDK.MetricInput(languages: ["Swift"], include: ["Vendor"], exclude: [])

        let result1 = try await sut.countLOC(metric: metric1, repoPath: samplesURL)
        let result2 = try await sut.countLOC(metric: metric2, repoPath: samplesURL)

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
