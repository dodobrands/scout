# types

Count Swift types by inheritance across git history.

## Usage

```bash
# Specify types directly
scout types UIView UIViewController View

# Or use config file
scout types --config types-config.json

# Analyze specific commits
scout types UIView --commits abc123 def456
```

## Arguments

### Positional

- `<types>` — Type names to count (e.g., UIView UIViewController)

### Optional

- `--repo-path, -r <path>` — Path to repository with Swift sources (default: current directory)
- `--config <path>` — Path to configuration JSON file
- `--commits, -c <hashes>` — Commit hashes to analyze (default: HEAD)
- `--output, -o <path>` — Path to save JSON results
- `--verbose, -v` — Enable verbose logging
- `--initialize-submodules, -I` — Initialize submodules (reset and update to correct commits)

## Configuration (Optional)

Configuration file is optional. **Command-line arguments take priority over config file values.**

```bash
# Config only
scout types --config types-config.json

# Arguments override config
scout types UIView --config types-config.json
```

### JSON Format

```json
{
  "types": ["UIView", "UIViewController", "View", "XCTestCase"]
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `types` | `[String]` | Types to count by inheritance |

### Examples

Any type name can be used. The tool counts classes/structs that inherit from or conform to the specified types.

**UIKit/SwiftUI:**
```json
{ "types": ["UIView", "UIViewController", "View"] }
```

**Testing frameworks:**
```json
{ "types": ["XCTestCase", "QuickSpec"] }
```

**Generics (with wildcard):**
```json
{ "types": ["BaseCoordinator<*>", "Repository<*>", "UseCase<*>"] }
```

Use `<*>` wildcard to match any generic variant (e.g., `BaseCoordinator<*>` matches `BaseCoordinator<SomeFlow>`, `BaseCoordinator<OtherFlow>`). Without the wildcard, only exact type name matches.

**Custom base classes:**
```json
{ "types": ["BaseViewModel", "BaseService", "FeatureModule"] }
```

## See Also

- [CodeReader](../CodeReader/README.md) — Code parsing library