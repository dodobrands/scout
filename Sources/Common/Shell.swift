import Foundation
import Logging
import Subprocess
import System

/// Shell command executor that runs commands directly without shell interpretation.
///
/// ## Usage
///
/// ### ✅ Correct: Direct command execution
///
/// Pass the executable and arguments separately. The executor will call the command directly:
///
/// ```swift
/// // Good: git command with separate arguments
/// let output = try await Shell.execute(
///     "git",
///     arguments: [
///         "-C", repoPath.path(percentEncoded: false),
///         "log", "--after=\(timestamp)", "--pretty=format:%h", "--reverse", branch
///     ]
/// )
/// // Parse output programmatically
/// let commitHash = output.split(separator: "\n").first.map(String.init) ?? ""
/// ```
///
/// ### ❌ Incorrect: Shell wrapper with pipes or cd commands
///
/// Do NOT use shell wrappers (sh, bash) with pipes, shell operators, or cd commands. Instead:
/// - Use `workingDirectory` parameter for directory changes
/// - Parse output programmatically instead of using pipes
///
/// ```swift
/// // Bad: Using shell wrapper with pipe
/// let output = try await Shell.execute(
///     "sh",
///     arguments: [
///         "-c",
///         "git -C '\(path)' log --after='\(date)' | head -1"
///     ]
/// )
///
/// // Bad: Using bash with pipe
/// let output = try await Shell.execute(
///     "bash",
///     arguments: [
///         "-c",
///         "git log | head -1"
///     ]
/// )
///
/// // Bad: Using sh -c with cd commands
/// let output = try await Shell.execute(
///     "sh",
///     arguments: [
///         "-c",
///         "cd '\(path)' && cd '\(subdir)' && xcodebuild -list -json"
///     ]
/// )
/// ```
///
/// ### ✅ Correct: Use workingDirectory parameter
///
/// Use the `workingDirectory` parameter instead of cd commands:
///
/// ```swift
/// // Good: Use workingDirectory parameter
/// let output = try await Shell.execute(
///     "xcodebuild",
///     arguments: ["-list", "-json", "-workspace", "MyApp.xcworkspace"],
///     workingDirectory: FilePath("ios/MyApp")
/// )
///
/// // Good: For git commands, use -C flag OR workingDirectory
/// let output = try await Shell.execute(
///     "git",
///     arguments: ["log", "--oneline"],
///     workingDirectory: FilePath(repoPath)
/// )
/// ```
///
/// ## Why?
///
/// - Direct execution is more secure (no shell injection risks)
/// - Better error handling and logging
/// - Cross-platform compatibility
/// - Output parsing is explicit and controllable
public class Shell {
    private static let logger = Logger(label: "mobile-code-metrics.Shell")

    /// Executes a command directly without shell interpretation.
    ///
    /// - Parameters:
    ///   - executable: The command to execute (e.g., "git", "ls", "cat")
    ///   - arguments: Command arguments as separate strings
    ///   - workingDirectory: Optional working directory for command execution
    /// - Returns: Command output as a string
    /// - Throws: `ShellError` if the command fails
    ///
    /// ## Examples
    ///
    /// ```swift
    /// // Execute git log
    /// let output = try await Shell.execute(
    ///     "git",
    ///     arguments: ["-C", "/path/to/repo", "log", "--oneline"]
    /// )
    ///
    /// // Execute command in specific directory
    /// let output = try await Shell.execute(
    ///     "tuist",
    ///     arguments: ["install"],
    ///     workingDirectory: FilePath("path-to-project")
    /// )
    ///
    /// // Parse output programmatically (equivalent to shell pipe)
    /// let firstLine = output.split(separator: "\n").first.map(String.init) ?? ""
    /// ```
    @discardableResult
    public static func execute(
        _ executable: String,
        arguments: [String] = [],
        workingDirectory: FilePath? = nil
    ) async throws(ShellError) -> String {
        var metadata: Logger.Metadata = [
            "executable": "\(executable)",
            "arguments": "\(arguments.joined(separator: " "))",
        ]
        if let workingDirectory {
            metadata["workingDirectory"] = "\(workingDirectory.string)"
        }
        logger.debug("Executing command", metadata: metadata)

        let result: CollectedResult<StringOutput<Unicode.UTF8>, StringOutput<Unicode.UTF8>>
        do {
            var configuration = Subprocess.Configuration(
                executable: .name(executable),
                arguments: .init(arguments)
            )
            if let workingDirectory {
                configuration.workingDirectory = workingDirectory
            }
            result = try await run(
                configuration,
                output: .string(limit: .max),
                error: .string(limit: .max)
            )
        } catch let error {
            // Convert any error from run() to ShellError with detailed information
            logger.error(
                "Command execution failed",
                metadata: [
                    "executable": "\(executable)",
                    "arguments": "\(arguments.joined(separator: " "))",
                    "error": "\(error.localizedDescription)",
                    "errorType": "\(type(of: error))",
                ]
            )
            throw ShellError.executionFailed(
                executable: executable,
                arguments: arguments,
                underlyingError: error.localizedDescription
            )
        }

        // Check if process exited successfully
        guard case .exited(let code) = result.terminationStatus, code == 0 else {
            let errorOutput = result.standardError ?? ""
            let exitCode: String
            if case .exited(let exitCodeValue) = result.terminationStatus {
                exitCode = "\(exitCodeValue)"
            } else {
                exitCode = "\(result.terminationStatus)"
            }
            let error = ShellError.processFailed(
                executable: executable,
                arguments: arguments,
                exitCode: result.terminationStatus,
                error: errorOutput
            )
            let errorMessage = error.errorDescription ?? "Command failed"
            logger.error(
                "Command failed: \(errorMessage)",
                metadata: [
                    "executable": "\(executable)",
                    "arguments": "\(arguments.joined(separator: " "))",
                    "exitCode": "\(exitCode)",
                    "error": "\(errorOutput)",
                ]
            )
            throw error
        }

        let output =
            result.standardOutput?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            ?? ""
        logger.debug(
            "Command completed successfully",
            metadata: [
                "executable": "\(executable)",
                "outputLength": "\(output.count)",
            ]
        )
        return output
    }
}

public enum ShellError: Error {
    /// Process execution failed (executable not found, permission denied, etc.)
    case executionFailed(executable: String, arguments: [String], underlyingError: String)

    /// Process exited with non-zero exit code
    case processFailed(
        executable: String,
        arguments: [String],
        exitCode: TerminationStatus,
        error: String
    )
}

extension ShellError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .executionFailed(let executable, let arguments, let underlyingError):
            return
                "Failed to execute command '\(executable)' with arguments [\(arguments.joined(separator: ", "))]: \(underlyingError)"
        case .processFailed(let executable, let arguments, let exitCode, let error):
            let exitCodeString: String
            if case .exited(let code) = exitCode {
                exitCodeString = "\(code)"
            } else {
                exitCodeString = "\(exitCode)"
            }
            let command = "\(executable) \(arguments.joined(separator: " "))"
            return
                "Command failed: '\(command)' (exit code: \(exitCodeString))\nError output: \(error)"
        }
    }
}

extension ShellError: CustomNSError {
    public var errorUserInfo: [String: Any] {
        switch self {
        case .executionFailed(let executable, let arguments, let underlyingError):
            return [
                "executable": executable,
                "arguments": arguments,
                "underlyingError": underlyingError,
            ]
        case .processFailed(let executable, let arguments, let exitCode, let error):
            let exitCodeString: String
            if case .exited(let code) = exitCode {
                exitCodeString = "\(code)"
            } else {
                exitCodeString = "\(exitCode)"
            }
            return [
                "executable": executable,
                "arguments": arguments,
                "exitCode": exitCodeString,
                "errorOutput": error,
            ]
        }
    }
}
