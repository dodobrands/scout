import FilesSDK
import Foundation
import Testing

struct FilesSDKTests {
    let sut = FilesSDK()

    @Test
    func `When searching for swift files, should find all swift files`() async throws {
        let samplesURL = try samplesDirectory()
        let input = FilesInput(repoPath: samplesURL, filetype: "swift")

        let result = try await sut.countFiles(input: input)

        #expect(result.filetype == "swift")
        #expect(result.files.count == 2)
        #expect(result.files.contains { $0.hasSuffix("file1.swift") })
        #expect(result.files.contains { $0.hasSuffix("file2.swift") })
    }

    @Test
    func `When searching for storyboard files, should find all storyboards`() async throws {
        let samplesURL = try samplesDirectory()
        let input = FilesInput(repoPath: samplesURL, filetype: "storyboard")

        let result = try await sut.countFiles(input: input)

        #expect(result.filetype == "storyboard")
        #expect(result.files.count == 1)
        #expect(result.files.first?.hasSuffix("view.storyboard") == true)
    }

    @Test
    func `When searching for xib files, should find all xibs`() async throws {
        let samplesURL = try samplesDirectory()
        let input = FilesInput(repoPath: samplesURL, filetype: "xib")

        let result = try await sut.countFiles(input: input)

        #expect(result.filetype == "xib")
        #expect(result.files.count == 1)
        #expect(result.files.first?.hasSuffix("cell.xib") == true)
    }

    @Test
    func `When searching for json files, should find all json files`() async throws {
        let samplesURL = try samplesDirectory()
        let input = FilesInput(repoPath: samplesURL, filetype: "json")

        let result = try await sut.countFiles(input: input)

        #expect(result.filetype == "json")
        #expect(result.files.count == 1)
    }

    @Test
    func `When searching for non-existent extension, should return empty result`() async throws {
        let samplesURL = try samplesDirectory()
        let input = FilesInput(repoPath: samplesURL, filetype: "xyz")

        let result = try await sut.countFiles(input: input)

        #expect(result.files.isEmpty)
    }
}

private func samplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}
