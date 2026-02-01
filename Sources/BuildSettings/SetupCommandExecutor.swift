import Common
import Foundation
import Logging
import System

/// Error that occurred during setup command execution.
public struct SetupCommandExecutionError: Error {
    /// The command that failed
    public let command: BuildSettingsConfig.SetupCommand

    /// The underlying error that occurred
    public let underlyingError: Error

    public init(command: BuildSettingsConfig.SetupCommand, underlyingError: Error) {
        self.command = command
        self.underlyingError = underlyingError
    }
}

extension SetupCommandExecutionError: LocalizedError {
    public var errorDescription: String? {
        let commandString = command.command
        let workingDirString = command.workingDirectory ?? "repo root"
        let underlyingDescription =
            (underlyingError as? LocalizedError)?.errorDescription
            ?? underlyingError.localizedDescription

        return
            "Setup command failed: '\(commandString)' (workingDirectory: \(workingDirString)). \(underlyingDescription)"
    }
}

/// Executes setup commands in a repository.
public struct SetupCommandExecutor {
    private static let logger = Logger(label: "mobile-code-metrics.SetupCommandExecutor")

    /// Executes setup commands sequentially in the specified repository.
    ///
    /// - Parameters:
    ///   - commands: Array of setup commands from config
    ///   - repoPath: Path to the repository root
    /// - Throws: `CommandParserError` if a command cannot be prepared
    public static func execute(
        _ commands: [BuildSettingsConfig.SetupCommand],
        in repoPath: URL
    ) async throws {
        for setupCommand in commands {
            // Use command-specific workingDirectory, or repo root if not specified
            let workingDirPath: FilePath
            if let dir = setupCommand.workingDirectory {
                let workingDirURL = repoPath.appendingPathComponent(dir, isDirectory: true)
                workingDirPath = FilePath(workingDirURL.path(percentEncoded: false))
            } else {
                workingDirPath = FilePath(repoPath.path(percentEncoded: false))
            }

            // Prepare command for execution
            let preparedCommand: CommandParser.PreparedCommand
            do {
                preparedCommand = try CommandParser.prepareExecution(setupCommand.command)
            } catch {
                throw SetupCommandExecutionError(command: setupCommand, underlyingError: error)
            }

            let commandMetadata: Logger.Metadata = [
                "executable": "\(preparedCommand.executable)",
                "arguments": "\(preparedCommand.arguments.joined(separator: " "))",
                "workingDirectory": "\(workingDirPath.string)",
            ]
            Self.logger.info("Executing setup command", metadata: commandMetadata)

            do {
                _ = try await Shell.execute(
                    preparedCommand.executable,
                    arguments: preparedCommand.arguments,
                    workingDirectory: workingDirPath
                )
            } catch {
                throw SetupCommandExecutionError(command: setupCommand, underlyingError: error)
            }
        }
    }
}
