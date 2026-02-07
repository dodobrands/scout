# AGENTS.md

This file provides guidance to LLM when working with code in this repository.

## Project Overview

Scout is a Swift-based code analysis toolkit for mobile repositories. It provides executable tools for counting types, files, imports, and lines of code across git history, with optional Google Sheets integration for metrics tracking.

## Build Commands

```bash
swift build                           # Build all targets
swift build --build-tests             # Build including tests
swift build --product CountTypes      # Build specific executable
swift run CountTypes [args]           # Run executable directly
```

## Testing

Uses Swift Testing framework with `@Test` macros. Tests are in `Tests/CodeReaderTests/`.

```bash
swift test                            # Build and run tests
swift test --skip-build               # Run tests (after build)
```

## Linting and Formatting

Uses Swift Format with configuration in `.swift-format.json`.

```bash
sh scripts/lint.sh                    # Lint with --strict
sh scripts/format.sh                  # Auto-format in place
```

## Documentation

Each module has its own README in `Sources/*/README.md` with API details and configuration formats.

## Branching

Each issue must be solved in a separate branch created from fresh main:

```bash
git checkout main
git pull origin main
git checkout -b <branch-name>
```

Before creating a PR, run all tests and linter:

```bash
sh scripts/lint.sh
swift test
periphery scan --skip-build --strict
```

**Never force push (`git push --force` or `--force-with-lease`) without explicit user request.**

## Commits

Make a commit after each logical unit of work:

- After completing a task or todo item
- Before switching from coding to validation (linting, testing, static analysis)
- After fixing issues found during validation
- Before switching to documentation updates
- After documentation updates

Each commit should represent a single coherent change that can be understood in isolation.

## Coding Conventions

### Protocol Conformance

Use specific protocols instead of `Codable`:
- `Encodable` — for output structs that are only serialized to JSON
- `Decodable` — for config/input structs that are only read from JSON

Only use `Codable` when both encoding and decoding are actually needed.

### SDK API Design

1. **Single source of truth for parameters** — if data is in `input` (e.g., `input.metrics`), don't pass it as a separate parameter:

```swift
// Bad
func countFiles(filetype: String, input: FilesInput) -> Result

// Good
func countFiles(input: FilesInput) -> [Result]  // reads from input.metrics
```

2. **Minimize public API** — only methods used by CLI should be public. Internal methods accessed via `@testable import` in tests:

```swift
// SDK
public func analyzeCommit(hash: String, input: Input) -> [Result]  // used by CLI
func count(input: Input) -> [Result]  // internal, for tests

// Tests
@testable import MySDK
let results = try await sut.count(input: input)
```

### Common Module Visibility

Prefer `package` over `public` in `Sources/Common/`. Use `public` only when the type is part of a public SDK API (e.g., `GitConfiguration` used in `*Input` structs).

### Safe Array Access

Use `[safe: index]` subscript instead of direct index access:

```swift
// Bad
let item = array[0]

// Good
guard let item = array[safe: 0] else { return }
```

### Testing

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

## Documentation Updates

When changing public APIs of any tool, update all relevant READMEs in `Sources/*/README.md`.

## Issues

When creating issues, use the issue template in `.github/ISSUE_TEMPLATE.md`.

## Pull Requests

Each issue must be solved in a separate PR. Never combine multiple issues in one PR unless explicitly told otherwise.

When creating PRs, use the PR template in `.github/pull_request_template.md`.

## Language

All work in this repository must be in English: PR titles, PR descriptions, commit messages, issue titles, issue descriptions, comments, code comments, and documentation.
