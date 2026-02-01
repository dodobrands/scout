import Common
import Foundation
import System

/// Error when cloc is not installed.
public enum ClocError: Error, LocalizedError, Sendable {
    case notInstalled

    public var errorDescription: String? {
        switch self {
        case .notInstalled:
            return """
                cloc is not installed. Please install it manually:

                macOS:
                  brew install cloc

                Linux (Ubuntu/Debian):
                  sudo apt-get update && sudo apt-get install -y cloc

                Linux (Fedora/RHEL):
                  sudo dnf install cloc

                Or download from: https://github.com/AlDanial/cloc/releases
                """
        }
    }
}

/// Configuration for LOC counting.
public struct LOCConfiguration: Sendable {
    public let languages: [String]
    public let include: [String]
    public let exclude: [String]

    public init(languages: [String], include: [String], exclude: [String]) {
        self.languages = languages
        self.include = include
        self.exclude = exclude
    }
}

/// Input parameters for LOCSDK operations.
public struct LOCInput: Sendable {
    public let git: GitConfiguration
    public let configurations: [LOCConfiguration]
    public let commits: [String]

    public init(
        git: GitConfiguration,
        configurations: [LOCConfiguration],
        commits: [String] = ["HEAD"]
    ) {
        self.git = git
        self.configurations = configurations
        self.commits = commits
    }

    public init(
        git: GitConfiguration,
        configuration: LOCConfiguration,
        commits: [String] = ["HEAD"]
    ) {
        self.git = git
        self.configurations = [configuration]
        self.commits = commits
    }
}

/// SDK for counting lines of code.
public struct LOCSDK: Sendable {
    public init() {}

    /// Result of LOC counting operation.
    public struct Result: Sendable, Codable {
        public let commit: String
        public let metric: String
        public let linesOfCode: Int

        public init(commit: String = "", metric: String, linesOfCode: Int) {
            self.commit = commit
            self.metric = metric
            self.linesOfCode = linesOfCode
        }
    }

    /// Checks if cloc is installed on the system.
    public static func checkClocInstalled() async throws {
        let result = try await Shell.execute("which", arguments: ["cloc"])
        let isInstalled =
            !result.isEmpty && !result.contains("not found") && result.contains("cloc")

        guard isInstalled else {
            throw ClocError.notInstalled
        }
    }

    /// Counts lines of code in the repository with the specified configuration.
    /// - Parameters:
    ///   - configuration: LOC configuration to use
    ///   - input: Input parameters for the operation
    /// - Returns: Result containing total LOC count
    public func countLOC(configuration: LOCConfiguration, input: LOCInput) async throws -> Result {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Self.checkClocInstalled()
        try await GitFix.prepareRepository(git: input.git)

        let clocRunner = ClocRunner()
        let foldersToAnalyze = foldersToAnalyze(
            in: repoPath,
            include: configuration.include,
            exclude: configuration.exclude
        )

        let loc =
            try await configuration.languages
            .asyncFlatMap { language in
                try await foldersToAnalyze.asyncMap {
                    try await clocRunner.linesOfCode(at: $0, language: language)
                }
            }
            .compactMap { Int($0) }
            .reduce(0, +)

        let metric = "LOC \(configuration.languages) \(configuration.include)"
        return Result(metric: metric, linesOfCode: loc)
    }

    /// Counts lines of code in the repository with all specified configurations.
    /// - Parameter input: Input parameters including array of configurations
    /// - Returns: Array of results, one for each configuration
    public func countLOC(input: LOCInput) async throws -> [Result] {
        var results: [Result] = []
        for configuration in input.configurations {
            let result = try await countLOC(configuration: configuration, input: input)
            results.append(result)
        }
        return results
    }

    /// Checks out a commit and counts lines of code with the specified configuration.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - configuration: LOC configuration to use
    ///   - input: Input parameters for the operation
    /// - Returns: Result containing total LOC count
    public func analyzeCommit(
        hash: String,
        configuration: LOCConfiguration,
        input: LOCInput
    ) async throws -> Result {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        return try await countLOC(configuration: configuration, input: input)
    }

    /// Checks out a commit and counts lines of code with all specified configurations.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - input: Input parameters including array of configurations
    /// - Returns: Array of results, one for each configuration
    public func analyzeCommit(
        hash: String,
        input: LOCInput
    ) async throws -> [Result] {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        return try await countLOC(input: input).map {
            Result(commit: hash, metric: $0.metric, linesOfCode: $0.linesOfCode)
        }
    }

    private func foldersToAnalyze(
        in repoPath: URL,
        include: [String],
        exclude: [String]
    ) -> [URL] {
        let fileManager = FileManager.default

        guard
            let enumerator = fileManager.enumerator(
                at: repoPath,
                includingPropertiesForKeys: nil
            )
        else { return [] }

        var folders = [URL]()

        for case let url as URL in enumerator {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
                isDirectory.boolValue
            {
                if include.contains(where: { url.path.hasSuffix($0) }) {
                    folders.append(url)
                }
            }
        }

        folders = folders.filter { folder in
            !exclude.contains(where: {
                folder.path.range(of: $0, options: .caseInsensitive) != nil
            })
        }

        return folders
    }
}
