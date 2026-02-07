import Common
import Foundation
import Logging
import System

/// SDK for counting files by extension.
public struct FilesSDK: Sendable {
    private static let logger = Logger(label: "scout.FilesSDK")

    public init() {}

    /// Counts files for a single extension in current repository state (no checkout).
    /// - Parameter input: Analysis input with repository path and file extension
    /// - Returns: Result with list of matching files
    func countFiles(input: AnalysisInput) -> Result {
        let repoPath = URL(filePath: input.repoPath)
        let files = findFiles(of: input.extension, in: repoPath)
        return Result(filetype: input.extension, files: files)
    }

    /// Analyzes all commits from metrics and returns outputs for each.
    /// Groups metrics by commit to minimize checkouts.
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Array of outputs, one for each unique commit
    public func analyze(input: Input) async throws -> [Output] {
        let repoPath = URL(filePath: input.git.repoPath)

        // Resolve HEAD commits to actual hashes
        let resolvedMetrics = try await input.metrics.resolvingHeadCommits(
            repoPath: input.git.repoPath
        )

        // Group metrics by commit to minimize checkouts
        var commitToFiletypes: [String: [String]] = [:]
        for metric in resolvedMetrics {
            for commit in metric.commits {
                commitToFiletypes[commit, default: []].append(metric.extension)
            }
        }

        var outputs: [Output] = []
        for (hash, filetypes) in commitToFiletypes {
            Self.logger.debug("Processing commit: \(hash)")

            try await Shell.execute(
                "git",
                arguments: ["checkout", hash],
                workingDirectory: FilePath(repoPath.path(percentEncoded: false))
            )

            try await GitFix.prepareRepository(git: input.git)

            var resultItems: [ResultItem] = []
            for ext in filetypes {
                let analysisInput = AnalysisInput(repoPath: input.git.repoPath, `extension`: ext)
                let result = countFiles(input: analysisInput)
                resultItems.append(ResultItem(filetype: result.filetype, files: result.files))
            }

            let date = try await Git.commitDate(for: hash, in: repoPath)
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
