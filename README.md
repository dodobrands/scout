# Scout

<p align="center">
  <img width="128" height="128" alt="Scout Logo" src="https://github.com/user-attachments/assets/b9ef981b-0f65-4a16-abfb-6391af834d7a" />
</p>

Code analysis tools for mobile repositories.

## Installation

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
