# pattern

Search for string patterns in source files across git history.

## Usage

```bash
# Specify patterns directly
scout pattern "import UIKit" "import SwiftUI"

# Or use config file
scout pattern --config pattern-config.json

# Analyze specific commits
scout pattern "// TODO:" --commits abc123 def456
```

## Arguments

### Positional

- `<patterns>` — Patterns to search (e.g., "import UIKit" "import SwiftUI")

### Optional

- `--repo-path, -r <path>` — Path to repository (default: current directory)
- `--config <path>` — Path to configuration JSON file
- `--commits, -c <hashes>` — Commit hashes to analyze (default: HEAD)
- `--output, -o <path>` — Path to save JSON results
- `--extensions, -e <extensions>` — Comma-separated file extensions to search (default: swift)
- `--verbose, -v` — Enable verbose logging
- `--initialize-submodules, -I` — Initialize submodules (reset and update to correct commits)

## Configuration (Optional)

Configuration file is optional. **Command-line arguments take priority over config file values.**

```bash
# Config only
scout pattern --config pattern-config.json

# Arguments override config
scout pattern "import UIKit" --config pattern-config.json
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