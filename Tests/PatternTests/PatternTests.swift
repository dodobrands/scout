import Foundation
import Testing

@testable import Pattern

struct PatternTests {
    let sut = Pattern()

    @Test
    func `When searching for TODO comments, should find all occurrences`() throws {
        let samplesURL = try samplesDirectory()
        let input = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "// TODO:"
        )

        let result = try sut.search(input: input)

        #expect(result.pattern == "// TODO:")
        #expect(result.matches.count == 2)
    }

    @Test
    func `When searching for FIXME comments, should find all occurrences`() throws {
        let samplesURL = try samplesDirectory()
        let input = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "// FIXME:"
        )

        let result = try sut.search(input: input)

        #expect(result.matches.count == 2)
    }

    @Test
    func `When searching for periphery ignore, should find all annotations`() throws {
        let samplesURL = try samplesDirectory()
        let input = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "periphery:ignore"
        )

        let result = try sut.search(input: input)

        #expect(result.matches.count == 2)
    }

    @Test
    func `When searching for non-existent pattern, should return empty result`() throws {
        let samplesURL = try samplesDirectory()
        let input = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "THIS_PATTERN_DOES_NOT_EXIST"
        )

        let result = try sut.search(input: input)

        #expect(result.matches.isEmpty)
    }

    @Test
    func `When match found, should return correct line number`() throws {
        let samplesURL = try samplesDirectory()
        let input = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "swiftlint:disable"
        )

        let result = try sut.search(input: input)

        #expect(result.matches.count == 1)
        let match = try #require(result.matches.first)
        #expect(match.line == 4)
    }

    @Test
    func `When pattern found multiple times, should return different line numbers`() throws {
        let samplesURL = try samplesDirectory()
        let input = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "// TODO:"
        )

        let result = try sut.search(input: input)

        #expect(result.matches.count == 2)
        let lines = result.matches.map { $0.line }.sorted()
        #expect(lines == [7, 26])
    }

    // MARK: - Regex Tests

    @Test
    func `When isRegex is true, should match using regular expression`() throws {
        let samplesURL = try samplesDirectory()
        let input = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "Task\\b.*\\{.*@MainActor",
            isRegex: true
        )

        let result = try sut.search(input: input)

        #expect(result.matches.count == 3)
    }

    @Test
    func `When isRegex is false, should use literal matching`() throws {
        let samplesURL = try samplesDirectory()
        let input = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "Task\\b.*\\{.*@MainActor",
            isRegex: false
        )

        let result = try sut.search(input: input)

        #expect(result.matches.isEmpty)
    }

    @Test
    func `When isRegex is true with simple pattern, should find matches`() throws {
        let samplesURL = try samplesDirectory()
        let input = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "//\\s+TODO:",
            isRegex: true
        )

        let result = try sut.search(input: input)

        #expect(result.matches.count == 2)
    }

    @Test
    func `When isRegex is true with invalid regex, should throw error`() throws {
        let samplesURL = try samplesDirectory()
        let input = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "[invalid",
            isRegex: true
        )

        #expect(throws: (any Error).self) {
            try sut.search(input: input)
        }
    }

    @Test
    func `When regex matches force unwraps, should find all occurrences`() throws {
        let samplesURL = try samplesDirectory()
        let input = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "\\w+!",
            isRegex: true
        )

        let result = try sut.search(input: input)

        // value!, value!.count, try!
        #expect(result.matches.count >= 3)
    }

    @Test
    func `When regex matches DispatchQueue usage, should find all queues`() throws {
        let samplesURL = try samplesDirectory()
        let input = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "DispatchQueue\\.(main|global)",
            isRegex: true
        )

        let result = try sut.search(input: input)

        #expect(result.matches.count == 3)
    }

    @Test
    func `When regex matches deprecated annotations, should find all variants`() throws {
        let samplesURL = try samplesDirectory()
        let input = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "@available\\(.*deprecated",
            isRegex: true
        )

        let result = try sut.search(input: input)

        // @available(*, deprecated) on LegacyManager, @available(*, deprecated, message:), @available(iOS, deprecated: 15.0)
        #expect(result.matches.count == 3)
    }

    @Test
    func `When regex matches print and debug statements, should find all logging`() throws {
        let samplesURL = try samplesDirectory()
        let input = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "\\b(print|debugPrint|NSLog)\\(",
            isRegex: true
        )

        let result = try sut.search(input: input)

        // print("debug value"), debugPrint("detailed debug"), NSLog("legacy log")
        // + print calls inside Task closures and DispatchQueue
        #expect(result.matches.count >= 3)
    }

    @Test
    func `When regex matches Notification.Name definitions, should find all`() throws {
        let samplesURL = try samplesDirectory()
        let input = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "Notification\\.Name\\(",
            isRegex: true
        )

        let result = try sut.search(input: input)

        #expect(result.matches.count == 2)
    }

    @Test
    func `When regex matches try with bang, should find force tries`() throws {
        let samplesURL = try samplesDirectory()
        let input = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "\\btry!\\s",
            isRegex: true
        )

        let result = try sut.search(input: input)

        #expect(result.matches.count == 1)
    }

    // MARK: - Multiple Patterns Tests

    @Test
    func `When searching for multiple patterns, should return results for each`() throws {
        let samplesURL = try samplesDirectory()
        let todoInput = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "// TODO:"
        )
        let fixmeInput = Pattern.AnalysisInput(
            repoPath: samplesURL.path,
            extensions: ["swift"],
            pattern: "// FIXME:"
        )

        let todoResult = try sut.search(input: todoInput)
        let fixmeResult = try sut.search(input: fixmeInput)

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
