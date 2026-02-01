import Common
import Foundation
import Logging
import System

/// Input parameters for PatternSDK operations.
public struct PatternInput: Sendable {
    public let repoPath: URL
    public let pattern: String
    public let extensions: [String]
    public let gitClean: Bool
    public let fixLFS: Bool
    public let initializeSubmodules: Bool

    public init(
        repoPath: URL,
        pattern: String,
        extensions: [String] = ["swift"],
        gitClean: Bool = false,
        fixLFS: Bool = false,
        initializeSubmodules: Bool = false
    ) {
        self.repoPath = repoPath
        self.pattern = pattern
        self.extensions = extensions
        self.gitClean = gitClean
        self.fixLFS = fixLFS
        self.initializeSubmodules = initializeSubmodules
    }
}

/// SDK for searching string patterns in source files.
public struct PatternSDK: Sendable {
    private static let logger = Logger(label: "scout.PatternSDK")

    public init() {}

    /// A single match of a pattern in a file.
    public struct Match: Sendable, Codable {
        public let file: String
        public let line: Int

        public init(file: String, line: Int) {
            self.file = file
            self.line = line
        }
    }

    /// Result of pattern search operation.
    public struct Result: Sendable, Codable {
        public let pattern: String
        public let matches: [Match]

        public init(pattern: String, matches: [Match]) {
            self.pattern = pattern
            self.matches = matches
        }
    }

    /// Searches for occurrences of the specified pattern in the repository.
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Result containing all matches with file and line number
    public func search(input: PatternInput) async throws -> Result {
        try await GitFix.prepareRepository(
            in: input.repoPath,
            gitClean: input.gitClean,
            fixLFS: input.fixLFS,
            initializeSubmodules: input.initializeSubmodules
        )

        var allMatches: [Match] = []

        for ext in input.extensions {
            let files = findFiles(of: ext, in: input.repoPath)
            for file in files {
                let fileMatches = try searchInFile(
                    pattern: input.pattern,
                    file: file,
                    repoPath: input.repoPath
                )
                allMatches.append(contentsOf: fileMatches)
            }
        }

        return Result(pattern: input.pattern, matches: allMatches)
    }

    /// Checks out a commit and searches for pattern occurrences.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - input: Input parameters for the operation
    /// - Returns: Result containing all matches
    public func analyzeCommit(
        hash: String,
        input: PatternInput
    ) async throws -> Result {
        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(input.repoPath.path(percentEncoded: false))
        )

        return try await search(input: input)
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
