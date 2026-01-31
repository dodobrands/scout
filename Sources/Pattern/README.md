# pattern

Search for string patterns in source files across git history.

## Usage

```bash
# Run from within a repository (uses current directory)
scout pattern --commits "abc123,def456"

# Or specify repository path explicitly
scout pattern --repo-path /path/to/repo --commits "abc123,def456"
```

## Arguments

### Optional

- `--repo-path, -r <path>` — Path to repository (default: current directory)
- `--config <path>` — Path to configuration JSON file
- `--commits, -c <hashes>` — Comma-separated list of commit hashes to analyze (default: HEAD)
- `--output, -o <path>` — Path to save JSON results
- `--extensions, -e <extensions>` — Comma-separated file extensions to search (default: swift)
- `--verbose, -v` — Enable verbose logging
- `--initialize-submodules, -I` — Initialize submodules (reset and update to correct commits)

## Configuration (Optional)

Configuration file is optional. Pass it via `--config` flag:

```bash
scout pattern --repo-path /path/to/repo --config pattern-config.json
```

### JSON Format

```json
{
  "patterns": ["import Testing", "import Quick", "// TODO:"],
  "extensions": ["swift", "m"]
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `patterns` | `[String]` | String patterns to search for |
| `extensions` | `[String]?` | File extensions to search in (default: `["swift"]`) |

## Pattern Matching

Performs exact string matching. Useful for:

- Counting import statements: `"import Testing"`, `"@testable import Quick"`
- Finding TODOs: `"// TODO:"`, `"// FIXME:"`
- Tracking API usage: `"periphery:ignore"`, `"@available"`

## See Also

- [CodeReader](../CodeReader/README.md) — Code parsing library