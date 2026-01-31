# loc

Count lines of code using `cloc`.

## Usage

```bash
# Run from within a repository (uses current directory)
scout loc --commits "abc123,def456"

# Or specify repository path explicitly
scout loc --repo-path /path/to/repo --commits "abc123,def456"
```

## Arguments

### Optional

- `--repo-path, -r <path>` — Path to repository (default: current directory)
- `--config <path>` — Path to configuration JSON file
- `--commits, -c <hashes>` — Comma-separated list of commit hashes to analyze (default: HEAD)
- `--output, -o <path>` — Path to save JSON results
- `--verbose, -v` — Enable verbose logging
- `--initialize-submodules, -I` — Initialize submodules (reset and update to correct commits)

## Configuration (Optional)

Configuration file is optional. Pass it via `--config` flag:

```bash
scout loc --repo-path /path/to/repo --config loc-config.json
```

### JSON Format

```json
{
  "configurations": [
    {
      "languages": ["Swift"],
      "include": ["Sources"],
      "exclude": ["Tests", "Vendor"]
    },
    {
      "languages": ["Swift", "Objective-C"],
      "include": ["LegacyModule"],
      "exclude": []
    }
  ]
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `configurations` | `[Configuration]` | Array of LOC configurations |
| `configurations[].languages` | `[String]` | Programming languages to count |
| `configurations[].include` | `[String]` | Paths to include |
| `configurations[].exclude` | `[String]` | Paths to exclude |

## Requirements

`cloc` must be installed:

```bash
# macOS
brew install cloc

# Linux (Ubuntu/Debian)
sudo apt-get install -y cloc
```

## See Also

- [cloc documentation](https://github.com/AlDanial/cloc)