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

    /// Checks if cloc is installed on the system.
    public static func checkClocInstalled() async throws {
        let result = try await Shell.execute("which", arguments: ["cloc"])
        let isInstalled =
            !result.isEmpty && !result.contains("not found") && result.contains("cloc")

        guard isInstalled else {
            throw ClocError.notInstalled
        }
    }

    /// Counts LOC for current repository state (no checkout).
    /// - Parameter input: Analysis input with repository path and metric configuration
    /// - Returns: Result item with LOC count
    func countLOC(input: AnalysisInput) async throws -> ResultItem {
        let repoPath = URL(filePath: input.repoPath)
        let clocRunner = ClocRunner()
        let foldersToAnalyze = foldersToAnalyze(
            in: repoPath,
            include: input.include,
            exclude: input.exclude
        )

        let loc =
            try await input.languages
            .asyncFlatMap { language in
                try await foldersToAnalyze.asyncMap {
                    try await clocRunner.linesOfCode(at: $0, language: language)
                }
            }
            .compactMap { Int($0) }
            .reduce(0, +)

        return ResultItem(metric: input.metricIdentifier, linesOfCode: loc)
    }

    /// Analyzes lines of code for all metrics across their specified commits.
    /// Yields outputs incrementally, one for each unique commit as it is processed.
    /// - Parameter input: Input parameters containing metrics with their commits
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

        try await Self.checkClocInstalled()

        // Resolve HEAD commits to actual hashes
        let resolvedMetrics = try await input.metrics.resolvingHeadCommits(
            repoPath: input.git.repoPath
        )

        // Group metrics by commit to minimize checkouts
        var commitToMetrics: [String: [MetricInput]] = [:]
        for metric in resolvedMetrics {
            for commit in metric.commits {
                commitToMetrics[commit, default: []].append(metric)
            }
        }

        for (hash, metrics) in commitToMetrics {
            try Task.checkCancellation()

            try await Shell.execute(
                "git",
                arguments: ["checkout", hash],
                workingDirectory: FilePath(repoPath.path(percentEncoded: false))
            )

            try await GitFix.prepareRepository(git: input.git)

            var resultItems: [ResultItem] = []
            for metric in metrics {
                let analysisInput = AnalysisInput(
                    repoPath: input.git.repoPath,
                    languages: metric.languages,
                    include: metric.include,
                    exclude: metric.exclude,
                    metricIdentifier: metric.metricIdentifier
                )
                let result = try await countLOC(input: analysisInput)
                resultItems.append(result)
            }

            let date = try await Git.commitDate(for: hash, in: repoPath)
            onOutput(Output(commit: hash, date: date, results: resultItems))
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
