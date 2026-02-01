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

- `--repo-path, -r <path>` — Path to repository (default: current directory)
- `--config <path>` — Path to configuration JSON file
- `--commits, -c <hashes>` — Commit hashes to analyze (default: HEAD)
- `--output, -o <path>` — Path to save JSON results
- `--verbose, -v` — Enable verbose logging
- `--initialize-submodules, -I` — Initialize submodules (reset and update to correct commits)

## Configuration (Optional)

Configuration file is optional. **Command-line arguments take priority over config file values.**

```bash
# Config only
scout files --config files-config.json

# Arguments override config
scout files swift --config files-config.json
```

### JSON Format

```json
{
  "filetypes": ["storyboard", "xib", "swift"]
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `filetypes` | `[String]` | File extensions to count (without dot)