import Common
import Foundation
import Logging
import System

/// SDK for counting files by extension.
public struct FilesSDK: Sendable {
    private static let logger = Logger(label: "scout.FilesSDK")

    public init() {}

    /// Counts files for specific commit (filters metrics that include this commit).
    private func countFilesForCommit(_ commit: String, input: Input) async throws -> [Result] {
        try await GitFix.prepareRepository(git: input.git)

        let repoPath = URL(filePath: input.git.repoPath)
        return input.metrics.filter { $0.commits.contains(commit) }.map { metric in
            let files = findFiles(of: metric.extension, in: repoPath)
            return Result(filetype: metric.extension, files: files)
        }
    }

    /// Counts files for all metrics without checkout (for testing).
    func countFiles(input: Input) async throws -> [Result] {
        try await GitFix.prepareRepository(git: input.git)

        let repoPath = URL(filePath: input.git.repoPath)
        return input.metrics.map { metric in
            let files = findFiles(of: metric.extension, in: repoPath)
            return Result(filetype: metric.extension, files: files)
        }
    }

    /// Analyzes all commits from metrics and returns outputs for each.
    /// Groups metrics by commit to minimize checkouts.
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Array of outputs, one for each unique commit
    public func analyze(input: Input) async throws -> [Output] {
        let repoPath = URL(filePath: input.git.repoPath)

        // Group metrics by commit to minimize checkouts
        var commitToFiletypes: [String: [String]] = [:]
        for metric in input.metrics {
            for commit in metric.commits {
                commitToFiletypes[commit, default: []].append(metric.extension)
            }
        }

        var outputs: [Output] = []
        for (hash, _) in commitToFiletypes {
            Self.logger.debug("Processing commit: \(hash)")

            try await Shell.execute(
                "git",
                arguments: ["checkout", hash],
                workingDirectory: FilePath(repoPath.path(percentEncoded: false))
            )

            let results = try await countFilesForCommit(hash, input: input)
            let date = try await Git.commitDate(for: hash, in: repoPath)

            let resultItems = results.map { ResultItem(filetype: $0.filetype, files: $0.files) }
            outputs.append(Output(commit: hash, date: date, results: resultItems))
        }

        return outputs
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
