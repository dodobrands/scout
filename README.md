# Scout

<p align="center">
  <img width="128" height="128" alt="Scout Logo" src="https://github.com/user-attachments/assets/b9ef981b-0f65-4a16-abfb-6391af834d7a" />
</p>

Code analysis tools for mobile repositories.

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

Count Swift types by inheritance across git history. Tracks UIView, UIViewController, SwiftUI View, XCTestCase and other types.

```bash
scout types --ios-sources /path/to/repo --config config.json --commits "abc123,def456"
```

📖 [Full documentation](Sources/Types/README.md)

### files

Count files by extension across git history. Useful for tracking storyboard, xib, swift files count over time.

```bash
scout files --repo-path /path/to/repo --config config.json --commits "abc123"
```

📖 [Full documentation](Sources/Files/README.md)

### imports

Count import statement usage across git history. Extracts base module name and performs exact matching.

```bash
scout imports --repo-path /path/to/repo --config config.json --commits "abc123"
```

📖 [Full documentation](Sources/Pattern/README.md)

### loc

Count lines of code using `cloc`. Supports filtering by languages, include/exclude paths.

```bash
scout loc --repo-path /path/to/repo --config config.json --commits "abc123"
```

📖 [Full documentation](Sources/LOC/README.md)

### build-settings

Extract build settings from Xcode projects. Supports Tuist-generated projects with custom setup commands.

```bash
scout build-settings --repo-path /path/to/repo --config config.json --commits "abc123"
```

📖 [Full documentation](Sources/BuildSettings/README.md)

## Requirements

- macOS 15+
- Swift 6.2+
