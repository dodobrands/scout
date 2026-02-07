import Common
import Foundation
import Testing

@testable import FilesSDK

struct FilesSDKTests {
    let sut = FilesSDK()

    @Test
    func `When searching for swift files, should find all swift files`() async throws {
        let samplesURL = try samplesDirectory()

        let result = sut.countFiles(extension: "swift", repoPath: samplesURL)

        #expect(result.filetype == "swift")
        #expect(result.files.count == 2)
        #expect(result.files.contains { $0.hasSuffix("file1.swift") })
        #expect(result.files.contains { $0.hasSuffix("file2.swift") })
    }

    @Test
    func `When searching for storyboard files, should find all storyboards`() async throws {
        let samplesURL = try samplesDirectory()

        let result = sut.countFiles(extension: "storyboard", repoPath: samplesURL)

        #expect(result.filetype == "storyboard")
        #expect(result.files.count == 1)
        let file = try #require(result.files.first)
        #expect(file.hasSuffix("view.storyboard"))
    }

    @Test
    func `When searching for xib files, should find all xibs`() async throws {
        let samplesURL = try samplesDirectory()

        let result = sut.countFiles(extension: "xib", repoPath: samplesURL)

        #expect(result.filetype == "xib")
        #expect(result.files.count == 1)
        let file = try #require(result.files.first)
        #expect(file.hasSuffix("cell.xib"))
    }

    @Test
    func `When searching for json files, should find all json files`() async throws {
        let samplesURL = try samplesDirectory()

        let result = sut.countFiles(extension: "json", repoPath: samplesURL)

        #expect(result.filetype == "json")
        #expect(result.files.count == 1)
    }

    @Test
    func `When searching for non-existent extension, should return empty result`() async throws {
        let samplesURL = try samplesDirectory()

        let result = sut.countFiles(extension: "xyz", repoPath: samplesURL)

        #expect(result.files.isEmpty)
    }

    @Test
    func `When searching for multiple filetypes, should return results for each`() async throws {
        let samplesURL = try samplesDirectory()

        let swiftResult = sut.countFiles(extension: "swift", repoPath: samplesURL)
        let storyboardResult = sut.countFiles(extension: "storyboard", repoPath: samplesURL)

        #expect(swiftResult.filetype == "swift")
        #expect(swiftResult.files.count == 2)
        #expect(storyboardResult.filetype == "storyboard")
        #expect(storyboardResult.files.count == 1)
    }
}

private func samplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}
