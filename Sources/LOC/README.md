# loc

Count lines of code using `cloc`.

## Usage

```bash
# Use config file (required for LOC configurations)
scout loc --config loc-config.json

# Analyze specific commits
scout loc --config loc-config.json --commits abc123 def456
```

## Arguments

### Optional

- `--config <path>` — Path to configuration JSON file
- `--commits, -c <hashes>` — Commit hashes to analyze (default: HEAD)
- `--output, -o <path>` — Path to save JSON results
- `--verbose, -v` — Enable verbose logging
- `--repo-path, -r <path>` — Path to repository (default: current directory)
- `--git-clean` — Clean working directory before analysis (`git clean -ffdx && git reset --hard HEAD`)
- `--fix-lfs` — Fix broken LFS pointers by committing modified files after checkout
- `--initialize-submodules` — Initialize submodules (reset and update to correct commits)

## Configuration

LOC tool requires a config file to specify languages and paths.

> **Note:** CLI flags take priority over config values.

```bash
scout loc --config loc-config.json
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