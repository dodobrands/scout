# Scout

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdodobrands%2Fscout%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/dodobrands/scout)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdodobrands%2Fscout%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/dodobrands/scout)
[![](https://github.com/dodobrands/scout/actions/workflows/tests.yml/badge.svg)](https://github.com/dodobrands/scout/actions/workflows/tests.yml)

<p align="center">
  <img width="128" height="128" alt="Scout Logo" src="https://github.com/user-attachments/assets/b9ef981b-0f65-4a16-abfb-6391af834d7a" />
</p>

Code analysis toolkit for iOS/macOS repositories. Analyze any commit in your git history to track metrics over time — from the first commit to the latest. Build dashboards showing how your codebase evolves: type counts, file distributions, lines of code, and more.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Tools](#tools)
  - [types](#types)
  - [files](#files)
  - [pattern](#pattern)
  - [loc](#loc)
  - [build-settings](#build-settings)
- [Configuration](#configuration)
- [Analyzing Git History](#analyzing-git-history)
  - [Best Practices for Config and Output Paths](#best-practices-for-config-and-output-paths)
- [Requirements](#requirements)

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

**Command:**
```bash
scout types UIView UIViewController View --output results.json
```

**Output:**
```json
[
  {
    "commit": "abc1234def5678",
    "date": "2025-01-15T07:30:00Z",
    "results": [
      {
        "typeName": "UIView",
        "types": [
          { "name": "CustomButton", "fullName": "CustomButton", "path": "Sources/UI/CustomButton.swift" },
          { "name": "HeaderView", "fullName": "Components.HeaderView", "path": "Sources/Components/HeaderView.swift" }
        ]
      },
      {
        "typeName": "UIViewController",
        "types": [
          { "name": "HomeViewController", "fullName": "HomeViewController", "path": "Sources/Screens/HomeVC.swift" }
        ]
      }
    ]
  }
]
```

📖 [Full documentation](Sources/TypesCLI/README.md)

### files

Count files by extension. Useful for tracking storyboard, xib, swift files count.

**Command:**
```bash
scout files swift storyboard xib --output results.json
```

**Output:**
```json
[
  {
    "commit": "abc1234def5678",
    "date": "2025-01-15T07:30:00Z",
    "results": [
      {
        "filetype": "swift",
        "files": ["Sources/App.swift", "Sources/Model.swift"]
      },
      {
        "filetype": "storyboard",
        "files": ["Main.storyboard"]
      }
    ]
  }
]
```

📖 [Full documentation](Sources/FilesCLI/README.md)

### pattern

Search for string patterns in source files. Useful for tracking import statements, API usage, etc.

**Command:**
```bash
scout pattern "import UIKit" "import SwiftUI" --output results.json
```

**Output:**
```json
[
  {
    "commit": "abc1234def5678",
    "date": "2025-01-15T07:30:00Z",
    "results": [
      {
        "pattern": "import UIKit",
        "matches": [
          { "file": "Sources/App.swift", "line": 1 }
        ]
      },
      {
        "pattern": "import SwiftUI",
        "matches": [
          { "file": "Sources/ContentView.swift", "line": 1 }
        ]
      }
    ]
  }
]
```

📖 [Full documentation](Sources/PatternCLI/README.md)

### loc

Count lines of code using `cloc`. Supports filtering by languages, include/exclude paths.

**Command:**
```bash
scout loc --config loc.json --output results.json
```

**Output:**
```json
[
  {
    "commit": "abc1234def5678",
    "date": "2025-01-15T07:30:00Z",
    "results": [
      {
        "metric": "Swift | Sources",
        "linesOfCode": 48500
      }
    ]
  }
]
```

📖 [Full documentation](Sources/LOCCLI/README.md)

### build-settings

Extract build settings from Xcode projects. Supports Tuist-generated projects with custom setup commands.

**Command:**
```bash
scout build-settings --config build.json --output results.json
```

**Output:**
```json
[
  {
    "commit": "abc1234def5678",
    "date": "2025-01-15T07:30:00Z",
    "results": [
      {
        "setting": "SWIFT_VERSION",
        "targets": { "MyApp": "5.0", "MyAppTests": "5.0" }
      },
      {
        "setting": "IPHONEOS_DEPLOYMENT_TARGET",
        "targets": { "MyApp": "15.0", "MyAppTests": "15.0" }
      }
    ]
  }
]
```

📖 [Full documentation](Sources/BuildSettingsCLI/README.md)

## Configuration

All tools support both command-line arguments and JSON configuration files. **Command-line arguments take priority over config file values.**

```bash
# Config only
scout types --config types.json

# Arguments override config
scout types UIView UIViewController --config types.json
```

## Analyzing Git History

All tools support `--commits` option to analyze specific commits. This enables tracking metrics over time:

```bash
scout types UIView --commits abc123 def456 ghi789 --output results.json
```

When analyzing multiple commits, the output is an array:

```json
[
  {
    "commit": "abc123",
    "date": "2025-01-15T07:30:00Z",
    "results": { "UIView": ["Button", "Card"] }
  },
  {
    "commit": "def456",
    "date": "2025-02-15T11:45:00Z",
    "results": { "UIView": ["Button", "Card", "Header"] }
  }
]
```

Commits are processed in the order they are provided.

Use this to build historical dashboards by analyzing commits at regular intervals (e.g., monthly) from your repository's history.

### Best Practices for Config and Output Paths

When analyzing historical commits, Scout checks out each commit in the working tree. If `--git-clean` is enabled, it runs `git clean -ffdx` which **removes all untracked and ignored files** — including config files and output results placed inside the repository directory.

To avoid losing files during analysis:

1. **Place config and output paths outside the repository.** For example, on GitHub Actions use `$RUNNER_TEMP`:
   ```bash
   cp scout-config.json "$RUNNER_TEMP/scout-config.json"

   scout types --config "$RUNNER_TEMP/scout-config.json" \
               --output "$RUNNER_TEMP/results.json" \
               --commits abc123 def456
   ```

2. **Or pass all parameters via CLI flags** instead of relying on config files in the working tree:
   ```bash
   scout types UIView UIViewController \
               --output /tmp/results.json \
               --commits abc123 def456
   ```

This applies to `--config` and `--output` paths for all commands (`types`, `files`, `pattern`, `loc`, `build-settings`).

## Requirements

- macOS 15+
- Swift 6.2+
