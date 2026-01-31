# Scout

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdodobrands%2Fscout%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/dodobrands/scout)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdodobrands%2Fscout%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/dodobrands/scout)
[![](https://github.com/dodobrands/scout/actions/workflows/tests.yml/badge.svg)](https://github.com/dodobrands/scout/actions/workflows/tests.yml)

<p align="center">
  <img width="128" height="128" alt="Scout Logo" src="https://github.com/user-attachments/assets/b9ef981b-0f65-4a16-abfb-6391af834d7a" />
</p>

Code analysis toolkit for iOS/macOS repositories. Analyze any commit in your git history to track metrics over time — from the first commit to the latest. Build dashboards showing how your codebase evolves: type counts, file distributions, lines of code, and more.

## Installation

### Using mise (recommended)

Install [mise](https://mise.jdx.dev/getting-started.html) if you haven't already, then:

```bash
mise use github:dodobrands/scout
```

### Building from source

```bash
swift build
```

## Usage

Scout provides a single CLI with subcommands:

```bash
scout <subcommand> [options]
```

## Tools

### types

Count Swift types by inheritance. Tracks UIView, UIViewController, SwiftUI View, XCTestCase and other types.

```bash
scout types UIView UIViewController View
```

```json
{"commit":"abc123","date":"2025-01-15","results":{"UIView":42,"UIViewController":18,"View":156}}
```

📖 [Full documentation](Sources/Types/README.md)

### files

Count files by extension. Useful for tracking storyboard, xib, swift files count.

```bash
scout files swift storyboard xib
```

```json
{"commit":"abc123","date":"2025-01-15","results":{"swift":1250,"storyboard":12,"xib":8}}
```

📖 [Full documentation](Sources/Files/README.md)

### pattern

Search for string patterns in source files. Useful for tracking import statements, API usage, etc.

```bash
scout pattern "import UIKit" "import SwiftUI"
```

```json
{"commit":"abc123","date":"2025-01-15","results":{"import UIKit":89,"import SwiftUI":45}}
```

📖 [Full documentation](Sources/Pattern/README.md)

### loc

Count lines of code using `cloc`. Supports filtering by languages, include/exclude paths.

```bash
scout loc --config loc.json
```

```json
{"commit":"abc123","date":"2025-01-15","results":[{"languages":["Swift"],"linesOfCode":48500}]}
```

📖 [Full documentation](Sources/LOC/README.md)

### build-settings

Extract build settings from Xcode projects. Supports Tuist-generated projects with custom setup commands.

```bash
scout build-settings --config build.json
```

```json
{"commit":"abc123","date":"2025-01-15","results":[{"target":"MyApp","buildSettings":{"SWIFT_VERSION":"5.0"}}]}
```

📖 [Full documentation](Sources/BuildSettings/README.md)

## Analyzing Git History

All tools support `--commits` option to analyze specific commits. This enables tracking metrics over time:

```bash
# Analyze multiple commits
scout types --commits "abc123,def456,ghi789"

# Combine with other options
scout types --commits "abc123,def456" --config types.json
```

Use this to build historical dashboards by analyzing commits at regular intervals (e.g., monthly) from your repository's history.

## Requirements

- macOS 15+
- Swift 6.2+
