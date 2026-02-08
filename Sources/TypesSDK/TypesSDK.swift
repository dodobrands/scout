import Common
import Foundation
import Logging
import System

/// SDK for counting Swift types by inheritance.
public struct TypesSDK: Sendable {
    private static let logger = Logger(label: "scout.TypesSDK")

    public init() {}

    /// Counts types inherited from the specified base type in current repository state.
    /// - Parameter input: Analysis input with repository path and type name
    /// - Returns: Result containing list of matching types
    func countTypes(input: AnalysisInput) async throws -> Result {
        let repoPath = URL(filePath: input.repoPath)
        let repoPathString = repoPath.path(percentEncoded: false)
        let parser = SwiftParser()

        let swiftFiles = findSwiftFiles(in: repoPath)
        let objects = try swiftFiles.flatMap {
            try parser.parseFile(from: $0)
        }

        let types = objects.filter {
            !$0.isTypealias
                && parser.isInherited(
                    objectFromCode: $0,
                    from: input.typeName,
                    allObjects: objects
                )
        }.sorted(by: { $0.name < $1.name })

        Self.logger.debug("Types conforming to \(input.typeName): \(types.map { $0.name })")

        let typeInfos = types.map { obj in
            TypeInfo(
                name: obj.name,
                fullName: obj.fullName,
                path: relativePath(from: obj.filePath, relativeTo: repoPathString)
            )
        }

        return Result(
            typeName: input.typeName,
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

    /// Analyzes all commits from metrics and returns outputs for each.
    /// Groups metrics by commit to minimize checkouts.
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Array of outputs, one for each unique commit
    public func analyze(input: Input) async throws -> [Output] {
        let repoPath = URL(filePath: input.git.repoPath)

        // Resolve HEAD commits to actual hashes
        let resolvedMetrics = try await input.metrics.resolvingHeadCommits(
            repoPath: input.git.repoPath
        )

        // Group metrics by commit to minimize checkouts
        var commitToTypes: [String: [String]] = [:]
        for metric in resolvedMetrics {
            for commit in metric.commits {
                commitToTypes[commit, default: []].append(metric.type)
            }
        }

        var outputs: [Output] = []
        for (hash, typeNames) in commitToTypes {
            Self.logger.debug("Processing commit: \(hash) for types: \(typeNames)")

            try await Shell.execute(
                "git",
                arguments: ["checkout", hash],
                workingDirectory: FilePath(repoPath.path(percentEncoded: false))
            )

            try await GitFix.prepareRepository(git: input.git)

            var resultItems: [ResultItem] = []
            for typeName in typeNames {
                let analysisInput = AnalysisInput(repoPath: input.git.repoPath, typeName: typeName)
                let result = try await countTypes(input: analysisInput)
                resultItems.append(ResultItem(typeName: result.typeName, types: result.types))
            }

            let date = try await Git.commitDate(for: hash, in: repoPath)
            outputs.append(Output(commit: hash, date: date, results: resultItems))
        }

        return outputs
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
