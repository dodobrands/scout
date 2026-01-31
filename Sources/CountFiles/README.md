# files

Count files by extension across git history.

## Usage

```bash
swift run scout files \
  --repo-path /path/to/repo \
  --config count-files-config.json \
  --commits "abc123,def456"
```

## Arguments

### Required

- `--repo-path, -r <path>` — Path to repository
- `--commits, -c <hashes>` — Comma-separated list of commit hashes to analyze

### Optional

- `--config <path>` — Path to configuration JSON file (default: `count-files-config.json`)
- `--verbose, -v` — Enable verbose logging
- `--initialize-submodules, -I` — Initialize submodules (reset and update to correct commits)

## Configuration

Create `count-files-config.json`:

```json
{
  "filetypes": ["storyboard", "xib", "swift"]
}
```

## See Also

- [AGENTS.md](../../AGENTS.md) — General project documentation