import BuildSettings
import Foundation
import Testing

@Suite("CommandParser")
struct CommandParserTests {

    // MARK: - parse() Tests

    @Suite("parse")
    struct ParseTests {

        @Test("Simple command without arguments")
        func simpleCommandWithoutArguments() throws {
            let result = try CommandParser.parse("ls")
            #expect(result.executable == "ls")
            #expect(result.arguments == [])
        }

        @Test("Command with single argument")
        func commandWithSingleArgument() throws {
            let result = try CommandParser.parse("ls -la")
            #expect(result.executable == "ls")
            #expect(result.arguments == ["-la"])
        }

        @Test("Command with multiple arguments")
        func commandWithMultipleArguments() throws {
            let result = try CommandParser.parse("mise install")
            #expect(result.executable == "mise")
            #expect(result.arguments == ["install"])
        }

        @Test("Command with single quoted argument")
        func commandWithSingleQuotedArgument() throws {
            let result = try CommandParser.parse("echo 'hello world'")
            #expect(result.executable == "echo")
            #expect(result.arguments == ["'hello world'"])
        }

        @Test("Command with empty single quotes")
        func commandWithEmptySingleQuotes() throws {
            let result = try CommandParser.parse("sed -i ''")
            #expect(result.executable == "sed")
            #expect(result.arguments == ["-i", "''"])
        }

        @Test("Complex sed command with quotes")
        func complexSedCommand() throws {
            let result = try CommandParser.parse("sed -i '' -n '1p; /tuist/p' .tool-versions")
            #expect(result.executable == "sed")
            #expect(result.arguments == ["-i", "''", "-n", "'1p; /tuist/p'", ".tool-versions"])
        }

        @Test("Command with leading whitespace")
        func commandWithLeadingWhitespace() throws {
            let result = try CommandParser.parse("   echo hello")
            #expect(result.executable == "echo")
            #expect(result.arguments == ["hello"])
        }

        @Test("Command with trailing whitespace")
        func commandWithTrailingWhitespace() throws {
            let result = try CommandParser.parse("echo hello   ")
            #expect(result.executable == "echo")
            #expect(result.arguments == ["hello"])
        }

        @Test("Command with multiple spaces between arguments")
        func commandWithMultipleSpaces() throws {
            let result = try CommandParser.parse("echo    hello    world")
            #expect(result.executable == "echo")
            #expect(result.arguments == ["hello", "world"])
        }

        @Test("Empty command throws error")
        func emptyCommandThrowsError() throws {
            #expect(throws: CommandParserError.self) {
                try CommandParser.parse("")
            }
        }

        @Test("Whitespace only command throws error")
        func whitespaceOnlyCommandThrowsError() throws {
            #expect(throws: CommandParserError.self) {
                try CommandParser.parse("   ")
            }
        }

        @Test("Unclosed single quote throws error")
        func unclosedSingleQuoteThrowsError() throws {
            #expect(throws: CommandParserError.self) {
                try CommandParser.parse("echo 'hello")
            }
        }
    }

    // MARK: - prepareExecution() Tests

    @Suite("prepareExecution")
    struct PrepareExecutionTests {

        @Test("Simple command executes directly")
        func simpleCommandExecutesDirectly() throws {
            let result = try CommandParser.prepareExecution("mise install")
            #expect(result.executable == "mise")
            #expect(result.arguments == ["install"])
        }

        @Test("Command with pipe uses shell")
        func commandWithPipeUsesShell() throws {
            let result = try CommandParser.prepareExecution("cat file.txt | grep pattern")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "cat file.txt | grep pattern"])
        }

        @Test("Command with && uses shell")
        func commandWithAndUsesShell() throws {
            let result = try CommandParser.prepareExecution("cd dir && make")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "cd dir && make"])
        }

        @Test("Command with || uses shell")
        func commandWithOrUsesShell() throws {
            let result = try CommandParser.prepareExecution("test -f file || touch file")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "test -f file || touch file"])
        }

        @Test("Command with semicolon uses shell")
        func commandWithSemicolonUsesShell() throws {
            let result = try CommandParser.prepareExecution("echo hello; echo world")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "echo hello; echo world"])
        }

        @Test("Command with output redirect uses shell")
        func commandWithOutputRedirectUsesShell() throws {
            let result = try CommandParser.prepareExecution("echo hello > file.txt")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "echo hello > file.txt"])
        }

        @Test("Command with append redirect uses shell")
        func commandWithAppendRedirectUsesShell() throws {
            let result = try CommandParser.prepareExecution("echo hello >> file.txt")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "echo hello >> file.txt"])
        }

        @Test("Command with input redirect uses shell")
        func commandWithInputRedirectUsesShell() throws {
            let result = try CommandParser.prepareExecution("sort < file.txt")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "sort < file.txt"])
        }

        @Test("Command with background operator uses shell")
        func commandWithBackgroundOperatorUsesShell() throws {
            let result = try CommandParser.prepareExecution("sleep 10 &")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "sleep 10 &"])
        }

        @Test("Pipe inside single quotes does not trigger shell")
        func pipeInsideSingleQuotesDoesNotTriggerShell() throws {
            let result = try CommandParser.prepareExecution("grep 'a|b' file.txt")
            #expect(result.executable == "grep")
            #expect(result.arguments == ["'a|b'", "file.txt"])
        }

        @Test("Pipe inside double quotes does not trigger shell")
        func pipeInsideDoubleQuotesDoesNotTriggerShell() throws {
            let result = try CommandParser.prepareExecution("grep \"a|b\" file.txt")
            #expect(result.executable == "grep")
            #expect(result.arguments == ["\"a|b\"", "file.txt"])
        }

        @Test("Semicolon inside quotes does not trigger shell")
        func semicolonInsideQuotesDoesNotTriggerShell() throws {
            let result = try CommandParser.prepareExecution("sed -n '1p; /test/p' file")
            #expect(result.executable == "sed")
            #expect(result.arguments == ["-n", "'1p; /test/p'", "file"])
        }
    }
}
