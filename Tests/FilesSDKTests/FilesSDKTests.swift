import Common
import Foundation
import Testing

@testable import FilesSDK

struct FilesSDKTests {
    let sut = FilesSDK()

    @Test
    func `When searching for swift files, should find all swift files`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = FilesInput(
            git: gitConfig,
            metrics: [FileMetricInput(extension: "swift")]
        )

        let results = try await sut.countFiles(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.filetype == "swift")
        #expect(result.files.count == 2)
        #expect(result.files.contains { $0.hasSuffix("file1.swift") })
        #expect(result.files.contains { $0.hasSuffix("file2.swift") })
    }

    @Test
    func `When searching for storyboard files, should find all storyboards`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = FilesInput(
            git: gitConfig,
            metrics: [FileMetricInput(extension: "storyboard")]
        )

        let results = try await sut.countFiles(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.filetype == "storyboard")
        #expect(result.files.count == 1)
        let file = try #require(result.files.first)
        #expect(file.hasSuffix("view.storyboard"))
    }

    @Test
    func `When searching for xib files, should find all xibs`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = FilesInput(
            git: gitConfig,
            metrics: [FileMetricInput(extension: "xib")]
        )

        let results = try await sut.countFiles(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.filetype == "xib")
        #expect(result.files.count == 1)
        let file = try #require(result.files.first)
        #expect(file.hasSuffix("cell.xib"))
    }

    @Test
    func `When searching for json files, should find all json files`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = FilesInput(
            git: gitConfig,
            metrics: [FileMetricInput(extension: "json")]
        )

        let results = try await sut.countFiles(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.filetype == "json")
        #expect(result.files.count == 1)
    }

    @Test
    func `When searching for non-existent extension, should return empty result`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = FilesInput(
            git: gitConfig,
            metrics: [FileMetricInput(extension: "xyz")]
        )

        let results = try await sut.countFiles(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.files.isEmpty)
    }

    @Test
    func `When searching for multiple filetypes, should return results for each`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = FilesInput(
            git: gitConfig,
            metrics: [
                FileMetricInput(extension: "swift"),
                FileMetricInput(extension: "storyboard"),
            ]
        )

        let results = try await sut.countFiles(input: input)

        #expect(results.count == 2)
        let result0 = try #require(results[safe: 0])
        let result1 = try #require(results[safe: 1])
        #expect(result0.filetype == "swift")
        #expect(result0.files.count == 2)
        #expect(result1.filetype == "storyboard")
        #expect(result1.files.count == 1)
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
