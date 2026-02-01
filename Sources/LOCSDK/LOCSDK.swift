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

/// Input parameters for LOCSDK operations.
public struct LOCInput: Sendable {
    public let repoPath: URL
    public let configuration: LOCConfiguration
    public let gitClean: Bool
    public let fixLFS: Bool
    public let initializeSubmodules: Bool

    public init(
        repoPath: URL,
        configuration: LOCConfiguration,
        gitClean: Bool = false,
        fixLFS: Bool = false,
        initializeSubmodules: Bool = false
    ) {
        self.repoPath = repoPath
        self.configuration = configuration
        self.gitClean = gitClean
        self.fixLFS = fixLFS
        self.initializeSubmodules = initializeSubmodules
    }
}

/// SDK for counting lines of code.
public struct LOCSDK: Sendable {
    public init() {}

    /// Result of LOC counting operation.
    public struct Result: Sendable, Codable {
        public let metric: String
        public let linesOfCode: Int

        public init(metric: String, linesOfCode: Int) {
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
    /// - Parameter input: Input parameters for the operation
    /// - Returns: Result containing total LOC count
    public func countLOC(input: LOCInput) async throws -> Result {
        try await Self.checkClocInstalled()
        try await GitFix.prepareRepository(
            in: input.repoPath,
            gitClean: input.gitClean,
            fixLFS: input.fixLFS,
            initializeSubmodules: input.initializeSubmodules
        )

        let clocRunner = ClocRunner()
        let foldersToAnalyze = foldersToAnalyze(
            in: input.repoPath,
            include: input.configuration.include,
            exclude: input.configuration.exclude
        )

        let loc =
            try await input.configuration.languages
            .asyncFlatMap { language in
                try await foldersToAnalyze.asyncMap {
                    try await clocRunner.linesOfCode(at: $0, language: language)
                }
            }
            .compactMap { Int($0) }
            .reduce(0, +)

        let metric = "LOC \(input.configuration.languages) \(input.configuration.include)"
        return Result(metric: metric, linesOfCode: loc)
    }

    /// Checks out a commit and counts lines of code.
    /// - Parameters:
    ///   - hash: Commit hash to checkout
    ///   - input: Input parameters for the operation
    /// - Returns: Result containing total LOC count
    public func analyzeCommit(
        hash: String,
        input: LOCInput
    ) async throws -> Result {
        try await Shell.execute(
            "git",
            arguments: ["checkout", hash],
            workingDirectory: FilePath(input.repoPath.path(percentEncoded: false))
        )

        return try await countLOC(input: input)
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
