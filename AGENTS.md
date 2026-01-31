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
```

## Documentation Updates

When changing public APIs of any tool, update all relevant READMEs in `Sources/*/README.md`.

## Issues

When creating issues, use the issue template in `.github/ISSUE_TEMPLATE.md`.

## Pull Requests

Each issue must be solved in a separate PR. Never combine multiple issues in one PR unless explicitly told otherwise.

When creating PRs, use the PR template in `.github/pull_request_template.md`.
