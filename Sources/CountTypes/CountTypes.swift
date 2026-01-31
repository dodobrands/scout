import ArgumentParser
import CodeReader
import Common
import Foundation
import Logging
import System
import SystemPackage

@main
public class CountTypes: AsyncParsableCommand {
  required public init() {}

  struct Summary: JobSummaryFormattable {
    let typeResults: [(typeName: String, count: Int)]

    var markdown: String {
      var md = "## CountTypes Summary\n\n"

      if !typeResults.isEmpty {
        md += "### Type Counts\n\n"
        md += "| Type | Count |\n"
        md += "|------|-------|\n"
        for result in typeResults {
          md += "| `\(result.typeName)` | \(result.count) |\n"
        }
        md += "\n"
      }

      return md
    }
  }

  @Option(name: [.long, .short], help: "Path to iOS repository")
  public var iosSources: String

  @Option(name: .long, help: "Path to configuration JSON file")
  public var config: String?

  @Option(name: [.long, .short], help: "Comma-separated list of commit hashes to analyze")
  public var commits: String

  @Flag(name: [.long, .short])
  public var verbose: Bool = false

  @Flag(
    name: [.long, .customShort("I")],
    help: "Initialize submodules (reset and update to correct commits)"
  )
  public var initializeSubmodules: Bool = false

  private static let logger = Logger(label: "mobile-code-metrics.CountTypes")

  public func run() async throws {
    LoggingSetup.setup(verbose: verbose)

    let configFilePath = SystemPackage.FilePath(config ?? "count-types-config.json")
    let config = try await CountTypesConfig(configFilePath: configFilePath)

    let repoPath =
      try URL(string: iosSources)
      ?! URLError.invalidURL(parameter: "iosSources", value: iosSources)

    let commitHashes = commits.split(separator: ",").map {
      String($0.trimmingCharacters(in: .whitespaces))
    }

    var typeResults: [(typeName: String, count: Int)] = []

    for typeName in config.types {
      Self.logger.info("Processing type: \(typeName)")

      Self.logger.info(
        "Will analyze \(commitHashes.count) commits for type '\(typeName)'",
        metadata: [
          "commits": .array(commitHashes.map { .string($0) })
        ]
      )

      var lastTypeCount = 0
      for hash in commitHashes {
        lastTypeCount = try await analyzeCommit(
          hash: hash,
          repoPath: repoPath,
          typeName: typeName
        )
      }

      Self.logger.notice(
        "Summary for '\(typeName)': analyzed \(commitHashes.count) commit(s)"
      )
      if !commitHashes.isEmpty {
        typeResults.append((typeName, lastTypeCount))
      }
    }

    let summary = Summary(typeResults: typeResults)
    logSummary(summary)
  }

  private func logSummary(_ summary: Summary) {
    if !summary.typeResults.isEmpty {
      Self.logger.info("Type counts:")
      for result in summary.typeResults {
        Self.logger.info("  - \(result.typeName): \(result.count)")
      }
    }

    writeJobSummary(summary)
  }

  private func writeJobSummary(_ summary: Summary) {
    GitHubActionsLogHandler.writeSummary(summary)
  }

  private func analyzeCommit(
    hash: String,
    repoPath: URL,
    typeName: String
  ) async throws -> Int {

    let codeReader = CodeReader()

    try await Shell.execute(
      "git",
      arguments: ["checkout", hash],
      workingDirectory: System.FilePath(iosSources)
    )
    try await GitFix.fixGitIssues(in: repoPath, initializeSubmodules: initializeSubmodules)

    let swiftFiles = findSwiftFiles(in: repoPath) ?? []
    let objects = try swiftFiles.flatMap {
      try codeReader.parseFile(from: $0)
    }

    let types = objects.filter {
      codeReader.isInherited(
        objectFromCode: $0,
        from: typeName,
        allObjects: objects
      )
    }.sorted(by: { $0.name < $1.name })

    Self.logger.debug("Types conforming to \(typeName): \(types.map { $0.name })")

    Self.logger.notice(
      "Found \(types.count) types inherited from \(typeName) at \(hash)"
    )

    return types.count
  }

  private func findSwiftFiles(in directory: URL) -> [URL]? {
    let fileManager = FileManager.default

    // Ensure the directory exists
    guard fileManager.fileExists(atPath: directory.path) else {
      Self.logger.info("Directory does not exist.")
      return nil
    }

    // Get the enumerator for the directory
    guard
      let enumerator = fileManager.enumerator(
        at: directory,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles],
        errorHandler: nil
      )
    else {
      Self.logger.info("Failed to create enumerator.")
      return nil
    }

    var swiftFiles: [URL] = []

    // Iterate through the files
    for case let fileURL as URL in enumerator {
      // Check if the file has a .swift extension
      if fileURL.pathExtension == "swift" {
        swiftFiles.append(fileURL)
      }
    }

    return swiftFiles
  }
}
