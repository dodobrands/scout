import Common
import Foundation
import Logging
import System

/// SDK for counting Swift types by inheritance.
public struct TypesSDK: Sendable {
    private static let logger = Logger(label: "scout.TypesSDK")

    public init() {}

    /// A single type metric with its commits to analyze.
    public struct MetricInput: Sendable, CommitResolvable {
        /// Type name to count (e.g., "UIView")
        public let type: String

        /// Commits to analyze for this type
        public let commits: [String]

        public init(type: String, commits: [String] = ["HEAD"]) {
            self.type = type
            self.commits = commits
        }

        public func withResolvedCommits(_ commits: [String]) -> MetricInput {
            MetricInput(type: type, commits: commits)
        }
    }

    /// Input parameters for TypesSDK operations.
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

    /// Information about a found type.
    public struct TypeInfo: Sendable, Encodable, Equatable {
        /// Simple type name (e.g., "AddToCartEvent")
        public let name: String
        /// Full qualified type name (e.g., "Analytics.AddToCartEvent")
        public let fullName: String
        /// Relative path to the file containing this type
        public let path: String

        public init(name: String, fullName: String, path: String) {
            self.name = name
            self.fullName = fullName
            self.path = path
        }
    }

    /// A single types result item.
    public struct ResultItem: Sendable, Encodable {
        public let typeName: String
        public let types: [TypeInfo]

        public init(typeName: String, types: [TypeInfo]) {
            self.typeName = typeName
            self.types = types
        }
    }

    /// Output of types analysis for a single commit.
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

    /// Result of type counting operation.
    public struct Result: Sendable, Encodable {
        public let commit: String
        public let typeName: String
        public let types: [TypeInfo]

        public init(commit: String = "", typeName: String, types: [TypeInfo]) {
            self.commit = commit
            self.typeName = typeName
            self.types = types
        }
    }

    /// Counts types inherited from the specified base type in the repository.
    /// - Parameters:
    ///   - typeName: Base type name to search for
    ///   - input: Input parameters for the operation
    /// - Returns: Result containing count and list of matching types
    func countTypes(typeName: String, input: Input) async throws -> Result {
        let repoPath = URL(filePath: input.git.repoPath)
        let repoPathString = repoPath.path(percentEncoded: false)
        let parser = SwiftParser()

        try await GitFix.prepareRepository(git: input.git)

        let swiftFiles = findSwiftFiles(in: repoPath)
        let objects = try swiftFiles.flatMap {
            try parser.parseFile(from: $0)
        }

        let types = objects.filter {
            parser.isInherited(
                objectFromCode: $0,
                from: typeName,
                allObjects: objects
            )
        }.sorted(by: { $0.name < $1.name })

        Self.logger.debug("Types conforming to \(typeName): \(types.map { $0.name })")

        let typeInfos = types.map { obj in
            TypeInfo(
                name: obj.name,
                fullName: obj.fullName,
                path: relativePath(from: obj.filePath, relativeTo: repoPathString)
            )
        }

        return Result(
            typeName: typeName,
            types: typeInfos
        )
    }

    /// Converts an absolute file path to a path relative to the repository root.
    private func relativePath(from absolutePath: String, relativeTo repoPath: String) -> String {
        let repoPrefix = repoPath.hasSuffix("/") ? repoPath : repoPath + "/"
        if absolutePath.hasPrefix(repoPrefix) {
            return String(absolutePath.dropFirst(repoPrefix.count))
        }
        return absolutePath
    }

    /// Counts types inherited from all base types in input.metrics.
    /// - Parameter input: Input parameters including array of metrics
    /// - Returns: Array of results, one for each type
    func countTypes(input: Input) async throws -> [Result] {
        var results: [Result] = []
        for metric in input.metrics {
            let result = try await countTypes(typeName: metric.type, input: input)
            results.append(result)
        }
        return results
    }

    /// Checks out a commit and counts types inherited from all base types in input.metrics.
    /// - Parameter input: Input parameters for the operation including commit hash
    /// - Returns: Output with commit info, date, and results
    public func analyzeCommit(input: Input) async throws -> Output {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Shell.execute(
            "git",
            arguments: ["checkout", input.commit],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        let results = try await countTypes(input: input)
        let date = try await Git.commitDate(for: input.commit, in: repoPath)

        let resultItems = results.map { ResultItem(typeName: $0.typeName, types: $0.types) }
        return Output(commit: input.commit, date: date, results: resultItems)
    }

    private func findSwiftFiles(in directory: URL) -> [URL] {
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

        var swiftFiles: [URL] = []

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift" {
                swiftFiles.append(fileURL)
            }
        }

        return swiftFiles
    }
}
