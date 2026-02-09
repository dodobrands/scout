import Foundation

package enum CommandParserError: Error {
    case invalidCommand(String)
}

extension CommandParserError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidCommand(let message):
            return "CommandParser error: \(message)"
        }
    }
}

package struct ParsedCommand {
    package let executable: String
    package let arguments: [String]
}

package struct CommandParser {
    /// Parses a command string into executable and arguments.
    ///
    /// Handles single quotes: content inside single quotes is treated as a single argument.
    /// For simple commands without quotes, the original command can be reconstructed
    /// by joining executable and arguments with spaces.
    ///
    /// Example: `mise install`
    /// Returns: executable: "mise", arguments: ["install"]
    ///
    /// Example: `sed -i '' -n '1p; /tuist/p' .tool-versions`
    /// Returns: executable: "sed", arguments: ["-i", "''", "-n", "'1p; /tuist/p'", ".tool-versions"]
    package static func parse(_ command: String) throws -> ParsedCommand {
        let trimmed = command.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw CommandParserError.invalidCommand(command)
        }

        var parts: [String] = []
        var currentPart = ""
        var i = trimmed.startIndex
        var inSingleQuote = false

        while i < trimmed.endIndex {
            let char = trimmed[i]

            if char == "'" {
                // Toggle single quote mode
                inSingleQuote.toggle()
                currentPart.append(char)
            } else if char == " " && !inSingleQuote {
                // End of argument (outside quotes)
                if !currentPart.isEmpty || parts.isEmpty {
                    // Add part if non-empty, or if it's the first part (executable can't be empty)
                    parts.append(currentPart)
                    currentPart = ""
                }
            } else {
                // Regular character (including spaces inside quotes)
                currentPart.append(char)
            }

            i = trimmed.index(after: i)
        }

        // Add last part
        if !currentPart.isEmpty || parts.isEmpty {
            parts.append(currentPart)
        }

        // Validate quote balance
        if inSingleQuote {
            throw CommandParserError.invalidCommand(
                "Unclosed single quote in command: \(command)"
            )
        }

        guard let executable = parts.first, !executable.isEmpty else {
            throw CommandParserError.invalidCommand(command)
        }

        let arguments = Array(parts.dropFirst())

        return ParsedCommand(executable: executable, arguments: arguments)
    }

    /// Represents a command prepared for execution with executable and arguments.
    package struct PreparedCommand {
        /// Executable to run (e.g., "/bin/sh" for shell commands, or "mise" for direct commands)
        package let executable: String

        /// Arguments to pass to executable
        package let arguments: [String]
    }

    /// Prepares a command string for execution, determining whether to use shell or direct execution.
    ///
    /// - Parameter command: Command string to prepare
    /// - Returns: PreparedCommand with executable and arguments ready to execute
    /// - Throws: CommandParserError if command is invalid
    package static func prepareExecution(_ command: String) throws -> PreparedCommand {
        // Check if command contains shell operators (pipes, redirects, etc.)
        if requiresShellExecution(command) {
            // Execute through shell for commands with pipes, redirects, etc.
            return PreparedCommand(executable: "/bin/sh", arguments: ["-c", command])
        } else {
            // Parse command into executable and arguments for direct execution
            let parsedCommand = try parse(command)
            return PreparedCommand(
                executable: parsedCommand.executable,
                arguments: parsedCommand.arguments
            )
        }
    }

    /// Determines if a command requires shell execution (contains pipes, redirects, etc.)
    private static func requiresShellExecution(_ command: String) -> Bool {
        // Check for shell operators that require shell interpretation
        let shellOperators = ["|", "&&", "||", ";", ">", ">>", "<", "<<", "&"]
        for shellOp in shellOperators {
            // Check if operator exists outside of quotes
            var inSingleQuote = false
            var inDoubleQuote = false
            var i = command.startIndex

            while i < command.endIndex {
                let char = command[i]

                if char == "'" && !inDoubleQuote {
                    inSingleQuote.toggle()
                } else if char == "\"" && !inSingleQuote {
                    inDoubleQuote.toggle()
                } else if !inSingleQuote && !inDoubleQuote {
                    // Check if we found the operator
                    if command[i...].hasPrefix(shellOp) {
                        return true
                    }
                }

                i = command.index(after: i)
            }
        }
        return false
    }
}
