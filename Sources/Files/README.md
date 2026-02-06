# files

Count files by extension across git history.

## Usage

```bash
# Specify file types directly
scout files swift storyboard xib

# Or use config file
scout files --config files-config.json

# Analyze specific commits
scout files swift --commits abc123 def456
```

## Arguments

### Positional

- `<filetypes>` — File extensions to count (e.g., swift storyboard xib)

### Optional

- `--config <path>` — Path to configuration JSON file
- `--commits, -c <hashes>` — Commit hashes to analyze (default: HEAD)
- `--output, -o <path>` — Path to save JSON results
- `--verbose, -v` — Enable verbose logging
- `--repo-path, -r <path>` — Path to repository (default: current directory)
- `--git-clean` — Clean working directory before analysis (`git clean -ffdx && git reset --hard HEAD`)
- `--fix-lfs` — Fix broken LFS pointers by committing modified files after checkout
- `--initialize-submodules` — Initialize submodules (reset and update to correct commits)

## Configuration (Optional)

Configuration file is optional.

> **Note:** CLI flags take priority over config values.

```bash
# Config only
scout files --config files-config.json

# Arguments override config
scout files swift --config files-config.json
```

### JSON Format

```json
{
  "metrics": [
    { "extension": "storyboard" },
    { "extension": "xib" },
    { "extension": "swift" }
  ]
}
```

**With git configuration:**

```json
{
  "metrics": [
    { "extension": "storyboard" },
    { "extension": "xib" },
    { "extension": "swift" }
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
| `metrics` | `[Metric]` | Array of file extension metrics to analyze |
| `metrics[].extension` | `String` | File extension to count (without dot) |
| `metrics[].commits` | `[String]?` | Commits for this extension (default: `["HEAD"]`) |
| `git` | `Object` | [Git configuration](../Common/GitConfiguration.md) (optional) |

### Per-Metric Commits (Config Only)

Different extensions can be analyzed on different commits. This is only available via config file — CLI arguments apply the same commits to all extensions.

```json
{
  "metrics": [
    { "extension": "storyboard", "commits": ["abc123", "def456"] },
    { "extension": "xib", "commits": ["ghi789"] },
    { "extension": "swift" },
    { "extension": "deprecated", "commits": [] }
  ]
}
```

| Extension | Analyzed On |
|-----------|-------------|
| `storyboard` | `abc123`, `def456` |
| `xib` | `ghi789` |
| `swift` | `HEAD` (default) |
| `deprecated` | skipped (empty array) |

> **Note:** CLI `--commits` flag overrides all config commits and applies to every extension equally.

## Output Format

When using `--output`, results are saved as JSON array:

```json
[
  {
    "commit": "abc1234def5678",
    "date": "2025-01-15T10:30:00+03:00",
    "results": {
      "swift": ["Sources/App.swift", "Sources/Model.swift"],
      "storyboard": ["Main.storyboard", "Launch.storyboard"]
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
      "swift": ["Sources/App.swift"],
      "storyboard": ["Main.storyboard"]
    }
  },
  {
    "commit": "def5678abc1234",
    "date": "2025-02-15T14:45:00+03:00",
    "results": {
      "swift": ["Sources/App.swift", "Sources/NewFeature.swift"],
      "storyboard": ["Main.storyboard"]
    }
  }
]
```