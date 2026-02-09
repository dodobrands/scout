import Common
import Foundation
import Logging
import System

/// SDK for counting files by extension.
public struct Files: Sendable {
    private static let logger = Logger(label: "scout.Files")

    public init() {}

    /// Counts files for a single extension in current repository state (no checkout).
    /// - Parameter input: Analysis input with repository path and file extension
    /// - Returns: Result with list of matching files
    func countFiles(input: AnalysisInput) -> Result {
        let repoPath = URL(filePath: input.repoPath)
        let files = findFiles(of: input.extension, in: repoPath)
        return Result(filetype: input.extension, files: files)
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
        let commitToFiletypes = resolvedMetrics.groupedByCommit()

        for (hash, metrics) in commitToFiletypes {
            try Task.checkCancellation()

            Self.logger.debug("Processing commit: \(hash)")

            try await Git.checkout(hash: hash, git: input.git)

            var resultItems: [ResultItem] = []
            for metric in metrics {
                let analysisInput = AnalysisInput(
                    repoPath: input.git.repoPath,
                    extension: metric.extension
                )
                let result = countFiles(input: analysisInput)
                resultItems.append(
                    ResultItem(filetype: result.filetype, files: result.files)
                )
            }

            let date = try await Git.commitDate(for: hash, in: repoPath)
            onOutput(Output(commit: hash, date: date, results: resultItems))
        }
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
