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
        let input = FilesInput(git: gitConfig, filetypes: ["swift"])

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
        let input = FilesInput(git: gitConfig, filetypes: ["storyboard"])

        let result = try await sut.countFiles(filetype: "storyboard", input: input)

        #expect(result.filetype == "storyboard")
        #expect(result.files.count == 1)
        #expect(result.files.first?.hasSuffix("view.storyboard") == true)
    }

    @Test
    func `When searching for xib files, should find all xibs`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = FilesInput(git: gitConfig, filetypes: ["xib"])

        let result = try await sut.countFiles(filetype: "xib", input: input)

        #expect(result.filetype == "xib")
        #expect(result.files.count == 1)
        #expect(result.files.first?.hasSuffix("cell.xib") == true)
    }

    @Test
    func `When searching for json files, should find all json files`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = FilesInput(git: gitConfig, filetypes: ["json"])

        let result = try await sut.countFiles(filetype: "json", input: input)

        #expect(result.filetype == "json")
        #expect(result.files.count == 1)
    }

    @Test
    func `When searching for non-existent extension, should return empty result`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = FilesInput(git: gitConfig, filetypes: ["xyz"])

        let result = try await sut.countFiles(filetype: "xyz", input: input)

        #expect(result.files.isEmpty)
    }

    @Test
    func `When searching for multiple filetypes, should return results for each`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = FilesInput(git: gitConfig, filetypes: ["swift", "storyboard"])

        let results = try await sut.countFiles(input: input)

        #expect(results.count == 2)
        #expect(results[0].filetype == "swift")
        #expect(results[0].files.count == 2)
        #expect(results[1].filetype == "storyboard")
        #expect(results[1].files.count == 1)
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
