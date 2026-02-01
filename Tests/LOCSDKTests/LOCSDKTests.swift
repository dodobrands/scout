import Common
import Foundation
import LOCSDK
import Testing

struct LOCSDKTests {
    let sut = LOCSDK()

    @Test
    func `When counting Swift LOC, should return correct count`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let config = LOCConfiguration(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: []
        )
        let input = LOCInput(git: gitConfig, configuration: config)

        let result = try await sut.countLOC(configuration: config, input: input)

        #expect(result.linesOfCode == 16)
    }

    @Test
    func `When exclude path specified, should not count excluded folders`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let configWithExclude = LOCConfiguration(
            languages: ["Swift"],
            include: ["Sources", "Vendor"],
            exclude: ["Vendor"]
        )
        let input = LOCInput(git: gitConfig, configuration: configWithExclude)

        let result = try await sut.countLOC(configuration: configWithExclude, input: input)

        #expect(result.linesOfCode == 16)
    }

    @Test
    func `When multiple folders in include, should count all`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let config = LOCConfiguration(
            languages: ["Swift"],
            include: ["Sources", "Vendor"],
            exclude: []
        )
        let input = LOCInput(git: gitConfig, configuration: config)

        let result = try await sut.countLOC(configuration: config, input: input)

        #expect(result.linesOfCode == 22)
    }

    @Test
    func `When include path does not exist, should return zero`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let config = LOCConfiguration(
            languages: ["Swift"],
            include: ["NonExistentFolder"],
            exclude: []
        )
        let input = LOCInput(git: gitConfig, configuration: config)

        let result = try await sut.countLOC(configuration: config, input: input)

        #expect(result.linesOfCode == 0)
    }

    @Test
    func `When language has no files, should return zero`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let config = LOCConfiguration(
            languages: ["Rust"],
            include: ["Sources"],
            exclude: []
        )
        let input = LOCInput(git: gitConfig, configuration: config)

        let result = try await sut.countLOC(configuration: config, input: input)

        #expect(result.linesOfCode == 0)
    }

    @Test
    func `When counting multiple configurations, should return results for each`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let config1 = LOCConfiguration(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: []
        )
        let config2 = LOCConfiguration(
            languages: ["Swift"],
            include: ["Vendor"],
            exclude: []
        )
        let input = LOCInput(git: gitConfig, configurations: [config1, config2])

        let results = try await sut.countLOC(input: input)

        #expect(results.count == 2)
        #expect(results[0].linesOfCode == 16)
        #expect(results[1].linesOfCode == 6)
    }
}

private func samplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}
