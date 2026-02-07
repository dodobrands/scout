import Common
import Foundation
import Logging
import System

/// SDK for searching string patterns in source files.
public struct PatternSDK: Sendable {
    private static let logger = Logger(label: "scout.PatternSDK")

    public init() {}

    /// Searches for a pattern in current repository state (no checkout).
    /// - Parameters:
    ///   - pattern: Pattern to search for
    ///   - extensions: File extensions to search in
    ///   - repoPath: Path to the repository
    /// - Returns: Result with list of matches
    func search(pattern: String, extensions: [String], repoPath: URL) throws -> Result {
        var allMatches: [Match] = []
        for ext in extensions {
            let files = findFiles(of: ext, in: repoPath)
            for file in files {
                let fileMatches = try searchInFile(
                    pattern: pattern,
                    file: file,
                    repoPath: repoPath
                )
                allMatches.append(contentsOf: fileMatches)
            }
        }
        return Result(pattern: pattern, matches: allMatches)
    }

    /// Analyzes all commits from metrics and returns outputs for each.
    /// Groups metrics by commit to minimize checkouts.
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Array of outputs, one for each unique commit
    public func analyze(input: Input) async throws -> [Output] {
        let repoPath = URL(filePath: input.git.repoPath)

        // Group metrics by commit to minimize checkouts
        var commitToPatterns: [String: [String]] = [:]
        for metric in input.metrics {
            for commit in metric.commits {
                commitToPatterns[commit, default: []].append(metric.pattern)
            }
        }

        var outputs: [Output] = []
        for (hash, patterns) in commitToPatterns {
            Self.logger.debug("Processing commit: \(hash)")

            try await Shell.execute(
                "git",
                arguments: ["checkout", hash],
                workingDirectory: FilePath(repoPath.path(percentEncoded: false))
            )

            try await GitFix.prepareRepository(git: input.git)

            var resultItems: [ResultItem] = []
            for pattern in patterns {
                let result = try search(
                    pattern: pattern,
                    extensions: input.extensions,
                    repoPath: repoPath
                )
                resultItems.append(ResultItem(pattern: result.pattern, matches: result.matches))
            }

            let date = try await Git.commitDate(for: hash, in: repoPath)
            outputs.append(Output(commit: hash, date: date, results: resultItems))
        }

        return outputs
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
