import Common
import Foundation
import Logging
import System

/// SDK for searching string patterns in source files.
public struct Pattern: Sendable {
    private static let logger = Logger(label: "scout.Pattern")

    public init() {}

    /// Searches for a pattern in current repository state (no checkout).
    /// - Parameter input: Analysis input with repository path, file extensions, and pattern
    /// - Returns: Result with list of matches
    func search(input: AnalysisInput) throws -> Result {
        let repoPath = URL(filePath: input.repoPath)
        var allMatches: [Match] = []
        for ext in input.extensions {
            let files = findFiles(of: ext, in: repoPath)
            for file in files {
                let fileMatches = try searchInFile(
                    pattern: input.pattern,
                    file: file,
                    repoPath: repoPath
                )
                allMatches.append(contentsOf: fileMatches)
            }
        }
        return Result(pattern: input.pattern, matches: allMatches)
    }

    /// Analyzes all commits from metrics and yields outputs incrementally.
    /// Groups metrics by commit to minimize checkouts.
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Async stream of outputs, one for each unique commit
    public func analyze(input: Input) -> AsyncThrowingStream<Output, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await performAnalysis(input: input) { output in
                        continuation.yield(output)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func performAnalysis(
        input: Input,
        onOutput: (Output) -> Void
    ) async throws {
        let repoPath = URL(filePath: input.git.repoPath)

        // Resolve HEAD commits to actual hashes
        let resolvedMetrics = try await input.metrics.resolvingHeadCommits(
            repoPath: input.git.repoPath
        )

        // Group metrics by commit to minimize checkouts
        var commitToPatterns: [String: [String]] = [:]
        for metric in resolvedMetrics {
            for commit in metric.commits {
                commitToPatterns[commit, default: []].append(metric.pattern)
            }
        }

        for (hash, patterns) in commitToPatterns {
            try Task.checkCancellation()

            Self.logger.debug("Processing commit: \(hash)")

            try await Git.checkout(hash: hash, git: input.git)

            var resultItems: [ResultItem] = []
            for pattern in patterns {
                let analysisInput = AnalysisInput(
                    repoPath: input.git.repoPath,
                    extensions: input.extensions,
                    pattern: pattern
                )
                let result = try search(input: analysisInput)
                resultItems.append(
                    ResultItem(pattern: result.pattern, matches: result.matches)
                )
            }

            let date = try await Git.commitDate(for: hash, in: repoPath)
            onOutput(Output(commit: hash, date: date, results: resultItems))
        }
    }

    private func searchInFile(pattern: String, file: URL, repoPath: URL) throws -> [Match] {
        let content = try String(contentsOf: file, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        var matches: [Match] = []

        let relativePath = file.path.replacingOccurrences(
            of: repoPath.path + "/",
            with: ""
        )

        for (index, line) in lines.enumerated() {
            if line.contains(pattern) {
                matches.append(Match(file: relativePath, line: index + 1))
            }
        }

        return matches
    }

    private func findFiles(of type: String, in directory: URL) -> [URL] {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: directory.path) else {
            Self.logger.info("Directory does not exist: \(directory.path)")
            return []
        }

        guard
            let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles],
                errorHandler: nil
            )
        else {
            Self.logger.info("Failed to create enumerator for: \(directory.path)")
            return []
        }

        var matchingFiles: [URL] = []

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == type {
                matchingFiles.append(fileURL)
            }
        }

        return matchingFiles
    }
}
