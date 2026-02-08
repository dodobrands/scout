import Foundation
import Testing

@testable import BuildSettingsCLI

@Suite("CommandParser")
struct CommandParserTests {

    // MARK: - parse() Tests

    @Suite("parse")
    struct ParseTests {

        @Test
        func `When parsing simple command, should return executable only`() throws {
            let result = try CommandParser.parse("ls")
            #expect(result.executable == "ls")
            #expect(result.arguments == [])
        }

        @Test
        func `When parsing command with single argument, should split correctly`() throws {
            let result = try CommandParser.parse("ls -la")
            #expect(result.executable == "ls")
            #expect(result.arguments == ["-la"])
        }

        @Test
        func `When parsing command with multiple arguments, should split all`() throws {
            let result = try CommandParser.parse("mise install")
            #expect(result.executable == "mise")
            #expect(result.arguments == ["install"])
        }

        @Test
        func `When parsing command with single quoted argument, should preserve quotes`() throws {
            let result = try CommandParser.parse("echo 'hello world'")
            #expect(result.executable == "echo")
            #expect(result.arguments == ["'hello world'"])
        }

        @Test
        func `When parsing command with empty single quotes, should preserve them`() throws {
            let result = try CommandParser.parse("sed -i ''")
            #expect(result.executable == "sed")
            #expect(result.arguments == ["-i", "''"])
        }

        @Test
        func `When parsing complex sed command, should handle quotes correctly`() throws {
            let result = try CommandParser.parse("sed -i '' -n '1p; /tuist/p' .tool-versions")
            #expect(result.executable == "sed")
            #expect(result.arguments == ["-i", "''", "-n", "'1p; /tuist/p'", ".tool-versions"])
        }

        @Test
        func `When parsing command with leading whitespace, should trim it`() throws {
            let result = try CommandParser.parse("   echo hello")
            #expect(result.executable == "echo")
            #expect(result.arguments == ["hello"])
        }

        @Test
        func `When parsing command with trailing whitespace, should trim it`() throws {
            let result = try CommandParser.parse("echo hello   ")
            #expect(result.executable == "echo")
            #expect(result.arguments == ["hello"])
        }

        @Test
        func `When parsing command with multiple spaces, should collapse them`() throws {
            let result = try CommandParser.parse("echo    hello    world")
            #expect(result.executable == "echo")
            #expect(result.arguments == ["hello", "world"])
        }

        @Test
        func `When parsing empty command, should throw error`() throws {
            #expect(throws: CommandParserError.self) {
                try CommandParser.parse("")
            }
        }

        @Test
        func `When parsing whitespace only command, should throw error`() throws {
            #expect(throws: CommandParserError.self) {
                try CommandParser.parse("   ")
            }
        }

        @Test
        func `When parsing command with unclosed quote, should throw error`() throws {
            #expect(throws: CommandParserError.self) {
                try CommandParser.parse("echo 'hello")
            }
        }
    }

    // MARK: - prepareExecution() Tests

    @Suite("prepareExecution")
    struct PrepareExecutionTests {

        @Test
        func `When preparing simple command, should execute directly`() throws {
            let result = try CommandParser.prepareExecution("mise install")
            #expect(result.executable == "mise")
            #expect(result.arguments == ["install"])
        }

        @Test
        func `When command contains pipe, should use shell`() throws {
            let result = try CommandParser.prepareExecution("cat file.txt | grep pattern")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "cat file.txt | grep pattern"])
        }

        @Test
        func `When command contains &&, should use shell`() throws {
            let result = try CommandParser.prepareExecution("cd dir && make")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "cd dir && make"])
        }

        @Test
        func `When command contains ||, should use shell`() throws {
            let result = try CommandParser.prepareExecution("test -f file || touch file")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "test -f file || touch file"])
        }

        @Test
        func `When command contains semicolon, should use shell`() throws {
            let result = try CommandParser.prepareExecution("echo hello; echo world")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "echo hello; echo world"])
        }

        @Test
        func `When command contains output redirect, should use shell`() throws {
            let result = try CommandParser.prepareExecution("echo hello > file.txt")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "echo hello > file.txt"])
        }

        @Test
        func `When command contains append redirect, should use shell`() throws {
            let result = try CommandParser.prepareExecution("echo hello >> file.txt")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "echo hello >> file.txt"])
        }

        @Test
        func `When command contains input redirect, should use shell`() throws {
            let result = try CommandParser.prepareExecution("sort < file.txt")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "sort < file.txt"])
        }

        @Test
        func `When command contains background operator, should use shell`() throws {
            let result = try CommandParser.prepareExecution("sleep 10 &")
            #expect(result.executable == "/bin/sh")
            #expect(result.arguments == ["-c", "sleep 10 &"])
        }

        @Test
        func `When pipe is inside single quotes, should not use shell`() throws {
            let result = try CommandParser.prepareExecution("grep 'a|b' file.txt")
            #expect(result.executable == "grep")
            #expect(result.arguments == ["'a|b'", "file.txt"])
        }

        @Test
        func `When pipe is inside double quotes, should not use shell`() throws {
            let result = try CommandParser.prepareExecution("grep \"a|b\" file.txt")
            #expect(result.executable == "grep")
            #expect(result.arguments == ["\"a|b\"", "file.txt"])
        }

        @Test
        func `When semicolon is inside quotes, should not use shell`() throws {
            let result = try CommandParser.prepareExecution("sed -n '1p; /test/p' file")
            #expect(result.executable == "sed")
            #expect(result.arguments == ["-n", "'1p; /test/p'", "file"])
        }
    }
}
