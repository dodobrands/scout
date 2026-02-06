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
  "metrics": [
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
  "metrics": [
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
| `metrics` | `[Metric]` | Array of LOC metrics to analyze |
| `metrics[].languages` | `[String]` | Programming languages to count |
| `metrics[].include` | `[String]` | Paths to include |
| `metrics[].exclude` | `[String]` | Paths to exclude |
| `metrics[].commits` | `[String]?` | Commits for this metric (default: `["HEAD"]`) |
| `git` | `Object` | [Git configuration](../Common/GitConfiguration.md) (optional) |

### Per-Metric Commits (Config Only)

Different metrics can be analyzed on different commits. This is only available via config file — CLI arguments apply the same commits to all metrics.

```json
{
  "metrics": [
    {
      "languages": ["Swift"],
      "include": ["Sources"],
      "exclude": ["Tests"],
      "commits": ["abc123", "def456"]
    },
    {
      "languages": ["Swift", "Objective-C"],
      "include": ["LegacyModule"],
      "exclude": [],
      "commits": ["ghi789"]
    },
    {
      "languages": ["JSON"],
      "include": ["."],
      "exclude": []
    }
  ]
}
```

| Metric | Analyzed On |
|--------|-------------|
| `Swift in Sources` | `abc123`, `def456` |
| `Swift+ObjC in LegacyModule` | `ghi789` |
| `JSON` | `HEAD` (default) |

> **Note:** CLI `--commits` flag overrides all config commits and applies to every metric equally.

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