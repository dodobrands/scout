import Foundation
import Testing

@testable import BuildSettings

@Suite("CommandParser")
struct CommandParserTests {

    // MARK: - parse() Tests

    @Suite("parse")
    struct ParseTests {

        @Test("When parsing simple command, should return executable only")
        func simpleCommandWithoutArguments() throws {
            let result = try CommandParser.parse("ls")
            #expect(result.executable == "ls")
            #expect(result.arguments == [])
        }

        @Test("When parsing command with single argument, should split correctly")
        func commandWithSingleArgument() throws {
            let result = try CommandParser.parse("ls -la")
            #expect(result.executable == "ls")
            #expect(result.arguments == ["-la"])
        }

        @Test("When parsing command with multiple arguments, should split all")
        func commandWithMultipleArguments() throws {
            let result = try CommandParser.parse("mise install")
            #expect(result.executable == "mise")
            #expect(result.arguments == ["install"])
        }

        @Test("When parsing command with single quoted argument, should preserve quotes")
        func commandWithSingleQuotedArgument() throws {
            let result = try CommandParser.parse("echo 'hello world'")
            #expect(result.executable == "echo")
            #expect(result.arguments == ["'hello world'"])
        }

        @Test("When parsing command with empty single quotes, should preserve them")
        func commandWithEmptySingleQuotes() throws {
            let result = try CommandParser.parse("sed -i ''")
            #expect(result.executable == "sed")
            #expect(result.arguments == ["-i", "''"])
        }

        @Test("When parsing complex sed command, should handle quotes correctly")
        func complexSedCommand() throws {
            let result = try CommandParser.parse("sed -i '' -n '1p; /tuist/p' .tool-versions")
            #expect(result.executable == "sed")
            #expect(result.arguments == ["-i", "''", "-n", "'1p; /tuist/p'", ".tool-versions"])
        }

        @Test("When parsing command with leading whitespace, should trim it")
        func commandWithLeadingWhitespace() throws {
            let result = try CommandParser.parse("   echo hello")
            #expect(result.executable == "echo")
            #expect(result.arguments == ["hello"])
        }

        @Test("When parsing command with trailing whitespace, should trim it")
        func commandWithTrailingWhitespace() throws {
            let result = try CommandParser.parse("echo hello   ")
            #expect(result.executable == "echo")
            #expect(result.arguments == ["hello"])
        }

        @Test("When parsing command with multiple spaces, should collapse them")
        func commandWithMultipleSpaces() throws {
            let result = try CommandParser.parse("echo    hello    world")
            #expect(result.executable == "echo")
            #expect(result.arguments == ["hello", "world"])
        }

        @Test("When parsing empty command, should throw error")
        func emptyCommandThrowsError() throws {
            #expect(throws: CommandParserError.self) {
                try CommandParser.parse("")
            }
        }

        @Test("When parsing whitespace only command, should throw error")
        func whitespaceOnlyCommandThrowsError() throws {
            #expect(throws: CommandParserError.self) {
                try CommandParser.parse("   ")
            }
        }

        @Test("When parsing command with unclosed quote, should throw error")
        func unclosedSingleQuoteThrowsError() throws {
            #expect(throws: CommandParserError.self) {
                try CommandParser.parse("echo 'hello")
            }
        }
    }

    // MARK: - prepareExecution() Tests

    @Suite("prepareExecution")
    struct PrepareExecutionTests {

        @Test("When preparing simple command, should execute directly")
        func simpleCommandExecutesDirectly() throws {
            let result = try CommandParser.prepareExecution("mise install")
            #expect(result.executable == "mise")
            #expect(result.arguments == ["install"])
        }

        @Test("When command contains pipe, should use shell")
        func commandWithPipeUsesShell() throws {
            let result = try CommandParser.prepareExecution("cat file.txt | grep pattern")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "cat file.txt | grep pattern"])
        }

        @Test("When command contains &&, should use shell")
        func commandWithAndUsesShell() throws {
            let result = try CommandParser.prepareExecution("cd dir && make")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "cd dir && make"])
        }

        @Test("When command contains ||, should use shell")
        func commandWithOrUsesShell() throws {
            let result = try CommandParser.prepareExecution("test -f file || touch file")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "test -f file || touch file"])
        }

        @Test("When command contains semicolon, should use shell")
        func commandWithSemicolonUsesShell() throws {
            let result = try CommandParser.prepareExecution("echo hello; echo world")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "echo hello; echo world"])
        }

        @Test("When command contains output redirect, should use shell")
        func commandWithOutputRedirectUsesShell() throws {
            let result = try CommandParser.prepareExecution("echo hello > file.txt")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "echo hello > file.txt"])
        }

        @Test("When command contains append redirect, should use shell")
        func commandWithAppendRedirectUsesShell() throws {
            let result = try CommandParser.prepareExecution("echo hello >> file.txt")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "echo hello >> file.txt"])
        }

        @Test("When command contains input redirect, should use shell")
        func commandWithInputRedirectUsesShell() throws {
            let result = try CommandParser.prepareExecution("sort < file.txt")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "sort < file.txt"])
        }

        @Test("When command contains background operator, should use shell")
        func commandWithBackgroundOperatorUsesShell() throws {
            let result = try CommandParser.prepareExecution("sleep 10 &")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "sleep 10 &"])
        }

        @Test("When pipe is inside single quotes, should not use shell")
        func pipeInsideSingleQuotesDoesNotTriggerShell() throws {
            let result = try CommandParser.prepareExecution("grep 'a|b' file.txt")
            #expect(result.executable == "grep")
            #expect(result.arguments == ["'a|b'", "file.txt"])
        }

        @Test("When pipe is inside double quotes, should not use shell")
        func pipeInsideDoubleQuotesDoesNotTriggerShell() throws {
            let result = try CommandParser.prepareExecution("grep \"a|b\" file.txt")
            #expect(result.executable == "grep")
            #expect(result.arguments == ["\"a|b\"", "file.txt"])
        }

        @Test("When semicolon is inside quotes, should not use shell")
        func semicolonInsideQuotesDoesNotTriggerShell() throws {
            let result = try CommandParser.prepareExecution("sed -n '1p; /test/p' file")
            #expect(result.executable == "sed")
            #expect(result.arguments == ["-n", "'1p; /test/p'", "file"])
        }
    }
}
