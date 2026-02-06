import Common
import FilesSDK
import Foundation
import Testing

struct FilesSDKTests {
    let sut = FilesSDK()

    @Test
    func `When searching for swift files, should find all swift files`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = FilesInput(git: gitConfig, metrics: [])

        let result = try await sut.countFiles(filetype: "swift", input: input)

        #expect(result.filetype == "swift")
        #expect(result.files.count == 2)
        #expect(result.files.contains { $0.hasSuffix("file1.swift") })
        #expect(result.files.contains { $0.hasSuffix("file2.swift") })
    }

    @Test
    func `When searching for storyboard files, should find all storyboards`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = FilesInput(git: gitConfig, metrics: [])

        let result = try await sut.countFiles(filetype: "storyboard", input: input)

        #expect(result.filetype == "storyboard")
        #expect(result.files.count == 1)
        let file = try #require(result.files.first)
        #expect(file.hasSuffix("view.storyboard"))
    }

    @Test
    func `When searching for xib files, should find all xibs`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = FilesInput(git: gitConfig, metrics: [])

        let result = try await sut.countFiles(filetype: "xib", input: input)

        #expect(result.filetype == "xib")
        #expect(result.files.count == 1)
        let file = try #require(result.files.first)
        #expect(file.hasSuffix("cell.xib"))
    }

    @Test
    func `When searching for json files, should find all json files`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = FilesInput(git: gitConfig, metrics: [])

        let result = try await sut.countFiles(filetype: "json", input: input)

        #expect(result.filetype == "json")
        #expect(result.files.count == 1)
    }

    @Test
    func `When searching for non-existent extension, should return empty result`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = FilesInput(git: gitConfig, metrics: [])

        let result = try await sut.countFiles(filetype: "xyz", input: input)

        #expect(result.files.isEmpty)
    }

    @Test
    func `When searching for multiple filetypes, should return results for each`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = FilesInput(git: gitConfig, metrics: [])

        let results = try await sut.countFiles(input: input, filetypes: ["swift", "storyboard"])

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
