import Common
import Foundation
import Logging
import System

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
    /// - Parameters:
    ///   - repoPath: Path to the repository
    ///   - typeName: Base type name to search for
    ///   - gitClean: Run `git clean -ffdx && git reset --hard HEAD` before analysis
    ///   - fixLFS: Fix broken LFS pointers by committing modified files
    ///   - initializeSubmodules: Whether to initialize git submodules
    /// - Returns: Result containing count and list of matching types
    public func countTypes(
        in repoPath: URL,
        typeName: String,
        gitClean: Bool = false,
        fixLFS: Bool = false,
        initializeSubmodules: Bool = false
    ) async throws -> Result {
        let parser = SwiftParser()

        try await GitFix.prepareRepository(
            in: repoPath,
            gitClean: gitClean,
            fixLFS: fixLFS,
            initializeSubmodules: initializeSubmodules
        )

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

    /// Checks out a commit and counts types inherited from the specified base type.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - repoPath: Path to the repository
    ///   - typeName: Base type name to search for
    ///   - gitClean: Run `git clean -ffdx && git reset --hard HEAD` before analysis
    ///   - fixLFS: Fix broken LFS pointers by committing modified files
    ///   - initializeSubmodules: Whether to initialize git submodules
    /// - Returns: Result containing count and list of matching types
    public func analyzeCommit(
        hash: String,
        repoPath: URL,
        typeName: String,
        gitClean: Bool = false,
        fixLFS: Bool = false,
        initializeSubmodules: Bool = false
    ) async throws -> Result {
        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(repoPath.path(percentEncoded: false))
        )

        return try await countTypes(
            in: repoPath,
            typeName: typeName,
            gitClean: gitClean,
            fixLFS: fixLFS,
            initializeSubmodules: initializeSubmodules
        )
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
