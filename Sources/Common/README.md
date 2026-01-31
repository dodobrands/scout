# Common

Shared utilities and helpers used across the project.

## What It Does

Provides common functionality including:
- Shell command execution
- Error types for the project
- Retry logic for async operations
- URL and file path helpers
- Logging setup
- Custom operators

## Architecture

### Error Types

- **`FileError`** — File and resource access errors
- **`GitError`** — Git operation errors
- **`NetworkError`** — Network and URL-related errors
- **`ParseError`** — JSON and date parsing errors
- **`ValidationError`** — Input validation errors
- **`ConfigurationError`** — Configuration-related errors

### Core Utilities

- **`Shell`** — Safe shell command execution without shell interpretation
- **`Task+Retry`** — Automatic retry with exponential backoff for async operations
- **`UnwrapOrThrow`** — Custom `?!` operator for unwrapping optionals or throwing errors
- **`URL+Helpers`** — URL manipulation helpers
- **`LoggingSetup`** — Structured logging configuration

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

### Retry Logic

```swift
import Common

// Automatically retry network operation
let data = try await Task.retrying {
    try await downloadData(from: url)
}
```

The retry mechanism uses exponential backoff and handles transient failures automatically.

### Unwrap Operator

```swift
import Common

// Unwrap optional or throw error
let value = optionalValue ?! ValidationError.invalidURL(
    parameter: "endpoint",
    value: urlString
)
```

### Error Handling

```swift
import Common

do {
    let file = try readFile(at: path)
} catch FileError.resourceNotFound(let name, let ext, let subdirectory) {
    print("Resource not found: \(name).\(ext) in \(subdirectory ?? "root")")
} catch {
    // Handle other errors
}
```

## API Reference

### `Shell`

#### `execute(_:arguments:workingDirectory:)`

Executes a command directly without shell interpretation.

**Parameters:**
- `_ executable: String` — Executable name (e.g., "git", "cloc")
- `arguments: [String]` — Command arguments
- `workingDirectory: URL?` — Optional working directory

**Returns:** Command output as `String`

**Throws:** `Subprocess.Error` for command execution failures

**Example:**
```swift
let output = try await Shell.execute(
    "git",
    arguments: ["log", "--oneline"],
    workingDirectory: repoPath
)
```

### `Task+Retry`

#### `retrying(maxAttempts:baseDelay:maxDelay:operation:)`

Automatically retries an async operation with exponential backoff.

**Parameters:**
- `maxAttempts: Int` — Maximum number of retry attempts (default: 3)
- `baseDelay: TimeInterval` — Base delay between retries (default: 1.0)
- `maxDelay: TimeInterval` — Maximum delay cap (default: 60.0)
- `operation: () async throws -> T` — Async operation to retry

**Returns:** Result of the operation

**Example:**
```swift
let result = try await Task.retrying {
    try await networkRequest()
}
```

### Custom Operator `?!`

Unwraps an optional or throws an error.

**Usage:**
```swift
let value = optional ?! Error.missingValue
```

If `optional` is `nil`, throws the provided error. Otherwise, returns the unwrapped value.

## Error Types

### `FileError`

```swift
public enum FileError: Error {
    case fileNotFound(name: String, in: URL)
    case resourceNotFound(name: String, extension: String?, subdirectory: String?)
}
```

### `GitError`

```swift
public enum GitError: Error {
    case commandFailed(command: String, output: String)
    case invalidCommitHash(String)
}
```

### `NetworkError`

```swift
public enum NetworkError: Error {
    case invalidURLComponents(parameter: String, value: String)
    case cannotBuildURL(components: URLComponents)
}
```

### `ParseError`

```swift
public enum ParseError: Error {
    case invalidJSON(Data)
    case invalidDateFormat(String)
}
```

### `ValidationError`

```swift
public enum ValidationError: Error {
    case invalidURL(parameter: String, value: String)
    case invalidEnumValue(String, allowedValues: [String])
}
```

## See Also

- Used by all modules in the project for common functionality
