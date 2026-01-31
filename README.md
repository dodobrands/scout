# Scout

Code analysis tools for mobile repositories.

## Tools

| Tool | Description |
|------|-------------|
| **CountTypes** | Count types by inheritance (UIView, UIViewController, etc.) |
| **CountFiles** | Count files by extension (storyboard, xib, etc.) |
| **CountImports** | Count import statements |
| **CountLOC** | Count lines of code with cloc |
| **ExtractBuildSettings** | Extract Xcode build settings |

## Libraries

| Module | Description |
|--------|-------------|
| **Common** | Shared utilities (shell, git, logging, retry logic) |
| **CodeReader** | Source code parsing with SourceKitten |

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dodobrands/scout.git", branch: "main")
]
```

## Usage

Each tool accepts `--commits` flag with comma-separated commit hashes:

```bash
swift run CountTypes --repo-path /path/to/repo --config config.json --commits "abc123,def456"
swift run CountFiles --repo-path /path/to/repo --config config.json --commits "abc123"
swift run CountImports --repo-path /path/to/repo --config config.json --commits "abc123"
swift run CountLOC --repo-path /path/to/repo --config config.json --commits "abc123"
swift run ExtractBuildSettings --repo-path /path/to/repo --config config.json --commits "abc123"
```

## Configuration

Each tool requires a JSON config file. See individual README files in `Sources/*/README.md` for config format.

## Requirements

- macOS 15+
- Swift 6.2+
