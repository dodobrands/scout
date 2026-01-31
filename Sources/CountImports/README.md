# imports

Count import statement usage across git history.

## Usage

```bash
swift run scout imports \
  --repo-path /path/to/ios/repo \
  --config count-imports-config.json \
  --commits "abc123,def456"
```

## Arguments

### Required

- `--repo-path, -r <path>` — Path to iOS repository
- `--commits, -c <hashes>` — Comma-separated list of commit hashes to analyze

### Optional

- `--config <path>` — Path to configuration JSON file (default: `count-imports-config.json`)
- `--verbose, -v` — Enable verbose logging
- `--initialize-submodules, -I` — Initialize submodules (reset and update to correct commits)

## Configuration

Create `count-imports-config.json`:

```json
{
  "imports": ["Testing", "Quick", "Nimble"]
}
```

## Import Matching

Extracts base module name and performs exact matching:

- `import Testing` → "Testing"
- `@testable import Testing` → "Testing"
- `import Testing.Foundation` → "Testing"

## See Also

- [AGENTS.md](../../AGENTS.md) — General project documentation
- [CodeReader](../CodeReader/README.md) — Code parsing library