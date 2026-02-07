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
  "metrics": [
    { "type": "UIView" },
    { "type": "UIViewController" },
    { "type": "View" }
  ]
}
```

**With git configuration:**

```json
{
  "metrics": [
    { "type": "UIView" },
    { "type": "UIViewController" }
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
| `metrics` | `[Metric]` | Array of type metrics to analyze |
| `metrics[].type` | `String` | Type name to count by inheritance |
| `metrics[].commits` | `[String]?` | Commits for this type (default: `["HEAD"]`) |
| `git` | `Object` | [Git configuration](../Common/GitConfiguration.md) (optional) |

### Per-Metric Commits (Config Only)

Different types can be analyzed on different commits. This is only available via config file — CLI arguments apply the same commits to all types.

```json
{
  "metrics": [
    { "type": "UIView", "commits": ["abc123", "def456"] },
    { "type": "UIViewController", "commits": ["ghi789"] },
    { "type": "XCTestCase" },
    { "type": "NSObject", "commits": [] }
  ]
}
```

| Type | Analyzed On |
|------|-------------|
| `UIView` | `abc123`, `def456` |
| `UIViewController` | `ghi789` |
| `XCTestCase` | `HEAD` (default) |
| `NSObject` | skipped (empty array) |

> **Note:** CLI `--commits` flag overrides all config commits and applies to every type equally.

### Examples

Any type name can be used. The tool counts classes/structs that inherit from or conform to the specified types.

**UIKit/SwiftUI:**
```json
{
  "metrics": [
    { "type": "UIView" },
    { "type": "UIViewController" },
    { "type": "View" }
  ]
}
```

**Testing frameworks:**
```json
{
  "metrics": [
    { "type": "XCTestCase" },
    { "type": "QuickSpec" }
  ]
}
```

**Generics (with wildcard):**
```json
{
  "metrics": [
    { "type": "BaseCoordinator<*>" },
    { "type": "Repository<*>" },
    { "type": "UseCase<*>" }
  ]
}
```

Use `<*>` wildcard to match any generic variant (e.g., `BaseCoordinator<*>` matches `BaseCoordinator<SomeFlow>`, `BaseCoordinator<OtherFlow>`). Without the wildcard, only exact type name matches.

**Custom base classes:**
```json
{
  "metrics": [
    { "type": "BaseViewModel" },
    { "type": "BaseService" },
    { "type": "FeatureModule" }
  ]
}
```

## Output Format

When using `--output`, results are saved as JSON array. Each found type includes:

| Field | Description |
|-------|-------------|
| `name` | Simple type name (e.g., `AddToCartEvent`) |
| `fullName` | Qualified name with parent types (e.g., `Analytics.AddToCartEvent`) |
| `path` | Relative file path from repository root |

```json
[
  {
    "commit": "abc1234def5678",
    "date": "2025-01-15T10:30:00+03:00",
    "results": [
      {
        "typeName": "UIView",
        "types": [
          { "name": "CustomButton", "fullName": "CustomButton", "path": "Sources/UI/CustomButton.swift" },
          { "name": "HeaderView", "fullName": "Components.HeaderView", "path": "Sources/Components/HeaderView.swift" }
        ]
      },
      {
        "typeName": "UIViewController",
        "types": [
          { "name": "HomeViewController", "fullName": "HomeViewController", "path": "Sources/Screens/HomeViewController.swift" }
        ]
      }
    ]
  }
]
```

**Multiple commits:**
```json
[
  {
    "commit": "abc1234def5678",
    "date": "2025-01-15T10:30:00+03:00",
    "results": [
      {
        "typeName": "UIView",
        "types": [
          { "name": "CustomButton", "fullName": "CustomButton", "path": "Sources/UI/CustomButton.swift" }
        ]
      }
    ]
  },
  {
    "commit": "def5678abc1234",
    "date": "2025-02-15T14:45:00+03:00",
    "results": [
      {
        "typeName": "UIView",
        "types": [
          { "name": "CustomButton", "fullName": "CustomButton", "path": "Sources/UI/CustomButton.swift" },
          { "name": "NewView", "fullName": "NewView", "path": "Sources/UI/NewView.swift" }
        ]
      }
    ]
  }
]
```

## See Also

- [CodeReader](../CodeReader/README.md) — Code parsing library