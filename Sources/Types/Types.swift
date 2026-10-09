import Common
import Foundation
import Logging

/// SDK for counting Swift types by inheritance.
public struct Types: Sendable {
    private static let logger = Logger(label: "scout.Types")

    /// Where resolved package dependencies keep their sources, relative to the repository root:
    /// SwiftPM and Tuist-managed dependencies respectively.
    static let packageCheckoutsDirectories = [".build/checkouts", "Tuist/.build/checkouts"]

    private let hierarchyProvider: any ExternalHierarchyProvider

    public init() {
        self.init(hierarchyProvider: SymbolGraphHierarchyProvider())
    }

    init(hierarchyProvider: any ExternalHierarchyProvider) {
        self.hierarchyProvider = hierarchyProvider
    }

    /// Counts types inherited from each of the base types in current repository state.
    /// Sources, imports and the external hierarchy are read once and shared by all base types.
    /// - Parameter input: Analysis input with repository path and base type names
    /// - Returns: One result per base type, in the order of `input.typeNames`
    func countTypes(input: AnalysisInput) async throws -> [Result] {
        let repoPath = URL(filePath: input.repoPath)
        let repoPathString = repoPath.path(percentEncoded: false)
        let parser = SwiftParser()

        let swiftFiles = Signposts.interval("Find Swift files") { findSwiftFiles(in: repoPath) }
        let objects = try Signposts.interval("Parse sources", "\(swiftFiles.count) files") {
            try swiftFiles.flatMap { try parser.parseFile(from: $0) }
        }

        // Superclasses declared in package dependencies (e.g. an SPM package's
        // `open class StateViewController: UIViewController`) are resolved from the checked-out
        // package sources. They take part in the lookup but are never reported.
        let packageObjects = Signposts.interval("Parse package checkouts") {
            parsePackageCheckouts(in: repoPath, parser: parser)
        }

        // Resolve inheritance past the source boundary (e.g. UICollectionViewCell -> UIView)
        // by merging in external class-inheritance edges for the modules the source imports.
        // Source objects come first so name lookups prefer local definitions.
        let modules = Signposts.interval("Scan imports") { ImportScanner.modules(in: swiftFiles) }
        let externalObjects = try await Signposts.interval("External hierarchy") {
            try await hierarchyProvider.externalObjects(forModules: modules)
        }
        let allObjects = objects + packageObjects + externalObjects
        let index = SwiftParser.ObjectIndex(allObjects)

        return input.typeNames.map { typeName in
            // Typealiases and protocols take part in the inheritance lookup through the index,
            // but they can't be instantiated, so they are never reported.
            let types = Signposts.interval("Inheritance search", typeName) {
                objects.filter {
                    !$0.isTypealias
                        && $0.kind != .protocolType
                        && parser.isInherited(
                            objectFromCode: $0,
                            from: typeName,
                            index: index
                        )
                }.sorted(by: { $0.name < $1.name })
            }

            Self.logger.debug("Types conforming to \(typeName): \(types.map { $0.name })")

            let typeInfos = types.map { obj in
                TypeInfo(
                    name: obj.name,
                    fullName: obj.fullName,
                    path: relativePath(from: obj.filePath, relativeTo: repoPathString)
                )
            }

            return Result(typeName: typeName, types: typeInfos)
        }
    }

    /// Parses the Swift sources of resolved package dependencies.
    /// The analyzed source skips hidden directories, so these files are never part of it.
    /// A package file that fails to parse is skipped rather than failing the analysis.
    private func parsePackageCheckouts(in repoPath: URL, parser: SwiftParser) -> [ObjectFromCode] {
        let files = Self.packageCheckoutsDirectories
            .map { repoPath.appending(path: $0) }
            .filter { FileManager.default.fileExists(atPath: $0.path(percentEncoded: false)) }
            .flatMap { findSwiftFiles(in: $0) }
        guard !files.isEmpty else { return [] }

        Self.logger.debug("Parsing \(files.count) Swift files from package checkouts")
        return files.flatMap { file in
            do {
                return try parser.parseFile(from: file)
            } catch {
                Self.logger.debug("Skipping package file \(file.path): \(error)")
                return []
            }
        }
    }

    /// Converts an absolute file path to a path relative to the repository root.
    private func relativePath(from absolutePath: String, relativeTo repoPath: String) -> String {
        let repoPrefix = repoPath.hasSuffix("/") ? repoPath : repoPath + "/"
        if absolutePath.hasPrefix(repoPrefix) {
            return String(absolutePath.dropFirst(repoPrefix.count))
        }
        return absolutePath
    }

    /// Analyzes all commits from metrics and yields outputs incrementally.
    /// Groups metrics by commit to minimize checkouts.
    /// - Parameter input: Input parameters for the operation
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

        let checksOutCommits = Git.checksOutCommits(for: input.metrics, git: input.git)

        // Resolve HEAD commits to actual hashes
        let resolvedMetrics = try await input.metrics.resolvingHeadCommits(
            repoPath: input.git.repoPath
        )

        // Group metrics by commit to minimize checkouts
        let commitToTypes = resolvedMetrics.groupedByCommit()

        for (hash, metrics) in commitToTypes {
            try Task.checkCancellation()

            let typeNames = metrics.map(\.type)
            Self.logger.debug("Processing commit: \(hash) for types: \(typeNames)")

            if checksOutCommits {
                try await Git.checkout(hash: hash, git: input.git)
            }

            let analysisInput = AnalysisInput(repoPath: input.git.repoPath, typeNames: typeNames)
            let resultItems = try await countTypes(input: analysisInput).map {
                ResultItem(typeName: $0.typeName, types: $0.types)
            }

            let date = try await Git.commitDate(for: hash, in: repoPath)
            onOutput(Output(commit: hash, date: date, results: resultItems))
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
