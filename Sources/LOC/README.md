# loc

Count lines of code using `cloc`.

## Usage

```bash
# Specify languages directly
scout loc Swift Objective-C

# With include/exclude paths
scout loc Swift --include Sources App --exclude Tests Vendor

# Or use config file
scout loc --config loc-config.json

# Analyze specific commits
scout loc Swift --commits abc123 def456
```

## Arguments

### Positional

- `<languages>` — Programming languages to count (e.g., Swift Objective-C)

### Optional

- `--include, -i <paths>` — Paths to include (e.g., Sources App)
- `--exclude, -e <paths>` — Paths to exclude (e.g., Tests Vendor)
- `--config <path>` — Path to configuration JSON file
- `--commits, -c <hashes>` — Commit hashes to analyze (default: HEAD)
- `--output, -o <path>` — Path to save JSON results
- `--verbose, -v` — Enable verbose logging
- `--repo-path, -r <path>` — Path to repository (default: current directory)
- `--git-clean` — Clean working directory before analysis (`git clean -ffdx && git reset --hard HEAD`)
- `--fix-lfs` — Fix broken LFS pointers by committing modified files after checkout
- `--initialize-submodules` — Initialize submodules (reset and update to correct commits)

## Configuration (Optional)

Configuration file is optional. Use it when you need multiple configurations with different include/exclude paths.

> **Note:** CLI flags take priority over config values.

```bash
# Arguments only (counts all files)
scout loc Swift Objective-C

# Arguments with paths
scout loc Swift --include Sources --exclude Tests

# Config only (multiple configurations)
scout loc --config loc-config.json

# Arguments override config
scout loc Swift --config loc-config.json
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

**With git configuration:**

```json
{
  "configurations": [
    {
      "languages": ["Swift"],
      "include": ["Sources"],
      "exclude": ["Tests"]
    }
  ],
  "git": {
    "repoPath": "/path/to/repo",
    "clean": true,
    "initializeSubmodules": true
  }
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `configurations` | `[Configuration]` | Array of LOC configurations |
| `configurations[].languages` | `[String]` | Programming languages to count |
| `configurations[].include` | `[String]` | Paths to include |
| `configurations[].exclude` | `[String]` | Paths to exclude |
| `git` | `Object` | [Git configuration](../Common/GitConfiguration.md) (optional) |

## Output Format

When using `--output`, results are saved as JSON array:

```json
[
  {
    "commit": "abc1234def5678",
    "date": "2025-01-15T10:30:00+03:00",
    "results": {
      "LOC [Swift] [Sources]": 48500,
      "LOC [Swift, Objective-C] [LegacyModule]": 12000
    }
  }
]
```

**Multiple commits:**
```json
[
  {
    "commit": "abc1234def5678",
    "date": "2025-01-15T10:30:00+03:00",
    "results": {
      "LOC [Swift] [Sources]": 48500
    }
  },
  {
    "commit": "def5678abc1234",
    "date": "2025-02-15T14:45:00+03:00",
    "results": {
      "LOC [Swift] [Sources]": 52000
    }
  }
]
```

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