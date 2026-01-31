# loc

Count lines of code using `cloc`.

## Usage

```bash
swift run scout loc \
  --repo-path /path/to/repo \
  --config count-loc-config.json \
  --commits "abc123,def456"
```

## Arguments

### Required

- `--repo-path, -r <path>` — Path to repository
- `--commits, -c <hashes>` — Comma-separated list of commit hashes to analyze

### Optional

- `--config <path>` — Path to configuration JSON file (default: `count-loc-config.json`)
- `--verbose, -v` — Enable verbose logging
- `--initialize-submodules, -I` — Initialize submodules (reset and update to correct commits)

## Configuration

Create `count-loc-config.json`:

```json
{
  "languages": ["Swift", "Objective-C"],
  "include": ["Sources"],
  "exclude": ["Tests"]
}
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

- [AGENTS.md](../../AGENTS.md) — General project documentation
- [cloc documentation](https://github.com/AlDanial/cloc)