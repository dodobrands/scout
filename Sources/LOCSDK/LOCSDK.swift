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

/// SDK for counting lines of code.
public struct LOCSDK: Sendable {
    public init() {}

    /// A single LOC metric with its commits to analyze.
    public struct MetricInput: Sendable, CommitResolvable {
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

        public func withResolvedCommits(_ commits: [String]) -> MetricInput {
            MetricInput(languages: languages, include: include, exclude: exclude, commits: commits)
        }

        /// Returns a unique metric identifier for output
        public var metricIdentifier: String {
            "LOC \(languages) \(include)"
        }
    }

    /// Input parameters for LOCSDK operations.
    public struct Input: Sendable {
        public let commit: String
        public let git: GitConfiguration
        public let metrics: [MetricInput]

        public init(
            commit: String,
            git: GitConfiguration,
            metrics: [MetricInput]
        ) {
            self.commit = commit
            self.git = git
            self.metrics = metrics
        }
    }

    /// A single LOC result item.
    public struct ResultItem: Sendable, Encodable {
        public let metric: String
        public let linesOfCode: Int

        public init(metric: String, linesOfCode: Int) {
            self.metric = metric
            self.linesOfCode = linesOfCode
        }
    }

    /// Output of LOC analysis for a single commit.
    public struct Output: Sendable, Encodable {
        public let commit: String
        public let date: String
        public let results: [ResultItem]

        public init(commit: String, date: String, results: [ResultItem]) {
            self.commit = commit
            self.date = date
            self.results = results
        }
    }

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

    /// Counts lines of code for all metrics in input.
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Array of results, one for each metric
    func countLOC(input: Input) async throws -> [Result] {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Self.checkClocInstalled()
        try await GitFix.prepareRepository(git: input.git)

        var results: [Result] = []
        for metric in input.metrics {
            let clocRunner = ClocRunner()
            let foldersToAnalyze = foldersToAnalyze(
                in: repoPath,
                include: metric.include,
                exclude: metric.exclude
            )

            let loc =
                try await metric.languages
                .asyncFlatMap { language in
                    try await foldersToAnalyze.asyncMap {
                        try await clocRunner.linesOfCode(at: $0, language: language)
                    }
                }
                .compactMap { Int($0) }
                .reduce(0, +)

            results.append(Result(metric: metric.metricIdentifier, linesOfCode: loc))
        }
        return results
    }

    /// Checks out a commit and counts lines of code for all metrics in input.
    /// - Parameter input: Input parameters for the operation including commit hash
    /// - Returns: Output with commit info, date, and results
    public func analyzeCommit(input: Input) async throws -> Output {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Shell.execute(
            "git",
            arguments: ["checkout", input.commit],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        let results = try await countLOC(input: input)
        let date = try await Git.commitDate(for: input.commit, in: repoPath)

        let resultItems = results.map { ResultItem(metric: $0.metric, linesOfCode: $0.linesOfCode) }
        return Output(commit: input.commit, date: date, results: resultItems)
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
