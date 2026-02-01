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

- `--config <path>` — Path to configuration JSON file
- `--commits, -c <hashes>` — Commit hashes to analyze (default: HEAD)
- `--output, -o <path>` — Path to save JSON results
- `--verbose, -v` — Enable verbose logging
- `--repo-path, -r <path>` — Path to repository with Swift sources (default: current directory)
- `--git-clean` — Clean working directory before analysis (`git clean -ffdx && git reset --hard HEAD`)
- `--fix-lfs` — Fix broken LFS pointers by committing modified files after checkout
- `--initialize-submodules` — Initialize submodules (reset and update to correct commits)

## Configuration (Optional)

Configuration file is optional.

> **Note:** CLI flags take priority over config values.

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

**With git configuration:**

```json
{
  "types": ["UIView", "UIViewController", "View", "XCTestCase"],
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
| `types` | `[String]` | Types to count by inheritance |
| `git` | `Object` | [Git configuration](../Common/GitConfiguration.md) (optional) |

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

## Output Format

When using `--output`, results are saved as JSON array:

```json
[
  {
    "commit": "abc1234def5678",
    "date": "2025-01-15T10:30:00+03:00",
    "results": {
      "UIView": ["CustomButton", "HeaderView", "CardView"],
      "UIViewController": ["HomeViewController", "SettingsViewController"]
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
      "UIView": ["CustomButton", "HeaderView"],
      "UIViewController": ["HomeViewController"]
    }
  },
  {
    "commit": "def5678abc1234",
    "date": "2025-02-15T14:45:00+03:00",
    "results": {
      "UIView": ["CustomButton", "HeaderView", "NewView"],
      "UIViewController": ["HomeViewController", "SettingsViewController"]
    }
  }
]
```

## See Also

- [CodeReader](../CodeReader/README.md) — Code parsing library