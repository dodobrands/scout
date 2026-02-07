# Common

Shared utilities and helpers used across the project.

## What It Does

Provides common functionality including:
- Shell command execution
- Git operations and configuration
- Logging setup for CLI and GitHub Actions
- Custom operators
- Async collection extensions

## Architecture

### Git Operations

- **`Git`** — Git commands (e.g., get HEAD commit)
- **`GitConfiguration`** — Resolved git configuration with all values set
- **`GitCLIInputs`** — Raw CLI inputs for git options
- **`GitFileConfig`** — Git configuration from JSON file
- **`GitFix`** — Repository preparation (clean, LFS fix, submodules)

### Core Utilities

- **`Shell`** — Safe shell command execution without shell interpretation
- **`UnwrapOrThrow`** — Custom `?!` operator for unwrapping optionals or throwing errors
- **`LoggingSetup`** — Structured logging configuration
- **`GitHubActionsLogHandler`** — GitHub Actions compatible log handler with job summaries

### Extensions

- **`Array+AsyncMap`** — `asyncMap` and `asyncFlatMap` for arrays
- **`Array+NilIfEmpty`** — `nilIfEmpty` property for arrays
- **`Sequence+ConcurrentMap`** — `concurrentMap` for parallel async operations

### Error Types

- **`ParseError`** — JSON and structure parsing errors
- **`URLError`** — URL validation errors
- **`ShellError`** — Shell command execution errors

## Usage

### Shell Command Execution

```swift
import Common

// Execute git command
let output = try await Shell.execute(
    "git",
    arguments: ["log", "--oneline", "main"]
)

// Execute with working directory
let result = try await Shell.execute(
    "git",
    arguments: ["status"],
    workingDirectory: repoPath
)
```

**Important:** Always pass executable and arguments separately. The executor calls commands directly without shell interpretation for security.

### Unwrap Operator

```swift
import Common

// Unwrap optional or throw error
let value = optionalValue ?! URLError.invalidURL(
    parameter: "endpoint",
    value: urlString
)
```

### Git Operations

```swift
import Common

// Get current HEAD commit
let commit = try await Git.headCommit(repoPath: "/path/to/repo")

// Prepare repository before analysis
try await GitFix.prepareRepository(git: gitConfiguration)
```

## API Reference

### `Shell`

#### `execute(_:arguments:workingDirectory:)`

Executes a command directly without shell interpretation.

**Parameters:**
- `_ executable: String` — Executable name (e.g., "git", "cloc")
- `arguments: [String]` — Command arguments
- `workingDirectory: FilePath?` — Optional working directory

**Returns:** Command output as `String`

**Throws:** `ShellError` for command execution failures

**Example:**
```swift
let output = try await Shell.execute(
    "git",
    arguments: ["log", "--oneline"],
    workingDirectory: FilePath(repoPath)
)
```

### Custom Operator `?!`

Unwraps an optional or throws an error.

**Usage:**
```swift
let value = optional ?! Error.missingValue
```

If `optional` is `nil`, throws the provided error. Otherwise, returns the unwrapped value.

## Error Types

### `ParseError`

```swift
public enum ParseError: Error {
    case invalidJSON(data: Data, underlyingError: Error?, responseString: String?)
    case invalidDateFormat(string: String, format: String)
    case missingKey(key: String, in: [String: Sendable])
    case invalidType(key: String, expected: String, actual: String)
    case invalidStructure(key: String)
}
```

### `URLError`

```swift
public enum URLError: Error {
    case emptyURL(parameter: String)
    case invalidURL(parameter: String, value: String)
}
```

### `ShellError`

```swift
public enum ShellError: Error {
    case executionFailed(executable: String, arguments: [String], underlyingError: String)
    case processFailed(executable: String, arguments: [String], exitCode: TerminationStatus, error: String)
}
```

## See Also

- Used by all modules in the project for common functionality
- [GitConfiguration.md](GitConfiguration.md) — Git configuration format documentation
