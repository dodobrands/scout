# files

Count files by extension across git history.

## Usage

```bash
# Run from within a repository (uses current directory)
scout files --commits "abc123,def456"

# Or specify repository path explicitly
scout files --repo-path /path/to/repo --commits "abc123,def456"
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
scout files --repo-path /path/to/repo --config files-config.json
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

## See Also

- [CodeReader](../CodeReader/README.md) — Code parsing library