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
        public let git: GitConfiguration
        public let metrics: [MetricInput]

        public init(
            git: GitConfiguration,
            metrics: [MetricInput]
        ) {
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

    /// Checks if cloc is installed on the system.
    public static func checkClocInstalled() async throws {
        let result = try await Shell.execute("which", arguments: ["cloc"])
        let isInstalled =
            !result.isEmpty && !result.contains("not found") && result.contains("cloc")

        guard isInstalled else {
            throw ClocError.notInstalled
        }
    }

    /// Counts LOC for all metrics without checkout (for testing).
    func countLOC(input: Input) async throws -> [Output] {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Self.checkClocInstalled()
        try await GitFix.prepareRepository(git: input.git)

        var resultItems: [ResultItem] = []
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

            resultItems.append(ResultItem(metric: metric.metricIdentifier, linesOfCode: loc))
        }

        return [Output(commit: "HEAD", date: "", results: resultItems)]
    }

    /// Analyzes lines of code for all metrics across their specified commits.
    /// - Parameter input: Input parameters containing metrics with their commits
    /// - Returns: Array of outputs, one for each unique commit
    public func analyze(input: Input) async throws -> [Output] {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Self.checkClocInstalled()

        // Group metrics by commit to minimize checkouts
        var commitToMetrics: [String: [MetricInput]] = [:]
        for metric in input.metrics {
            for commit in metric.commits {
                commitToMetrics[commit, default: []].append(metric)
            }
        }

        var outputs: [Output] = []
        for (hash, metrics) in commitToMetrics {
            try await Shell.execute(
                "git",
                arguments: ["checkout", hash],
                workingDirectory: FilePath(repoPath.path(percentEncoded: false))
            )

            try await GitFix.prepareRepository(git: input.git)

            var resultItems: [ResultItem] = []
            for metric in metrics {
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

                resultItems.append(ResultItem(metric: metric.metricIdentifier, linesOfCode: loc))
            }

            let date = try await Git.commitDate(for: hash, in: repoPath)
            outputs.append(Output(commit: hash, date: date, results: resultItems))
        }

        return outputs
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
