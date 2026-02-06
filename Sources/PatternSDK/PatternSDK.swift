import Common
import Foundation
import Logging
import System

/// A single pattern metric with its commits to analyze.
public struct PatternMetricInput: Sendable, CommitResolvable {
    /// Pattern to search for (e.g., "// TODO:")
    public let pattern: String

    /// Commits to analyze for this pattern
    public let commits: [String]

    public init(pattern: String, commits: [String] = ["HEAD"]) {
        self.pattern = pattern
        self.commits = commits
    }

    public func withResolvedCommits(_ commits: [String]) -> PatternMetricInput {
        PatternMetricInput(pattern: pattern, commits: commits)
    }
}

/// Input parameters for PatternSDK operations.
public struct PatternInput: Sendable {
    public let git: GitConfiguration
    public let metrics: [PatternMetricInput]
    public let extensions: [String]

    public init(
        git: GitConfiguration,
        metrics: [PatternMetricInput],
        extensions: [String] = ["swift"]
    ) {
        self.git = git
        self.metrics = metrics
        self.extensions = extensions
    }
}

/// SDK for searching string patterns in source files.
public struct PatternSDK: Sendable {
    private static let logger = Logger(label: "scout.PatternSDK")

    public init() {}

    /// A single match of a pattern in a file.
    public struct Match: Sendable, Encodable {
        public let file: String
        public let line: Int

        public init(file: String, line: Int) {
            self.file = file
            self.line = line
        }
    }

    /// Result of pattern search operation.
    public struct Result: Sendable, Encodable {
        public let pattern: String
        public let matches: [Match]

        public init(pattern: String, matches: [Match]) {
            self.pattern = pattern
            self.matches = matches
        }
    }

    /// Searches for occurrences of the specified pattern in the repository.
    /// - Parameters:
    ///   - pattern: Pattern to search for
    ///   - input: Input parameters for the operation
    /// - Returns: Result containing all matches with file and line number
    public func search(pattern: String, input: PatternInput) async throws -> Result {
        try await search(patterns: [pattern], input: input).first
            ?? Result(pattern: pattern, matches: [])
    }

    /// Searches for occurrences of all specified patterns in the repository.
    /// - Parameters:
    ///   - patterns: Array of patterns to search for
    ///   - input: Input parameters for the operation
    /// - Returns: Array of results, one for each pattern
    public func search(patterns: [String], input: PatternInput) async throws -> [Result] {
        let repoPath = URL(filePath: input.git.repoPath)

        try await GitFix.prepareRepository(git: input.git)

        var results: [Result] = []
        for pattern in patterns {
            var allMatches: [Match] = []
            for ext in input.extensions {
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
            results.append(Result(pattern: pattern, matches: allMatches))
        }
        return results
    }

    /// Checks out a commit and searches for pattern occurrences.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - patterns: Patterns to search for
    ///   - input: Input parameters for the operation
    /// - Returns: Array of results, one for each pattern
    public func analyzeCommit(
        hash: String,
        patterns: [String],
        input: PatternInput
    ) async throws -> [Result] {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        return try await search(patterns: patterns, input: input)
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
