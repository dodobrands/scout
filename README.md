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
swift run scout <subcommand> [options]
```

### Available Subcommands

| Subcommand | Description |
|------------|-------------|
| `types` | Count types by inheritance (UIView, UIViewController, etc.) |
| `files` | Count files by extension (storyboard, xib, etc.) |
| `imports` | Count import statements |
| `loc` | Count lines of code with cloc |
| `build-settings` | Extract Xcode build settings |

## Tools

### types

Count Swift types by inheritance across git history. Tracks UIView, UIViewController, SwiftUI View, XCTestCase and other types.

📖 [Full documentation](Sources/Types/README.md)

### files

Count files by extension across git history. Useful for tracking storyboard, xib, swift files count over time.

📖 [Full documentation](Sources/Files/README.md)

### imports

Count import statement usage across git history. Extracts base module name and performs exact matching.

📖 [Full documentation](Sources/Pattern/README.md)

### loc

Count lines of code using `cloc`. Supports filtering by languages, include/exclude paths.

📖 [Full documentation](Sources/LOC/README.md)

### build-settings

Extract build settings from Xcode projects. Supports Tuist-generated projects with custom setup commands.

📖 [Full documentation](Sources/BuildSettings/README.md)

### Examples

```bash
swift run scout types --ios-sources /path/to/repo --config config.json --commits "abc123,def456"
swift run scout files --repo-path /path/to/repo --config config.json --commits "abc123"
swift run scout imports --repo-path /path/to/repo --config config.json --commits "abc123"
swift run scout loc --repo-path /path/to/repo --config config.json --commits "abc123"
swift run scout build-settings --repo-path /path/to/repo --config config.json --commits "abc123"
```

## Libraries

| Module | Description |
|--------|-------------|
| **Common** | Shared utilities (shell, git, logging, retry logic) |
| **CodeReader** | Source code parsing with SourceKitten |

## Configuration

Each subcommand requires a JSON config file. See individual README files in `Sources/*/README.md` for config format.

## Requirements

- macOS 15+
- Swift 6.2+
