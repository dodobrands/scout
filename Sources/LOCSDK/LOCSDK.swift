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

/// A single LOC metric with its commits to analyze.
public struct LOCMetricInput: Sendable, CommitResolvable {
    /// Languages to count
    public let languages: [String]

    /// Paths to include
    public let include: [String]

    /// Paths to exclude
    public let exclude: [String]

    /// Commits to analyze for this metric
    public let commits: [String]

    public init(
        languages: [String],
        include: [String],
        exclude: [String],
        commits: [String] = ["HEAD"]
    ) {
        self.languages = languages
        self.include = include
        self.exclude = exclude
        self.commits = commits
    }

    public func withResolvedCommits(_ commits: [String]) -> LOCMetricInput {
        LOCMetricInput(languages: languages, include: include, exclude: exclude, commits: commits)
    }

    /// Returns the LOCConfiguration for this metric
    public var configuration: LOCConfiguration {
        LOCConfiguration(languages: languages, include: include, exclude: exclude)
    }

    /// Returns a unique metric identifier for output
    public var metricIdentifier: String {
        "LOC \(languages) \(include)"
    }
}

/// Input parameters for LOCSDK operations.
public struct LOCInput: Sendable {
    public let git: GitConfiguration
    public let metrics: [LOCMetricInput]

    public init(
        git: GitConfiguration,
        metrics: [LOCMetricInput]
    ) {
        self.git = git
        self.metrics = metrics
    }
}

/// SDK for counting lines of code.
public struct LOCSDK: Sendable {
    public init() {}

    /// Result of LOC counting operation.
    public struct Result: Sendable, Encodable {
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
    /// - Parameters:
    ///   - configurations: Array of LOC configurations
    ///   - input: Input parameters for the operation
    /// - Returns: Array of results, one for each configuration
    public func countLOC(configurations: [LOCConfiguration], input: LOCInput) async throws
        -> [Result]
    {
        var results: [Result] = []
        for configuration in configurations {
            let result = try await countLOC(configuration: configuration, input: input)
            results.append(result)
        }
        return results
    }

    /// Checks out a commit and counts lines of code with the specified configuration.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - configurations: LOC configurations to use
    ///   - input: Input parameters for the operation
    /// - Returns: Array of results, one for each configuration
    public func analyzeCommit(
        hash: String,
        configurations: [LOCConfiguration],
        input: LOCInput
    ) async throws -> [Result] {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        return try await countLOC(configurations: configurations, input: input).map {
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
