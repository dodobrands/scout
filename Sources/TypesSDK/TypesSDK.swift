import Common
import Foundation
import Logging
import System

/// Input parameters for TypesSDK operations.
public struct TypesInput: Sendable {
    public let git: GitConfiguration
    public let typeName: String

    public init(
        git: GitConfiguration,
        typeName: String
    ) {
        self.git = git
        self.typeName = typeName
    }
}

/// SDK for counting Swift types by inheritance.
public struct TypesSDK: Sendable {
    private static let logger = Logger(label: "scout.TypesSDK")

    public init() {}

    /// Result of type counting operation.
    public struct Result: Sendable, Codable {
        public let typeName: String
        public let types: [String]

        public init(typeName: String, types: [String]) {
            self.typeName = typeName
            self.types = types
        }
    }

    /// Counts types inherited from the specified base type in the repository.
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Result containing count and list of matching types
    public func countTypes(input: TypesInput) async throws -> Result {
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
                from: input.typeName,
                allObjects: objects
            )
        }.sorted(by: { $0.name < $1.name })

        Self.logger.debug("Types conforming to \(input.typeName): \(types.map { $0.name })")

        return Result(
            typeName: input.typeName,
            types: types.map { $0.name }
        )
    }

    /// Checks out a commit and counts types inherited from the specified base type.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - input: Input parameters for the operation
    /// - Returns: Result containing count and list of matching types
    public func analyzeCommit(
        hash: String,
        input: TypesInput
    ) async throws -> Result {
        let repoPath = URL(filePath: input.git.repoPath)

        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        return try await countTypes(input: input)
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
