# Architecture

This document describes coding conventions and architectural patterns used in this repository.

## Protocol Conformance

Use specific protocols instead of `Codable`:
- `Encodable` — for output structs that are only serialized to JSON
- `Decodable` — for config/input structs that are only read from JSON

Only use `Codable` when both encoding and decoding are actually needed.

## SDK API Design

**Standardized Input/Output types** — all SDKs must follow the same naming and structure:

```swift
public struct MySDK {
    // Input type inside SDK namespace
    public struct MetricInput: Sendable, CommitResolvable {
        public let commits: [String]
        // ... metric-specific fields
    }
    
    public struct Input: Sendable {
        public let git: GitConfiguration
        public let metrics: [MetricInput]
        // NO commit field - SDK iterates internally
    }
    
    // ResultItem for single metric result
    public struct ResultItem: Sendable, Encodable {
        // ... metric-specific fields
    }
    
    // Output for single commit analysis
    public struct Output: Sendable, Encodable {
        public let commit: String
        public let date: String
        public let results: [ResultItem]
    }
    
    // Public method: analyze all commits, yield outputs incrementally
    public func analyze(input: Input) -> AsyncThrowingStream<Output, any Error>
}
```

**SDK owns iteration logic** — SDK groups metrics by commit, performs checkouts, and yields outputs incrementally. CLI only builds Input and consumes the stream:

```swift
// CLI
let input = SDK.Input(git: gitConfig, metrics: metrics)
for try await output in sdk.analyze(input: input) {
    // Log and persist each output incrementally
}
```

**Single source of truth for parameters** — if data is in `input` (e.g., `input.metrics`), don't pass it as a separate parameter:

```swift
// Bad
func countFiles(filetype: String, input: FilesInput) -> Result

// Good
func analyze(input: Input) -> AsyncThrowingStream<Output, any Error>  // reads from input.metrics
```

**Minimize public API** — only methods used by CLI should be public. Internal methods accessed via `@testable import` in tests:

```swift
// SDK
public func analyze(input: Input) -> AsyncThrowingStream<Output, any Error>  // used by CLI
func count(input: Input) -> [Result]  // internal, for tests

// Tests
@testable import MySDK
let results = try await sut.count(input: input)
```

**Separate git operations from analysis logic** — SDK must have two layers:
- **Public `analyze()` method** — handles git operations (checkout, prepare repository) and orchestrates analysis across multiple commits. Must minimize checkouts — at most one checkout per unique commit. All metrics for the same commit must be analyzed within a single checkout
- **Internal analysis method** — performs domain-specific analysis on current repository state without any git operations. Must accept `AnalysisInput` as its only parameter — all domain-specific fields (type name, pattern, extension, etc.) must be inside `AnalysisInput`
- **Simplified input type** — internal analysis method uses a separate input type without git/metrics fields, but containing all parameters needed for a single analysis call

```swift
// SDK public types
public struct Input: Sendable {
    public let git: GitConfiguration
    public let metrics: [MetricInput]
    // ... other fields
}

public struct AnalysisInput: Sendable {
    public let repoPath: String
    // ... analysis-specific fields (no git, no metrics)
}

// Public method - handles git operations
// Groups metrics by commit to minimize checkouts (one checkout per unique commit)
// Yields outputs incrementally via AsyncThrowingStream
public func analyze(input: Input) -> AsyncThrowingStream<Output, any Error> {
    AsyncThrowingStream { continuation in
        let task = Task {
            do {
                let commitToMetrics = groupByCommit(input.metrics)
                for (commit, metrics) in commitToMetrics {
                    try Task.checkCancellation()
                    try await git.checkout(commit)           // one checkout per commit
                    try await GitFix.prepareRepository(git: input.git)
                    
                    for metric in metrics {                  // all metrics within single checkout
                        let analysisInput = AnalysisInput(repoPath: input.git.repoPath, ...)
                        let result = try await extractData(input: analysisInput)  // internal
                    }
                    continuation.yield(Output(...))
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        continuation.onTermination = { _ in task.cancel() }
    }
}

// Internal method - pure analysis, no git operations
func extractData(input: AnalysisInput) async throws -> [Result]

// Tests - use internal method directly with sample project
@testable import MySDK
let input = MySDK.AnalysisInput(repoPath: samplesDir.path, ...)
let results = try await sut.extractData(input: input)
```

**Benefits:**
- Tests are fast (no git operations, no checkout)
- Tests work with static sample projects in test resources
- Clear separation of concerns (git vs domain analysis)
- Consistent pattern across all SDK modules

## Type Organization

- Each type must live in its own dedicated file (e.g., `SetupCommand.swift`, `ObjectFromCode.swift`, `AnalysisInput.swift`)
- Types must be nested inside their parent namespace (e.g., `BuildSettings.SetupCommand`, not top-level `SetupCommand`)

## Input Data Layers

Input data flows through three layers with priority **CLI > Config file > Default**:

- **CLI arguments** (`*CLIInputs` structs) — raw values from ArgumentParser, all fields optional
- **Config file** (`*Config` structs) — JSON deserialization with `Decodable`, all fields optional (`Bool?`, `String?`)
- **SDK Input** (`*.Input` structs) — strictly typed public API with required fields and defaults, no `Decodable`

Merging happens in `*CLIInput+CLI.swift` extensions via `init(cli:config:)` initializer on `*.Input`. Optionals are resolved with defaults at this layer (e.g., `cli.value ?? config?.value ?? defaultValue`).

## Common Module Visibility

Prefer `package` over `public` in `Sources/Common/`. Use `public` only when the type is part of a public SDK API (e.g., `GitConfiguration` used in `*Input` structs).

## Safe Array Access

Use `[safe: index]` subscript instead of direct index access:

```swift
// Bad
let item = array[0]

// Good
guard let item = array[safe: 0] else { return }
```

## Testing

Use `try #require` instead of `#expect` with optionals:

```swift
// Bad
#expect(array.first?.value == expected)

// Good
let item = try #require(array.first)
#expect(item.value == expected)
```

Use `try #require` with safe subscript for index access:

```swift
// Bad
#expect(results[0].value == expected)

// Good
let item = try #require(results[safe: 0])
#expect(item.value == expected)
```
