# build-settings

Extract build settings from Xcode projects.

## Usage

```bash
# Specify parameters directly
scout build-settings SWIFT_VERSION IPHONEOS_DEPLOYMENT_TARGET

# Or use config file
scout build-settings --config build-settings-config.json

# Analyze specific commits
scout build-settings SWIFT_VERSION --commits abc123 def456
```

## Arguments

### Positional

- `<build-settings-parameters>` — Build settings parameters to extract (e.g., SWIFT_VERSION IPHONEOS_DEPLOYMENT_TARGET)

### Optional

- `--config <path>` — Path to configuration JSON file
- `--commits, -c <hashes>` — Commit hashes to analyze (default: HEAD)
- `--output, -o <path>` — Path to save JSON results
- `--verbose, -v` — Enable verbose logging
- `--repo-path, -r <path>` — Path to repository (default: current directory)
- `--git-clean` — Clean working directory before analysis (`git clean -ffdx && git reset --hard HEAD`)
- `--fix-lfs` — Fix broken LFS pointers by committing modified files after checkout
- `--initialize-submodules` — Initialize submodules (reset and update to correct commits)

## Configuration (Optional)

Configuration file is optional for basic usage, but required for setup commands.

> **Note:** CLI flags take priority over config values.

```bash
# Arguments only
scout build-settings SWIFT_VERSION IPHONEOS_DEPLOYMENT_TARGET

# Config only
scout build-settings --config build-settings-config.json

# Arguments override config
scout build-settings SWIFT_VERSION --config build-settings-config.json
```

### JSON Format

**Minimal (no setup commands):**

```json
{
  "workspaceName": "MyApp",
  "configuration": "Debug",
  "buildSettingsParameters": ["SWIFT_VERSION", "IPHONEOS_DEPLOYMENT_TARGET"]
}
```

**With setup commands (e.g., for generated projects):**

```json
{
  "workspaceName": "MyApp",
  "configuration": "Debug",
  "buildSettingsParameters": ["SWIFT_VERSION", "IPHONEOS_DEPLOYMENT_TARGET"],
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
  "workspaceName": "MyApp",
  "configuration": "Debug",
  "buildSettingsParameters": ["SWIFT_VERSION"],
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
| `workspaceName` | `String` | Xcode workspace/project name (without extension) |
| `configuration` | `String` | Build configuration (Debug, Release, etc.) |
| `buildSettingsParameters` | `[String]` | Build settings to extract |
| `setupCommands` | `[SetupCommand]?` | Commands to execute before analyzing each commit (optional) |
| `setupCommands[].command` | `String` | Shell command to execute |
| `setupCommands[].workingDirectory` | `String?` | Directory relative to repo root (optional) |
| `setupCommands[].optional` | `Bool` | If `true`, analysis continues even if command fails (default: `false`) |
| `git` | `Object` | [Git configuration](../Common/GitConfiguration.md) (optional) |

## Output Format

When using `--output`, results are saved as JSON array:

```json
[
  {
    "commit": "abc1234def5678",
    "date": "2025-01-15T10:30:00+03:00",
    "results": {
      "MyApp": {
        "SWIFT_VERSION": "5.0",
        "IPHONEOS_DEPLOYMENT_TARGET": "15.0"
      },
      "MyAppTests": {
        "SWIFT_VERSION": "5.0",
        "IPHONEOS_DEPLOYMENT_TARGET": "15.0"
      }
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
      "MyApp": {
        "SWIFT_VERSION": "5.0"
      }
    }
  },
  {
    "commit": "def5678abc1234",
    "date": "2025-02-15T14:45:00+03:00",
    "results": {
      "MyApp": {
        "SWIFT_VERSION": "5.9"
      }
    }
  }
]
```

## Requirements

- `xcodebuild` command-line tool
