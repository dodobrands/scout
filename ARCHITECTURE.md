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
    
    // Public method: analyze all commits, return array of outputs
    public func analyze(input: Input) async throws -> [Output]
}
```

**SDK owns iteration logic** — SDK groups metrics by commit, performs checkouts, and returns complete outputs. CLI only builds Input and formats Output:

```swift
// CLI
let input = SDK.Input(git: gitConfig, metrics: metrics)
let outputs = try await sdk.analyze(input: input)
// Format/write outputs
```

**Single source of truth for parameters** — if data is in `input` (e.g., `input.metrics`), don't pass it as a separate parameter:

```swift
// Bad
func countFiles(filetype: String, input: FilesInput) -> Result

// Good
func analyze(input: Input) -> [Output]  // reads from input.metrics
```

**Minimize public API** — only methods used by CLI should be public. Internal methods accessed via `@testable import` in tests:

```swift
// SDK
public func analyze(input: Input) -> [Output]  // used by CLI
func count(input: Input) -> [Result]  // internal, for tests

// Tests
@testable import MySDK
let results = try await sut.count(input: input)
```

**Separate git operations from analysis logic** — SDK must have two layers:
- **Public `analyze()` method** — handles git operations (checkout, prepare repository) and orchestrates analysis across multiple commits
- **Internal analysis method** — performs domain-specific analysis on current repository state without any git operations
- **Simplified input type** — internal analysis method uses a separate input type without git/metrics fields

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
public func analyze(input: Input) async throws -> [Output] {
    for commit in commits {
        try await git.checkout(commit)
        try await GitFix.prepareRepository(git: input.git)
        
        let analysisInput = AnalysisInput(repoPath: input.git.repoPath, ...)
        let result = try await extractData(input: analysisInput)  // internal
        // ...
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
