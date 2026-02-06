import Common
import Foundation
import Logging
import System

/// A single type metric with its commits to analyze.
public struct TypeMetricInput: Sendable, CommitResolvable {
    /// Type name to count (e.g., "UIView")
    public let type: String

    /// Commits to analyze for this type
    public let commits: [String]

    public init(type: String, commits: [String] = ["HEAD"]) {
        self.type = type
        self.commits = commits
    }

    public func withResolvedCommits(_ commits: [String]) -> TypeMetricInput {
        TypeMetricInput(type: type, commits: commits)
    }
}

/// Input parameters for TypesSDK operations.
public struct TypesInput: Sendable {
    public let git: GitConfiguration
    public let metrics: [TypeMetricInput]

    public init(
        git: GitConfiguration,
        metrics: [TypeMetricInput]
    ) {
        self.git = git
        self.metrics = metrics
    }
}

/// SDK for counting Swift types by inheritance.
public struct TypesSDK: Sendable {
    private static let logger = Logger(label: "scout.TypesSDK")

    public init() {}

    /// Result of type counting operation.
    public struct Result: Sendable, Encodable {
        public let commit: String
        public let typeName: String
        public let types: [String]

        public init(commit: String = "", typeName: String, types: [String]) {
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
    public func countTypes(typeName: String, input: TypesInput) async throws -> Result {
        let repoPath = URL(filePath: input.git.repoPath)
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

        return Result(
            typeName: typeName,
            types: types.map { $0.name }
        )
    }

    /// Counts types inherited from all specified base types in the repository.
    /// - Parameter input: Input parameters including array of metrics
    /// - Returns: Array of results, one for each type
    public func countTypes(input: TypesInput, typeNames: [String]) async throws -> [Result] {
        var results: [Result] = []
        for typeName in typeNames {
            let result = try await countTypes(typeName: typeName, input: input)
            results.append(result)
        }
        return results
    }

    /// Checks out a commit and counts types inherited from the specified base type.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - typeName: Base type name to search for
    ///   - input: Input parameters for the operation
    /// - Returns: Result containing count and list of matching types
    public func analyzeCommit(
        hash: String,
        typeName: String,
        input: TypesInput
    ) async throws -> Result {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        return try await countTypes(typeName: typeName, input: input)
    }

    /// Checks out a commit and counts types inherited from specified base types.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - typeNames: Type names to search for
    ///   - input: Input parameters for the operation
    /// - Returns: Array of results, one for each type
    public func analyzeCommit(
        hash: String,
        typeNames: [String],
        input: TypesInput
    ) async throws -> [Result] {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        return try await countTypes(input: input, typeNames: typeNames).map {
            Result(commit: hash, typeName: $0.typeName, types: $0.types)
        }
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
