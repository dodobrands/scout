# build-settings

Extract build settings from Xcode projects.

## Usage

```bash
# Specify project and parameters directly
scout build-settings --project MyApp.xcworkspace SWIFT_VERSION IPHONEOS_DEPLOYMENT_TARGET

# Or use config file
scout build-settings --config build-settings-config.json

# CLI overrides config
scout build-settings --project Other.xcodeproj --config build-settings-config.json

# Analyze specific commits
scout build-settings --project MyApp.xcworkspace SWIFT_VERSION --commits abc123 def456
```

## Arguments

### Positional

- `<build-settings-parameters>` — Build settings parameters to extract (e.g., SWIFT_VERSION IPHONEOS_DEPLOYMENT_TARGET)

### Required

- `--project, -p <path>` — Path to Xcode workspace (.xcworkspace) or project (.xcodeproj). Can be relative to repo root or absolute. Required via CLI or config file.

### Optional

- `--config <path>` — Path to configuration JSON file
- `--commits, -c <hashes>` — Commit hashes to analyze (default: HEAD)
- `--output, -o <path>` — Path to save JSON results
- `--verbose, -v` — Enable verbose logging
- `--repo-path, -r <path>` — Path to repository (default: current directory)
- `--git-clean` — Clean working directory before analysis (`git clean -ffdx && git reset --hard HEAD`)
- `--fix-lfs` — Fix broken LFS pointers by committing modified files after checkout
- `--initialize-submodules` — Initialize submodules (reset and update to correct commits)

## Configuration

Configuration file is optional if `--project` is provided via CLI.

> **Note:** CLI flags take priority over config values.

```bash
# CLI only (no config needed)
scout build-settings --project MyApp.xcworkspace SWIFT_VERSION

# Config only
scout build-settings --config build-settings-config.json

# CLI overrides config
scout build-settings --project Other.xcodeproj --config build-settings-config.json
```

### JSON Format

**Minimal:**

```json
{
  "project": "MyApp.xcworkspace"
}
```

**With build settings metrics:**

```json
{
  "project": "MyApp.xcworkspace",
  "configuration": "Debug",
  "metrics": [
    { "setting": "SWIFT_VERSION" },
    { "setting": "IPHONEOS_DEPLOYMENT_TARGET" }
  ]
}
```

**With setup commands (e.g., for generated projects):**

```json
{
  "project": "App/MyApp.xcworkspace",
  "configuration": "Debug",
  "metrics": [
    { "setting": "SWIFT_VERSION" },
    { "setting": "IPHONEOS_DEPLOYMENT_TARGET" }
  ],
  "setupCommands": [
    { "command": "mise install", "optional": true },
    { "command": "tuist install", "workingDirectory": "App" },
    { "command": "tuist generate --no-open", "workingDirectory": "App" }
  ]
}
```

**With git configuration:**

```json
{
  "project": "MyApp.xcodeproj",
  "configuration": "Debug",
  "metrics": [
    { "setting": "SWIFT_VERSION" }
  ],
  "git": {
    "repoPath": "/path/to/repo",
    "clean": true,
    "initializeSubmodules": true
  }
}
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `project` | `String` | **Yes*** | Path to Xcode workspace (.xcworkspace) or project (.xcodeproj). Relative to repo root or absolute. *Can be provided via `--project` CLI flag instead. |
| `configuration` | `String` | No | Build configuration (default: "Debug") |
| `metrics` | `[Metric]` | No | Array of build setting metrics to analyze |
| `metrics[].setting` | `String` | Yes | Build setting name (e.g., `SWIFT_VERSION`) |
| `metrics[].commits` | `[String]?` | No | Commits for this setting (default: `["HEAD"]`) |
| `setupCommands` | `[SetupCommand]` | No | Commands to execute before analyzing each commit |
| `setupCommands[].command` | `String` | Yes | Shell command to execute |
| `setupCommands[].workingDirectory` | `String` | No | Directory relative to repo root |
| `setupCommands[].optional` | `Bool` | No | If `true`, analysis continues even if command fails (default: `false`) |
| `git` | `Object` | No | [Git configuration](../Common/GitConfiguration.md) |

### Per-Metric Commits (Config Only)

Different build settings can be analyzed on different commits. This is only available via config file — CLI arguments apply the same commits to all settings.

```json
{
  "project": "MyApp.xcworkspace",
  "metrics": [
    { "setting": "SWIFT_VERSION", "commits": ["abc123", "def456"] },
    { "setting": "IPHONEOS_DEPLOYMENT_TARGET", "commits": ["ghi789"] },
    { "setting": "MARKETING_VERSION" },
    { "setting": "CURRENT_PROJECT_VERSION", "commits": [] }
  ]
}
```

| Setting | Analyzed On |
|---------|-------------|
| `SWIFT_VERSION` | `abc123`, `def456` |
| `IPHONEOS_DEPLOYMENT_TARGET` | `ghi789` |
| `MARKETING_VERSION` | `HEAD` (default) |
| `CURRENT_PROJECT_VERSION` | skipped (empty array) |

> **Note:** CLI `--commits` flag overrides all config commits and applies to every setting equally.

## Output Format

When using `--output`, results are saved as JSON array:

```json
[
  {
    "commit": "abc1234def5678",
    "date": "2025-01-15T10:30:00+03:00",
    "results": [
      {
        "target": "MyApp",
        "settings": {
          "SWIFT_VERSION": "5.0",
          "IPHONEOS_DEPLOYMENT_TARGET": "15.0"
        }
      },
      {
        "target": "MyAppTests",
        "settings": {
          "SWIFT_VERSION": "5.0",
          "IPHONEOS_DEPLOYMENT_TARGET": "15.0"
        }
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
        "target": "MyApp",
        "settings": {
          "SWIFT_VERSION": "5.0"
        }
      }
    ]
  },
  {
    "commit": "def5678abc1234",
    "date": "2025-02-15T14:45:00+03:00",
    "results": [
      {
        "target": "MyApp",
        "settings": {
          "SWIFT_VERSION": "5.9"
        }
      }
    ]
  }
]
```

## Requirements

- `xcodebuild` command-line tool
